"""Re-rank species and bone type with measurements the user took.

A photo has no scale, so the model can't tell a 45 cm human femur from a 20 cm pig
femur by size. When the user measures the bone, every (taxon, bone type) candidate is
weighted by how well the measurements fit its reference ranges (length_reference.json)
and the model's probabilities are renormalised. Four measurements can be given
(MEASUREMENTS): the length, and three widths that also work on broken bones: across an
end, across the shaft at its narrowest, and across the ball of the femur or humerus or
the hip socket. A candidate's weight is the product of its weights for each measurement.

Wrong ranges or a mistyped measurement must not wreck a good identification, so:
- the length is only checked on complete bones: an end or a fragment isn't the bone's
  length. The widths are checked on any bone (a broken-off end still has its width), but
  a shaft fragment may be missing its narrowest point, so a wide shaft counts gently
- a measurement inside a range doesn't boost a candidate; it only rules others out, and
  candidates without a reference range are left alone: what a ruled-out candidate loses
  goes to the candidates the measurements could check, never to ones they couldn't
  (otherwise a length that rules out every mammal would make an unchecked "bird" more certain)
- some entries are only an upper bound (birds: nothing living is bigger than an ostrich);
  they rule out lengths above it and say nothing about lengths under it
- no candidate's weight drops to zero, so a strong photo can still win
- smaller than the range counts far more gently than bigger, because juvenile bones
  are small (a child's femur must not be reassigned to a pig on length alone)
- ranges from less trusted sources pull less

`python -m bone_analyzer.inference.length_check` (with src/ on the path, or after
`pip install -e .`) tests the table against the annotated complete bones and walks through
example cases.
"""
import json
import math
from pathlib import Path

from bone_analyzer.config import ANIMAL_CLASSES, BONE_TYPES, MAMMAL_FAMILIES, SPECIES_CLASSES

REFERENCE_FILE = Path(__file__).with_name('length_reference.json')

# Bigger than the range: weight ~0.37 at 10% over, ~0.02 at 20% over, never below the floor
TOLERANCE_ABOVE = 0.10
FLOOR_ABOVE = 0.05
# Smaller than the range: weight ~0.37 at 20% under, ~0.02 at 40% under, never below the floor
TOLERANCE_BELOW = 0.20
FLOOR_BELOW = 0.25
# Hand measurements are off by a little: this much slack either side counts as inside
SLACK_CM = 0.5
SLACK_FRACTION = 0.03
# How strongly a range of each confidence level can push a candidate down (1.0 = fully)
CONFIDENCE_PULL = {'high': 1.0, 'medium': 0.9, 'low': 0.6}
# Below this much probability on checkable candidates the measurements tell us nothing
MIN_CHECKABLE_MASS = 0.05
CANDIDATES_REPORTED = 5

# What the user can measure, in report order: the table of length_reference.json each is
# checked against ('ranges' for the length, else a table under 'widths'), the hand-measuring
# slack (a width is a few cm, so half a centimetre would be a big share of it), whether it
# needs a whole bone, and how it reads in the explanations
MEASUREMENTS = {
    'length_cm': {'table': 'ranges', 'slack_cm': SLACK_CM, 'whole_bone_only': True, 'shown': 'long'},
    'end_width_cm': {'table': 'end_width', 'slack_cm': 0.2, 'whole_bone_only': False, 'shown': 'across the end'},
    'shaft_width_cm': {'table': 'shaft_width', 'slack_cm': 0.2, 'whole_bone_only': False, 'shown': 'across the shaft'},
    'head_diameter_cm': {'table': 'head_diameter', 'slack_cm': 0.2, 'whole_bone_only': False,
                         'shown': 'across the ball or socket'},
}

HUMAN = SPECIES_CLASSES.index('human')
NON_HUMAN = SPECIES_CLASSES.index('non_human')
# The non-human answers a report can give: a mammal family group, or a class for birds and
# reptiles. Their probabilities come from the class and family heads combined (see
# analyzer.py): p(mammal) x p(family), p(bird), p(reptile).
ANIMAL_TAXA = MAMMAL_FAMILIES + [c for c in ANIMAL_CLASSES if c != 'mammal']
UNNAMED_TAXA = ('none', 'unknown')
# How each answer reads in the explanations people see: the family's proper name, then
# what it means
SHOWN_AS = {
    'canid': 'canid (dog family)', 'cervid': 'cervid (deer family)', 'bovid': 'bovid (cattle family)',
    'suid': 'suid (pig family)', 'felid': 'felid (cat family)', 'ursid': 'ursid (bear)',
    'leporid': 'leporid (rabbit or hare)', 'procyonid': 'procyonid (raccoon family)',
    'equid': 'equid (horse family)', 'other_mammal': 'mammal',
}
# What the photo shows when it isn't a whole bone, for "This looks like ..."
PART_SHOWN_AS = {
    'shaft': 'the middle (shaft) of a bone', 'proximal_end': 'one end of a bone',
    'distal_end': 'one end of a bone', 'fragment': 'a broken piece of bone',
}

_reference = None


def reference():
    global _reference
    if _reference is None:
        with open(REFERENCE_FILE, encoding='utf-8') as f:
            _reference = json.load(f)
    return _reference


def reference_range(taxon, bone_type, measurement='length_cm'):
    """The table entry for a taxon ('human' or an animal class) and bone type, or None."""
    table = MEASUREMENTS[measurement]['table']
    ranges = reference()['ranges'] if table == 'ranges' else reference()['widths'][table]
    return ranges.get(taxon, {}).get(bone_type)


def length_fit(length_cm, min_cm, max_cm, slack_cm=SLACK_CM):
    """Returns (fit, side): fit is 1.0 inside the range and decays outside; side is
    'inside', 'above' or 'below'. Works the same for any measurement in cm."""
    slack = max(slack_cm, SLACK_FRACTION * length_cm)
    if length_cm > max_cm + slack:
        over = (length_cm - max_cm - slack) / max_cm
        return math.exp(-(over / TOLERANCE_ABOVE) ** 2), 'above'
    if length_cm < min_cm - slack:
        under = (min_cm - slack - length_cm) / min_cm
        return math.exp(-(under / TOLERANCE_BELOW) ** 2), 'below'
    return 1.0, 'inside'


def candidate_weight(value_cm, entry, measurement='length_cm', gentle_above=False):
    """Weight applied to a candidate's probability, plus its fit and side (None if unchecked).
    A value under an upper-bound-only entry leaves the candidate unchecked. gentle_above
    treats a too-big value like a too-small one (a shaft fragment without its narrowest point)."""
    if entry is None:
        return 1.0, None, None
    slack = MEASUREMENTS[measurement]['slack_cm']
    fit, side = length_fit(value_cm, entry['min_cm'], entry['max_cm'], slack)
    if entry.get('upper_bound_only') and side != 'above':
        return 1.0, None, None
    if side == 'above' and gentle_above:
        fit **= (TOLERANCE_ABOVE / TOLERANCE_BELOW) ** 2      # decays at the too-small rate instead
    floor = FLOOR_ABOVE if side == 'above' and not gentle_above else FLOOR_BELOW
    weight = floor + (1 - floor) * fit
    return 1 - CONFIDENCE_PULL[entry['confidence']] * (1 - weight), fit, side


def display_name(taxon, bone_type):
    who = 'unidentified animal' if taxon in UNNAMED_TAXA else SHOWN_AS.get(taxon, taxon)
    bone = bone_type.replace('_', ' ').replace('vertebrae', 'vertebra')
    return f'{who} {bone}'


def _a(phrase):
    """'a human femur', 'an equid (horse family) femur'."""
    return f"{'an' if phrase[0] in 'aeiou' else 'a'} {phrase}"


def _argmax(values):
    return max(range(len(values)), key=values.__getitem__)


def answer(species_probs, bone_type_probs, animal_probs):
    """The headline the report shows: species, then taxon and bone type from the top classes."""
    species = _argmax(species_probs)
    bone_type = _argmax(bone_type_probs)
    animal = _argmax(animal_probs)
    taxon = 'human' if species == HUMAN else ANIMAL_TAXA[animal]
    return {
        'taxon': taxon,
        'bone_type': BONE_TYPES[bone_type],
        'species_confidence': species_probs[species],
        'bone_type_confidence': bone_type_probs[bone_type],
    }


def rerank(species_probs, bone_type_probs, animal_probs, measurements, part, completeness):
    """Weigh the model's species, bone type and taxon probabilities by measured sizes.

    Arguments are the softmax outputs as lists (SPECIES_CLASSES, BONE_TYPES and
    ANIMAL_TAXA order), the user's measurements as {MEASUREMENTS name: cm} (missing or
    None = not measured), and the predicted part and completeness labels.

    Returns (probabilities, report). probabilities is (species, bone_type, animal)
    after the check, identical to the inputs when the check did not apply; report is a
    JSON-ready summary for the analysis result.
    """
    species_probs = [float(p) for p in species_probs]
    bone_type_probs = [float(p) for p in bone_type_probs]
    animal_probs = [float(p) for p in animal_probs]
    unchanged = (species_probs, bone_type_probs, animal_probs)
    given = {m: float(measurements[m]) for m in MEASUREMENTS if (measurements or {}).get(m) is not None}
    image_answer = answer(*unchanged)
    report = {
        'applied': False,
        'changed': False,
        'user_length_cm': given.get('length_cm'),
        'measurements': given,
        'image_only': image_answer,
        'with_length': image_answer,
    }

    if not given:
        report['reason'] = 'No length was entered.'
        return unchanged, report
    whole = part == 'complete' and completeness == 'complete'
    # Either label may be unknown (None) on images whose portion was never recorded
    shown = PART_SHOWN_AS.get(part if part != 'complete' else completeness, 'only part of a bone')
    used = {m: v for m, v in given.items() if whole or not MEASUREMENTS[m]['whole_bone_only']}
    # Said first when the length was given but couldn't be used
    note = '' if len(used) == len(given) else f"This looks like {shown}, so its length wasn't used. "
    if not used:
        report['reason'] = f"This looks like {shown}, so its length can't be compared with whole bones."
        return unchanged, report
    report['measurements_used'] = list(used)

    candidates = []
    for t, p_type in enumerate(bone_type_probs):
        taxa = [('human', species_probs[HUMAN])]
        taxa += [(name, species_probs[NON_HUMAN] * p) for name, p in zip(ANIMAL_TAXA, animal_probs)]
        for taxon, p_taxon in taxa:
            weight, fits = 1.0, {}
            for m, value in used.items():
                w, _, side = candidate_weight(value, reference_range(taxon, BONE_TYPES[t], m), m,
                                              gentle_above=m == 'shaft_width_cm' and not whole)
                if side is not None:        # under an upper bound counts as no entry
                    weight *= w
                    fits[m] = side
            candidates.append({'taxon': taxon, 'bone_type': BONE_TYPES[t], 'checked': bool(fits),
                               'prior': p_taxon * p_type, 'weight': weight, 'fits': fits})

    checkable = sum(c['prior'] for c in candidates if c['checked'])
    if checkable < MIN_CHECKABLE_MASS:
        names = ' or '.join(_a(display_name(c['taxon'], c['bone_type']))
                            for c in sorted(candidates, key=lambda c: -c['prior'])[:2])
        report['reason'] = note + (f"We don't have usual lengths for {names}, so the length wasn't used."
                                   if list(used) == ['length_cm'] else
                                   f"We don't have usual sizes for {names}, so your measurements weren't used.")
        return unchanged, report

    # Probability moves only between the candidates the measurements could check; the others
    # keep exactly what the photo gave them.
    scale = checkable / sum(c['prior'] * c['weight'] for c in candidates if c['checked'])
    for c in candidates:
        c['posterior'] = c['prior'] * c['weight'] * scale if c['checked'] else c['prior']

    new_species = [0.0] * len(species_probs)
    new_bone_type = [0.0] * len(bone_type_probs)
    new_animal = [0.0] * len(animal_probs)
    for c in candidates:
        t = BONE_TYPES.index(c['bone_type'])
        new_bone_type[t] += c['posterior']
        if c['taxon'] == 'human':
            new_species[HUMAN] += c['posterior']
        else:
            new_species[NON_HUMAN] += c['posterior']
            new_animal[ANIMAL_TAXA.index(c['taxon'])] += c['posterior']
    if new_species[NON_HUMAN] > 0:
        new_animal = [p / new_species[NON_HUMAN] for p in new_animal]
    else:
        new_animal = animal_probs

    final_answer = answer(new_species, new_bone_type, new_animal)
    changed = (final_answer['taxon'], final_answer['bone_type']) != (image_answer['taxon'], image_answer['bone_type'])
    report.update({
        'applied': True,
        'candidates': [
            {
                'taxon': c['taxon'],
                'bone_type': c['bone_type'],
                'reference_cm': _reference_cm(c['taxon'], c['bone_type'], 'length_cm'),
                'length_fit': c['fits'].get('length_cm') or 'no reference',
                'reference_widths_cm': {m: _reference_cm(c['taxon'], c['bone_type'], m)
                                        for m in used if m != 'length_cm'},
                'fits': c['fits'],
                'image_probability': c['prior'],
                'length_weighted_probability': c['posterior'],
            }
            for c in sorted(candidates, key=lambda c: -c['posterior'])[:CANDIDATES_REPORTED]
        ],
    })

    # Only let the measurements replace the answer with one they actually fit (or can't
    # check). Swapping between two candidates they contradict would be guesswork,
    # especially for juveniles, whose bones are all proportionally small.
    _, after_side = _describe(used, final_answer)
    if changed and after_side in ('above', 'below'):
        report['reason'] = note + _explain_no_fit(used, image_answer, final_answer)
        return unchanged, report

    report['changed'] = changed
    report['with_length'] = final_answer
    report['reason'] = note + _explain(used, image_answer, final_answer, changed)
    return (new_species, new_bone_type, new_animal), report


def _reference_cm(taxon, bone_type, measurement):
    entry = reference_range(taxon, bone_type, measurement)
    return None if entry is None else [entry['min_cm'], entry['max_cm']]


def _length_only(used):
    return list(used) == ['length_cm']


def _join(items):
    """'a', 'a and b', 'a, b and c'."""
    return ' and '.join(filter(None, [', '.join(items[:-1]), items[-1]]))


def _values(used, labelled=False):
    """'19 cm' for a length on its own (unless labelled), else '19 cm long and 4.1 cm across the end'."""
    if _length_only(used) and not labelled:
        return f"{used['length_cm']:g} cm"
    return _join([f"{v:g} cm {MEASUREMENTS[m]['shown']}" for m, v in used.items()])


def _sides(used, a):
    """{measurement: 'inside' / 'above' / 'below'} for the ones a's ranges can check."""
    sides = {}
    for m, value in used.items():
        entry = reference_range(a['taxon'], a['bone_type'], m)
        if entry is not None:
            side = length_fit(value, entry['min_cm'], entry['max_cm'], MEASUREMENTS[m]['slack_cm'])[1]
            if side == 'above' or not entry.get('upper_bound_only'):
                sides[m] = side
    return sides


def _describe(used, a, labelled=False):
    """'a human femur (usually 34.4–55 cm)' plus where the measurements fall, for the
    explanation: 'above' if any is too big, else 'below' if any is too small, else 'inside'
    (None when none could be checked)."""
    name = _a(display_name(a['taxon'], a['bone_type']))
    usual, never, sides = [], [], []
    for m, value in used.items():
        entry = reference_range(a['taxon'], a['bone_type'], m)
        if entry is None:
            continue
        _, side = length_fit(value, entry['min_cm'], entry['max_cm'], MEASUREMENTS[m]['slack_cm'])
        what = '' if _length_only(used) and not labelled else f" {MEASUREMENTS[m]['shown']}"
        if entry.get('upper_bound_only'):
            if side == 'above':
                never.append(f"{entry['max_cm']:g} cm{what}")
                sides.append(side)
            continue
        usual.append(f"{entry['min_cm']:g}–{entry['max_cm']:g} cm{what}")
        sides.append(side)
    if not sides:
        return name, None
    ranges = '; '.join(filter(None, ['usually ' + _join(usual) if usual else '',
                                     'never over ' + _join(never) if never else '']))
    side = next(s for s in ('above', 'below', 'inside') if s in sides)
    return f'{name} ({ranges})', side


def _explain_no_fit(used, image_answer, best_alternative):
    before, _ = _describe(used, image_answer)
    after, _ = _describe(used, best_alternative)
    fit = "doesn't fit" if len(used) == 1 else "don't fit"
    return (f"{_values(used)} {fit} {before} or the next closest option, {after}, so we kept "
            f"the photo's answer. It could be from a young animal or person, or worth measuring again.")


def _explain(used, image_answer, final_answer, changed):
    values = _values(used)
    before, before_side = _describe(used, image_answer)
    after, after_side = _describe(used, final_answer)
    if _length_only(used):
        if changed:
            why = {'above': f'is too long for {before}',
                   'below': f'is too short for {before}',
                   'inside': f'fits {before}, but ruling out other options shifted the answer',
                   None: f"can't be checked against {before}"}[before_side]
            fits = f'it fits {after}' if after_side == 'inside' else f"{after} can't be ruled out by length"
            return f'{values} {why}, and {fits}, so the length changed the answer.'
        if before_side is None:
            return (f"We don't have a usual length for {before}, so the length couldn't confirm it. "
                    f"It only helped weigh up the other options.")
        if before_side == 'inside':
            return f'{values} is a normal length for {before}, which backs up the answer.'
        if before_side == 'below':
            return (f'{values} is short for {before}, but the photo still points to it. '
                    f'It could be from a young animal or person, or worth measuring again.')
        return f'{values} is long for {before}, but the photo still points to it. Worth measuring again.'

    one = len(used) == 1
    is_, they = ('is', 'it') if one else ('are', 'they')
    # Too big or too small: name only the measurements that are, with their ranges
    if before_side in ('above', 'below'):
        bad = {m: v for m, v in used.items() if _sides(used, image_answer).get(m) == before_side}
        bad_before, _ = _describe(bad, image_answer, labelled=True)
        bad_is = f"{_values(bad, labelled=True)} {'is' if len(bad) == 1 else 'are'}"
    if changed:
        fits = (f"{they} {'fits' if one else 'fit'} {after}" if after_side == 'inside'
                else f"{after} can't be ruled out by {'this measurement' if one else 'these measurements'}")
        if before_side in ('above', 'below'):
            size = 'big' if before_side == 'above' else 'small'
            if one:
                return f'{bad_is} too {size} for {bad_before}, and {fits}, so the measurement changed the answer.'
            fits = f'fit {after}' if after_side == 'inside' else f"can't rule out {after}"
            return f'{bad_is} too {size} for {bad_before}, and your measurements {fits}, so they changed the answer.'
        why = {'inside': f"{'fits' if one else 'fit'} {before}, but ruling out other options shifted the answer",
               None: f"can't be checked against {before}"}[before_side]
        return f"{values} {why}, and {fits}, so {'the measurement' if one else 'the measurements'} changed the answer."
    if before_side is None:
        return (f"We don't have usual sizes for {before}, so your {'measurement' if one else 'measurements'} "
                f"couldn't confirm it. {'It' if one else 'They'} only helped weigh up the other options.")
    if before_side == 'inside':
        return f'{values} {is_} normal for {before}, which backs up the answer.'
    if before_side == 'below':
        return (f'{bad_is} small for {bad_before}, but the photo still points to it. '
                f'It could be from a young animal or person, or worth measuring again.')
    return f'{bad_is} big for {bad_before}, but the photo still points to it. Worth measuring again.'


def _validate():
    """Check the table against annotated complete bones and walk through example cases."""
    from bone_analyzer.config import annotation_file
    from bone_analyzer.taxonomy import class_label, family_label

    print('Reference table vs. annotated complete bones (midpoint of each label):')
    outside = 0
    for split in ('train', 'val'):
        with open(annotation_file(split), encoding='utf-8') as f:
            annotations = json.load(f)
        seen = set()
        for a in annotations:
            if a['phase4_bone_part']['part'] != 'complete' or a['phase5_completeness']['status'] != 'complete':
                continue
            if a['phase2_species'].get('species') == 'human':
                taxon = 'human'
            else:
                taxon = family_label(a) or class_label(a)
            bone_type = a['phase3_bone_type']['bone_type']
            entry = reference_range(taxon, bone_type)
            if entry is None:
                continue
            lo = (a.get('bone_length') or {}).get('min_length_cm')
            hi = (a.get('bone_length') or {}).get('max_length_cm')
            if lo is None or hi is None:
                continue
            key = (split, taxon, bone_type, lo, hi)
            if key in seen:
                continue
            seen.add(key)
            mid = (lo + hi) / 2
            weight, fit, side = candidate_weight(mid, entry)
            flag = '' if side in ('inside', None) else f'  <-- {side}, weight {weight:.2f}'
            outside += side not in ('inside', None)
            print(f"  {split:<5s} {display_name(taxon, bone_type):<18s} label {lo:g}-{hi:g}  "
                  f"reference {entry['min_cm']:g}-{entry['max_cm']:g}{flag}")
    print(f'  {outside} label(s) outside their reference range\n')

    def p(n, **hot):
        """n-class distribution with the given indices hot and the rest sharing what is left."""
        probs = [0.0] * n
        for i, v in hot.items():
            probs[int(i[1:])] = v
        rest = (1 - sum(hot.values())) / (n - len(hot)) if len(hot) < n else 0.0
        return [v if v else rest for v in probs]

    bt = {b: f'_{i}' for i, b in enumerate(BONE_TYPES)}
    an = {s: f'_{i}' for i, s in enumerate(ANIMAL_TAXA)}
    na = len(ANIMAL_TAXA)
    cases = [
        ('human femur 55% vs pig 30%, 19 cm', p(2, _0=0.55, _1=0.45), p(16, **{bt['femur']: 0.9}), p(na, **{an['suid']: 0.67, an['canid']: 0.3}), {'length_cm': 19.0}),
        ('human femur 90%, 19 cm (child?)', p(2, _0=0.9, _1=0.1), p(16, **{bt['femur']: 0.9}), p(na, **{an['suid']: 0.6, an['canid']: 0.35}), {'length_cm': 19.0}),
        ('pig femur 60%, 45 cm', p(2, _0=0.4, _1=0.6), p(16, **{bt['femur']: 0.9}), p(na, **{an['suid']: 0.9}), {'length_cm': 45.0}),
        ('human femur 80%, 44 cm', p(2, _0=0.8, _1=0.2), p(16, **{bt['femur']: 0.9}), p(na, **{an['suid']: 0.9}), {'length_cm': 44.0}),
        ('human femur 55% vs humerus 35%, 19 cm (fits neither)', p(2, _0=0.9, _1=0.1), p(16, **{bt['femur']: 0.55, bt['humerus']: 0.35}), p(na, **{an['suid']: 0.9}), {'length_cm': 19.0}),
        ('vertebra 70%, 5 cm (no ranges)', p(2, _0=0.8, _1=0.2), p(16, **{bt['thoracic_vertebrae']: 0.7, bt['femur']: 0.2}), p(na, **{an['suid']: 0.9}), {'length_cm': 5.0}),
        ('human femur 60% vs deer 40%, 8 cm across the end', p(2, _0=0.6, _1=0.4), p(16, **{bt['femur']: 0.9}), p(na, **{an['cervid']: 0.9}), {'end_width_cm': 8.0}),
        ('human femur 55% vs deer 45%, 4.5 cm across the end', p(2, _0=0.55, _1=0.45), p(16, **{bt['femur']: 0.9}), p(na, **{an['cervid']: 0.9}), {'end_width_cm': 4.5}),
        ('human femur 70%, 46 cm long, 8 cm end, 4.7 cm head', p(2, _0=0.7, _1=0.3), p(16, **{bt['femur']: 0.9}), p(na, **{an['bovid']: 0.9}), {'length_cm': 46.0, 'end_width_cm': 8.0, 'head_diameter_cm': 4.7}),
        ('hip bone, bird 60% vs mammal, 18.4 cm', p(2, _0=0.1, _1=0.9), p(16, **{bt['os_coxa']: 0.8}), p(na, **{an['bird']: 0.6, an['cervid']: 0.2, an['bovid']: 0.15}), {'length_cm': 18.4}),
    ]
    for name, sp, bone, animal, measures in cases:
        (new_sp, new_bt, new_an), r = rerank(sp, bone, animal, measures, 'complete', 'complete')
        w = r['with_length']
        print(f"{name}\n  -> {display_name(w['taxon'], w['bone_type'])} "
              f"(species {w['species_confidence']:.0%}, changed={r['changed']})\n  {r['reason']}")
        assert abs(sum(new_sp) - 1) < 1e-9 and abs(sum(new_bt) - 1) < 1e-9 and abs(sum(new_an) - 1) < 1e-9
    for measures in ({'length_cm': 19.0}, {'length_cm': 19.0, 'end_width_cm': 4.5}, {'shaft_width_cm': 3.0}):
        _, r = rerank(p(2, _0=0.9, _1=0.1), p(16, **{bt['femur']: 0.9}), p(na, **{an['suid']: 0.9}), measures, 'proximal_end', 'complete')
        print(f"end of a femur, {measures}\n  -> applied={r['applied']}: {r['reason']}")


if __name__ == '__main__':
    _validate()
