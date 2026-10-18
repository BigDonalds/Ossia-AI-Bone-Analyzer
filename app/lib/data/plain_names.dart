/// Everyday meanings for the scientific words a report uses, so "Cervid" or
/// "Humerus" also says what it is. Keys match the model's labels.
library;

import '../core/util/formatting.dart';

/// A proper name and what it means, e.g. Cervid: the deer family.
class PlainName {
  const PlainName(this.name, this.meaning);

  final String name;
  final String meaning;
}

const Map<String, PlainName> _animals = <String, PlainName>{
  'human': PlainName('Human', 'a person'),
  'canid': PlainName('Canid', 'the dog family (dogs, wolves, coyotes and foxes)'),
  'cervid': PlainName('Cervid', 'the deer family (deer, elk, moose and caribou)'),
  'bovid': PlainName('Bovid', 'the cattle family (cows, bison, sheep, goats and antelope)'),
  'suid': PlainName('Suid', 'the pig family (pigs, wild boar and warthogs)'),
  'felid': PlainName('Felid', 'the cat family (house cats, bobcats, cougars and lions)'),
  'ursid': PlainName('Ursid', 'bears'),
  'leporid': PlainName('Leporid', 'rabbits and hares'),
  'procyonid': PlainName('Procyonid', 'the raccoon family (raccoons, coatis and ringtails)'),
  'equid': PlainName('Equid', 'the horse family (horses, donkeys and zebras)'),
  'rodent': PlainName('Rodent', 'rats, mice, squirrels, beavers and their kin'),
  'other_mammal': PlainName('Mammal',
      'an animal with fur that feeds its young milk, from a family Ossia doesn\'t name, like a skunk or opossum'),
  'mammal': PlainName('Mammal',
      'an animal with fur that feeds its young milk. This bone doesn\'t show which family'),
  'bird': PlainName('Bird', 'any bird, from sparrows to ostriches'),
  'reptile': PlainName('Reptile', 'turtles, snakes, lizards and crocodiles'),
};

const PlainName _unnamedAnimal =
    PlainName('Animal', 'an animal bone that no animal group stood out for');

/// What a reported animal group means. Unnamed groups ('none', 'unknown',
/// 'non_human') read as "Animal"; any other name keeps its own, with no
/// meaning to add.
PlainName animalName(String taxon) =>
    _animals[taxon] ??
    (const <String>{'none', 'unknown', 'non_human'}.contains(taxon)
        ? _unnamedAnimal
        : PlainName(titleCase(taxon), ''));

const Map<String, String> _bones = <String, String>{
  'skull': 'the whole head',
  'cranium': 'the skull without the lower jaw',
  'mandible': 'the lower jaw',
  'femur': 'the thigh bone',
  'tibia': 'the shin bone',
  'humerus': 'the upper arm or upper front-leg bone',
  'radius': 'a forearm or lower front-leg bone',
  'ulna': 'a forearm or lower front-leg bone, with the elbow point',
  'scapula': 'the shoulder blade',
  'os_coxa': 'the hip bone',
  'rib_1_2': 'one of the top two ribs',
  'typical_rib': 'a rib from the middle of the chest',
  'rib_11_12': 'one of the bottom two ribs',
  'cervical_vertebrae': 'a neck bone',
  'thoracic_vertebrae': 'a bone from the upper back',
  'lumbar_vertebrae': 'a bone from the lower back',
};

/// What a bone type is in everyday words, e.g. femur: the thigh bone.
String? boneMeaning(String boneType) => _bones[boneType];

const Map<String, String> _parts = <String, String>{
  'complete': 'Whole bone',
  'shaft': 'Middle (shaft)',
  'proximal_end': 'Near end',
  'distal_end': 'Far end',
  'fragment': 'Broken piece',
};

/// Which part of the bone the photo shows, in everyday words.
String partLabel(String part) => _parts[part] ?? titleCase(part);

/// Whole or broken, in everyday words.
String completenessLabel(String status) =>
    const <String, String>{'complete': 'Complete', 'fragment': 'Broken'}[status] ?? titleCase(status);

/// One phrase for both, without saying the same thing twice:
/// "Whole bone", "Near end, broken", "Broken piece".
String conditionLabel(String part, String status) {
  if (part == 'complete') return status == 'fragment' ? 'Whole bone, but broken' : 'Whole bone';
  return status == 'fragment' && part != 'fragment' ? '${partLabel(part)}, broken' : partLabel(part);
}
