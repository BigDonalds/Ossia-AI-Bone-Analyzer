"""What a measured femoral or humeral head diameter suggests about sex.

Shown separately from the sex head's answer, and only for an adult human femur or humerus. The
cut points come from the Goldman Osteometric Data Set (B. M. Auerbach; 1,509 adults of known
sex from 59 places worldwide, see length_reference.json 'goldman'): with men and women counted
equally, a head below the female cut is female 9 times in 10, and one at or above the male cut
male 9 times in 10. Between them the sexes overlap and the hint says it can't tell. The male cut
is raised from the data set's 45.7 mm (femur) and 44.8 mm (humerus) to 46 mm because modern
populations are bigger than its mostly preindustrial ones: recent White American women average
42.2 mm (femur) and 42.1 mm (humerus) (Milner & Boldsen 2012, J Forensic Sci 57(1):35-40).
Body size varies between populations, so this is a hint, not a determination.
"""

# cm: (suggests female below, suggests male from)
CUTS_CM = {'femur': (3.85, 4.6), 'humerus': (3.8, 4.6)}
SOURCE = ('Cut points from the Goldman Osteometric Data Set: 1,509 adults of known sex from 59 places '
          'worldwide. Below the lower value 9 in 10 adults are female, from the upper value 9 in 10 are male.')


def sex_from_head(taxon, bone_type, head_cm):
    """The hint block for the report, or None when it doesn't apply (not a human femur or
    humerus, or no head diameter measured)."""
    if taxon != 'human' or bone_type not in CUTS_CM or head_cm is None:
        return None
    female_below, male_from = CUTS_CM[bone_type]
    head = f'A {head_cm:g} cm {bone_type} head'
    if head_cm < female_below:
        suggests = 'female'
        reason = f'{head} is in the range usually seen in women (under {female_below:g} cm), so it suggests female.'
    elif head_cm >= male_from:
        suggests = 'male'
        reason = f'{head} is in the range usually seen in men ({male_from:g} cm and over), so it suggests male.'
    else:
        suggests = 'unclear'
        reason = (f'{head} is in the range where men and women overlap ({female_below:g}–{male_from:g} cm), '
                  f"so it can't tell.")
    return {
        'suggests': suggests, 'bone_type': bone_type, 'head_diameter_cm': head_cm,
        'female_below_cm': female_below, 'male_from_cm': male_from,
        'reason': reason + " This is separate from the AI's guess and only holds for adult bones.",
        'source': SOURCE,
    }
