"""The categorical heads as training, calibration and the reports see them."""
from bone_analyzer.config import (AGE_LABELS, ANIMAL_CLASSES, BONE_TYPES, COMPLETENESS_LABELS, MAMMAL_FAMILIES,
                                  PART_LABELS, SEX_LABELS, SPECIES_CLASSES)
from bone_analyzer.data.dataset import age_label
from bone_analyzer.taxonomy import class_label, family_label


def _phase(ann, phase):
    return ann.get(phase) or {}


def _sex_label(ann):
    profile = _phase(ann, 'phase8_biological_profile')
    return profile.get('sex') if profile.get('applicable') else None


# Batch label key, model output key, class list, metric name, the label an annotation gives
# this head (None = masked), and which images in a batch the head is trained on.
HEADS = {
    'species': ('species', 'species', SPECIES_CLASSES, 'species_accuracy',
                lambda a: _phase(a, 'phase2_species').get('species'),
                lambda b: b['species'] != -1),
    'bone_type': ('bone_type', 'bone_type', BONE_TYPES, 'bone_type_accuracy',
                  lambda a: _phase(a, 'phase3_bone_type').get('bone_type'),
                  lambda b: b['bone_type'] != -1),
    'bone_part': ('part', 'bone_part', PART_LABELS, 'part_accuracy',
                  lambda a: _phase(a, 'phase4_bone_part').get('part'),
                  lambda b: b['part'] != -1),
    'completeness': ('completeness', 'completeness', COMPLETENESS_LABELS, 'completeness_accuracy',
                     lambda a: _phase(a, 'phase5_completeness').get('status'),
                     lambda b: b['completeness'] != -1),
    'animal_class': ('animal_class', 'animal_class', ANIMAL_CLASSES, 'animal_class_accuracy',
                     class_label,
                     lambda b: (b['species'] == 1) & (b['animal_class'] != -1)),
    'animal_family': ('animal_family', 'animal_family', MAMMAL_FAMILIES, 'animal_family_accuracy',
                      family_label,
                      lambda b: (b['species'] == 1) & (b['animal_family'] != -1)),
    'age_group': ('age_group', 'age_group', AGE_LABELS, 'age_accuracy',
                  lambda a: age_label(_phase(a, 'phase8_biological_profile')),
                  lambda b: (b['species'] == 0) & (b['age_group'] != -1)),
    'sex': ('sex', 'sex', SEX_LABELS, 'sex_accuracy',
            _sex_label,
            lambda b: (b['species'] == 0) & (b['sex'] != -1)),
}

# Reported (not scored) as balanced accuracy, the mean of each class's hit rate, so a big class
# can't hide a weak one in the printed numbers; the save score uses F1 (see config.SAVE_WEIGHTS).
BALANCED_REPORT = ('species', 'animal_class', 'animal_family')
# F1 averaged over classes weighted by their image count; other heads average it plainly
WEIGHTED_F1 = ('bone_type',)
