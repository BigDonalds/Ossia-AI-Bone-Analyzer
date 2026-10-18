"""Favour the bone types that match the shape the user picked (long bone, skull, ...).

The pick is a hint, not a filter: bone types of other shapes keep SHAPE_FLOOR of their
probability and everything is renormalised, so a photo that clearly shows something else still
wins over a wrong pick. A simulation on an earlier test set: with every user right, a
hard filter fixed 3.4 points of bone-type accuracy and this gentle one 2.2; with 10-25% of users
picking wrong, the hard filter lost 6-17 points while the gentle one still gained 1.2-1.9.
Only about a quarter of the model's bone-type mistakes cross shapes (femur vs humerus doesn't),
which is why the gain is modest.

Ribs are under both long and flat: people see them either way.
"""
from bone_analyzer.config import BONE_TYPES

_RIBS = ('rib_1_2', 'typical_rib', 'rib_11_12')
SHAPES = {
    'long': ('femur', 'humerus', 'tibia', 'radius', 'ulna') + _RIBS,
    'skull': ('skull', 'cranium', 'mandible'),
    'flat': ('scapula', 'os_coxa') + _RIBS,
    'vertebra': ('cervical_vertebrae', 'thoracic_vertebrae', 'lumbar_vertebrae'),
}
# How each pick reads in the explanation: "You said it's ..."
SHAPE_SHOWN_AS = {'long': 'a long bone', 'skull': 'part of a skull or jaw', 'flat': 'a flat bone',
                  'vertebra': 'a piece of backbone (vertebra)'}
SHAPE_FLOOR = 0.2

assert all(t in BONE_TYPES for types in SHAPES.values() for t in types)


def _name(bone_type):
    return bone_type.replace('_', ' ').replace('vertebrae', 'vertebra')


def apply_shape(bone_type_probs, shape):
    """Bone-type probabilities (BONE_TYPES order) weighed by the user's shape pick.

    Returns (probabilities, report); the probabilities are the inputs unchanged when no shape
    was given. Raises ValueError for a shape not in SHAPES.
    """
    probs = [float(p) for p in bone_type_probs]
    before = max(range(len(probs)), key=probs.__getitem__)
    report = {'applied': False, 'changed': False, 'shape': shape, 'image_only': BONE_TYPES[before],
              'with_shape': BONE_TYPES[before]}
    if shape is None:
        return probs, report
    if shape not in SHAPES:
        raise ValueError(f"Unknown shape '{shape}'; expected one of {', '.join(SHAPES)}")

    weighted = [p * (1.0 if t in SHAPES[shape] else SHAPE_FLOOR) for t, p in zip(BONE_TYPES, probs)]
    total = sum(weighted)
    new = [p / total for p in weighted]
    after = max(range(len(new)), key=new.__getitem__)
    said = f"You said it's {SHAPE_SHOWN_AS[shape]}"
    if after != before:
        reason = (f"{said}, so we went with {_name(BONE_TYPES[after])} rather than "
                  f"{_name(BONE_TYPES[before])}, which the photo leaned towards.")
    elif BONE_TYPES[after] in SHAPES[shape]:
        reason = f"{said}, which matches what the photo shows."
    else:
        bone = _name(BONE_TYPES[after])
        reason = (f"{said}, but the photo still points to {'an' if bone[0] in 'aeiou' else 'a'} {bone}, so we kept "
                  f"that. If you're sure, a photo from another angle may help.")
    report.update(applied=True, changed=after != before, with_shape=BONE_TYPES[after], reason=reason)
    return new, report
