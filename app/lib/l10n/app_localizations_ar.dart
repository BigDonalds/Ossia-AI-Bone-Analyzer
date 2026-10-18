// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Ossia';

  @override
  String get tabScan => 'فحص';

  @override
  String get tabStash => 'مجموعتي';

  @override
  String get tabAtlas => 'الأطلس';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get back => 'رجوع';

  @override
  String get confirm => 'تأكيد';

  @override
  String get dismiss => 'إغلاق';

  @override
  String get nah => 'لا، شكرًا';

  @override
  String get save => 'حفظ';

  @override
  String get done => 'تم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get tryAgain => 'حاول مجددًا';

  @override
  String get engineOnDevice => 'هذا الهاتف';

  @override
  String get engineServer => 'عبر الإنترنت';

  @override
  String get engineAnalyzeOn => 'التحليل على';

  @override
  String get engineWorksOffline => 'يعمل دون إنترنت';

  @override
  String get engineUsesInternet => 'يحتاج إلى إنترنت';

  @override
  String dateAtTime(String date, String time) {
    return '$date الساعة $time';
  }

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: 'أقل من دقيقة',
    );
    return 'قبل $_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتين',
      one: 'ساعة',
      zero: 'أقل من ساعة',
    );
    return 'قبل $_temp0';
  }

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم',
      zero: 'يوم',
    );
    return 'قبل $_temp0';
  }

  @override
  String get accentSunny => 'أصفر مشمس';

  @override
  String get accentLime => 'أخضر ليموني';

  @override
  String get accentBubblegum => 'وردي علكة';

  @override
  String get accentTangerine => 'برتقالي';

  @override
  String get accentGrape => 'بنفسجي';

  @override
  String get accentSky => 'أزرق سماوي';

  @override
  String get welcomeTitle => 'بأي لغة تريد أن يتحدث Ossia؟';

  @override
  String get welcomeSubtitle =>
      'اخترنا لغة هاتفك. غيّرها هنا، أو في أي وقت من زر الكرة الأرضية في الأعلى.';

  @override
  String get welcomeSubtitleNoMatch =>
      'اختر لغة من هنا. يمكنك تغييرها في أي وقت من زر الكرة الأرضية في الأعلى.';

  @override
  String get welcomeContinue => 'هيا بنا';

  @override
  String get languageCardLine => 'العظام، مشروحة بالعربية';

  @override
  String get languageFromPhone => 'من هاتفك';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get globeTooltip => 'تغيير اللغة';

  @override
  String get languageSheetTitle => 'اختر لغة';

  @override
  String get languageSheetMessage => 'يتغير كل شيء فورًا، حتى ما حفظته.';

  @override
  String get languageMatchPhone => 'مثل هاتفي';

  @override
  String languageMatchPhoneHint(String language) {
    return 'حاليًا: $language';
  }

  @override
  String languageFollowingPhone(String language) {
    return 'الهاتف ($language)';
  }

  @override
  String get languageNameEnglish => 'الإنجليزية';

  @override
  String get languageNameGerman => 'الألمانية';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get languageNowSpeaking => 'Ossia يتحدث العربية الآن';

  @override
  String get boneSkull => 'الجمجمة';

  @override
  String get boneSkullMeaning => 'الرأس كاملًا';

  @override
  String get boneCranium => 'القحف';

  @override
  String get boneCraniumMeaning => 'الجمجمة من دون الفك السفلي';

  @override
  String get boneMandible => 'الفك السفلي';

  @override
  String get boneMandibleMeaning => 'عظم الفك الذي يتحرك عند المضغ';

  @override
  String get boneFemur => 'عظم الفخذ';

  @override
  String get boneFemurMeaning => 'أطول عظم في الساق، من الورك إلى الركبة';

  @override
  String get boneTibia => 'الظنبوب';

  @override
  String get boneTibiaMeaning => 'عظم القصبة في مقدمة الساق';

  @override
  String get boneHumerus => 'عظم العضد';

  @override
  String get boneHumerusMeaning => 'عظم أعلى الذراع أو أعلى الساق الأمامية';

  @override
  String get boneRadius => 'الكعبرة';

  @override
  String get boneRadiusMeaning => 'أحد عظمي الساعد أو أسفل الساق الأمامية';

  @override
  String get boneUlna => 'الزند';

  @override
  String get boneUlnaMeaning =>
      'أحد عظمي الساعد أو أسفل الساق الأمامية، وفيه رأس المرفق';

  @override
  String get boneScapula => 'لوح الكتف';

  @override
  String get boneScapulaMeaning => 'عظم الكتف العريض المسطح';

  @override
  String get boneOsCoxa => 'عظم الورك';

  @override
  String get boneOsCoxaMeaning => 'عظم الحوض على جانب الجسم';

  @override
  String get boneRib12 => 'الضلعان 1–2';

  @override
  String get boneRib12Meaning => 'أحد الضلعين العلويين';

  @override
  String get boneTypicalRib => 'ضلع نموذجي';

  @override
  String get boneTypicalRibMeaning => 'ضلع من وسط الصدر';

  @override
  String get boneRib1112 => 'الضلعان 11–12';

  @override
  String get boneRib1112Meaning => 'أحد الضلعين السفليين';

  @override
  String get boneCervical => 'الفقرات العنقية';

  @override
  String get boneCervicalMeaning => 'عظم من الرقبة';

  @override
  String get boneThoracic => 'الفقرات الصدرية';

  @override
  String get boneThoracicMeaning => 'عظم من أعلى الظهر';

  @override
  String get boneLumbar => 'الفقرات القطنية';

  @override
  String get boneLumbarMeaning => 'عظم من أسفل الظهر';

  @override
  String get boneUnidentified => 'غير محدد';

  @override
  String get noBoneDetected => 'لم يُكتشف عظم';

  @override
  String get animalHuman => 'إنسان';

  @override
  String get animalHumanMeaning => 'شخص';

  @override
  String get animalCanid => 'الكلبيات';

  @override
  String get animalCanidMeaning =>
      'فصيلة الكلاب (الكلاب والذئاب والقيوط والثعالب)';

  @override
  String get animalCervid => 'الأيليات';

  @override
  String get animalCervidMeaning => 'فصيلة الأيائل (الأيائل والموظ والرنة)';

  @override
  String get animalBovid => 'البقريات';

  @override
  String get animalBovidMeaning =>
      'فصيلة البقر (الأبقار والبيسون والأغنام والماعز والظباء)';

  @override
  String get animalSuid => 'الخنزيريات';

  @override
  String get animalSuidMeaning =>
      'فصيلة الخنازير (الخنازير الأليفة والبرية وخنازير الثآليل)';

  @override
  String get animalFelid => 'السنوريات';

  @override
  String get animalFelidMeaning =>
      'فصيلة القطط (القطط المنزلية والوشق وأسد الجبال والأسود)';

  @override
  String get animalUrsid => 'الدببة';

  @override
  String get animalUrsidMeaning => 'الدببة بكل أنواعها';

  @override
  String get animalLeporid => 'الأرنبيات';

  @override
  String get animalLeporidMeaning => 'الأرانب الأليفة والبرية';

  @override
  String get animalProcyonid => 'الراكونيات';

  @override
  String get animalProcyonidMeaning =>
      'فصيلة الراكون (الراكون والكوتي والقط ذو الذيل الحلقي)';

  @override
  String get animalEquid => 'الخيليات';

  @override
  String get animalEquidMeaning =>
      'فصيلة الخيل (الخيول والحمير والحمر الوحشية)';

  @override
  String get animalRodent => 'القوارض';

  @override
  String get animalRodentMeaning =>
      'الجرذان والفئران والسناجب والقنادس وأقاربها';

  @override
  String get animalMammal => 'ثديي';

  @override
  String get animalOtherMammalMeaning =>
      'حيوان ذو فرو يُرضع صغاره، من فصيلة لا يسمّيها Ossia، مثل الظربان أو الأبوسوم';

  @override
  String get animalMammalMeaning =>
      'حيوان ذو فرو يُرضع صغاره. هذا العظم لا يُظهر من أي فصيلة هو';

  @override
  String get animalBird => 'طائر';

  @override
  String get animalBirdMeaning => 'أي طائر، من العصفور إلى النعامة';

  @override
  String get animalReptile => 'زاحف';

  @override
  String get animalReptileMeaning => 'السلاحف والثعابين والسحالي والتماسيح';

  @override
  String get animalUnnamed => 'حيوان';

  @override
  String get animalUnnamedMeaning => 'عظم حيوان لم تبرز له أي مجموعة حيوانية';

  @override
  String get partComplete => 'عظم كامل';

  @override
  String get partShaft => 'الوسط (جسم العظم)';

  @override
  String get partProximal => 'الطرف القريب';

  @override
  String get partDistal => 'الطرف البعيد';

  @override
  String get partFragment => 'قطعة مكسورة';

  @override
  String get statusComplete => 'كامل';

  @override
  String get statusFragment => 'مكسور';

  @override
  String get conditionWholeButBroken => 'عظم كامل لكنه مكسور';

  @override
  String conditionPartBroken(String part) {
    return '$part، مكسور';
  }

  @override
  String get damageFracture => 'كسر';

  @override
  String get damageCutMarks => 'آثار قطع';

  @override
  String get damageBurnSigns => 'آثار حرق';

  @override
  String get ageAdult => 'بالغ';

  @override
  String get ageJuvenile => 'يافع';

  @override
  String get sexMale => 'ذكر';

  @override
  String get sexFemale => 'أنثى';

  @override
  String get unknownValue => 'غير معروف';

  @override
  String get sourceOnDevice => 'على هذا الهاتف';

  @override
  String get sourceServer => 'خادمك';

  @override
  String get regionCranial => 'الرأس';

  @override
  String get regionAxial => 'العمود الفقري';

  @override
  String get regionThoracic => 'القفص الصدري';

  @override
  String get regionUpperLimb => 'الطرف العلوي';

  @override
  String get regionLowerLimb => 'الطرف السفلي';

  @override
  String get regionGirdle => 'حزاما الكتف والحوض';

  @override
  String get phaseFinding => 'البحث عن العظم';

  @override
  String get phaseHumanOrAnimal => 'إنسان أم حيوان؟';

  @override
  String get phaseWhichBone => 'أي عظم؟';

  @override
  String get phaseWhichPart => 'أي جزء؟';

  @override
  String get phaseWholeOrBroken => 'كامل أم مكسور؟';

  @override
  String get phaseMarks => 'البحث عن الآثار';

  @override
  String get phaseWhichAnimal => 'أي حيوان؟';

  @override
  String get phaseAgeSex => 'العمر والجنس';

  @override
  String get phaseWriting => 'كتابة التقرير';

  @override
  String get unitCentimetres => 'سنتيمتر';

  @override
  String get unitInches => 'بوصة';

  @override
  String get unitCm => 'سم';

  @override
  String get unitIn => 'بوصة';

  @override
  String get atlasSkullBlurb => 'القحف والفك السفلي معًا';

  @override
  String get atlasSkullSummary =>
      'الرأس العظمي كاملًا: القحف مع الفك السفلي. اثنان وعشرون عظمًا في المجموع، تربطها دروز متشابكة؛ ولا يتحرك بحرية سوى الفك السفلي.';

  @override
  String get atlasSkullLm1 => 'الدروز الإكليلي والسهمي واللامي';

  @override
  String get atlasSkullLm2 => 'محجرا العينين والفتحة الكمثرية (الأنفية)';

  @override
  String get atlasSkullLm3 => 'الثقبة العظمى في قاعدة الجمجمة';

  @override
  String get atlasSkullLm4 => 'الناتئان الخشائيان خلف قناتي الأذن';

  @override
  String get atlasSkullSiding =>
      'متناظرة. يُعرف الاتجاه من العظم الجبهي (في الأمام) وحرشفة العظم القذالي (في الخلف).';

  @override
  String get atlasCraniumBlurb => 'الجمجمة من دون فكها';

  @override
  String get atlasCraniumSummary =>
      'الجمجمة بعد إزالة الفك السفلي. تحيط بالدماغ وتحميه؛ وتتكوّن القبة من العظام الجبهي والجداري والصدغي والقذالي.';

  @override
  String get atlasCraniumLm1 => 'الحافتان فوق الحجاجين — أبرز في جماجم الذكور';

  @override
  String get atlasCraniumLm2 => 'الخطوط القفوية على العظم القذالي';

  @override
  String get atlasCraniumLm3 => 'الخطوط الصدغية الممتدة عبر العظمين الجداريين';

  @override
  String get atlasCraniumLm4 => 'الصماخ السمعي الظاهر';

  @override
  String get atlasCraniumSiding =>
      'متناظرة حين تكون كاملة. تُحدَّد جهة قطع القبة المنفردة من اتجاه الدروز ونمط أخاديد الأوعية السحائية.';

  @override
  String get atlasCraniumAka => 'القلنسوة (القبة فقط)';

  @override
  String get atlasMandibleBlurb => 'الفك السفلي؛ كثيف ومتين';

  @override
  String get atlasMandibleSummary =>
      'الفك السفلي — العظم الوحيد المتحرك بحرية في الجمجمة. كثيف ومتماسك، لذا يصمد أمام الدفن والحرق أكثر من معظم العظام.';

  @override
  String get atlasMandibleLm1 => 'البروز الذقني (الذقن)';

  @override
  String get atlasMandibleLm2 => 'زاوية الفك حيث يلتقي الفرع بالجسم';

  @override
  String get atlasMandibleLm3 => 'لقمة الفك والناتئ الإكليلي';

  @override
  String get atlasMandibleLm4 => 'الثقبة الذقنية أسفل الضواحك';

  @override
  String get atlasMandibleSiding =>
      'متناظر حين يكون كاملًا. يُحدَّد جانب نصف الفك من اتجاه صعود الفرع ومن جهة انحناء صف الأسنان.';

  @override
  String get atlasFemurBlurb => 'عظم الفخذ؛ أفضل مؤشر على طول القامة';

  @override
  String get atlasFemurSummary =>
      'عظم الفخذ — أطول عظام الجسم وأقواها. طوله الأقصى هو الأوثق ارتباطًا بطول القامة في الحياة.';

  @override
  String get atlasFemurLm1 => 'رأس كروي فيه نُقرة الرأس';

  @override
  String get atlasFemurLm2 => 'المدوّران الكبير والصغير';

  @override
  String get atlasFemurLm3 => 'الخط الخشن على الوجه الخلفي لجسم العظم';

  @override
  String get atlasFemurLm4 => 'اللقمتان الإنسية والوحشية عند الركبة';

  @override
  String get atlasFemurSiding =>
      'أمسك العظم عموديًا: يتجه الرأس نحو الداخل ويكون الخط الخشن إلى الخلف. الجهة التي يشير إليها الرأس هي جهة الجسم.';

  @override
  String get atlasTibiaBlurb => 'عظم الساق؛ جسم مثلث المقطع';

  @override
  String get atlasTibiaSummary =>
      'عظم القصبة، الإنسي والحامل للوزن في أسفل الساق. جسمه المثلث المقطع مميز حتى في القطع المكسورة.';

  @override
  String get atlasTibiaLm1 => 'الحدبة الظنبوبية في مقدمة الجزء العلوي من الجسم';

  @override
  String get atlasTibiaLm2 => 'حافة أمامية حادة';

  @override
  String get atlasTibiaLm3 => 'الكعب الإنسي عند الكاحل';

  @override
  String get atlasTibiaLm4 => 'لقمتان إنسية ووحشية مسطحتان';

  @override
  String get atlasTibiaSiding =>
      'يبرز الكعب الإنسي في الجهة نفسها من الجسم التي جاء منها العظم؛ وتحدد الحدبة الظنبوبية الجهة الأمامية.';

  @override
  String get atlasHumerusBlurb => 'أعلى الذراع، من الكتف إلى المرفق';

  @override
  String get atlasHumerusSummary =>
      'عظم أعلى الذراع، يمتد من مفصل الكتف إلى المرفق. لا يفوقه طولًا إلا عظم الفخذ.';

  @override
  String get atlasHumerusLm1 => 'رأس مستدير مع الحديبتين الكبرى والصغرى';

  @override
  String get atlasHumerusLm2 => 'الحدبة الدالية في منتصف الجسم';

  @override
  String get atlasHumerusLm3 => 'الحفرة الزُّجّية في الخلف عند الطرف البعيد';

  @override
  String get atlasHumerusLm4 => 'البكرة والرُّؤيس تشكّلان مفصل المرفق';

  @override
  String get atlasHumerusSiding =>
      'أوقفه عموديًا ورأسه مواجه لك: تقع الحفرة الزجية في الخلف، ويتجه الرأس نحو الداخل باتجاه خط منتصف الجسم.';

  @override
  String get atlasRadiusBlurb => 'العظم الوحشي في الساعد، في جهة الإبهام';

  @override
  String get atlasRadiusSummary =>
      'عظم الساعد الوحشي، في جهة الإبهام. يدور فوق الزند ليقلب راحة اليد.';

  @override
  String get atlasRadiusLm1 => 'رأس قرصي الشكل في الطرف القريب';

  @override
  String get atlasRadiusLm2 => 'الحدبة الكعبرية أسفل العنق مباشرة';

  @override
  String get atlasRadiusLm3 => 'طرف بعيد عريض ومتسع';

  @override
  String get atlasRadiusLm4 => 'الناتئ الإبري عند الرسغ';

  @override
  String get atlasRadiusSiding =>
      'الرأس الصغير في الطرف القريب والطرف العريض في الطرف البعيد؛ ويتجه الناتئ الإبري نحو الخارج، بعيدًا عن خط المنتصف.';

  @override
  String get atlasUlnaBlurb => 'العظم الإنسي في الساعد؛ رأس المرفق';

  @override
  String get atlasUlnaSummary =>
      'عظم الساعد الإنسي، في جهة الخنصر. يشكّل مفصل المرفق الرزّي، وهو الشريك الثابت الذي تدور حوله الكعبرة.';

  @override
  String get atlasUlnaLm1 => 'الناتئ الزُّجّي — رأس المرفق';

  @override
  String get atlasUlnaLm2 => 'الثلمة البكرية التي تمسك بعظم العضد';

  @override
  String get atlasUlnaLm3 => 'الناتئ المنقاري أسفل الثلمة';

  @override
  String get atlasUlnaLm4 => 'رأس بعيد نحيل مع ناتئ إبري';

  @override
  String get atlasUlnaSiding =>
      'تنفتح الثلمة البكرية نحو الأمام؛ وحين يكون الزُّج في الأعلى والثلمة مواجهة لك، ينحني جسم العظم نحو جهة الجسم.';

  @override
  String get atlasScapulaBlurb => 'لوح الكتف؛ صفيحة رقيقة مثلثة';

  @override
  String get atlasScapulaSummary =>
      'لوح الكتف — صفيحة مثلثة رقيقة تستقر على ظهر القفص الصدري. رقيقة لدرجة أنها كثيرًا ما تبقى على شكل قطع فقط.';

  @override
  String get atlasScapulaLm1 => 'الشوكة الممتدة عبر السطح الخلفي';

  @override
  String get atlasScapulaLm2 => 'الناتئ الأخرمي عند طرف الكتف';

  @override
  String get atlasScapulaLm3 => 'الناتئ الغرابي المعقوف في الأمام';

  @override
  String get atlasScapulaLm4 => 'الحفرة العنابية التي يستقر فيها رأس العضد';

  @override
  String get atlasScapulaSiding =>
      'تتجه الحفرة العنابية نحو الخارج وتقع الشوكة على السطح الخلفي؛ والجهة التي تواجهها الحفرة هي جهة الجسم.';

  @override
  String get atlasOsCoxaBlurb => 'عظم الورك؛ أفضل مؤشر على الجنس';

  @override
  String get atlasOsCoxaSummary =>
      'عظم الورك: الحرقفة والإسك والعانة ملتحمة عند الحُق. أوثق عظم منفرد لتقدير الجنس وعمر البالغين.';

  @override
  String get atlasOsCoxaLm1 =>
      'الثلمة الوركية الكبرى — عريضة عند الإناث وضيقة عند الذكور';

  @override
  String get atlasOsCoxaLm2 => 'الزاوية تحت العانة والقوس البطني';

  @override
  String get atlasOsCoxaLm3 => 'السطح الأذيني، يُستخدم لتقدير العمر عند الوفاة';

  @override
  String get atlasOsCoxaLm4 => 'الحُق الذي يستقر فيه رأس الفخذ';

  @override
  String get atlasOsCoxaSiding =>
      'وجّه جناح الحرقفة إلى الأعلى والحُق إلى الخارج: تقع العانة في الأمام وتنفتح الثلمة الوركية نحو الخلف.';

  @override
  String get atlasOsCoxaAka => 'العظم الغُفل، عظم الورك';

  @override
  String get atlasRib12Blurb => 'ضلوع غير نموذجية؛ مسطحة وشديدة الانحناء';

  @override
  String get atlasRib12Summary =>
      'الضلعان الأولان غير نموذجيين. الضلع 1 هو الأقصر والأعرض والأشد انحناءً؛ والضلع 2 أطول لكنه يحتفظ بالشكل المسطح نفسه.';

  @override
  String get atlasRib12Lm1 => 'الضلع 1 مسطح، له سطح علوي وسطح سفلي';

  @override
  String get atlasRib12Lm2 => 'الحديبة الأخمعية مع أخاديد للأوعية تحت الترقوة';

  @override
  String get atlasRib12Lm3 => 'يحمل الضلع 2 حدبة للعضلة المنشارية الأمامية';

  @override
  String get atlasRib12Lm4 => 'وجيه مفصلي واحد على رأس الضلع 1';

  @override
  String get atlasRib12Siding =>
      'ضع الضلع مسطحًا ورأسه إلى الخلف: يتجه السطح الداخلي المقعّر نحو خط المنتصف، فيدلّ على الجهة.';

  @override
  String get atlasTypicalRibBlurb => 'الضلوع 3–9؛ رأس وحديبة وأخدود ضلعي';

  @override
  String get atlasTypicalRibSummary =>
      'تشترك الضلوع من 3 إلى 9 في تصميم واحد: رأس وعنق وحديبة وجسم طويل منحنٍ يلتوي عند الزاوية.';

  @override
  String get atlasTypicalRibLm1 => 'نصفا وجيه مفصلي على الرأس';

  @override
  String get atlasTypicalRibLm2 => 'حديبة تتمفصل مع ناتئ مستعرض';

  @override
  String get atlasTypicalRibLm3 => 'زاوية يتغير عندها اتجاه جسم الضلع';

  @override
  String get atlasTypicalRibLm4 =>
      'الأخدود الضلعي على امتداد الحافة السفلية الداخلية';

  @override
  String get atlasTypicalRibSiding =>
      'يمتد الأخدود الضلعي على الحافة السفلية الداخلية؛ وحين يكون الأخدود في الأسفل والداخل، يشير الرأس إلى الخلف ويدلّ على الجهة.';

  @override
  String get atlasRib1112Blurb => 'الضلوع العائمة؛ قصيرة وغير متصلة';

  @override
  String get atlasRib1112Summary =>
      'الضلوع العائمة. قصيرة ومستدقة وغير متصلة من الأمام، ولهذا تفتقر إلى معظم ملامح الضلع النموذجي.';

  @override
  String get atlasRib1112Lm1 => 'وجيه مفصلي واحد على الرأس';

  @override
  String get atlasRib1112Lm2 => 'لا عنق ولا حديبة';

  @override
  String get atlasRib1112Lm3 => 'أخدود ضلعي ضعيف أو معدوم';

  @override
  String get atlasRib1112Lm4 => 'طرف أمامي مدبب ينتهي بغضروف';

  @override
  String get atlasRib1112Siding =>
      'الانحناء وحده يدلّ على الجهة: يتجه السطح المقعّر نحو خط المنتصف.';

  @override
  String get atlasCervicalBlurb => 'C1–C7؛ الوحيدة ذات الثقوب المستعرضة';

  @override
  String get atlasCervicalSummary =>
      'فقرات الرقبة السبع، C1–C7. أصغر أجسام في العمود الفقري، والفقرات الوحيدة التي في نواتئها المستعرضة ثقوب.';

  @override
  String get atlasCervicalLm1 => 'الثقوب المستعرضة — علامة مميزة لهذه المنطقة';

  @override
  String get atlasCervicalLm2 =>
      'ليس للفقرة C1 (الفهقة) جسم؛ وتحمل C2 (المحور) الناتئ السني';

  @override
  String get atlasCervicalLm3 => 'نواتئ شوكية مشقوقة في C2–C6';

  @override
  String get atlasCervicalLm4 => 'ثقبة فقرية كبيرة مثلثة';

  @override
  String get atlasCervicalSiding =>
      'متناظرة. يُعرف موقعها في السلسلة من الناتئ الشوكي وحجم الجسم؛ وللفقرة C7 شوكة طويلة غير مشقوقة تُعرف بـ«البارزة».';

  @override
  String get atlasThoracicBlurb => 'T1–T12؛ تحمل الوجيهات الضلعية';

  @override
  String get atlasThoracicSummary =>
      'فقرات أعلى الظهر الاثنتا عشرة، T1–T12. تتمفصل كل واحدة مع زوج من الضلوع، والوجيهات الخاصة بتلك الضلوع تميّز هذه المنطقة.';

  @override
  String get atlasThoracicLm1 => 'وجيهات ضلعية على الجسم والنواتئ المستعرضة';

  @override
  String get atlasThoracicLm2 => 'أجسام فقرية على شكل قلب';

  @override
  String get atlasThoracicLm3 => 'نواتئ شوكية طويلة مائلة بشدة نحو الأسفل';

  @override
  String get atlasThoracicLm4 => 'ثقبة فقرية دائرية';

  @override
  String get atlasThoracicSiding =>
      'متناظرة. يُستدل على الترتيب من حجم الجسم ومن مدى تراكب الناتئ الشوكي على الفقرة التي تحته.';

  @override
  String get atlasLumbarBlurb => 'L1–L5؛ الأثقل في العمود الفقري';

  @override
  String get atlasLumbarSummary =>
      'فقرات أسفل الظهر الخمس، L1–L5. الأكبر والأمتن في العمود الفقري، مصممة لتحمّل الوزن لا للحركة.';

  @override
  String get atlasLumbarLm1 => 'أجسام ضخمة على شكل كلية';

  @override
  String get atlasLumbarLm2 => 'لا ثقوب مستعرضة ولا وجيهات ضلعية';

  @override
  String get atlasLumbarLm3 => 'نواتئ شوكية قصيرة كليلة على شكل فأس';

  @override
  String get atlasLumbarLm4 => 'نواتئ حلمية على الوجيهات المفصلية العلوية';

  @override
  String get atlasLumbarSiding =>
      'متناظرة. تُعرف الفقرة L5 بشكلها الإسفيني، فهي أعمق من الأمام منها من الخلف، حيث تلتقي بالعجز.';

  @override
  String get phaseDoc1Title => 'هل يوجد عظم؟';

  @override
  String get phaseDoc1Detail =>
      'يتحقق Ossia أولًا من وجود عظم في الصورة أصلًا، حتى لا يحصل غصن أو حجر على إجابة مختلَقة.';

  @override
  String get phaseDoc2Title => 'إنسان أم حيوان؟';

  @override
  String get phaseDoc2Detail =>
      'ثم يقرر إن كان العظم من إنسان أم من حيوان. كل ما يلي يعتمد على هذه الخطوة.';

  @override
  String get phaseDoc3Title => 'أي عظم؟';

  @override
  String get phaseDoc3Detail =>
      'ستة عشر نوعًا من العظام، من الجمجمة والفك إلى الضلوع والعمود الفقري والورك والأطراف. ترى أفضل ثلاثة تخمينات، لا الفائز وحده.';

  @override
  String get phaseDoc4Title => 'أي جزء؟';

  @override
  String get phaseDoc4Detail =>
      'هل تُظهر الصورة العظم كاملًا، أم وسطه (جسم العظم)، أم أحد طرفيه، أم قطعة مكسورة.';

  @override
  String get phaseDoc5Title => 'كامل أم مكسور؟';

  @override
  String get phaseDoc5Detail =>
      'نعم أو لا بسرعة: هل العظم كامل، أم مجرد قطعة منه؟';

  @override
  String get phaseDoc6Title => 'الآثار والأضرار';

  @override
  String get phaseDoc6Detail =>
      'يُفحص كل من الكسور وآثار القطع والحرق على حدة، لذا قد يُظهر عظم واحد الثلاثة معًا.';

  @override
  String get phaseDoc7Title => 'أي حيوان؟';

  @override
  String get phaseDoc7Detail =>
      'لعظام الحيوانات: ثديي أو طائر أو زاحف. وللثدييات أيضًا الفصيلة، مثل فصيلة الكلاب أو الأيائل أو البقر أو الخنازير أو القطط أو الدببة أو الأرانب أو الراكون أو الخيل، أو القوارض. ولا تُسمّى الفصيلة إلا حين يستطيع العظم إظهارها، كالجمجمة أو الفك أو عظم ساق كامل.';

  @override
  String get phaseDoc8Title => 'العمر والجنس';

  @override
  String get phaseDoc8Detail =>
      'للعظام البشرية فقط. اعتبرها تلميحًا يجب التحقق منه، لا إجابة قائمة بذاتها.';

  @override
  String get phaseDoc9Title => 'جمع النتائج';

  @override
  String get phaseDoc9Detail =>
      'تُقرأ صور العظم نفسه من جهات مختلفة معًا، ويُقارن الطول الذي قسته بالحجم المعتاد لهذا العظم. وكلاهما يساعد حين تكون صورة واحدة غير واضحة.';

  @override
  String get errNotReadyOnPhone =>
      'تعذّر تجهيز Ossia على هذا الهاتف. حاول مجددًا، أو أعد تشغيل التطبيق.';

  @override
  String get errPhotoUnreadable =>
      'تعذّرت قراءة هذه الصورة. جرّب صورة بصيغة JPEG أو PNG.';

  @override
  String errPhotoNUnreadable(int number) {
    return 'تعذّرت قراءة الصورة رقم $number. احذفها وحاول مجددًا.';
  }

  @override
  String get errReadingPhoto =>
      'حدث خطأ أثناء قراءة الصورة. يُرجى المحاولة مجددًا.';

  @override
  String get errPhotoTryAnother => 'تعذّرت قراءة هذه الصورة. جرّب صورة أخرى.';

  @override
  String get errBadOnlineAddress =>
      'لا يبدو عنوان التحليل عبر الإنترنت صحيحًا. تحقّق منه في الإعدادات.';

  @override
  String get errThisDevice =>
      'هذا العنوان يشير إلى هذا الهاتف نفسه. اكتب بدلًا منه العنوان الظاهر على حاسوب Ossia.';

  @override
  String errServerStatus(int code) {
    return 'التحليل عبر الإنترنت لا يعمل الآن (الخطأ $code).';
  }

  @override
  String get errServerTooBig =>
      'الصور كبيرة جدًا لإرسالها. جرّب عددًا أقل من الصور.';

  @override
  String get errServerRejected =>
      'لم يقبل التحليل عبر الإنترنت هذه الصور. جرّب صورًا أخرى.';

  @override
  String get errServerCouldntAnalyze =>
      'تعذّر على التحليل عبر الإنترنت قراءة هذه الصور. جرّب صورًا أخرى.';

  @override
  String get errTimeout =>
      'استغرق التحليل عبر الإنترنت وقتًا طويلًا للرد. تحقّق من اتصالك، أو حلّل على هذا الهاتف.';

  @override
  String get errUnreachable =>
      'تعذّر الاتصال للتحليل عبر الإنترنت. تحقّق من الإنترنت ومن عنوان التحليل في الإعدادات.';

  @override
  String get errNotAReport =>
      'ردّ شيء ما، لكن ليس بتقرير. تحقّق من عنوان التحليل في الإعدادات.';

  @override
  String get errGeneric => 'حدث خطأ ما. يُرجى المحاولة مجددًا.';

  @override
  String get checkAddress => 'العنوان';

  @override
  String get checkReach => 'الوصول إليه';

  @override
  String get checkServer => 'استجابة Ossia';

  @override
  String get checkModel => 'جاهز للتحليل';

  @override
  String get checkSpeed => 'السرعة';

  @override
  String get checkBadAddress => 'هذا ليس عنوانًا صالحًا';

  @override
  String checkAnsweredIn(int ms) {
    return 'ردّ خلال $ms ملّي ثانية';
  }

  @override
  String checkRunningFor(String time) {
    return 'يعمل منذ $time';
  }

  @override
  String get checkNotReady => 'يعمل، لكنه ليس جاهزًا للتحليل بعد';

  @override
  String get checkReady => 'جاهز';

  @override
  String get checkLost => 'انقطع الاتصال';

  @override
  String checkPing(int ms, String word) {
    return '$ms ms · $word';
  }

  @override
  String get pingSnappy => 'سريع جدًا';

  @override
  String get pingGood => 'جيد';

  @override
  String get pingSluggish => 'بطيء نوعًا ما';

  @override
  String get pingSlow => 'بطيء';

  @override
  String uptimeSeconds(int s) {
    return '$s ث';
  }

  @override
  String uptimeMinutes(int m) {
    return '$m د';
  }

  @override
  String uptimeHours(int h, int m) {
    return '$h س $m د';
  }

  @override
  String uptimeDays(int d, int h) {
    return '$d ي $h س';
  }

  @override
  String get netBadAnswer => 'ردّ غير صالح';

  @override
  String netNoAnswer(int seconds) {
    return 'لا ردّ خلال $seconds ثوانٍ';
  }

  @override
  String get netNotFound =>
      'لم يُعثر على هذا العنوان. تأكّد من كتابته بشكل صحيح ومن أنه ما زال صالحًا';

  @override
  String get netRefused => 'لم يردّ شيء على هذا العنوان';

  @override
  String get netNoInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get netNotSecure => 'تعذّر إنشاء اتصال آمن';

  @override
  String get netNotRunning => 'العنوان يعمل، لكن Ossia لا يعمل خلفه';

  @override
  String get netExpired => 'انتهت صلاحية هذا العنوان';

  @override
  String netHttpError(int code) {
    return 'ردّ بخطأ ($code)';
  }

  @override
  String get netNotOssia => 'ردّ شيء ما، لكنه ليس Ossia';

  @override
  String lenThing(String animal, String bone) {
    return '«$animal · $bone»';
  }

  @override
  String lenUsually(String thing, String min, String max) {
    return '$thing (عادةً $min–$max سم)';
  }

  @override
  String lenNeverOver(String thing, String max) {
    return '$thing (لا يتجاوز $max سم)';
  }

  @override
  String lenOrThing(String first, String second) {
    return '$first أو $second';
  }

  @override
  String get lenNoBone => 'لم يُعثر على عظم، لذا لم يُستخدم الطول.';

  @override
  String get lenNoLength => 'لم يُدخَل أي طول.';

  @override
  String get lenOnlyShaft =>
      'يبدو هذا وسط عظم (جسم العظم)، لذا لا يمكن مقارنة طوله بالعظام الكاملة.';

  @override
  String get lenOnlyEnd =>
      'يبدو هذا أحد طرفي عظم، لذا لا يمكن مقارنة طوله بالعظام الكاملة.';

  @override
  String get lenOnlyPiece =>
      'يبدو هذا قطعة مكسورة من عظم، لذا لا يمكن مقارنة طولها بالعظام الكاملة.';

  @override
  String get lenOnlyPart =>
      'يبدو هذا جزءًا من عظم فقط، لذا لا يمكن مقارنة طوله بالعظام الكاملة.';

  @override
  String lenNoReference(String things) {
    return 'ليست لدينا أطوال معتادة لـ$things، لذا لم يُستخدم الطول.';
  }

  @override
  String lenNoFit(String cm, String before, String after) {
    return '$cm سم لا يناسب $before ولا الخيار الأقرب التالي، $after، لذا أبقينا على إجابة الصورة. قد يكون من حيوان أو إنسان صغير السن، أو يستحق القياس مجددًا.';
  }

  @override
  String lenChangedTooLong(String cm, String before) {
    return '$cm سم أطول من اللازم بالنسبة إلى $before.';
  }

  @override
  String lenChangedTooShort(String cm, String before) {
    return '$cm سم أقصر من اللازم بالنسبة إلى $before.';
  }

  @override
  String lenChangedFitsBut(String cm, String before) {
    return '$cm سم يناسب $before، لكن استبعاد الخيارات الأخرى غيّر الإجابة.';
  }

  @override
  String lenChangedUnchecked(String cm, String before) {
    return 'لا يمكن مقارنة $cm سم بـ$before.';
  }

  @override
  String lenChangedNowFits(String after) {
    return 'وهو يناسب $after، لذا غيّر الطول الإجابة.';
  }

  @override
  String lenChangedNotRuledOut(String after) {
    return 'لا يمكن استبعاد $after بالطول، لذا غيّر الطول الإجابة.';
  }

  @override
  String lenNoUsual(String before) {
    return 'ليس لدينا طول معتاد لـ$before، لذا لم يستطع الطول تأكيده. لقد ساعد فقط في الموازنة بين الخيارات الأخرى.';
  }

  @override
  String lenNormal(String cm, String before) {
    return '$cm سم طول طبيعي لـ$before، وهذا يدعم الإجابة.';
  }

  @override
  String lenShort(String cm, String before) {
    return '$cm سم قصير بالنسبة إلى $before، لكن الصورة ما زالت تشير إليه. قد يكون من حيوان أو إنسان صغير السن، أو يستحق القياس مجددًا.';
  }

  @override
  String lenLong(String cm, String before) {
    return '$cm سم طويل بالنسبة إلى $before، لكن الصورة ما زالت تشير إليه. يستحق القياس مجددًا.';
  }

  @override
  String lenPhotoAlone(String headline) {
    return 'بحسب الصورة وحدها، كان $headline.';
  }

  @override
  String lenMeasuredOn(String thing, String animals) {
    return '$thing (قيس على $animals)';
  }

  @override
  String get measuredBears => 'الدب الأسود والدب البني';

  @override
  String get measuredCattle => 'الأبقار';

  @override
  String get measuredCat => 'القطط المنزلية';

  @override
  String get measuredDogsFoxes =>
      'الكلاب المنزلية (كل السلالات) والثعلب الأحمر والثعلب الرمادي';

  @override
  String get measuredPigBoar => 'الخنزير الأليف والخنزير البري';

  @override
  String get measuredCottontail => 'أرنب الذيل القطني الشرقي';

  @override
  String get measuredHorse => 'الخيول';

  @override
  String get measuredRaccoon => 'الراكون';

  @override
  String get measuredDeer => 'الأيل أبيض الذيل وأيل البغل';

  @override
  String get scanHeroTitle => 'وجدت عظمة؟\nلنتعرّف عليها.';

  @override
  String get scanHeroBody =>
      'صوّرها أو ارفع صورتها، وسنخبرك ما هي، ولمن كانت، وماذا حدث لها.';

  @override
  String get scanSnap => 'صوّر عظمة';

  @override
  String get scanUpload => 'ارفع صورة';

  @override
  String get scanTipsHeader => 'نصائح لنتيجة واضحة';

  @override
  String get tipBackgroundTitle => 'خلفية سادة';

  @override
  String get tipBackgroundBody =>
      'ملاءة أو طاولة، بلا نقوش أو ملصقات أو كتابة.';

  @override
  String get tipLightTitle => 'إضاءة ناعمة';

  @override
  String get tipLightBody =>
      'ضوء النهار هو الأفضل، فالظلال الحادة تخفي التفاصيل.';

  @override
  String get tipLengthTitle => 'تعرف الطول؟';

  @override
  String get tipLengthBody => 'أضفه قبل التحليل ليصبح التخمين أدق.';

  @override
  String get tipAnglesTitle => 'جرّب عدة زوايا';

  @override
  String get tipAnglesBody => 'صور الأمام والخلف تحل لغز العظام الصعبة.';

  @override
  String get scanRecentFinds => 'آخر الاكتشافات';

  @override
  String scanSavedCount(int count) {
    return 'المحفوظ: $count';
  }

  @override
  String get scanNoFinds => 'لا اكتشافات بعد';

  @override
  String get scanNoFindsBody => 'ستتجمع هنا العظام التي تفحصها.';

  @override
  String get linkNotReady => 'غير جاهز';

  @override
  String get linkOnPhone => 'على هذا الهاتف';

  @override
  String get linkConnecting => 'جارٍ الاتصال…';

  @override
  String get linkOnline => 'متصل';

  @override
  String linkOnlineMs(int ms) {
    return 'متصل · $ms ms';
  }

  @override
  String get linkCantConnect => 'تعذّر الاتصال';

  @override
  String get toastLostConnection => 'انقطع الاتصال';

  @override
  String get toastBackOnline => 'عاد الاتصال';

  @override
  String get guideLongBone => 'عظمة طويلة';

  @override
  String get guideSkull => 'جمجمة';

  @override
  String get guideFlat => 'عظمة مسطحة';

  @override
  String get guideSmall => 'قطعة صغيرة';

  @override
  String get guideLongBoneTip => 'ضعها مسطحة وطابقها مع طرفيّ المنتفخين.';

  @override
  String get guideSkullTip =>
      'صوّرها من الأمام مباشرة، ومحجرا العينين داخل العينين المنقطتين.';

  @override
  String get guideFlatTip => 'ضعها مسطحة، وأدخل حدودها كلها من طرف إلى طرف.';

  @override
  String get guideSmallTip => 'عظمة صغيرة؟ اقترب حتى تملأ الإطار.';

  @override
  String camHold(int cm) {
    return 'ابتعد نحو $cm سم · واملأ الإطار';
  }

  @override
  String get camTitle => 'كاميرا العظام';

  @override
  String camAngle(int number) {
    return 'الزاوية $number';
  }

  @override
  String get camClose => 'إغلاق الكاميرا';

  @override
  String get camFlash => 'الفلاش';

  @override
  String get camZoom => 'تكبير';

  @override
  String get camSwitch => 'تبديل الكاميرا';

  @override
  String get camTakePhoto => 'التقط صورة';

  @override
  String get camUploadFromLibrary => 'ارفع من المعرض';

  @override
  String get camWarmingUp => 'جارٍ تشغيل الكاميرا…';

  @override
  String get camAnotherAngleTip =>
      'العظمة نفسها من جهة أخرى. اقلبها أو صوّر أحد طرفيها.';

  @override
  String get camShotFailed => 'تعذّر التقاط الصورة. تحاول مجددًا؟';

  @override
  String get camNoAccess => 'لا إذن للكاميرا';

  @override
  String get camNoAccessBody =>
      'اسمح لـ Ossia باستخدام الكاميرا من إعدادات هاتفك، أو ارفع صورة بدلًا من ذلك.';

  @override
  String get camNapping => 'الكاميرا نائمة';

  @override
  String get camNappingBody =>
      'تعذّر تشغيل الكاميرا هنا. هل ترفع صورة بدلًا من ذلك؟';

  @override
  String get reviewDropTitle => 'هل تتخلى عن هذه الصور؟';

  @override
  String reviewDropNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم تُحلَّل $count صورة لهذه العظمة بعد.',
      many: 'لم تُحلَّل $count صورة لهذه العظمة بعد.',
      few: 'لم تُحلَّل $count صور لهذه العظمة بعد.',
      two: 'لم تُحلَّل صورتا هذه العظمة بعد.',
      one: 'لم تُحلَّل صورة هذه العظمة بعد.',
      zero: 'لم تُحلَّل صور هذه العظمة بعد.',
    );
    return '$_temp0';
  }

  @override
  String get reviewDropRevising =>
      'لن تُحلَّل الزوايا التي أضفتها أو حذفتها، وسيبقى التقرير المحفوظ كما هو.';

  @override
  String get reviewDropConfirm => 'تخلَّ عنها';

  @override
  String get reviewTypeLength => 'اكتب الطول';

  @override
  String get reviewTypeLengthCm =>
      'من طرف إلى طرف، على أطول خط مستقيم، بالسنتيمتر.';

  @override
  String get reviewTypeLengthIn =>
      'من طرف إلى طرف، على أطول خط مستقيم، بالبوصة.';

  @override
  String reviewExample(String example) {
    return 'مثلًا $example';
  }

  @override
  String get reviewSetLength => 'اعتمد الطول';

  @override
  String get reviewRetake => 'أعد التصوير';

  @override
  String get reviewTitleRevising => 'زوايا إضافية';

  @override
  String reviewTitleAngles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عظمة واحدة، $count زاوية',
      many: 'عظمة واحدة، $count زاوية',
      few: 'عظمة واحدة، $count زوايا',
      two: 'عظمة واحدة، زاويتان',
      one: 'عظمة واحدة، زاوية واحدة',
      zero: 'عظمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reviewNiceShot => 'لقطة رائعة!';

  @override
  String get reviewLookingGood => 'هل تبدو جيدة؟';

  @override
  String reviewMysteryBone(int number) {
    return 'عظمة غامضة رقم $number';
  }

  @override
  String reviewAnalyzeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حلّل $count صورة',
      many: 'حلّل $count صورة',
      few: 'حلّل $count صور',
      two: 'حلّل الصورتين',
      one: 'حلّل الصورة',
      zero: 'حلّل',
    );
    return '$_temp0';
  }

  @override
  String get reviewSkipAnalyze => 'تخطَّ وحلّل';

  @override
  String get reviewAnalyzeIt => 'حلّلها';

  @override
  String get reviewMoreAnglesQ => 'زوايا أخرى؟';

  @override
  String get reviewAngles => 'الزوايا';

  @override
  String get reviewOptional => 'اختياري';

  @override
  String reviewAnglesOf(int count, int max) {
    return '$count من $max';
  }

  @override
  String get reviewAnglesBodyOne =>
      'العظمة نفسها من جهة أخرى. قد يحل الظهر أو أحد الطرفين أو لقطة قريبة لغز عظمة صعبة، وتُقرأ كل الصور معًا.';

  @override
  String reviewAnglesBodyMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'تُقرأ الصور الـ$count معًا كعظمة واحدة. اضغط على صورة لتراها، أو على علامة × لحذفها.',
      many:
          'تُقرأ الصور الـ$count معًا كعظمة واحدة. اضغط على صورة لتراها، أو على علامة × لحذفها.',
      few:
          'تُقرأ الصور الـ$count معًا كعظمة واحدة. اضغط على صورة لتراها، أو على علامة × لحذفها.',
      two:
          'تُقرأ الصورتان معًا كعظمة واحدة. اضغط على صورة لتراها، أو على علامة × لحذفها.',
      one: 'تُقرأ الصورة كعظمة واحدة.',
      zero: 'تُقرأ الصور معًا كعظمة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get reviewSnap => 'التقط';

  @override
  String get reviewUpload => 'ارفع';

  @override
  String get reviewSnapHint => 'التقط زاوية أخرى';

  @override
  String get reviewUploadHint => 'أضف زوايا من المعرض';

  @override
  String get reviewMaxPhotos => 'هذا أقصى ما يقبله التحليل الواحد.';

  @override
  String reviewRemovePhoto(int number) {
    return 'احذف الصورة $number';
  }

  @override
  String get reviewHowLong => 'كم طولها؟';

  @override
  String get reviewLengthBody =>
      'قستها من طرف إلى طرف؟ حرّك الشريط. لا مسطرة معك؟ لا بأس، تخطَّ هذه الخطوة وسيخمّن الذكاء الاصطناعي.';

  @override
  String get reviewEndToEnd => 'من طرف إلى طرف';

  @override
  String get reviewWaitingNumber => 'بانتظار رقم…';

  @override
  String get reviewTapToType => 'اضغط على الرقم لتكتبه بدقة.';

  @override
  String get reviewFlickTape => 'حرّك الشريط لتحديد الطول.';

  @override
  String get reviewClear => 'مسح';

  @override
  String analyzingStep(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String analyzingPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صورة',
      many: '$count صورة',
      few: '$count صور',
      two: 'صورتان',
      one: 'صورة واحدة',
      zero: 'لا صور',
    );
    return '$_temp0';
  }

  @override
  String get quipFinding => 'ألعب الغميضة مع عظمتك…';

  @override
  String get quipHumanOrAnimal => 'إنسان أم لا؟ أطرح الأسئلة الكبرى.';

  @override
  String get quipWhichBone => 'أي عظمة هذه؟ أستشير هيكلي العظمي الداخلي.';

  @override
  String get quipWhichEnd => 'أفرّق بين الطرفين.';

  @override
  String get quipMissingBits => 'أتحقق إن كانت هناك أجزاء ناقصة.';

  @override
  String get quipMarks => 'أبحث عن الكسور والجروح والأجزاء المحروقة.';

  @override
  String get quipWhose => 'أضيّق الاحتمالات: لمن كانت هذه العظمة؟';

  @override
  String get quipAgeSex => 'أقدّر العمر والجنس، باحترام.';

  @override
  String get quipWriting => 'أكتب النتائج. اقتربنا!';

  @override
  String get analyzingFailedTitle => 'أوه، حدث خلل';

  @override
  String get analyzingOnPhone => 'حلّل على هذا الهاتف';

  @override
  String get reportNameTitle => 'سمِّ هذه العظمة';

  @override
  String get reportNameBody =>
      'أي اسم يساعدك على إيجادها لاحقًا، مثل المكان الذي عُثر عليها فيه.';

  @override
  String get reportNameExample => 'مثلًا TR2-114';

  @override
  String get reportRename => 'إعادة التسمية';

  @override
  String get reportAddNote => 'أضف ملاحظة';

  @override
  String get reportEditNote => 'عدّل الملاحظة';

  @override
  String get reportNoteBody =>
      'أي شيء لا تُظهره الصورة، مثل مكان العثور عليها أو ملمسها في يدك.';

  @override
  String get reportNotePlaceholder => 'استُخرجت من المربع 4، الطبقة 2…';

  @override
  String get reportCopied => 'نُسخ التقرير';

  @override
  String get reportSavedToast => 'حُفظت في مجموعتي';

  @override
  String get reportDeleteTitle => 'هل تحذف هذا التحليل؟';

  @override
  String reportDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيُحذف التقرير وصوره الـ$count من هذا الجهاز.',
      many: 'سيُحذف التقرير وصوره الـ$count من هذا الجهاز.',
      few: 'سيُحذف التقرير وصوره الـ$count من هذا الجهاز.',
      two: 'سيُحذف التقرير وصورتاه من هذا الجهاز.',
      one: 'سيُحذف التقرير وصورته من هذا الجهاز.',
      zero: 'سيُحذف التقرير من هذا الجهاز.',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'احذف';

  @override
  String get reportOptions => 'خيارات أخرى';

  @override
  String get reportSheetTitle => 'التقرير';

  @override
  String get reportAddAngle => 'أضف زاوية أخرى';

  @override
  String get reportCopy => 'انسخ التقرير';

  @override
  String get reportDelete => 'احذف التحليل';

  @override
  String get reportSave => 'احفظ في مجموعتي';

  @override
  String get reportAnalyzeAnother => 'حلّل عظمة أخرى';

  @override
  String get confStrong => 'قوية';

  @override
  String get confGood => 'جيدة';

  @override
  String get confModerate => 'متوسطة';

  @override
  String get confWeak => 'ضعيفة';

  @override
  String get confVeryWeak => 'ضعيفة جدًا';

  @override
  String get resultBoneDetected => 'عُثر على عظمة';

  @override
  String get resultNoBoneFound => 'لم يُعثر على عظمة';

  @override
  String resultAngles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count زاوية',
      many: '$count زاوية',
      few: '$count زوايا',
      two: 'زاويتان',
      one: 'زاوية واحدة',
      zero: 'لا زوايا',
    );
    return '$_temp0';
  }

  @override
  String get resultHowSure => 'ما مدى ثقتنا؟';

  @override
  String get resultShakiest =>
      'الثقة لا تتجاوز أضعف خطوة: إيجاد العظمة، والتمييز بين الإنسان والحيوان، وتسمية العظمة، ومعرفة الحيوان إن كانت لحيوان.';

  @override
  String get resultCouldAlsoBe => 'غير مؤكد. قد تكون أيضًا:';

  @override
  String get resultNoBoneTitle => 'لم نرصد أي عظمة';

  @override
  String get resultNoBoneBody =>
      'لم نجد عظمة في هذه الصورة. جرّب خلفية سادة، واقترب حتى تملأ العظمة معظم الصورة.';

  @override
  String get resultIdentification => 'التعرّف';

  @override
  String get resultHumanOrAnimal => 'إنسان أم حيوان';

  @override
  String get resultWhichBone => 'أي عظمة';

  @override
  String resultTopGuesses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أفضل $count تخمين',
      many: 'أفضل $count تخمينًا',
      few: 'أفضل $count تخمينات',
      two: 'أفضل تخمينين',
      one: 'أفضل تخمين',
      zero: 'لا تخمينات',
    );
    return '$_temp0';
  }

  @override
  String get resultOnlyGuess => 'التخمين الوحيد';

  @override
  String get resultWhichPart => 'أي جزء';

  @override
  String get resultWholeOrBroken => 'كاملة أم مكسورة';

  @override
  String get resultCondition => 'الحالة';

  @override
  String get resultNoMarks => 'لا آثار لافتة';

  @override
  String resultMarksFooter(String threshold) {
    return 'يُفحص كل نوع من الآثار على حدة، فقد تظهر على العظمة أكثر من أثر. يُنبَّه إلى كل ما يبلغ $threshold أو أكثر.';
  }

  @override
  String get resultAgeSex => 'العمر والجنس';

  @override
  String get resultAgeGroup => 'الفئة العمرية';

  @override
  String get resultSex => 'الجنس';

  @override
  String get resultAgeFooter =>
      'العمر والجنس أصعب ما يُقرأ من صورة، وقد تعلّمهما Ossia من أمثلة قليلة. اعتبرهما تلميحًا يحتاج إلى تحقق، لا جوابًا.';

  @override
  String get resultWhichAnimal => 'أي حيوان';

  @override
  String get resultClosestMatch => 'الأقرب شبهًا';

  @override
  String get resultUndetermined => 'غير محدد';

  @override
  String get resultUndeterminedBody =>
      'تبدو عظمة حيوان، لكن لم تبرز أي مجموعة حيوانية بما يكفي لتسميتها.';

  @override
  String get resultAnimalFooter =>
      'في الثدييات يسمّي Ossia الفصيلة (مثل فصيلة الأيائل أو الكلاب) حين تُظهرها العظمة، وإلا فيقول ثديي أو طائر أو زاحف. قارن مع هيكل عظمي معروف قبل الاعتماد عليه.';

  @override
  String get resultMeasurements => 'القياسات';

  @override
  String get resultLengthChanged => 'غيّر الطول الجواب';

  @override
  String get resultTypicalLength => 'الطول المعتاد';

  @override
  String get resultAiEstimate => 'تقدير الذكاء الاصطناعي';

  @override
  String resultTypicalFor(String thing) {
    return 'المرجع: $thing';
  }

  @override
  String resultLengthAbout(String value, String unit) {
    return 'نحو $value $unit';
  }

  @override
  String resultLengthRange(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get resultYourMeasurement => 'قياسك';

  @override
  String get resultInsideRange => 'ضمن النطاق المعتاد تمامًا. رائع.';

  @override
  String get resultOutsideRange => 'خارج النطاق المعتاد. تستحق نظرة ثانية.';

  @override
  String get resultInsideEstimate => 'ضمن التقدير تمامًا. رائع.';

  @override
  String get resultOutsideEstimate => 'خارج التقدير. تستحق نظرة ثانية.';

  @override
  String get resultReference => 'المرجع';

  @override
  String resultAtlasSubtitle(String region) {
    return '$region · ما تبحث عنه، وأيمن أم أيسر';
  }

  @override
  String get resultDisclaimer =>
      'يقدّم Ossia أفضل تخمين، لا جوابًا نهائيًا. لا تعتمد عليه في قرارات طبية أو قانونية أو أمنية من دون أن يفحص خبير العظمة بنفسه.';

  @override
  String get libTitle => 'مجموعتي';

  @override
  String get libEmptySubtitle => 'فارغة… حتى الآن.';

  @override
  String libBonesCollected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عظمة',
      many: '$count عظمة',
      few: '$count عظام',
      two: 'عظمتان',
      one: 'عظمة واحدة',
      zero: 'لا عظام بعد',
    );
    return '$_temp0';
  }

  @override
  String libHumanCount(int count) {
    return 'البشرية منها: $count';
  }

  @override
  String get libSearchHint => 'ابحث في عظامك';

  @override
  String get libClearSearch => 'امسح البحث';

  @override
  String get libFilterAll => 'الكل';

  @override
  String get libFilterHuman => 'بشري';

  @override
  String get libFilterAnimal => 'حيواني';

  @override
  String get libFilterFlagged => 'مُعلَّمة';

  @override
  String get libToday => 'اليوم';

  @override
  String get libThisWeek => 'هذا الأسبوع';

  @override
  String get libThisMonth => 'هذا الشهر';

  @override
  String get libEarlier => 'أقدم';

  @override
  String get libEmptyTitle => 'مجموعتك فارغة';

  @override
  String get libEmptyBody =>
      'كل عظمة تفحصها تُحفظ هنا مع صورتها وملاحظاتك. بلا عناء.';

  @override
  String get libNoMatchTitle => 'لا نتائج مطابقة';

  @override
  String get libNoMatchBody => 'جرّب تصفية أخرى أو امسح البحث.';

  @override
  String atlasSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عظمة يعرفها الذكاء الاصطناعي جيدًا',
      many: '$count عظمة يعرفها الذكاء الاصطناعي جيدًا',
      few: '$count عظام يعرفها الذكاء الاصطناعي جيدًا',
      two: 'عظمتان يعرفهما الذكاء الاصطناعي جيدًا',
      one: 'عظمة واحدة يعرفها الذكاء الاصطناعي جيدًا',
      zero: 'لا عظام بعد',
    );
    return '$_temp0';
  }

  @override
  String get atlasHowCardTitle => 'كيف يفكر الذكاء الاصطناعي';

  @override
  String get atlasHowCardBody =>
      'المراحل التسع التي تمر بها كل صورة، وأيّها يمكنك الوثوق به.';

  @override
  String get atlasLookFor => 'ما الذي تبحث عنه';

  @override
  String get atlasSidingTitle => 'يمين أم يسار، وأي جهة إلى الأعلى';

  @override
  String get howTitle => 'كيف يعمل التحليل';

  @override
  String get howHeading => 'صورة واحدة، تسعة أسئلة';

  @override
  String get howIntro =>
      'ينظر Ossia إلى صورتك مرة واحدة ويجيب عن تسعة أسئلة حولها في الوقت نفسه. وتأتي كل إجابة مع مدى ثقته بها، حتى لا تُفسد إجابة غير مؤكدة بقية الإجابات.';

  @override
  String get settingsAppLanguage => 'لغة التطبيق';

  @override
  String get settingsLanguageFooter =>
      'يمكنك أيضًا التبديل في أي وقت من زر الكرة الأرضية أعلى كل تبويب.';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsAccent => 'اللون المميز';

  @override
  String get settingsAnalysis => 'التحليل';

  @override
  String get settingsOnDeviceBody =>
      'يعمل Ossia على هاتفك مباشرة، حتى من دون إشارة، وتبقى صورك على هاتفك.';

  @override
  String get settingsOnlineBody =>
      'تُرسل الصور إلى حاسوب Ossia على العنوان أدناه، ويعود إليك التقرير.';

  @override
  String get settingsOnlineAddress => 'العنوان على الإنترنت';

  @override
  String get settingsOnlineAddressBody =>
      'اكتب العنوان الظاهر على حاسوب Ossia.';

  @override
  String get settingsStatus => 'حالة المحلّل';

  @override
  String get settingsStatusSub => 'هل هو جاهز ومتصل؟';

  @override
  String get settingsCutoff => 'حد الثقة';

  @override
  String get settingsCutoffBody => 'تظهر التخمينات الأقل من هذا الحد باهتة.';

  @override
  String get settingsHideUnlikely => 'أخفِ التخمينات المستبعدة';

  @override
  String get settingsHideUnlikelyBody =>
      'لا تعرض العظام المحتملة الأخرى إلا إذا تجاوزت الحد.';

  @override
  String get settingsCapture => 'التصوير';

  @override
  String get settingsAutoSave => 'احفظ التحليلات تلقائيًا';

  @override
  String get settingsAutoSaveBody =>
      'عند الإيقاف، لا يُحفظ التقرير إلا إذا حفظته بنفسك.';

  @override
  String get settingsUnits => 'وحدة القياس';

  @override
  String get settingsHaptics => 'الاهتزاز عند اللمس';

  @override
  String get settingsLibrary => 'المجموعة';

  @override
  String get settingsSavedCount => 'التحليلات المحفوظة';

  @override
  String get settingsCopyAll => 'انسخ كل التقارير';

  @override
  String settingsCopiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُسخ $count تقرير',
      many: 'نُسخ $count تقريرًا',
      few: 'نُسخت $count تقارير',
      two: 'نُسخ تقريران',
      one: 'نُسخ تقرير واحد',
      zero: 'لم يُنسخ أي تقرير',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleteAll => 'احذف كل التحليلات';

  @override
  String get settingsDeleteAllTitle => 'هل تحذف كل شيء؟';

  @override
  String settingsDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ستُحذف التحليلات المحفوظة الـ$count وصورها من هذا الجهاز، ولا يمكن التراجع عن ذلك.',
      many:
          'ستُحذف التحليلات المحفوظة الـ$count وصورها من هذا الجهاز، ولا يمكن التراجع عن ذلك.',
      few:
          'ستُحذف التحليلات المحفوظة الـ$count وصورها من هذا الجهاز، ولا يمكن التراجع عن ذلك.',
      two:
          'سيُحذف التحليلان المحفوظان وصورهما من هذا الجهاز، ولا يمكن التراجع عن ذلك.',
      one:
          'سيُحذف التحليل المحفوظ وصوره من هذا الجهاز، ولا يمكن التراجع عن ذلك.',
      zero:
          'ستُحذف كل التحليلات المحفوظة من هذا الجهاز، ولا يمكن التراجع عن ذلك.',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleteAllConfirm => 'احذف الكل';

  @override
  String get settingsLibraryCleared => 'أُفرغت المجموعة';

  @override
  String get settingsPrivacyFooter =>
      'تبقى تقاريرك على هذا الهاتف، ولا تُرسل الصور إلا إذا اخترت التحليل عبر الإنترنت.';

  @override
  String get settingsAbout => 'حول';

  @override
  String get settingsAboutOssia => 'حول Ossia';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsDisclaimer =>
      'يساعدك Ossia على التعرف على العظام، لكنه لا يغني عن خبير يفحص العظمة بنفسه.';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get aboutIntro =>
      'صوّر عظمة وسيخبرك Ossia بما هي: أي عظمة، وهل هي لإنسان أم لحيوان، وأي حيوان، وما عليها من آثار. وتُظهر كل إجابة مدى الثقة بها، لتحكم عليها بنفسك.';

  @override
  String get aboutKnows => 'ما يعرفه Ossia';

  @override
  String get aboutKindsOfBone => 'أنواع العظام';

  @override
  String get aboutAnimalGroups => 'مجموعات الحيوانات';

  @override
  String get aboutQuestions => 'الأسئلة لكل صورة';

  @override
  String get aboutKnowsFooter =>
      'تعلّم Ossia من آلاف الصور الموسومة، لكن بعض العظام والحيوانات لم يكن لها إلا القليل. ولهذا يخبرك دائمًا بمدى ثقته.';

  @override
  String get aboutPrivacy => 'الخصوصية';

  @override
  String get aboutPhotos => 'الصور';

  @override
  String get aboutPhotosBody =>
      'تبقى على هذا الهاتف، ولا تُرسل إلا إذا اخترت التحليل عبر الإنترنت.';

  @override
  String get aboutAnalytics => 'بيانات الاستخدام';

  @override
  String get aboutAnalyticsBody => 'لا نجمع أي بيانات.';

  @override
  String get aboutWarning =>
      'النتائج أفضل تخمين، وليست إجابة نهائية. لا تعتمد عليها في قرارات طبية أو قانونية أو شُرَطية من دون أن يفحص خبير العظام العظمة بنفسه.';

  @override
  String get statusYou => 'أنت';

  @override
  String get statusNapping => 'نائم';

  @override
  String get statusAllOnPhone => 'كل شيء على هاتفك';

  @override
  String msShort(int ms) {
    return '$ms ms';
  }

  @override
  String statusChecked(String when) {
    return 'فُحص $when';
  }

  @override
  String secondsAgo(int count) {
    return 'قبل $count ث';
  }

  @override
  String get statusConnected => 'متصل';

  @override
  String statusConnectedBody(String ms) {
    return 'يستجيب التحليل عبر الإنترنت خلال $ms ملّي ثانية. ستُحلَّل صورك هناك.';
  }

  @override
  String statusOfflineBody(String reason) {
    return '$reason. تحقّق من العنوان ومن أن حاسوب Ossia يعمل.';
  }

  @override
  String get statusNoAnswer => 'لا ردّ';

  @override
  String get statusFailedTitle => 'تعذّر تجهيزه';

  @override
  String get statusFailedBody =>
      'منع شيءٌ Ossia من البدء على هذا الهاتف. حاول مجددًا أو أعد تشغيل التطبيق.';

  @override
  String get statusOnPhoneTitle => 'التحليل على هذا الهاتف';

  @override
  String get statusOnPhoneBody =>
      'يعمل في أي مكان، حتى من دون إشارة، ولا تغادر صورك هاتفك أبدًا.';

  @override
  String get statusConnectingBody =>
      'نتحقّق من أن التحليل عبر الإنترنت مستيقظ.';

  @override
  String get statusChecking => 'جارٍ الفحص…';

  @override
  String get statusCheckNow => 'افحص الاتصال';

  @override
  String get statusChangeAddress => 'غيّر العنوان';

  @override
  String get statusRunningFor => 'يعمل منذ';

  @override
  String get statusHistory => 'سجل الاتصال';

  @override
  String get statusAutoPaused => 'الفحص التلقائي متوقف';

  @override
  String statusNextIn(int seconds) {
    return 'التالي بعد $seconds ث';
  }

  @override
  String get statusNoChecks => 'لا فحوصات بعد';

  @override
  String statusHistoryFooter(int seconds) {
    return 'يُفحص الاتصال كل $seconds ثانية ما دام التطبيق مفتوحًا. الأعمدة الأقصر تعني اتصالًا أسرع.';
  }

  @override
  String get statusRow => 'الحالة';

  @override
  String get statusWakesUp => 'يستيقظ عند أول فحص';

  @override
  String get statusSleeping => 'نائم';

  @override
  String get statusGettingReady => 'يستعد…';

  @override
  String get statusCouldntStart => 'تعذّر البدء';

  @override
  String get statusInternetNeeded => 'يحتاج إلى إنترنت';

  @override
  String get statusNo => 'لا';

  @override
  String get statusPhotosSent => 'إرسال الصور إلى أي مكان';

  @override
  String get statusNever => 'أبدًا';

  @override
  String get statusGetReady => 'جهّزه الآن';
}
