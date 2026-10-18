"""Taxonomic class and family group of the animal an annotation names.

Annotations keep the name their source gave (phase7 'species', e.g. 'deer' or 'Bos taurus',
plus a top-level 'scientific_name'). This module turns that into what the model learns:
a class in config.ANIMAL_CLASSES and, for mammals, a group in config.MAMMAL_FAMILIES.
The lookup table (data/taxonomy_table.json) holds every name in the dataset, resolved with
the GBIF backbone taxonomy, with hand corrections for the few names GBIF matched wrongly.
"""
import json
import re
from functools import lru_cache

from bone_analyzer.config import ANIMAL_CLASSES, FAMILY_BONE_TYPES, MAMMAL_FAMILIES, TAXONOMY_TABLE

TABLE_FILE = TAXONOMY_TABLE

# GBIF family -> model family group. Rodents are grouped by order (see config.py).
FAMILY_GROUPS = {'Canidae': 'canid', 'Cervidae': 'cervid', 'Bovidae': 'bovid', 'Suidae': 'suid', 'Felidae': 'felid',
                 'Ursidae': 'ursid', 'Leporidae': 'leporid', 'Procyonidae': 'procyonid', 'Equidae': 'equid'}
# Names that never identify an animal
UNNAMED = {'', 'unidentified animal', 'unknown_species', 'unknown', 'none', 'vertebrata'}

assert set(FAMILY_GROUPS.values()) | {'rodent', 'other_mammal'} == set(MAMMAL_FAMILIES)


@lru_cache(maxsize=1)
def _table():
    return json.loads(TABLE_FILE.read_text(encoding='utf-8')) if TABLE_FILE.exists() else {}


def lookup(name):
    """{'class', 'order', 'family'} for a name, or None if it doesn't identify an animal."""
    name = (name or '').strip()
    if name.lower() in UNNAMED:
        return None
    return _table().get(name) or _table().get(re.sub(r'\s+sp\.?$', '', name))


def _groups(entry):
    """(class, family group) of a table entry; either may be None."""
    if entry is None:
        return None, None
    animal_class = entry['class'] if entry['class'] in ANIMAL_CLASSES else None
    if animal_class != 'mammal':
        return animal_class, None
    if entry.get('order') == 'Rodentia':
        return 'mammal', 'rodent'
    family = entry.get('family')
    return 'mammal', (FAMILY_GROUPS.get(family, 'other_mammal') if family else None)


def classify(annotation):
    """(class, family group) for a non-human annotation, each None when unknown.

    The phase7 name is the reviewed one (a reviewer can correct a source's label), so it
    wins; the scientific name only fills in detail it lacks, e.g. phase7 'Mammalia' plus
    scientific name 'Odocoileus virginianus'.
    """
    phase7 = annotation.get('phase7_species_detail') or {}
    if not phase7.get('applicable', False):
        return None, None
    reviewed = _groups(lookup(phase7.get('species')))
    source = _groups(lookup(annotation.get('scientific_name')))
    if 'needs_id' in (annotation.get('source') or ''):
        # iNaturalist observations nobody has confirmed yet: the class is near-certain,
        # the family is only the observer's first guess
        source = (source[0], None)
    if reviewed[0] is None:
        return source
    if reviewed[1] is None and source[0] == reviewed[0]:
        return reviewed[0], source[1]
    return reviewed


def family_visible(bone_type, part):
    """Whether a photo of this bone can show the animal's family (see config.FAMILY_BONE_TYPES)."""
    if bone_type not in FAMILY_BONE_TYPES:
        return False
    return bone_type in ('skull', 'cranium', 'mandible') or part not in ('fragment', 'shaft')


def class_label(annotation):
    """The class this annotation trains, or None (masked)."""
    return classify(annotation)[0]


def family_label(annotation):
    """The family group this annotation trains, or None (masked): only mammals whose bone shows it."""
    animal_class, family = classify(annotation)
    if animal_class != 'mammal' or family is None:
        return None
    bone_type = (annotation.get('phase3_bone_type') or {}).get('bone_type')
    part = (annotation.get('phase4_bone_part') or {}).get('part')
    return family if family_visible(bone_type, part) else None

