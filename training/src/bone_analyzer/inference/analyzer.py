"""Runs the trained model on a photo and builds the phase-by-phase report the app shows."""
import math
from pathlib import Path
from typing import Dict, List, Optional

import cv2
import numpy as np
import torch
import torch.nn.functional as F

from bone_analyzer.config import (AGE_LABELS, ANIMAL_CLASSES, BONE_TYPES, CHECKPOINT_DIR, COMPLETENESS_LABELS,
                                  DEVICE, FAMILY_MIN_CONFIDENCE, IMG_SIZE, MAMMAL_FAMILIES, PART_LABELS, SEX_LABELS,
                                  SPECIES_CLASSES, USE_LENGTH_RERANK)
from bone_analyzer.console import Colors, print_colored
from bone_analyzer.data.images import decode_image, letterbox_resize
from bone_analyzer.data.transforms import IMAGENET_MEAN, IMAGENET_STD
from bone_analyzer.model import load_bone_cnn
from bone_analyzer.taxonomy import family_visible

from .head_sex import sex_from_head
from .length_check import ANIMAL_TAXA, MEASUREMENTS, display_name, reference_range, rerank
from .shape_hint import apply_shape

UNAVAILABLE_PHASES = {
    'phase2_species': {'species': 'unknown', 'confidence': 0.0, 'available': False},
    'phase3_bone_type': {'predictions': [], 'available': False},
    'phase4_bone_part': {'part': 'unknown', 'available': False},
    'phase5_completeness': {'status': 'unknown', 'available': False},
    'phase6_damage': {'fracture': 0.0, 'cut_marks': 0.0, 'burn_signs': 0.0, 'available': False},
    'phase7_species_detail': {'species': 'unknown', 'available': False},
    'phase8_biological_profile': {'age_group': 'unknown', 'sex': 'unknown', 'available': False},
    'bone_length': {'available': False},
}


def _argmax(values):
    return max(range(len(values)), key=values.__getitem__)


def calibrated(outputs, temperatures):
    """Each head's logits divided by its temperature (training.calibration), so a stated 80%
    is right about 80% of the time. Dividing by a positive number never changes which answer
    a head picks, or which side of 0.5 a yes/no head lands on; only how sure it claims to be."""
    return {k: v / torch.as_tensor(temperatures[k], dtype=v.dtype, device=v.device) if k in temperatures else v
            for k, v in outputs.items()}


def calibration_note(model):
    return ('confidence calibration on' if model.temperatures
            else 'confidence calibration OFF: this checkpoint has none (python scripts/calibrate.py <checkpoint>)')


def animal_taxa_probs(outputs):
    """Probabilities over ANIMAL_TAXA (mammal family groups, then bird and reptile).

    A mammal family's probability is p(mammal) x p(family | mammal); bird and reptile take
    their class probability, so the list sums to 1.
    """
    class_probs = F.softmax(outputs['animal_class'][0], dim=0).tolist()
    family_probs = F.softmax(outputs['animal_family'][0], dim=0).tolist()
    p_class = dict(zip(ANIMAL_CLASSES, class_probs))
    return [p_class['mammal'] * p for p in family_probs] + [p_class[c] for c in ANIMAL_TAXA[len(MAMMAL_FAMILIES):]]


def animal_answer(taxa_probs, bone_type, part):
    """The phase 7 block from probabilities over ANIMAL_TAXA and the identified bone.

    The class always comes out. The family is given only for a mammal whose bone shows it
    (config.FAMILY_BONE_TYPES); 'species' is the family when it is one of the named
    groups and holds at least FAMILY_MIN_CONFIDENCE of the mammal probability, and
    otherwise the class (e.g. 'mammal' for a rib, a skunk jaw or an unclear family).
    """
    families = taxa_probs[:len(MAMMAL_FAMILIES)]
    class_probs = {'mammal': sum(families)}
    class_probs.update(zip(ANIMAL_TAXA[len(MAMMAL_FAMILIES):], taxa_probs[len(MAMMAL_FAMILIES):]))
    animal_class = max(class_probs, key=class_probs.get)
    family, family_conf = None, 0.0
    if animal_class == 'mammal' and family_visible(bone_type, part) and class_probs['mammal'] > 0:
        best = _argmax(families)
        family, family_conf = MAMMAL_FAMILIES[best], families[best] / class_probs['mammal']
    named = family if family not in (None, 'other_mammal') and family_conf >= FAMILY_MIN_CONFIDENCE else None
    return {
        'species': named or animal_class,
        'confidence': taxa_probs[ANIMAL_TAXA.index(named)] if named else class_probs[animal_class],
        'class': animal_class, 'class_confidence': class_probs[animal_class],
        'family': family, 'family_confidence': family_conf,
    }


def head_probabilities(outputs):
    """One photo's calibrated outputs as probability lists: species, bone type, animal taxa
    (ANIMAL_TAXA), part, completeness, damage (each its own yes/no), age group and sex."""
    return {
        'species': F.softmax(outputs['species'][0], dim=0).tolist(),
        'bone_type': F.softmax(outputs['bone_type'][0], dim=0).tolist(),
        'animal': animal_taxa_probs(outputs),
        'part': F.softmax(outputs['bone_part'][0], dim=0).tolist(),
        'completeness': F.softmax(outputs['completeness'][0], dim=0).tolist(),
        'damage': torch.sigmoid(outputs['damage'][0]).tolist(),
        'age': F.softmax(outputs['age_group'][0], dim=0).tolist(),
        'sex': F.softmax(outputs['sex'][0], dim=0).tolist(),
    }


def clarity(probs):
    """How clear one photo's answer is for a head: 1 when it is certain, 0 when every option is
    equally likely (one minus the normalised entropy), plus a floor so every photo counts."""
    entropy = -sum(p * math.log(p) for p in probs if p > 0)
    return 0.1 + 1 - entropy / math.log(len(probs))


def combine_photos(photos):
    """Head by head, the average of several photos' probabilities (head_probabilities after the
    shape and measurement checks), a clear photo counting more than a vague one: an end with
    its joint says more about the bone than a plain stretch of shaft. Damage is a plain mean."""
    combined = {}
    for head in photos[0]:
        rows = [p[head] for p in photos]
        weights = [1.0] * len(rows) if head == 'damage' else [clarity(r) for r in rows]
        total = sum(weights)
        combined[head] = [sum(w * r[i] for w, r in zip(weights, rows)) / total for i in range(len(rows[0]))]
    return combined


class BoneAnalyzer:
    """Phase 1 is the bone detection head; phases 2-8 the species, bone type, part,
    completeness, damage, taxon, age and sex heads.

    The shape the user picked (long bone, skull, ...) favours the matching bone types
    (shape_hint.py); measured sizes then re-rank species and bone type (length_check.py),
    and the report carries the reference ranges for the identified bone and, for a human
    femur or humerus, what its head diameter suggests about sex (head_sex.py).
    """

    def __init__(self):
        self.device = torch.device(DEVICE)
        self.model = None
        self.has_classifier = False

    def load_trained_model(self, model_path: str = None):
        """Load a checkpoint. If it can't be loaded, phases 2-8 are reported unavailable."""
        model_path = model_path or CHECKPOINT_DIR / 'bone_analyzer.pt'
        if not Path(model_path).exists():
            print(f"No trained model found at {model_path}")
            return
        try:
            self.model, _ = load_bone_cnn(model_path, self.device)
            self.has_classifier = True
            print(f"Loaded trained model from {model_path} ({calibration_note(self.model)})")
        except Exception as e:
            print(f"Error loading model: {e}")
            self.has_classifier = False

    def preprocess_for_model(self, image: np.ndarray) -> torch.Tensor:
        """Letterbox and normalise an RGB photo exactly like the training images."""
        # A plain resize would stretch long, thin bones into squares; the training images
        # were letterboxed by scripts/preprocess.py, so inference must be too.
        image = letterbox_resize(image, IMG_SIZE)
        tensor = torch.from_numpy(image).float().permute(2, 0, 1) / 255.0
        mean = torch.tensor(IMAGENET_MEAN).view(3, 1, 1)
        std = torch.tensor(IMAGENET_STD).view(3, 1, 1)
        return ((tensor - mean) / std).unsqueeze(0).to(self.device)

    def analyze_image(self, image_path: str, user_length: Optional[float] = None,
                      widths: Optional[Dict[str, float]] = None, shape: Optional[str] = None) -> Dict:
        """Analyze one photo.

        user_length is the bone's measured length in cm and widths its measured widths
        ({'end_width_cm', 'shaft_width_cm', 'head_diameter_cm'}: cm), if the user gave them;
        they re-rank species and bone type (length_check.py). shape is the user's pick
        from shape_hint.SHAPES, or None.
        """
        return self._analyze(image_path, user_length, widths, shape)[0]

    def _analyze(self, image_path, user_length, widths, shape):
        """analyze_image's report, plus the probabilities it was built from (after the shape and
        measurement checks), or None when no bone was found."""
        measurements = {'length_cm': user_length, **(widths or {})}
        image = decode_image(Path(image_path).read_bytes())
        if image is None:
            raise ValueError(f"Cannot load image: {image_path}")
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        if not self.has_classifier:
            results = {'phase1_bone_detection': {'bone_present': False, 'confidence': 0.0, 'final_verdict': False,
                                                 'final_confidence': 0.0, 'image_path': image_path}}
            results.update({k: dict(v, note='No trained model') for k, v in UNAVAILABLE_PHASES.items()})
            results['length_check'] = {'applied': False, 'changed': False, 'user_length_cm': user_length,
                                       'reason': 'No trained model.'}
            results['shape_hint'] = {'applied': False, 'changed': False, 'shape': shape}
            return results, None

        with torch.no_grad():
            outputs = calibrated(self.model(self.preprocess_for_model(image)), self.model.temperatures)

        # Phase 1: bone detection head, trained against the no_bone image set
        bone_conf = torch.sigmoid(outputs['bone_detection'][0]).item()
        present = bone_conf > 0.5
        results = {'phase1_bone_detection': {'bone_present': present, 'confidence': bone_conf, 'final_verdict': present,
                                             'final_confidence': bone_conf, 'image_path': image_path}}
        if not present:
            results.update({k: dict(v) for k, v in UNAVAILABLE_PHASES.items()})
            results['length_check'] = {'applied': False, 'changed': False, 'user_length_cm': user_length,
                                       'reason': "No bone was found, so the length wasn't used."}
            results['shape_hint'] = {'applied': False, 'changed': False, 'shape': shape}
            return results, None

        probs = head_probabilities(outputs)

        # The user's shape pick first: it says which bone types to expect, before sizes are compared
        probs['bone_type'], results['shape_hint'] = apply_shape(probs['bone_type'], shape)

        # Measurement check: weigh species / bone type / taxon by the user's measurements
        reranked, length_check = rerank(probs['species'], probs['bone_type'], probs['animal'], measurements,
                                        PART_LABELS[_argmax(probs['part'])],
                                        COMPLETENESS_LABELS[_argmax(probs['completeness'])])
        if USE_LENGTH_RERANK:
            probs['species'], probs['bone_type'], probs['animal'] = reranked
        results['length_check'] = length_check
        results.update(self._phases(probs, measurements))
        return results, probs

    def _phases(self, probs: Dict, measurements: Dict) -> Dict:
        """Phases 2-8 and the reference blocks, from one photo's probabilities or several
        photos' combined ones (combine_photos)."""
        results = {}
        part_idx, comp_idx = _argmax(probs['part']), _argmax(probs['completeness'])

        # Phase 2: Species
        species_idx = _argmax(probs['species'])
        results['phase2_species'] = {'species': SPECIES_CLASSES[species_idx],
                                     'confidence': probs['species'][species_idx], 'available': True}

        # Phase 3: Bone type (top 3)
        bone_type_probs = probs['bone_type']
        top3 = sorted(range(len(bone_type_probs)), key=lambda i: -bone_type_probs[i])[:3]
        results['phase3_bone_type'] = {
            'predictions': [{'bone_type': BONE_TYPES[i], 'confidence': bone_type_probs[i]} for i in top3],
            'available': True,
        }

        # Phases 4-5: Bone part and completeness
        results['phase4_bone_part'] = {'part': PART_LABELS[part_idx], 'confidence': probs['part'][part_idx],
                                       'available': True}
        results['phase5_completeness'] = {'status': COMPLETENESS_LABELS[comp_idx],
                                          'confidence': probs['completeness'][comp_idx], 'available': True}

        # Phase 6: Damage (multi-label)
        damage = probs['damage']
        results['phase6_damage'] = {'fracture': damage[0], 'cut_marks': damage[1], 'burn_signs': damage[2],
                                    'available': True}

        # Phase 7: animal class, and family group when the bone shows it
        is_human = SPECIES_CLASSES[species_idx] == 'human'
        animal = animal_answer(probs['animal'], BONE_TYPES[top3[0]], PART_LABELS[part_idx])
        results['phase7_species_detail'] = dict(animal, available=True, applicable=not is_human)

        # Phase 8: Biological profile (age and sex) - human only
        if is_human:
            age_idx, sex_idx = _argmax(probs['age']), _argmax(probs['sex'])
            results['phase8_biological_profile'] = {
                'age_group': AGE_LABELS[age_idx], 'age_confidence': probs['age'][age_idx],
                'sex': SEX_LABELS[sex_idx], 'sex_confidence': probs['sex'][sex_idx],
                'available': True, 'applicable': True,
            }
        else:
            results['phase8_biological_profile'] = {'available': True, 'applicable': False, 'note': 'Non-human bone'}

        taxon = 'human' if is_human else (animal['family'] or animal['class'])
        results['bone_length'] = self._length_block(taxon, BONE_TYPES[top3[0]])
        results['bone_widths'] = self._widths_block(taxon, BONE_TYPES[top3[0]])
        results['head_sex_hint'] = self._sex_block(taxon, BONE_TYPES[top3[0]], measurements)
        return results

    @staticmethod
    def _length_block(taxon: str, bone_type: str) -> Dict:
        """Reference length range for the identified bone, when the table has one."""
        entry = reference_range(taxon, bone_type)
        if entry is None or entry.get('upper_bound_only'):
            return {'available': False}
        measured = f" (measured on {entry['measured_on']})" if entry.get('measured_on') else ''
        return {'min_cm': entry['min_cm'], 'max_cm': entry['max_cm'], 'range_source': 'reference',
                'reference_for': display_name(taxon, bone_type) + measured, 'available': True}

    @staticmethod
    def _widths_block(taxon: str, bone_type: str) -> Dict:
        """Reference width ranges for the identified bone, per measurement the table has."""
        widths = {}
        for m in MEASUREMENTS:
            entry = None if m == 'length_cm' else reference_range(taxon, bone_type, m)
            if entry is not None:
                widths[m] = {'min_cm': entry['min_cm'], 'max_cm': entry['max_cm'],
                             'reference_for': display_name(taxon, bone_type)}
        return {'available': bool(widths), **widths}

    @staticmethod
    def _sex_block(taxon: str, bone_type: str, measurements: Dict) -> Dict:
        """What a measured femoral or humeral head says about sex, independent of the sex head."""
        hint = sex_from_head(taxon, bone_type, measurements.get('head_diameter_cm'))
        return {'available': False} if hint is None else dict(hint, available=True)

    def analyze_multiple_images(self, image_paths: List[str], user_length: Optional[float] = None,
                                widths: Optional[Dict[str, float]] = None, shape: Optional[str] = None) -> Dict:
        """Analyze several photos of the same bone. The photos that show a bone are combined head
        by head (combine_photos) and the report is built from that, as for a single photo; a
        photo without a bone doesn't water the answer down."""
        analyzed = []
        for img_path in image_paths:
            try:
                analyzed.append(self._analyze(img_path, user_length, widths, shape))
            except Exception as e:
                print_colored(f"  Error: {Path(img_path).name} - {e}", Colors.RED)
        if not analyzed:
            return {'error': True, 'message': 'No valid images to analyze'}
        n = len(analyzed)
        measurements = {'length_cm': user_length, **(widths or {})}

        # A bone is there if any photo shows one, as surely as the surest photo says so
        detections = [r['phase1_bone_detection'] for r, _ in analyzed]
        bone_photos = [probs for _, probs in analyzed if probs is not None]
        best = max(d['final_confidence'] for d in detections)
        report = {'phase1_bone_detection': {
            'bone_present': bool(bone_photos), 'confidence': best,
            'final_verdict': bool(bone_photos), 'final_confidence': best,
            'per_image': [{'image': Path(d['image_path']).name, 'final_verdict': d['final_verdict'],
                           'final_confidence': d['final_confidence']} for d in detections],
        }}
        if bone_photos:
            report.update(self._phases(combine_photos(bone_photos), measurements))
        else:
            report.update({k: dict(v) for k, v in UNAVAILABLE_PHASES.items()})
        report['bone_length']['user_length_cm'] = user_length

        # Each photo was re-ranked with the same shape and measurements before they were combined
        checks = [r['length_check'] for r, _ in analyzed]
        shapes = [r['shape_hint'] for r, _ in analyzed]
        report['length_check'] = {
            'applied': any(c['applied'] for c in checks),
            'changed': any(c['changed'] for c in checks),
            'user_length_cm': user_length,
            'measurements': {k: v for k, v in measurements.items() if v is not None},
            'per_image': checks,
        }
        report['shape_hint'] = {
            'applied': any(h['applied'] for h in shapes),
            'changed': any(h['changed'] for h in shapes),
            'shape': shape,
            'per_image': shapes,
        }
        report['phase9_multi_image'] = {'num_angles': n, 'photos_with_bone': len(bone_photos),
                                        'user_length_cm': user_length}
        report['num_images_analyzed'] = n
        return report
