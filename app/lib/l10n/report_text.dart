/// Says a report's length notes in the app's language.
///
/// Reports carry their length note as an English sentence, written by
/// report_builder.dart on the phone or length_check.py on the server, and
/// saved finds keep it that way. This reads the sentence back into its parts
/// and words it again. English shows the report's own sentence; a sentence
/// this doesn't recognise (a newer server, or notes about several
/// measurements) also stays in English rather than being guessed at.
library;

import 'app_localizations.dart';
import 'labels.dart';

/// [reason] from a report's length check, in the app's language.
String lengthNote(AppLocalizations l, String reason) {
  final String said =
      l.localeName == 'en' ? reason : _LengthNotes(l).say(reason.trim()) ?? reason;
  // A number keeps its unit on the same line ("33,4 cm", never "33,4" then "cm"),
  // and a range stays in one piece ("20,5–33,4", never broken after the dash).
  return said
      .replaceAllMapped(_numberThenUnit, (Match m) => '${m[1]}\u00A0${m[2]}')
      .replaceAllMapped(_range, (Match m) => '${m[1]}–\u2060${m[2]}');
}

final RegExp _numberThenUnit = RegExp(r'(\d) (cm|سم)');
final RegExp _range = RegExp(r'(\d)–(\d)');

/// What a typical range was taken from, e.g. "cervid (deer family) femur
/// (measured on white-tailed and mule deer)", in the app's language.
String referenceName(AppLocalizations l, String referenceFor) {
  if (l.localeName == 'en') return referenceFor;
  return _LengthNotes(l).reference(referenceFor.trim()) ?? referenceFor;
}

/// How report_builder.dart names an animal group ([shown_as] in
/// ossia_model.json, else the key itself), back to the key.
const Map<String, String> _who = <String, String>{
  'human': 'human',
  'canid (dog family)': 'canid',
  'cervid (deer family)': 'cervid',
  'bovid (cattle family)': 'bovid',
  'suid (pig family)': 'suid',
  'felid (cat family)': 'felid',
  'ursid (bear)': 'ursid',
  'leporid (rabbit or hare)': 'leporid',
  'procyonid (raccoon family)': 'procyonid',
  'equid (horse family)': 'equid',
  'mammal': 'other_mammal',
  'unidentified animal': 'none',
  'canid': 'canid',
  'cervid': 'cervid',
  'bovid': 'bovid',
  'suid': 'suid',
  'felid': 'felid',
  'ursid': 'ursid',
  'leporid': 'leporid',
  'procyonid': 'procyonid',
  'equid': 'equid',
  'rodent': 'rodent',
  'other_mammal': 'other_mammal',
  'bird': 'bird',
  'reptile': 'reptile',
};

const List<String> _boneKeys = <String>[
  'skull', 'cranium', 'mandible', 'femur', 'tibia', 'humerus', 'radius', 'ulna',
  'scapula', 'os_coxa', 'rib_1_2', 'typical_rib', 'rib_11_12',
  'cervical_vertebrae', 'thoracic_vertebrae', 'lumbar_vertebrae',
];

class _LengthNotes {
  _LengthNotes(this.l);

  final AppLocalizations l;

  static const String _n = r'(\d+(?:\.\d+)?)';
  static final RegExp _usually = RegExp(' \\(usually $_n–$_n cm\\)\$');
  static final RegExp _neverOver = RegExp(' \\(never over $_n cm\\)\$');
  // Greedy to the last bracket: "domestic dogs (all breeds) and …" has its own.
  static final RegExp _measuredOn = RegExp(r' \(measured on (.+)\)$');

  /// German writes a decimal comma; digits stay Western in Arabic.
  String _num(String raw) => l.localeName == 'de' ? raw.replaceAll('.', ',') : raw;

  /// "human femur" or "cervid (deer family) cervical vertebra" as
  /// (taxon, bone type), or null.
  (String, String)? _whoAndBone(String phrase) {
    for (final String key in _boneKeys) {
      final String shown = key.replaceAll('_', ' ').replaceAll('vertebrae', 'vertebra');
      if (!phrase.endsWith(' $shown')) continue;
      final String? taxon = _who[phrase.substring(0, phrase.length - shown.length - 1)];
      if (taxon != null) return (taxon, key);
    }
    return null;
  }

  String _named(String taxon, String bone) =>
      l.lenThing(l.animalName(taxon), l.boneName(bone));

  /// "a human femur (usually 34.4–55 cm)", the way _describe writes it, in
  /// the app's language.
  String? _thing(String text) {
    String phrase = text;
    if (phrase.startsWith('an ')) {
      phrase = phrase.substring(3);
    } else if (phrase.startsWith('a ')) {
      phrase = phrase.substring(2);
    } else {
      return null;
    }
    String Function(String)? withRange;
    final RegExpMatch? usual = _usually.firstMatch(phrase);
    final RegExpMatch? never = _neverOver.firstMatch(phrase);
    if (usual != null) {
      phrase = phrase.substring(0, usual.start);
      withRange = (String t) => l.lenUsually(t, _num(usual[1]!), _num(usual[2]!));
    } else if (never != null) {
      phrase = phrase.substring(0, never.start);
      withRange = (String t) => l.lenNeverOver(t, _num(never[1]!));
    }
    final (String, String)? found = _whoAndBone(phrase);
    if (found == null) return null;
    final String named = _named(found.$1, found.$2);
    return withRange == null ? named : withRange(named);
  }

  /// "a human femur or a cervid (deer family) femur". Animal names can hold
  /// an "or" of their own ("rabbit or hare"), so every split is tried.
  String? _things(String text) {
    final String? one = _thing(text);
    if (one != null) return one;
    int at = text.indexOf(' or ');
    while (at >= 0) {
      final String? first = _thing(text.substring(0, at));
      final String? second = _thing(text.substring(at + 4));
      if (first != null && second != null) return l.lenOrThing(first, second);
      at = text.indexOf(' or ', at + 1);
    }
    return null;
  }

  String? say(String s) {
    if (s == "No bone was found, so the length wasn't used.") return l.lenNoBone;
    if (s == 'No length was entered.') return l.lenNoLength;
    switch (s) {
      case "This looks like the middle (shaft) of a bone, so its length can't be compared with whole bones.":
        return l.lenOnlyShaft;
      case "This looks like one end of a bone, so its length can't be compared with whole bones.":
        return l.lenOnlyEnd;
      case "This looks like a broken piece of bone, so its length can't be compared with whole bones.":
        return l.lenOnlyPiece;
      case "This looks like only part of a bone, so its length can't be compared with whole bones.":
        return l.lenOnlyPart;
    }

    RegExpMatch? m;
    m = RegExp(r"^We don't have usual lengths for (.+), so the length wasn't used\.$").firstMatch(s);
    if (m != null) {
      final String? things = _things(m[1]!);
      return things == null ? null : l.lenNoReference(things);
    }

    m = RegExp('^$_n cm doesn\'t fit (.+) or the next closest option, (.+), so we kept the '
            "photo's answer\\. It could be from a young animal or person, or worth measuring again\\.\$")
        .firstMatch(s);
    if (m != null) {
      final String? before = _thing(m[2]!);
      final String? after = _thing(m[3]!);
      return before == null || after == null ? null : l.lenNoFit(_num(m[1]!), before, after);
    }

    const String changedTail = ', so the length changed the answer.';
    if (s.endsWith(changedTail)) return _changed(s.substring(0, s.length - changedTail.length));

    m = RegExp(r"^We don't have a usual length for (.+), so the length couldn't confirm it\. "
            r'It only helped weigh up the other options\.$')
        .firstMatch(s);
    if (m != null) {
      final String? before = _thing(m[1]!);
      return before == null ? null : l.lenNoUsual(before);
    }

    m = RegExp('^$_n cm is a normal length for (.+), which backs up the answer\\.\$').firstMatch(s);
    if (m != null) {
      final String? before = _thing(m[2]!);
      return before == null ? null : l.lenNormal(_num(m[1]!), before);
    }

    m = RegExp('^$_n cm is short for (.+), but the photo still points to it\\. It could be from a '
            'young animal or person, or worth measuring again\\.\$')
        .firstMatch(s);
    if (m != null) {
      final String? before = _thing(m[2]!);
      return before == null ? null : l.lenShort(_num(m[1]!), before);
    }

    m = RegExp('^$_n cm is long for (.+), but the photo still points to it\\. Worth measuring again\\.\$')
        .firstMatch(s);
    if (m != null) {
      final String? before = _thing(m[2]!);
      return before == null ? null : l.lenLong(_num(m[1]!), before);
    }
    return null;
  }

  /// "45 cm is too long for X, and it fits Y" (the tail already cut off).
  String? _changed(String body) {
    String? why;
    String? fits;
    const String itFits = ', and it fits ';
    const String notRuledOut = " can't be ruled out by length";
    final int fitsAt = body.lastIndexOf(itFits);
    if (fitsAt >= 0) {
      final String? after = _thing(body.substring(fitsAt + itFits.length));
      if (after != null) fits = l.lenChangedNowFits(after);
      why = body.substring(0, fitsAt);
    } else if (body.endsWith(notRuledOut)) {
      final String rest = body.substring(0, body.length - notRuledOut.length);
      final int andAt = rest.lastIndexOf(', and ');
      if (andAt < 0) return null;
      final String? after = _thing(rest.substring(andAt + 6));
      if (after != null) fits = l.lenChangedNotRuledOut(after);
      why = rest.substring(0, andAt);
    }
    if (why == null || fits == null) return null;

    final RegExpMatch? m = RegExp(
      '^$_n cm (is too long for|is too short for|fits|can\'t be checked against) (.+?)'
      '(, but ruling out other options shifted the answer)?\$',
    ).firstMatch(why);
    if (m == null) return null;
    final String cm = _num(m[1]!);
    final String? before = _thing(m[3]!);
    if (before == null) return null;
    final String first = switch (m[2]) {
      'is too long for' => l.lenChangedTooLong(cm, before),
      'is too short for' => l.lenChangedTooShort(cm, before),
      'fits' => l.lenChangedFitsBut(cm, before),
      _ => l.lenChangedUnchecked(cm, before),
    };
    return '$first $fits';
  }

  /// "human femur" or "cervid (deer family) femur (measured on white-tailed
  /// and mule deer)".
  String? reference(String text) {
    String phrase = text;
    String? measured;
    final RegExpMatch? m = _measuredOn.firstMatch(phrase);
    if (m != null) {
      phrase = phrase.substring(0, m.start);
      measured = switch (m[1]) {
        'black and brown bear' => l.measuredBears,
        'cattle' => l.measuredCattle,
        'domestic cat' => l.measuredCat,
        'domestic dogs (all breeds) and red and gray fox' => l.measuredDogsFoxes,
        'domestic pig and wild boar' => l.measuredPigBoar,
        'eastern cottontail' => l.measuredCottontail,
        'horse' => l.measuredHorse,
        'raccoon' => l.measuredRaccoon,
        'white-tailed and mule deer' => l.measuredDeer,
        _ => m[1],
      };
    }
    final (String, String)? found = _whoAndBone(phrase);
    if (found == null) return null;
    final String named = '${l.animalName(found.$1)} · ${l.boneName(found.$2)}';
    return measured == null ? named : l.lenMeasuredOn(named, measured);
  }
}
