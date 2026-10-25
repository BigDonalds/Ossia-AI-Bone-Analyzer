/// Field reference for the sixteen bone classes the model is trained on
/// (`bone_analyzer/config.py::BONE_TYPES`). Kept as plain data so the Reference
/// tab and the Results screen can share one source of truth.
library;

enum BoneRegion {
  cranial('Cranial'),
  axial('Axial'),
  thoracic('Thoracic'),
  upperLimb('Upper limb'),
  lowerLimb('Lower limb'),
  girdle('Girdle');

  const BoneRegion(this.label);
  final String label;
}

class BoneEntry {
  const BoneEntry({
    required this.key,
    required this.name,
    required this.code,
    required this.blurb,
    required this.region,
    required this.summary,
    required this.landmarks,
    required this.siding,
    this.alsoKnownAs,
  });

  /// Matches the model label, e.g. `cervical_vertebrae`.
  final String key;
  final String name;

  /// Short catalogue code, e.g. `FEM`.
  final String code;

  /// One line that distinguishes this element at a glance, for list rows.
  final String blurb;
  final BoneRegion region;
  final String summary;

  /// Diagnostic features an analyst would look for.
  final List<String> landmarks;

  /// How to tell left from right, or which position in a series.
  final String siding;
  final String? alsoKnownAs;
}

const List<BoneEntry> kBoneReference = <BoneEntry>[
  BoneEntry(
    key: 'skull',
    name: 'Skull',
    code: 'SKL',
    blurb: 'Cranium and mandible together',
    region: BoneRegion.cranial,
    summary:
        'The complete bony head: the cranium together with the mandible. '
        'Twenty-two bones in all, joined by interlocking sutures; only the '
        'mandible articulates freely.',
    landmarks: <String>[
      'Coronal, sagittal, lambdoid and squamous sutures',
      'Orbits and the piriform (nasal) aperture',
      'Foramen magnum on the basicranium',
      'Mastoid processes behind the ear canals',
    ],
    siding:
        'Symmetrical. Orientation comes from the frontal bone (anterior) and '
        'the occipital squama (posterior).',
  ),
  BoneEntry(
    key: 'cranium',
    name: 'Cranium',
    code: 'CRA',
    blurb: 'The skull without its jaw',
    region: BoneRegion.cranial,
    summary:
        'The skull with the mandible removed. Encloses and protects the brain; '
        'the vault is made of frontal, parietal, temporal and occipital bones.',
    landmarks: <String>[
      'Supraorbital ridges — heavier in male crania',
      'Nuchal lines on the occipital',
      'Temporal lines sweeping across the parietals',
      'External auditory meatus',
    ],
    siding:
        'Symmetrical when complete. Isolated vault fragments are sided by '
        'suture direction and meningeal groove patterning.',
    alsoKnownAs: 'Calvarium (vault only)',
  ),
  BoneEntry(
    key: 'mandible',
    name: 'Mandible',
    code: 'MND',
    blurb: 'Lower jaw; dense and durable',
    region: BoneRegion.cranial,
    summary:
        'The lower jaw — the only freely mobile bone of the skull. Dense and '
        'compact, so it survives burial and burning better than most.',
    landmarks: <String>[
      'Mental protuberance (the chin)',
      'Gonial angle where ramus meets body',
      'Mandibular condyle and coronoid process',
      'Mental foramen below the premolars',
    ],
    siding:
        'Symmetrical when whole. A half-mandible is sided by the direction the '
        'ramus rises and by which way the tooth row curves.',
  ),
  BoneEntry(
    key: 'femur',
    name: 'Femur',
    code: 'FEM',
    blurb: 'Thigh bone; best stature indicator',
    region: BoneRegion.lowerLimb,
    summary:
        'The thigh bone — the longest and strongest bone in the body. Its '
        'maximum length carries the tightest correlation with living stature.',
    landmarks: <String>[
      'Spherical head with the fovea capitis',
      'Greater and lesser trochanters',
      'Linea aspera ridging the posterior shaft',
      'Medial and lateral condyles at the knee',
    ],
    siding:
        'Hold the bone upright, head at the top, with the linea aspera facing '
        'away from you. The head then points to the side of the body the bone '
        'comes from.',
  ),
  BoneEntry(
    key: 'tibia',
    name: 'Tibia',
    code: 'TIB',
    blurb: 'Shin bone; triangular shaft',
    region: BoneRegion.lowerLimb,
    summary:
        'The shin bone, medial and weight-bearing in the lower leg. Its '
        'triangular shaft is distinctive even in fragments.',
    landmarks: <String>[
      'Tibial tuberosity on the anterior proximal shaft',
      'Sharp anterior crest',
      'Medial malleolus at the ankle',
      'Flat medial and lateral condyles',
    ],
    siding:
        'Hold it upright with the tibial tuberosity facing you and the '
        'malleolus at the bottom. The medial malleolus then points to the side '
        'of the body the bone comes from.',
  ),
  BoneEntry(
    key: 'humerus',
    name: 'Humerus',
    code: 'HUM',
    blurb: 'Upper arm, shoulder to elbow',
    region: BoneRegion.upperLimb,
    summary:
        'The upper arm bone, running from the shoulder joint to the elbow. The '
        'longest bone of the arm.',
    landmarks: <String>[
      'Rounded head with greater and lesser tubercles',
      'Deltoid tuberosity mid-shaft',
      'Olecranon fossa on the posterior distal end',
      'Trochlea and capitulum forming the elbow',
    ],
    siding:
        'Hold it upright, head at the top, with the olecranon fossa facing away '
        'from you. The head then points to the side of the body the bone comes '
        'from.',
  ),
  BoneEntry(
    key: 'radius',
    name: 'Radius',
    code: 'RAD',
    blurb: 'Lateral forearm, on the thumb side',
    region: BoneRegion.upperLimb,
    summary:
        'The lateral forearm bone, on the thumb side. It rotates over the ulna '
        'to turn the palm.',
    landmarks: <String>[
      'Disc-shaped proximal head',
      'Radial tuberosity just below the neck',
      'Broad, flared distal end',
      'Styloid process at the wrist',
    ],
    siding:
        'Hold it with the small head up and the flat palm side of the broad end '
        'facing you. The styloid process then points to the opposite side: left '
        'for a right radius.',
  ),
  BoneEntry(
    key: 'ulna',
    name: 'Ulna',
    code: 'ULN',
    blurb: 'Medial forearm; point of the elbow',
    region: BoneRegion.upperLimb,
    summary:
        'The medial forearm bone, on the little-finger side. Forms the hinge of '
        'the elbow and is the stable partner the radius rotates around.',
    landmarks: <String>[
      'Olecranon process — the point of the elbow',
      'Trochlear notch gripping the humerus',
      'Coronoid process below the notch',
      'Slender distal head with styloid process',
    ],
    siding:
        'Hold it with the olecranon up and the trochlear notch facing you. The '
        'radial notch, where the radius sits, then faces the opposite side: '
        'left for a right ulna.',
  ),
  BoneEntry(
    key: 'scapula',
    name: 'Scapula',
    code: 'SCP',
    blurb: 'Shoulder blade; thin triangular plate',
    region: BoneRegion.girdle,
    summary:
        'The shoulder blade — a thin triangular plate riding on the back of the '
        'ribcage. Thin enough that the blade often survives only as fragments.',
    landmarks: <String>[
      'Spine running across the posterior surface',
      'Acromion process at the shoulder tip',
      'Hooked coracoid process anteriorly',
      'Glenoid fossa receiving the humeral head',
    ],
    siding:
        'Hold it with the spine facing you and the acromion at the top. The '
        'glenoid fossa then points to the side of the body the bone comes from.',
  ),
  BoneEntry(
    key: 'os_coxa',
    name: 'Os Coxa',
    code: 'CXA',
    blurb: 'Hip bone; best indicator of sex',
    region: BoneRegion.girdle,
    summary:
        'The hip bone: ilium, ischium and pubis fused at the acetabulum. The '
        'single most reliable element for estimating sex and adult age.',
    landmarks: <String>[
      'Greater sciatic notch — broad in females, narrow in males',
      'Subpubic angle and the ventral arc',
      'Auricular surface, used for age-at-death',
      'Acetabulum receiving the femoral head',
    ],
    siding:
        'Point the iliac blade up and the acetabulum out: the pubis sits '
        'anteriorly and the sciatic notch opens posteriorly. Held this way '
        'against your own hip, it matches the side it comes from.',
    alsoKnownAs: 'Innominate, hip bone',
  ),
  BoneEntry(
    key: 'rib_1_2',
    name: 'Ribs 1–2',
    code: 'R12',
    blurb: 'Atypical ribs; flat and sharply curved',
    region: BoneRegion.thoracic,
    summary:
        'The first two ribs are atypical. Rib 1 is the shortest, broadest and '
        'most sharply curved; rib 2 is longer but keeps the same flattened set.',
    landmarks: <String>[
      'Rib 1 lies flat, with superior and inferior surfaces',
      'Scalene tubercle with grooves for the subclavian vessels',
      'Rib 2 carries a tuberosity for serratus anterior',
      'Single articular facet on the head of rib 1',
    ],
    siding:
        'Lay the rib flat with the head backward: the concave inner surface '
        'faces the midline, giving the side.',
  ),
  BoneEntry(
    key: 'typical_rib',
    name: 'Typical Rib',
    code: 'RIB',
    blurb: 'Ribs 3–9; head, tubercle, costal groove',
    region: BoneRegion.thoracic,
    summary:
        'Ribs 3 through 9 share one plan: a head, neck, tubercle and a long '
        'curving body that twists at the angle.',
    landmarks: <String>[
      'Two demifacets on the head',
      'Tubercle articulating with a transverse process',
      'Angle where the shaft changes direction',
      'Costal groove along the inner inferior border',
    ],
    siding:
        'The costal groove runs on the internal inferior edge; with the groove '
        'down and inside, the head points to the back and gives the side.',
  ),
  BoneEntry(
    key: 'rib_11_12',
    name: 'Ribs 11–12',
    code: 'R11',
    blurb: 'Floating ribs; short, free of the sternum',
    region: BoneRegion.thoracic,
    summary:
        'The floating ribs. Short, tapering and unattached to the sternum, '
        'which is why they lack most of the features a typical rib carries.',
    landmarks: <String>[
      'Single articular facet on the head',
      'No neck and no tubercle',
      'Little or no costal groove',
      'Pointed, cartilage-tipped anterior end',
    ],
    siding:
        'Curvature alone gives the side: the concave surface faces the midline.',
  ),
  BoneEntry(
    key: 'cervical_vertebrae',
    name: 'Cervical Vertebrae',
    code: 'CER',
    blurb: 'C1–C7; the only ones with transverse foramina',
    region: BoneRegion.axial,
    summary:
        'The seven neck vertebrae, C1–C7. Smallest bodies in the column and the '
        'only vertebrae with holes in the transverse processes.',
    landmarks: <String>[
      'Transverse foramina — diagnostic for the region',
      'C1 (atlas) has no body; C2 (axis) carries the dens',
      'Bifid spinous processes on C2–C6',
      'Large triangular vertebral foramen',
    ],
    siding:
        'Symmetrical. Position in the series is read from the spinous process '
        'and body size; C7 has the long, unsplit "prominens" spine.',
  ),
  BoneEntry(
    key: 'thoracic_vertebrae',
    name: 'Thoracic Vertebrae',
    code: 'THO',
    blurb: 'T1–T12; carry the costal facets',
    region: BoneRegion.axial,
    summary:
        'The twelve vertebrae of the upper back, T1–T12. Each one articulates '
        'with a pair of ribs, and the facets for those ribs identify the region.',
    landmarks: <String>[
      'Costal facets on the body and transverse processes',
      'Heart-shaped vertebral bodies',
      'Long spinous processes angled steeply downward',
      'Circular vertebral foramen',
    ],
    siding:
        'Symmetrical. Sequence is judged from body size and how far the spinous '
        'process overlaps the vertebra below.',
  ),
  BoneEntry(
    key: 'lumbar_vertebrae',
    name: 'Lumbar Vertebrae',
    code: 'LUM',
    blurb: 'L1–L5; the heaviest in the column',
    region: BoneRegion.axial,
    summary:
        'The five vertebrae of the lower back, L1–L5. The largest and most '
        'robust in the column, built for load rather than movement.',
    landmarks: <String>[
      'Massive kidney-shaped bodies',
      'No transverse foramina and no costal facets',
      'Short, blunt, hatchet-shaped spinous processes',
      'Mammillary processes on the superior articular processes',
    ],
    siding:
        'Symmetrical. L5 is recognised by its wedge shape, deeper in front than '
        'behind, where it meets the sacrum.',
  ),
];

BoneEntry? boneEntryFor(String key) {
  for (final BoneEntry e in kBoneReference) {
    if (e.key == key) return e;
  }
  return null;
}

/// The pipeline, described in everyday words for the "How analysis works"
/// screen. Order follows the phases in `bone_analyzer/inference/analyzer.py`.
class PhaseDoc {
  const PhaseDoc(this.number, this.title, this.detail);
  final int number;
  final String title;
  final String detail;
}

const List<PhaseDoc> kPhaseDocs = <PhaseDoc>[
  PhaseDoc(1, 'Is there a bone?',
      "First Ossia checks there's a bone in the photo at all, so a stick or a "
      "stone doesn't get a made-up answer."),
  PhaseDoc(2, 'Human or animal?',
      'Next it decides whether the bone came from a person or an animal. '
      'Everything after depends on this step.'),
  PhaseDoc(3, 'Which bone?',
      'Sixteen kinds of bone, from the skull and jaw to the ribs, spine, hip '
      'and limbs. You see its top three guesses, not just the winner.'),
  PhaseDoc(4, 'Which part?',
      'Whether the photo shows the whole bone, its middle (the shaft), one '
      'end, or a broken piece.'),
  PhaseDoc(5, 'Whole or broken?',
      'A quick yes or no: is the bone complete, or only a fragment?'),
  PhaseDoc(6, 'Marks and damage',
      'Breaks, cut marks and burning are each checked on their own, so one '
      'bone can show all three.'),
  PhaseDoc(7, 'Which animal?',
      'For animal bones: mammal, bird or reptile. For mammals, also the '
      'family, like the dog, deer, cattle, pig, cat, bear, rabbit, raccoon or '
      'horse family, or a rodent. The family is only named when the bone can '
      'show it, such as a skull, a jaw or a whole leg bone.'),
  PhaseDoc(8, 'Age and sex',
      'For human bones only. Treat these as a hint to check, never as an '
      'answer on their own.'),
  PhaseDoc(9, 'Putting it together',
      'Photos of the same bone from different sides are read together, and '
      "the length you measured is checked against the bone's usual size. Both "
      'help when one photo alone is unclear.'),
];
