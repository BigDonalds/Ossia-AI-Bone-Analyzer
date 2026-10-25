// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ossia';

  @override
  String get tabScan => 'Scan';

  @override
  String get tabStash => 'Stash';

  @override
  String get tabBones => 'Bones';

  @override
  String get tabSettings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String get confirm => 'Confirm';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get nah => 'Nah';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get tryAgain => 'Try again';

  @override
  String get engineOnDevice => 'This phone';

  @override
  String get engineServer => 'Online';

  @override
  String get engineAnalyzeOn => 'Analyze on';

  @override
  String get engineWorksOffline => 'Works offline';

  @override
  String get engineUsesInternet => 'Uses internet';

  @override
  String dateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get accentSunny => 'Sunny';

  @override
  String get accentLime => 'Lime';

  @override
  String get accentBubblegum => 'Bubblegum';

  @override
  String get accentTangerine => 'Tangerine';

  @override
  String get accentGrape => 'Grape';

  @override
  String get accentSky => 'Sky';

  @override
  String get welcomeTitle => 'Which language should Ossia speak?';

  @override
  String get welcomeSubtitle =>
      'We picked your phone\'s language. Change it here, or any time with the globe at the top.';

  @override
  String get welcomeSubtitleNoMatch =>
      'Pick one here. You can change it any time with the globe at the top.';

  @override
  String get welcomeContinue => 'Let\'s go';

  @override
  String get languageCardLine => 'Bones, explained in English';

  @override
  String get languageFromPhone => 'From your phone';

  @override
  String get languageTitle => 'Language';

  @override
  String get globeTooltip => 'Change language';

  @override
  String get languageSheetTitle => 'Pick a language';

  @override
  String get languageSheetMessage =>
      'Everything switches straight away, saved finds too.';

  @override
  String get languageMatchPhone => 'Match my phone';

  @override
  String languageMatchPhoneHint(String language) {
    return 'Right now that\'s $language';
  }

  @override
  String languageFollowingPhone(String language) {
    return 'Phone ($language)';
  }

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameGerman => 'German';

  @override
  String get languageNameArabic => 'Arabic';

  @override
  String get languageNowSpeaking => 'Ossia speaks English now';

  @override
  String get boneSkull => 'Skull';

  @override
  String get boneSkullMeaning => 'the whole head';

  @override
  String get boneCranium => 'Cranium';

  @override
  String get boneCraniumMeaning => 'the skull without the lower jaw';

  @override
  String get boneMandible => 'Mandible';

  @override
  String get boneMandibleMeaning => 'the lower jaw';

  @override
  String get boneFemur => 'Femur';

  @override
  String get boneFemurMeaning => 'the thigh bone';

  @override
  String get boneTibia => 'Tibia';

  @override
  String get boneTibiaMeaning => 'the shin bone';

  @override
  String get boneHumerus => 'Humerus';

  @override
  String get boneHumerusMeaning => 'the upper arm or upper front-leg bone';

  @override
  String get boneRadius => 'Radius';

  @override
  String get boneRadiusMeaning => 'a forearm or lower front-leg bone';

  @override
  String get boneUlna => 'Ulna';

  @override
  String get boneUlnaMeaning =>
      'a forearm or lower front-leg bone, with the elbow point';

  @override
  String get boneScapula => 'Scapula';

  @override
  String get boneScapulaMeaning => 'the shoulder blade';

  @override
  String get boneOsCoxa => 'Os Coxa';

  @override
  String get boneOsCoxaMeaning => 'the hip bone';

  @override
  String get boneRib12 => 'Ribs 1–2';

  @override
  String get boneRib12Meaning => 'one of the top two ribs';

  @override
  String get boneTypicalRib => 'Typical Rib';

  @override
  String get boneTypicalRibMeaning => 'a rib from the middle of the chest';

  @override
  String get boneRib1112 => 'Ribs 11–12';

  @override
  String get boneRib1112Meaning => 'one of the bottom two ribs';

  @override
  String get boneCervical => 'Cervical Vertebrae';

  @override
  String get boneCervicalMeaning => 'a neck bone';

  @override
  String get boneThoracic => 'Thoracic Vertebrae';

  @override
  String get boneThoracicMeaning => 'a bone from the upper back';

  @override
  String get boneLumbar => 'Lumbar Vertebrae';

  @override
  String get boneLumbarMeaning => 'a bone from the lower back';

  @override
  String get boneUnidentified => 'Unidentified';

  @override
  String get noBoneDetected => 'No bone detected';

  @override
  String get animalHuman => 'Human';

  @override
  String get animalHumanMeaning => 'a person';

  @override
  String get animalCanid => 'Canid';

  @override
  String get animalCanidMeaning =>
      'the dog family (dogs, wolves, coyotes and foxes)';

  @override
  String get animalCervid => 'Cervid';

  @override
  String get animalCervidMeaning =>
      'the deer family (deer, elk, moose and caribou)';

  @override
  String get animalBovid => 'Bovid';

  @override
  String get animalBovidMeaning =>
      'the cattle family (cows, bison, sheep, goats and antelope)';

  @override
  String get animalSuid => 'Suid';

  @override
  String get animalSuidMeaning =>
      'the pig family (pigs, wild boar and warthogs)';

  @override
  String get animalFelid => 'Felid';

  @override
  String get animalFelidMeaning =>
      'the cat family (house cats, bobcats, cougars and lions)';

  @override
  String get animalUrsid => 'Ursid';

  @override
  String get animalUrsidMeaning => 'bears';

  @override
  String get animalLeporid => 'Leporid';

  @override
  String get animalLeporidMeaning => 'rabbits and hares';

  @override
  String get animalProcyonid => 'Procyonid';

  @override
  String get animalProcyonidMeaning =>
      'the raccoon family (raccoons, coatis and ringtails)';

  @override
  String get animalEquid => 'Equid';

  @override
  String get animalEquidMeaning =>
      'the horse family (horses, donkeys and zebras)';

  @override
  String get animalRodent => 'Rodent';

  @override
  String get animalRodentMeaning =>
      'rats, mice, squirrels, beavers and their kin';

  @override
  String get animalMammal => 'Mammal';

  @override
  String get animalOtherMammalMeaning =>
      'an animal with fur that feeds its young milk, from a family Ossia doesn\'t name, like a skunk or opossum';

  @override
  String get animalMammalMeaning =>
      'an animal with fur that feeds its young milk. This bone doesn\'t show which family';

  @override
  String get animalBird => 'Bird';

  @override
  String get animalBirdMeaning => 'any bird, from sparrows to ostriches';

  @override
  String get animalReptile => 'Reptile';

  @override
  String get animalReptileMeaning => 'turtles, snakes, lizards and crocodiles';

  @override
  String get animalUnnamed => 'Animal';

  @override
  String get animalUnnamedMeaning =>
      'an animal bone that no animal group stood out for';

  @override
  String get partComplete => 'Whole bone';

  @override
  String get partShaft => 'Middle (shaft)';

  @override
  String get partProximal => 'Near end';

  @override
  String get partDistal => 'Far end';

  @override
  String get partFragment => 'Broken piece';

  @override
  String get statusComplete => 'Complete';

  @override
  String get statusFragment => 'Broken';

  @override
  String get conditionWholeButBroken => 'Whole bone, but broken';

  @override
  String conditionPartBroken(String part) {
    return '$part, broken';
  }

  @override
  String get damageFracture => 'Fracture';

  @override
  String get damageCutMarks => 'Cut marks';

  @override
  String get damageBurnSigns => 'Burn signs';

  @override
  String get ageAdult => 'Adult';

  @override
  String get ageJuvenile => 'Juvenile';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get sourceOnDevice => 'On this phone';

  @override
  String get sourceServer => 'On the Ossia computer';

  @override
  String get regionCranial => 'Cranial';

  @override
  String get regionAxial => 'Axial';

  @override
  String get regionThoracic => 'Thoracic';

  @override
  String get regionUpperLimb => 'Upper limb';

  @override
  String get regionLowerLimb => 'Lower limb';

  @override
  String get regionGirdle => 'Girdle';

  @override
  String get phaseFinding => 'Finding the bone';

  @override
  String get phaseHumanOrAnimal => 'Human or animal?';

  @override
  String get phaseWhichBone => 'Which bone?';

  @override
  String get phaseWhichPart => 'Which part?';

  @override
  String get phaseWholeOrBroken => 'Whole or broken?';

  @override
  String get phaseMarks => 'Looking for marks';

  @override
  String get phaseWhichAnimal => 'Which animal?';

  @override
  String get phaseAgeSex => 'Age and sex';

  @override
  String get phaseWriting => 'Writing it up';

  @override
  String get unitCentimetres => 'Centimetres';

  @override
  String get unitInches => 'Inches';

  @override
  String get unitCm => 'cm';

  @override
  String get unitIn => 'in';

  @override
  String get atlasSkullBlurb => 'Cranium and mandible together';

  @override
  String get atlasSkullSummary =>
      'The complete bony head: the cranium together with the mandible. Twenty-two bones in all, joined by interlocking sutures; only the mandible articulates freely.';

  @override
  String get atlasSkullLm1 =>
      'Coronal, sagittal, lambdoid and squamous sutures';

  @override
  String get atlasSkullLm2 => 'Orbits and the piriform (nasal) aperture';

  @override
  String get atlasSkullLm3 => 'Foramen magnum on the basicranium';

  @override
  String get atlasSkullLm4 => 'Mastoid processes behind the ear canals';

  @override
  String get atlasSkullSiding =>
      'Symmetrical. Orientation comes from the frontal bone (anterior) and the occipital squama (posterior).';

  @override
  String get atlasCraniumBlurb => 'The skull without its jaw';

  @override
  String get atlasCraniumSummary =>
      'The skull with the mandible removed. Encloses and protects the brain; the vault is made of frontal, parietal, temporal and occipital bones.';

  @override
  String get atlasCraniumLm1 => 'Supraorbital ridges — heavier in male crania';

  @override
  String get atlasCraniumLm2 => 'Nuchal lines on the occipital';

  @override
  String get atlasCraniumLm3 => 'Temporal lines sweeping across the parietals';

  @override
  String get atlasCraniumLm4 => 'External auditory meatus';

  @override
  String get atlasCraniumSiding =>
      'Symmetrical when complete. Isolated vault fragments are sided by suture direction and meningeal groove patterning.';

  @override
  String get atlasCraniumAka => 'Calvarium (vault only)';

  @override
  String get atlasMandibleBlurb => 'Lower jaw; dense and durable';

  @override
  String get atlasMandibleSummary =>
      'The lower jaw — the only freely mobile bone of the skull. Dense and compact, so it survives burial and burning better than most.';

  @override
  String get atlasMandibleLm1 => 'Mental protuberance (the chin)';

  @override
  String get atlasMandibleLm2 => 'Gonial angle where ramus meets body';

  @override
  String get atlasMandibleLm3 => 'Mandibular condyle and coronoid process';

  @override
  String get atlasMandibleLm4 => 'Mental foramen below the premolars';

  @override
  String get atlasMandibleSiding =>
      'Symmetrical when whole. A half-mandible is sided by the direction the ramus rises and by which way the tooth row curves.';

  @override
  String get atlasFemurBlurb => 'Thigh bone; best stature indicator';

  @override
  String get atlasFemurSummary =>
      'The thigh bone — the longest and strongest bone in the body. Its maximum length carries the tightest correlation with living stature.';

  @override
  String get atlasFemurLm1 => 'Spherical head with the fovea capitis';

  @override
  String get atlasFemurLm2 => 'Greater and lesser trochanters';

  @override
  String get atlasFemurLm3 => 'Linea aspera ridging the posterior shaft';

  @override
  String get atlasFemurLm4 => 'Medial and lateral condyles at the knee';

  @override
  String get atlasFemurSiding =>
      'Hold the bone upright, head at the top, with the linea aspera facing away from you. The head then points to the side of the body the bone comes from.';

  @override
  String get atlasTibiaBlurb => 'Shin bone; triangular shaft';

  @override
  String get atlasTibiaSummary =>
      'The shin bone, medial and weight-bearing in the lower leg. Its triangular shaft is distinctive even in fragments.';

  @override
  String get atlasTibiaLm1 =>
      'Tibial tuberosity on the anterior proximal shaft';

  @override
  String get atlasTibiaLm2 => 'Sharp anterior crest';

  @override
  String get atlasTibiaLm3 => 'Medial malleolus at the ankle';

  @override
  String get atlasTibiaLm4 => 'Flat medial and lateral condyles';

  @override
  String get atlasTibiaSiding =>
      'Hold it upright with the tibial tuberosity facing you and the malleolus at the bottom. The medial malleolus then points to the side of the body the bone comes from.';

  @override
  String get atlasHumerusBlurb => 'Upper arm, shoulder to elbow';

  @override
  String get atlasHumerusSummary =>
      'The upper arm bone, running from the shoulder joint to the elbow. The longest bone of the arm.';

  @override
  String get atlasHumerusLm1 =>
      'Rounded head with greater and lesser tubercles';

  @override
  String get atlasHumerusLm2 => 'Deltoid tuberosity mid-shaft';

  @override
  String get atlasHumerusLm3 => 'Olecranon fossa on the posterior distal end';

  @override
  String get atlasHumerusLm4 => 'Trochlea and capitulum forming the elbow';

  @override
  String get atlasHumerusSiding =>
      'Hold it upright, head at the top, with the olecranon fossa facing away from you. The head then points to the side of the body the bone comes from.';

  @override
  String get atlasRadiusBlurb => 'Lateral forearm, on the thumb side';

  @override
  String get atlasRadiusSummary =>
      'The lateral forearm bone, on the thumb side. It rotates over the ulna to turn the palm.';

  @override
  String get atlasRadiusLm1 => 'Disc-shaped proximal head';

  @override
  String get atlasRadiusLm2 => 'Radial tuberosity just below the neck';

  @override
  String get atlasRadiusLm3 => 'Broad, flared distal end';

  @override
  String get atlasRadiusLm4 => 'Styloid process at the wrist';

  @override
  String get atlasRadiusSiding =>
      'Hold it with the small head up and the flat palm side of the broad end facing you. The styloid process then points to the opposite side: left for a right radius.';

  @override
  String get atlasUlnaBlurb => 'Medial forearm; point of the elbow';

  @override
  String get atlasUlnaSummary =>
      'The medial forearm bone, on the little-finger side. Forms the hinge of the elbow and is the stable partner the radius rotates around.';

  @override
  String get atlasUlnaLm1 => 'Olecranon process — the point of the elbow';

  @override
  String get atlasUlnaLm2 => 'Trochlear notch gripping the humerus';

  @override
  String get atlasUlnaLm3 => 'Coronoid process below the notch';

  @override
  String get atlasUlnaLm4 => 'Slender distal head with styloid process';

  @override
  String get atlasUlnaSiding =>
      'Hold it with the olecranon up and the trochlear notch facing you. The radial notch, where the radius sits, then faces the opposite side: left for a right ulna.';

  @override
  String get atlasScapulaBlurb => 'Shoulder blade; thin triangular plate';

  @override
  String get atlasScapulaSummary =>
      'The shoulder blade — a thin triangular plate riding on the back of the ribcage. Thin enough that the blade often survives only as fragments.';

  @override
  String get atlasScapulaLm1 => 'Spine running across the posterior surface';

  @override
  String get atlasScapulaLm2 => 'Acromion process at the shoulder tip';

  @override
  String get atlasScapulaLm3 => 'Hooked coracoid process anteriorly';

  @override
  String get atlasScapulaLm4 => 'Glenoid fossa receiving the humeral head';

  @override
  String get atlasScapulaSiding =>
      'Hold it with the spine facing you and the acromion at the top. The glenoid fossa then points to the side of the body the bone comes from.';

  @override
  String get atlasOsCoxaBlurb => 'Hip bone; best indicator of sex';

  @override
  String get atlasOsCoxaSummary =>
      'The hip bone: ilium, ischium and pubis fused at the acetabulum. The single most reliable element for estimating sex and adult age.';

  @override
  String get atlasOsCoxaLm1 =>
      'Greater sciatic notch — broad in females, narrow in males';

  @override
  String get atlasOsCoxaLm2 => 'Subpubic angle and the ventral arc';

  @override
  String get atlasOsCoxaLm3 => 'Auricular surface, used for age-at-death';

  @override
  String get atlasOsCoxaLm4 => 'Acetabulum receiving the femoral head';

  @override
  String get atlasOsCoxaSiding =>
      'Point the iliac blade up and the acetabulum out: the pubis sits anteriorly and the sciatic notch opens posteriorly. Held this way against your own hip, it matches the side it comes from.';

  @override
  String get atlasOsCoxaAka => 'Innominate, hip bone';

  @override
  String get atlasRib12Blurb => 'Atypical ribs; flat and sharply curved';

  @override
  String get atlasRib12Summary =>
      'The first two ribs are atypical. Rib 1 is the shortest, broadest and most sharply curved; rib 2 is longer but keeps the same flattened set.';

  @override
  String get atlasRib12Lm1 =>
      'Rib 1 lies flat, with superior and inferior surfaces';

  @override
  String get atlasRib12Lm2 =>
      'Scalene tubercle with grooves for the subclavian vessels';

  @override
  String get atlasRib12Lm3 =>
      'Rib 2 carries a tuberosity for serratus anterior';

  @override
  String get atlasRib12Lm4 => 'Single articular facet on the head of rib 1';

  @override
  String get atlasRib12Siding =>
      'Lay the rib flat with the head backward: the concave inner surface faces the midline, giving the side.';

  @override
  String get atlasTypicalRibBlurb => 'Ribs 3–9; head, tubercle, costal groove';

  @override
  String get atlasTypicalRibSummary =>
      'Ribs 3 through 9 share one plan: a head, neck, tubercle and a long curving body that twists at the angle.';

  @override
  String get atlasTypicalRibLm1 => 'Two demifacets on the head';

  @override
  String get atlasTypicalRibLm2 =>
      'Tubercle articulating with a transverse process';

  @override
  String get atlasTypicalRibLm3 => 'Angle where the shaft changes direction';

  @override
  String get atlasTypicalRibLm4 =>
      'Costal groove along the inner inferior border';

  @override
  String get atlasTypicalRibSiding =>
      'The costal groove runs on the internal inferior edge; with the groove down and inside, the head points to the back and gives the side.';

  @override
  String get atlasRib1112Blurb => 'Floating ribs; short, free of the sternum';

  @override
  String get atlasRib1112Summary =>
      'The floating ribs. Short, tapering and unattached to the sternum, which is why they lack most of the features a typical rib carries.';

  @override
  String get atlasRib1112Lm1 => 'Single articular facet on the head';

  @override
  String get atlasRib1112Lm2 => 'No neck and no tubercle';

  @override
  String get atlasRib1112Lm3 => 'Little or no costal groove';

  @override
  String get atlasRib1112Lm4 => 'Pointed, cartilage-tipped anterior end';

  @override
  String get atlasRib1112Siding =>
      'Curvature alone gives the side: the concave surface faces the midline.';

  @override
  String get atlasCervicalBlurb =>
      'C1–C7; the only ones with transverse foramina';

  @override
  String get atlasCervicalSummary =>
      'The seven neck vertebrae, C1–C7. Smallest bodies in the column and the only vertebrae with holes in the transverse processes.';

  @override
  String get atlasCervicalLm1 =>
      'Transverse foramina — diagnostic for the region';

  @override
  String get atlasCervicalLm2 =>
      'C1 (atlas) has no body; C2 (axis) carries the dens';

  @override
  String get atlasCervicalLm3 => 'Bifid spinous processes on C2–C6';

  @override
  String get atlasCervicalLm4 => 'Large triangular vertebral foramen';

  @override
  String get atlasCervicalSiding =>
      'Symmetrical. Position in the series is read from the spinous process and body size; C7 has the long, unsplit \"prominens\" spine.';

  @override
  String get atlasThoracicBlurb => 'T1–T12; carry the costal facets';

  @override
  String get atlasThoracicSummary =>
      'The twelve vertebrae of the upper back, T1–T12. Each one articulates with a pair of ribs, and the facets for those ribs identify the region.';

  @override
  String get atlasThoracicLm1 =>
      'Costal facets on the body and transverse processes';

  @override
  String get atlasThoracicLm2 => 'Heart-shaped vertebral bodies';

  @override
  String get atlasThoracicLm3 =>
      'Long spinous processes angled steeply downward';

  @override
  String get atlasThoracicLm4 => 'Circular vertebral foramen';

  @override
  String get atlasThoracicSiding =>
      'Symmetrical. Sequence is judged from body size and how far the spinous process overlaps the vertebra below.';

  @override
  String get atlasLumbarBlurb => 'L1–L5; the heaviest in the column';

  @override
  String get atlasLumbarSummary =>
      'The five vertebrae of the lower back, L1–L5. The largest and most robust in the column, built for load rather than movement.';

  @override
  String get atlasLumbarLm1 => 'Massive kidney-shaped bodies';

  @override
  String get atlasLumbarLm2 => 'No transverse foramina and no costal facets';

  @override
  String get atlasLumbarLm3 => 'Short, blunt, hatchet-shaped spinous processes';

  @override
  String get atlasLumbarLm4 =>
      'Mammillary processes on the superior articular processes';

  @override
  String get atlasLumbarSiding =>
      'Symmetrical. L5 is recognised by its wedge shape, deeper in front than behind, where it meets the sacrum.';

  @override
  String get phaseDoc1Title => 'Is there a bone?';

  @override
  String get phaseDoc1Detail =>
      'First Ossia checks there\'s a bone in the photo at all, so a stick or a stone doesn\'t get a made-up answer.';

  @override
  String get phaseDoc2Title => 'Human or animal?';

  @override
  String get phaseDoc2Detail =>
      'Next it decides whether the bone came from a person or an animal. Everything after depends on this step.';

  @override
  String get phaseDoc3Title => 'Which bone?';

  @override
  String get phaseDoc3Detail =>
      'Sixteen kinds of bone, from the skull and jaw to the ribs, spine, hip and limbs. You see its top three guesses, not just the winner.';

  @override
  String get phaseDoc4Title => 'Which part?';

  @override
  String get phaseDoc4Detail =>
      'Whether the photo shows the whole bone, its middle (the shaft), one end, or a broken piece.';

  @override
  String get phaseDoc5Title => 'Whole or broken?';

  @override
  String get phaseDoc5Detail =>
      'A quick yes or no: is the bone complete, or only a fragment?';

  @override
  String get phaseDoc6Title => 'Marks and damage';

  @override
  String get phaseDoc6Detail =>
      'Breaks, cut marks and burning are each checked on their own, so one bone can show all three.';

  @override
  String get phaseDoc7Title => 'Which animal?';

  @override
  String get phaseDoc7Detail =>
      'For animal bones: mammal, bird or reptile. For mammals, also the family, like the dog, deer, cattle, pig, cat, bear, rabbit, raccoon or horse family, or a rodent. The family is only named when the bone can show it, such as a skull, a jaw or a whole leg bone.';

  @override
  String get phaseDoc8Title => 'Age and sex';

  @override
  String get phaseDoc8Detail =>
      'For human bones only. Treat these as a hint to check, never as an answer on their own.';

  @override
  String get phaseDoc9Title => 'Putting it together';

  @override
  String get phaseDoc9Detail =>
      'Photos of the same bone from different sides are read together, and the length you measured is checked against the bone\'s usual size. Both help when one photo alone is unclear.';

  @override
  String get errNotReadyOnPhone =>
      'Ossia couldn\'t get ready on this phone. Try again, or restart the app.';

  @override
  String get errPhotoUnreadable =>
      'Couldn\'t read that photo. Try a JPEG or PNG.';

  @override
  String errPhotoNUnreadable(int number) {
    return 'Couldn\'t read photo $number. Remove it and try again.';
  }

  @override
  String get errReadingPhoto =>
      'Something went wrong reading that photo. Please try again.';

  @override
  String get errPhotoTryAnother =>
      'Couldn\'t read that photo. Try another one.';

  @override
  String get errBadOnlineAddress =>
      'The online address doesn\'t look right. Check it in Settings.';

  @override
  String get errThisDevice =>
      'That address points back at this phone. Type the address shown on the Ossia computer instead.';

  @override
  String errServerStatus(int code) {
    return 'Online analysis isn\'t working right now (error $code).';
  }

  @override
  String get errServerTooBig =>
      'The photos are too big to send. Try fewer photos.';

  @override
  String get errServerRejected =>
      'The online analysis didn\'t accept these photos. Try other photos.';

  @override
  String get errServerCouldntAnalyze =>
      'The online analysis couldn\'t read these photos. Try other photos.';

  @override
  String get errTimeout =>
      'Online analysis took too long to answer. Check your connection, or analyze on this phone.';

  @override
  String get errUnreachable =>
      'Couldn\'t connect for online analysis. Check your internet and the online address in Settings.';

  @override
  String get errNotAReport =>
      'Something answered, but not with a report. Check the online address in Settings.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get checkAddress => 'Address';

  @override
  String get checkReach => 'Reaching it';

  @override
  String get checkServer => 'Ossia answering';

  @override
  String get checkModel => 'Ready to analyze';

  @override
  String get checkSpeed => 'Speed';

  @override
  String get checkBadAddress => 'That isn\'t a valid address';

  @override
  String checkAnsweredIn(int ms) {
    return 'Answered in $ms ms';
  }

  @override
  String checkRunningFor(String time) {
    return 'Running for $time';
  }

  @override
  String get checkNotReady => 'It\'s on, but not ready to analyze yet';

  @override
  String get checkReady => 'Ready';

  @override
  String get checkLost => 'Lost the connection';

  @override
  String checkPing(int ms, String word) {
    return '$ms ms · $word';
  }

  @override
  String get pingSnappy => 'snappy';

  @override
  String get pingGood => 'good';

  @override
  String get pingSluggish => 'sluggish';

  @override
  String get pingSlow => 'slow';

  @override
  String uptimeSeconds(int s) {
    return '${s}s';
  }

  @override
  String uptimeMinutes(int m) {
    return '${m}m';
  }

  @override
  String uptimeHours(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String uptimeDays(int d, int h) {
    return '${d}d ${h}h';
  }

  @override
  String get netBadAnswer => 'Bad answer';

  @override
  String netNoAnswer(int seconds) {
    return 'No answer within $seconds seconds';
  }

  @override
  String get netNotFound =>
      'That address wasn\'t found. Check it\'s typed right and still current';

  @override
  String get netRefused => 'Nothing answered at that address';

  @override
  String get netNoInternet => 'No internet connection';

  @override
  String get netNotSecure => 'Couldn\'t make a secure connection';

  @override
  String get netNotRunning =>
      'The address works, but Ossia isn\'t running behind it';

  @override
  String get netExpired => 'That address has expired';

  @override
  String netHttpError(int code) {
    return 'It answered with an error ($code)';
  }

  @override
  String get netNotOssia => 'Something answered, but it isn\'t Ossia';

  @override
  String lenThing(String animal, String bone) {
    return '\"$animal $bone\"';
  }

  @override
  String lenUsually(String thing, String min, String max) {
    return '$thing (usually $min–$max cm)';
  }

  @override
  String lenNeverOver(String thing, String max) {
    return '$thing (never over $max cm)';
  }

  @override
  String lenOrThing(String first, String second) {
    return '$first or $second';
  }

  @override
  String get lenNoBone => 'No bone was found, so the length wasn\'t used.';

  @override
  String get lenNoLength => 'No length was entered.';

  @override
  String get lenOnlyShaft =>
      'This looks like the middle (shaft) of a bone, so its length can\'t be compared with whole bones.';

  @override
  String get lenOnlyEnd =>
      'This looks like one end of a bone, so its length can\'t be compared with whole bones.';

  @override
  String get lenOnlyPiece =>
      'This looks like a broken piece of bone, so its length can\'t be compared with whole bones.';

  @override
  String get lenOnlyPart =>
      'This looks like only part of a bone, so its length can\'t be compared with whole bones.';

  @override
  String lenNoReference(String things) {
    return 'We don\'t have usual lengths for $things, so the length wasn\'t used.';
  }

  @override
  String lenNoFit(String cm, String before, String after) {
    return '$cm cm doesn\'t fit $before or the next closest option, $after, so we kept the photo\'s answer. It could be from a young animal or person, or worth measuring again.';
  }

  @override
  String lenChangedTooLong(String cm, String before) {
    return '$cm cm is too long for $before.';
  }

  @override
  String lenChangedTooShort(String cm, String before) {
    return '$cm cm is too short for $before.';
  }

  @override
  String lenChangedFitsBut(String cm, String before) {
    return '$cm cm fits $before, but ruling out other options shifted the answer.';
  }

  @override
  String lenChangedUnchecked(String cm, String before) {
    return '$cm cm can\'t be checked against $before.';
  }

  @override
  String lenChangedNowFits(String after) {
    return 'It fits $after, so the length changed the answer.';
  }

  @override
  String lenChangedNotRuledOut(String after) {
    return '$after can\'t be ruled out by length, so the length changed the answer.';
  }

  @override
  String lenNoUsual(String before) {
    return 'We don\'t have a usual length for $before, so the length couldn\'t confirm it. It only helped weigh up the other options.';
  }

  @override
  String lenNormal(String cm, String before) {
    return '$cm cm is a normal length for $before, which backs up the answer.';
  }

  @override
  String lenShort(String cm, String before) {
    return '$cm cm is short for $before, but the photo still points to it. It could be from a young animal or person, or worth measuring again.';
  }

  @override
  String lenLong(String cm, String before) {
    return '$cm cm is long for $before, but the photo still points to it. Worth measuring again.';
  }

  @override
  String lenPhotoAlone(String headline) {
    return 'From the photo alone, it was $headline.';
  }

  @override
  String lenMeasuredOn(String thing, String animals) {
    return '$thing (measured on $animals)';
  }

  @override
  String get measuredBears => 'black and brown bear';

  @override
  String get measuredCattle => 'cattle';

  @override
  String get measuredCat => 'domestic cat';

  @override
  String get measuredDogsFoxes =>
      'domestic dogs (all breeds) and red and gray fox';

  @override
  String get measuredPigBoar => 'domestic pig and wild boar';

  @override
  String get measuredCottontail => 'eastern cottontail';

  @override
  String get measuredHorse => 'horse';

  @override
  String get measuredRaccoon => 'raccoon';

  @override
  String get measuredDeer => 'white-tailed and mule deer';

  @override
  String get scanHeroTitle => 'Found a bone?\nLet’s ID it.';

  @override
  String get scanHeroBody =>
      'Snap it or upload it. We’ll tell you what it is, whose it was and what happened to it.';

  @override
  String get scanSnap => 'Snap a bone';

  @override
  String get scanUpload => 'Upload a pic';

  @override
  String get scanTipsHeader => 'Pro tips for a clean read';

  @override
  String get tipBackgroundTitle => 'Plain background';

  @override
  String get tipBackgroundBody =>
      'A sheet or a table. No patterns, labels or writing.';

  @override
  String get tipLightTitle => 'Soft light';

  @override
  String get tipLightBody => 'Daylight is best. Harsh shadows hide details.';

  @override
  String get tipLengthTitle => 'Know the length?';

  @override
  String get tipLengthBody => 'Add it before analyzing. It sharpens the guess.';

  @override
  String get tipAnglesTitle => 'Try a few angles';

  @override
  String get tipAnglesBody => 'Front and back views solve tricky bones.';

  @override
  String get scanRecentFinds => 'Recent finds';

  @override
  String scanSavedCount(int count) {
    return '$count saved';
  }

  @override
  String get scanNoFinds => 'No finds yet';

  @override
  String get scanNoFindsBody => 'Your scanned bones will pile up right here.';

  @override
  String get linkNotReady => 'Not ready';

  @override
  String get linkOnPhone => 'On this phone';

  @override
  String get linkConnecting => 'Connecting…';

  @override
  String get linkOnline => 'Online';

  @override
  String linkOnlineMs(int ms) {
    return 'Online · $ms ms';
  }

  @override
  String get linkCantConnect => 'Can’t connect';

  @override
  String get toastLostConnection => 'Lost the connection';

  @override
  String get toastBackOnline => 'Back online';

  @override
  String get guideLongBone => 'Long bone';

  @override
  String get guideSkull => 'Skull';

  @override
  String get guideFlat => 'Flat bone';

  @override
  String get guideSmall => 'Small bit';

  @override
  String get guideLongBoneTip =>
      'Lay it flat and line it up with my knobby ends.';

  @override
  String get guideSkullTip =>
      'Face it straight on. Eye sockets in the dotted eyes.';

  @override
  String get guideFlatTip =>
      'Lay it flat. Get the whole outline in, edge to edge.';

  @override
  String get guideSmallTip =>
      'Tiny bone? Get up close till it fills the outline.';

  @override
  String camHold(int cm) {
    return 'Hold ~$cm cm away · fill the outline';
  }

  @override
  String get camTitle => 'BONE CAM';

  @override
  String camAngle(int number) {
    return 'ANGLE #$number';
  }

  @override
  String get camClose => 'Close camera';

  @override
  String get camFlash => 'Flash';

  @override
  String get camZoom => 'Zoom';

  @override
  String get camSwitch => 'Switch camera';

  @override
  String get camTakePhoto => 'Take photo';

  @override
  String get camUploadFromLibrary => 'Upload from library';

  @override
  String get camWarmingUp => 'Warming up the camera…';

  @override
  String get camAnotherAngleTip =>
      'Same bone, new side. Flip it over, or get one of the ends.';

  @override
  String get camShotFailed => 'Couldn’t take that one. Try again?';

  @override
  String get camNoAccess => 'No camera access';

  @override
  String get camNoAccessBody =>
      'Allow camera access for Ossia in your phone settings, or upload a photo instead.';

  @override
  String get camNapping => 'Camera is napping';

  @override
  String get camNappingBody =>
      'Couldn’t start the camera here. Upload a photo instead?';

  @override
  String get camAuto => 'Auto snap';

  @override
  String get camAutoOnTip =>
      'Auto snap is on. Get the bone in the frame and hold still.';

  @override
  String get camAutoOffTip =>
      'Auto snap is off. Tap the big button to take the photo.';

  @override
  String get camAutoSpotted => 'BONE SPOTTED!';

  @override
  String get camAutoFound => 'Got it! Now hold the phone still.';

  @override
  String get camAutoHolding => 'Perfect, hold it right there…';

  @override
  String get camAutoSnapped => 'SNAP!';

  @override
  String get camAutoRearm => 'Move the phone a little to take another.';

  @override
  String get reviewDropTitle => 'Drop these photos?';

  @override
  String reviewDropNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count photos of this bone haven’t been analyzed yet.',
      one: 'This bone’s photo hasn’t been analyzed yet.',
    );
    return '$_temp0';
  }

  @override
  String get reviewDropRevising =>
      'The angles you added or removed won’t be analyzed. The saved report stays as it was.';

  @override
  String get reviewDropConfirm => 'Drop them';

  @override
  String get reviewTypeLength => 'Type the length';

  @override
  String get reviewTypeLengthCm =>
      'End to end, the longest straight line, in centimetres.';

  @override
  String get reviewTypeLengthIn =>
      'End to end, the longest straight line, in inches.';

  @override
  String reviewExample(String example) {
    return 'e.g. $example';
  }

  @override
  String get reviewSetLength => 'Set length';

  @override
  String get reviewRetake => 'Retake';

  @override
  String get reviewTitleRevising => 'More angles';

  @override
  String reviewTitleAngles(int count) {
    return 'One bone, $count angles';
  }

  @override
  String get reviewNiceShot => 'Nice shot!';

  @override
  String get reviewLookingGood => 'Looking good?';

  @override
  String reviewMysteryBone(int number) {
    return 'mystery bone #$number';
  }

  @override
  String reviewAnalyzeCount(int count) {
    return 'Analyze $count photos';
  }

  @override
  String get reviewSkipAnalyze => 'Skip & analyze';

  @override
  String get reviewAnalyzeIt => 'Analyze it';

  @override
  String get reviewMoreAnglesQ => 'More angles?';

  @override
  String get reviewAngles => 'Angles';

  @override
  String get reviewOptional => 'OPTIONAL';

  @override
  String reviewAnglesOf(int count, int max) {
    return '$count OF $max';
  }

  @override
  String get reviewAnglesBodyOne =>
      'Same bone, another side. The back, an end or a close-up can crack a tricky one. Every photo gets read together.';

  @override
  String reviewAnglesBodyMany(int count) {
    return 'All $count photos are read together as one bone. Tap one to look at it, or the cross to drop it.';
  }

  @override
  String get reviewSnap => 'Snap';

  @override
  String get reviewUpload => 'Upload';

  @override
  String get reviewSnapHint => 'Take another angle';

  @override
  String get reviewUploadHint => 'Add angles from the library';

  @override
  String get reviewMaxPhotos => 'That’s the most one analysis takes.';

  @override
  String reviewRemovePhoto(int number) {
    return 'Remove photo $number';
  }

  @override
  String get reviewHowLong => 'How long is it?';

  @override
  String get reviewLengthBody =>
      'Measured it end to end? Flick the tape. No ruler handy? Skip it, no biggie. The AI will guess.';

  @override
  String get reviewEndToEnd => 'end to end';

  @override
  String get reviewWaitingNumber => 'waiting for a number…';

  @override
  String get reviewTapToType => 'Tap the number to type it exactly.';

  @override
  String get reviewFlickTape => 'Flick the tape to set a length.';

  @override
  String get reviewClear => 'Clear';

  @override
  String analyzingStep(int step, int total) {
    return 'Step $step/$total';
  }

  @override
  String analyzingPhotos(int count) {
    return '$count photos';
  }

  @override
  String get quipFinding => 'Playing hide and seek with your bone…';

  @override
  String get quipHumanOrAnimal => 'Human or not? Asking the big questions.';

  @override
  String get quipWhichBone =>
      'Which bone is this? Consulting my inner skeleton.';

  @override
  String get quipWhichEnd => 'Figuring out which end is which.';

  @override
  String get quipMissingBits => 'Checking if any bits went missing.';

  @override
  String get quipMarks => 'Looking for cracks, cuts and crispy bits.';

  @override
  String get quipWhose => 'Narrowing down whose bone this was.';

  @override
  String get quipAgeSex => 'Estimating age and sex, respectfully.';

  @override
  String get quipWriting => 'Writing it all up. Almost there!';

  @override
  String get analyzingFailedTitle => 'Welp, that broke';

  @override
  String get analyzingOnPhone => 'Analyze on this phone';

  @override
  String get reportNameTitle => 'Name this find';

  @override
  String get reportNameBody =>
      'Any name that helps you find it later, like where it turned up.';

  @override
  String get reportNameExample => 'e.g. TR2-114';

  @override
  String get reportRename => 'Rename';

  @override
  String get reportAddNote => 'Add a note';

  @override
  String get reportEditNote => 'Edit note';

  @override
  String get reportNoteBody =>
      'Anything the photo can’t show, like where you found it or how it felt in your hand.';

  @override
  String get reportNotePlaceholder => 'Recovered from unit 4, spit 2…';

  @override
  String get reportCopied => 'Report copied';

  @override
  String get reportSavedToast => 'Saved to Library';

  @override
  String get reportDeleteTitle => 'Delete this analysis?';

  @override
  String reportDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The report and its $count photos are removed from this device.',
      one: 'The report and its photograph are removed from this device.',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String get reportOptions => 'More options';

  @override
  String get reportSheetTitle => 'Report';

  @override
  String get reportAddAngle => 'Add another angle';

  @override
  String get reportCopy => 'Copy report';

  @override
  String get reportDelete => 'Delete analysis';

  @override
  String get reportSave => 'Save to Library';

  @override
  String get reportAnalyzeAnother => 'Analyze Another';

  @override
  String get confStrong => 'Strong';

  @override
  String get confGood => 'Good';

  @override
  String get confModerate => 'Moderate';

  @override
  String get confWeak => 'Weak';

  @override
  String get confVeryWeak => 'Very weak';

  @override
  String get resultBoneDetected => 'Bone detected';

  @override
  String get resultNoBoneFound => 'No bone found';

  @override
  String resultAngles(int count) {
    return '$count angles';
  }

  @override
  String resultAnglesWithBone(int seen, int count) {
    return 'Bone in $seen of $count photos';
  }

  @override
  String get resultHowSure => 'How sure is this answer?';

  @override
  String get resultHowSureSteps =>
      'The answer is only as good as its weakest step, so the score above is the lowest of these.';

  @override
  String get resultHowSureNone =>
      'How sure the app is that this photo shows no bone.';

  @override
  String get resultStepBone => 'Bone or not';

  @override
  String get resultCouldAlsoBe => 'Not certain. It could also be:';

  @override
  String get resultNoBoneTitle => 'No bone spotted';

  @override
  String get resultNoBoneBody =>
      'We couldn’t find a bone in this photo. Try a plain background, and get close enough that the bone fills most of the picture.';

  @override
  String get resultIdentification => 'Identification';

  @override
  String get resultHumanOrAnimal => 'Human or animal';

  @override
  String get resultWhichBone => 'Which bone';

  @override
  String resultTopGuesses(int count) {
    return 'Top $count guesses';
  }

  @override
  String get resultOnlyGuess => 'Only guess';

  @override
  String get resultWhichPart => 'Which part';

  @override
  String get resultWholeOrBroken => 'Whole or broken';

  @override
  String get resultCondition => 'Condition';

  @override
  String get resultNoMarks => 'No marks flagged';

  @override
  String resultMarksFooter(String threshold) {
    return 'Each kind of mark is checked on its own, so a bone can show more than one. Anything at $threshold or more is flagged.';
  }

  @override
  String get resultAgeSex => 'Age and sex';

  @override
  String get resultAgeGroup => 'Age group';

  @override
  String get resultSex => 'Sex';

  @override
  String get resultAgeFooter =>
      'Age and sex are the hardest things to read from a photo, and Ossia learned them from few examples. Treat them as a hint to check, not an answer.';

  @override
  String get resultWhichAnimal => 'Which animal';

  @override
  String get resultClosestMatch => 'Closest match';

  @override
  String get resultUndetermined => 'Undetermined';

  @override
  String get resultUndeterminedBody =>
      'It looks like an animal bone, but no animal group stood out enough to name.';

  @override
  String get resultAnimalFooter =>
      'For mammals, Ossia names the family (like the deer or dog family) when the bone shows it; otherwise it says mammal, bird or reptile. Compare with a known skeleton before relying on it.';

  @override
  String get resultMeasurements => 'Measurements';

  @override
  String get resultLengthChanged => 'Length changed the answer';

  @override
  String get resultTypicalLength => 'Typical length';

  @override
  String get resultAiEstimate => 'AI estimate';

  @override
  String resultTypicalFor(String thing) {
    return 'For a $thing';
  }

  @override
  String resultLengthAbout(String value, String unit) {
    return '~$value $unit';
  }

  @override
  String resultLengthRange(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get resultYourMeasurement => 'Your measurement';

  @override
  String get resultInsideRange => 'Right inside the typical range. Nice.';

  @override
  String get resultOutsideRange =>
      'Outside the typical range. Worth a second look.';

  @override
  String get resultInsideEstimate => 'Right inside the estimate. Nice.';

  @override
  String get resultOutsideEstimate =>
      'Outside the estimate. Worth a second look.';

  @override
  String get resultReference => 'Reference';

  @override
  String resultAtlasSubtitle(String region) {
    return '$region · what to look for, and left or right';
  }

  @override
  String get resultDisclaimer =>
      'Ossia gives a best guess, not a final answer. Don’t rely on it for medical, legal or police decisions without a bone expert checking the bone in person.';

  @override
  String get libTitle => 'Your stash';

  @override
  String get libEmptySubtitle => 'Empty. For now.';

  @override
  String libBonesCollected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bones collected',
      one: '1 bone collected',
    );
    return '$_temp0';
  }

  @override
  String libHumanCount(int count) {
    return '$count human';
  }

  @override
  String get libSearchHint => 'Search your bones';

  @override
  String get libClearSearch => 'Clear search';

  @override
  String get libFilterAll => 'All';

  @override
  String get libFilterHuman => 'Human';

  @override
  String get libFilterAnimal => 'Animal';

  @override
  String get libFilterFlagged => 'Flagged';

  @override
  String get libToday => 'Today';

  @override
  String get libThisWeek => 'This week';

  @override
  String get libThisMonth => 'This month';

  @override
  String get libEarlier => 'Earlier';

  @override
  String get libEmptyTitle => 'Your stash is empty';

  @override
  String get libEmptyBody =>
      'Every bone you scan lands here with its photo and notes. No bones about it.';

  @override
  String get libNoMatchTitle => 'Nothing matches';

  @override
  String get libNoMatchBody => 'Try a different filter or clear the search.';

  @override
  String atlasSubtitle(int count) {
    return '$count bones the AI knows by heart';
  }

  @override
  String get atlasHowCardTitle => 'How the AI thinks';

  @override
  String get atlasHowCardBody =>
      'The nine passes every photo goes through, and which ones to trust.';

  @override
  String get atlasLookFor => 'What to look for';

  @override
  String get atlasSidingTitle => 'Left or right, and which way up';

  @override
  String get atlasMapTitle => 'Where it sits';

  @override
  String get atlasMapFront => 'Front';

  @override
  String get atlasMapBack => 'Back';

  @override
  String get atlasMapHidden =>
      'Dashed: hidden behind other bones from this side';

  @override
  String atlasMapLabel(String bone) {
    return '$bone highlighted on a whole skeleton, seen from the front and the back';
  }

  @override
  String get howTitle => 'How analysis works';

  @override
  String get howHeading => 'One photo, nine questions';

  @override
  String get howIntro =>
      'Ossia looks at your photo once and answers nine questions about it at the same time. Each answer comes with how sure it is, so one unsure answer doesn’t spoil the rest.';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsLanguageFooter =>
      'You can also switch any time with the globe at the top of each tab.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAccent => 'Accent';

  @override
  String get settingsAnalysis => 'Analysis';

  @override
  String get settingsOnDeviceBody =>
      'Ossia works right on your phone, even with no signal, and your photos stay on your phone.';

  @override
  String get settingsOnlineBody =>
      'Photos are sent to the Ossia computer at the address below, and the report comes back to you.';

  @override
  String get settingsOnlineAddress => 'Online address';

  @override
  String get settingsOnlineAddressBody =>
      'Type the address shown on the Ossia computer.';

  @override
  String get settingsStatus => 'Analyzer status';

  @override
  String get settingsStatusSub => 'Is it ready, and is it connected';

  @override
  String get settingsCutoff => 'Confidence cutoff';

  @override
  String get settingsCutoffBody => 'Guesses below this are shown faded.';

  @override
  String get settingsHideUnlikely => 'Hide unlikely guesses';

  @override
  String get settingsHideUnlikelyBody =>
      'Only show other possible bones when they are above the cutoff.';

  @override
  String get settingsCapture => 'Capture';

  @override
  String get settingsAutoSave => 'Save analyses automatically';

  @override
  String get settingsAutoSaveBody =>
      'Off means each report is kept only if you save it.';

  @override
  String get settingsAutoSnap => 'Auto snap';

  @override
  String get settingsAutoSnapBody =>
      'The camera takes the photo by itself once it sees a bone and the phone is still.';

  @override
  String get settingsUnits => 'Measurement units';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get settingsSavedCount => 'Saved analyses';

  @override
  String get settingsCopyAll => 'Copy all reports';

  @override
  String settingsCopiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports copied',
      one: '1 report copied',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleteAll => 'Delete all analyses';

  @override
  String get settingsDeleteAllTitle => 'Delete everything?';

  @override
  String settingsDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $count saved analyses and their photographs are removed from this device. This cannot be undone.',
      one:
          'The saved analysis and its photographs are removed from this device. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleteAllConfirm => 'Delete All';

  @override
  String get settingsLibraryCleared => 'Library cleared';

  @override
  String get settingsPrivacyFooter =>
      'Your reports stay on this phone. Photos are only sent out when you choose Online analysis.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutOssia => 'About Ossia';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDisclaimer =>
      'Ossia helps you identify bones. It is not a replacement for an expert looking at the bone in person.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutIntro =>
      'Take a photo of a bone and Ossia tells you what it is: which bone, human or animal, which animal, and any marks on it. Every answer shows how sure it is, so you can judge it for yourself.';

  @override
  String get aboutKnows => 'What Ossia knows';

  @override
  String get aboutKindsOfBone => 'Kinds of bone';

  @override
  String get aboutAnimalGroups => 'Animal groups';

  @override
  String get aboutQuestions => 'Questions per photo';

  @override
  String get aboutKnowsFooter =>
      'Ossia learned from thousands of labelled photos, but some bones and animals had only a few. That is why it always tells you how sure it is.';

  @override
  String get aboutPrivacy => 'Privacy';

  @override
  String get aboutPhotos => 'Photographs';

  @override
  String get aboutPhotosBody =>
      'Kept on this phone. Only sent out when you choose Online analysis.';

  @override
  String get aboutAnalytics => 'Analytics';

  @override
  String get aboutAnalyticsBody => 'None collected.';

  @override
  String get aboutWarning =>
      'Results are a best guess, not a final answer. Don’t use them for medical, legal or police decisions without a bone expert checking the bone in person.';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get privacyUpdated => 'Last updated 24 October 2026';

  @override
  String get privacyShortTitle => 'In short';

  @override
  String get privacyShortBody =>
      'Ossia collects nothing about you. There are no accounts, no ads, no usage statistics and no tracking, and nothing is shared with anyone.';

  @override
  String get privacyPhotosTitle => 'Photos and reports';

  @override
  String get privacyPhotosBody =>
      'Photos you take or pick are analyzed on this phone. Reports you save, with their photos and any names or notes you add, stay inside Ossia on this phone. Deleting a report, or the app, deletes them. A report only goes to your clipboard when you choose to copy it.';

  @override
  String get privacyOnlineTitle => 'Online analysis';

  @override
  String get privacyOnlineBody =>
      'Online analysis is off unless you turn it on in Settings. When it is on, the photos you analyze, and a length if you typed one, are sent to the address you entered: a computer you or your group run. The Ossia developer doesn’t run that computer and never receives your photos.';

  @override
  String get privacyPermissionsTitle => 'What Ossia asks for';

  @override
  String get privacyPermissionsBody =>
      'Camera: to photograph a bone. Photos: Ossia only sees the photos you pick. Local network: to reach your computer for Online analysis, if your phone asks. Ossia never records sound and never uses your location.';

  @override
  String get privacyChangesTitle => 'Changes and questions';

  @override
  String get privacyChangesBody =>
      'If this policy changes, the new version will be here in the app and at github.com/BigDonalds/Ossia-AI-Bone-Analyzer. You can ask questions there, or email danesh.amir2001@gmail.com.';

  @override
  String get statusYou => 'YOU';

  @override
  String get statusNapping => 'NAPPING';

  @override
  String get statusAllOnPhone => 'ALL ON YOUR PHONE';

  @override
  String msShort(int ms) {
    return '$ms ms';
  }

  @override
  String statusChecked(String when) {
    return 'checked $when';
  }

  @override
  String secondsAgo(int count) {
    return '${count}s ago';
  }

  @override
  String get statusConnected => 'Connected';

  @override
  String statusConnectedBody(String ms) {
    return 'Online analysis is answering in $ms ms. Your scans will be analyzed there.';
  }

  @override
  String statusOfflineBody(String reason) {
    return '$reason. Check the address, and that the Ossia computer is switched on.';
  }

  @override
  String get statusNoAnswer => 'No answer';

  @override
  String get statusFailedTitle => 'Couldn’t get ready';

  @override
  String get statusFailedBody =>
      'Something stopped Ossia from starting on this phone. Try again, or restart the app.';

  @override
  String get statusOnPhoneTitle => 'Analyzing on this phone';

  @override
  String get statusOnPhoneBody =>
      'Works anywhere, even with no signal, and your photos never leave your phone.';

  @override
  String get statusConnectingBody => 'Checking that online analysis is awake.';

  @override
  String get statusChecking => 'Checking…';

  @override
  String get statusCheckNow => 'Check connection';

  @override
  String get statusChangeAddress => 'Change address';

  @override
  String get statusRunningFor => 'Running for';

  @override
  String get statusHistory => 'Connection history';

  @override
  String get statusAutoPaused => 'auto-check paused';

  @override
  String statusNextIn(int seconds) {
    return 'next in ${seconds}s';
  }

  @override
  String get statusNoChecks => 'No checks yet';

  @override
  String statusHistoryFooter(int seconds) {
    return 'Checked every ${seconds}s while the app is open. Shorter bars mean a faster connection.';
  }

  @override
  String get statusRow => 'Status';

  @override
  String get statusWakesUp => 'Wakes up on your first scan';

  @override
  String get statusSleeping => 'Sleeping';

  @override
  String get statusGettingReady => 'Getting ready…';

  @override
  String get statusCouldntStart => 'Couldn’t start';

  @override
  String get statusInternetNeeded => 'Internet needed';

  @override
  String get statusNo => 'No';

  @override
  String get statusPhotosSent => 'Photos sent anywhere';

  @override
  String get statusNever => 'Never';

  @override
  String get statusGetReady => 'Get it ready now';
}
