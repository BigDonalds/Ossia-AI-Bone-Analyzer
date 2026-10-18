// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Ossia';

  @override
  String get tabScan => 'Scannen';

  @override
  String get tabStash => 'Sammlung';

  @override
  String get tabAtlas => 'Atlas';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get back => 'Zurück';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get dismiss => 'Schließen';

  @override
  String get nah => 'Lieber nicht';

  @override
  String get save => 'Speichern';

  @override
  String get done => 'Fertig';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get tryAgain => 'Nochmal versuchen';

  @override
  String get engineOnDevice => 'Dieses Handy';

  @override
  String get engineServer => 'Online';

  @override
  String get engineAnalyzeOn => 'Analysieren auf';

  @override
  String get engineWorksOffline => 'Geht ohne Internet';

  @override
  String get engineUsesInternet => 'Braucht Internet';

  @override
  String dateAtTime(String date, String time) {
    return '$date um $time';
  }

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String hoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String get yesterday => 'Gestern';

  @override
  String daysAgo(int count) {
    return 'vor $count Tagen';
  }

  @override
  String get accentSunny => 'Sonnengelb';

  @override
  String get accentLime => 'Limette';

  @override
  String get accentBubblegum => 'Kaugummi';

  @override
  String get accentTangerine => 'Mandarine';

  @override
  String get accentGrape => 'Traube';

  @override
  String get accentSky => 'Himmelblau';

  @override
  String get welcomeTitle => 'Welche Sprache soll Ossia sprechen?';

  @override
  String get welcomeSubtitle =>
      'Wir haben die Sprache deines Handys gewählt. Ändere sie hier oder jederzeit über den Globus oben.';

  @override
  String get welcomeSubtitleNoMatch =>
      'Wähle hier eine aus. Du kannst sie jederzeit über den Globus oben ändern.';

  @override
  String get welcomeContinue => 'Los geht\'s';

  @override
  String get languageCardLine => 'Knochen, auf Deutsch erklärt';

  @override
  String get languageFromPhone => 'Von deinem Handy';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get globeTooltip => 'Sprache ändern';

  @override
  String get languageSheetTitle => 'Sprache wählen';

  @override
  String get languageSheetMessage =>
      'Alles wechselt sofort, auch gespeicherte Funde.';

  @override
  String get languageMatchPhone => 'Wie mein Handy';

  @override
  String languageMatchPhoneHint(String language) {
    return 'Gerade ist das $language';
  }

  @override
  String languageFollowingPhone(String language) {
    return 'Handy ($language)';
  }

  @override
  String get languageNameEnglish => 'Englisch';

  @override
  String get languageNameGerman => 'Deutsch';

  @override
  String get languageNameArabic => 'Arabisch';

  @override
  String get languageNowSpeaking => 'Ossia spricht jetzt Deutsch';

  @override
  String get boneSkull => 'Schädel';

  @override
  String get boneSkullMeaning => 'der ganze Kopf';

  @override
  String get boneCranium => 'Cranium';

  @override
  String get boneCraniumMeaning => 'der Schädel ohne Unterkiefer';

  @override
  String get boneMandible => 'Mandibula';

  @override
  String get boneMandibleMeaning => 'der Unterkiefer';

  @override
  String get boneFemur => 'Femur';

  @override
  String get boneFemurMeaning => 'der Oberschenkelknochen';

  @override
  String get boneTibia => 'Tibia';

  @override
  String get boneTibiaMeaning => 'das Schienbein';

  @override
  String get boneHumerus => 'Humerus';

  @override
  String get boneHumerusMeaning =>
      'der Oberarmknochen oder der obere Knochen des Vorderbeins';

  @override
  String get boneRadius => 'Radius';

  @override
  String get boneRadiusMeaning =>
      'ein Unterarmknochen oder unterer Knochen des Vorderbeins';

  @override
  String get boneUlna => 'Ulna';

  @override
  String get boneUlnaMeaning =>
      'ein Unterarmknochen oder unterer Knochen des Vorderbeins, mit der Ellenbogenspitze';

  @override
  String get boneScapula => 'Scapula';

  @override
  String get boneScapulaMeaning => 'das Schulterblatt';

  @override
  String get boneOsCoxa => 'Os coxae';

  @override
  String get boneOsCoxaMeaning => 'das Hüftbein';

  @override
  String get boneRib12 => 'Rippen 1–2';

  @override
  String get boneRib12Meaning => 'eine der beiden obersten Rippen';

  @override
  String get boneTypicalRib => 'Typische Rippe';

  @override
  String get boneTypicalRibMeaning => 'eine Rippe aus der Mitte des Brustkorbs';

  @override
  String get boneRib1112 => 'Rippen 11–12';

  @override
  String get boneRib1112Meaning => 'eine der beiden untersten Rippen';

  @override
  String get boneCervical => 'Halswirbel';

  @override
  String get boneCervicalMeaning => 'ein Wirbel aus dem Hals';

  @override
  String get boneThoracic => 'Brustwirbel';

  @override
  String get boneThoracicMeaning => 'ein Wirbel aus dem oberen Rücken';

  @override
  String get boneLumbar => 'Lendenwirbel';

  @override
  String get boneLumbarMeaning => 'ein Wirbel aus dem unteren Rücken';

  @override
  String get boneUnidentified => 'Nicht erkannt';

  @override
  String get noBoneDetected => 'Kein Knochen erkannt';

  @override
  String get animalHuman => 'Mensch';

  @override
  String get animalHumanMeaning => 'eine Person';

  @override
  String get animalCanid => 'Hundeartige';

  @override
  String get animalCanidMeaning =>
      'die Familie der Hunde (Hunde, Wölfe, Kojoten und Füchse)';

  @override
  String get animalCervid => 'Hirsche';

  @override
  String get animalCervidMeaning =>
      'die Familie der Hirsche (Rehe, Rothirsche, Elche und Rentiere)';

  @override
  String get animalBovid => 'Hornträger';

  @override
  String get animalBovidMeaning =>
      'die Familie der Rinder (Kühe, Bisons, Schafe, Ziegen und Antilopen)';

  @override
  String get animalSuid => 'Schweine';

  @override
  String get animalSuidMeaning =>
      'die Familie der Schweine (Hausschweine, Wildschweine und Warzenschweine)';

  @override
  String get animalFelid => 'Katzen';

  @override
  String get animalFelidMeaning =>
      'die Familie der Katzen (Hauskatzen, Luchse, Pumas und Löwen)';

  @override
  String get animalUrsid => 'Bären';

  @override
  String get animalUrsidMeaning => 'Bären aller Art';

  @override
  String get animalLeporid => 'Hasen';

  @override
  String get animalLeporidMeaning => 'Kaninchen und Feldhasen';

  @override
  String get animalProcyonid => 'Kleinbären';

  @override
  String get animalProcyonidMeaning =>
      'die Familie der Waschbären (Waschbären, Nasenbären und Katzenfrette)';

  @override
  String get animalEquid => 'Pferde';

  @override
  String get animalEquidMeaning =>
      'die Familie der Pferde (Pferde, Esel und Zebras)';

  @override
  String get animalRodent => 'Nagetier';

  @override
  String get animalRodentMeaning =>
      'Ratten, Mäuse, Eichhörnchen, Biber und ihre Verwandten';

  @override
  String get animalMammal => 'Säugetier';

  @override
  String get animalOtherMammalMeaning =>
      'ein Tier mit Fell, das seine Jungen mit Milch säugt, aus einer Familie, die Ossia nicht benennt, etwa ein Stinktier oder Opossum';

  @override
  String get animalMammalMeaning =>
      'ein Tier mit Fell, das seine Jungen mit Milch säugt. Dieser Knochen zeigt nicht, aus welcher Familie';

  @override
  String get animalBird => 'Vogel';

  @override
  String get animalBirdMeaning => 'jeder Vogel, vom Spatz bis zum Strauß';

  @override
  String get animalReptile => 'Reptil';

  @override
  String get animalReptileMeaning =>
      'Schildkröten, Schlangen, Echsen und Krokodile';

  @override
  String get animalUnnamed => 'Tier';

  @override
  String get animalUnnamedMeaning =>
      'ein Tierknochen, bei dem keine Tiergruppe herausstach';

  @override
  String get partComplete => 'Ganzer Knochen';

  @override
  String get partShaft => 'Mitte (Schaft)';

  @override
  String get partProximal => 'Nahes Ende';

  @override
  String get partDistal => 'Fernes Ende';

  @override
  String get partFragment => 'Bruchstück';

  @override
  String get statusComplete => 'Vollständig';

  @override
  String get statusFragment => 'Zerbrochen';

  @override
  String get conditionWholeButBroken => 'Ganzer Knochen, aber gebrochen';

  @override
  String conditionPartBroken(String part) {
    return '$part, abgebrochen';
  }

  @override
  String get damageFracture => 'Bruch';

  @override
  String get damageCutMarks => 'Schnittspuren';

  @override
  String get damageBurnSigns => 'Brandspuren';

  @override
  String get ageAdult => 'Erwachsen';

  @override
  String get ageJuvenile => 'Jugendlich';

  @override
  String get sexMale => 'Männlich';

  @override
  String get sexFemale => 'Weiblich';

  @override
  String get unknownValue => 'Unbekannt';

  @override
  String get sourceOnDevice => 'Auf diesem Handy';

  @override
  String get sourceServer => 'Dein Server';

  @override
  String get regionCranial => 'Kopf';

  @override
  String get regionAxial => 'Wirbelsäule';

  @override
  String get regionThoracic => 'Brustkorb';

  @override
  String get regionUpperLimb => 'Obere Gliedmaße';

  @override
  String get regionLowerLimb => 'Untere Gliedmaße';

  @override
  String get regionGirdle => 'Schulter- und Beckengürtel';

  @override
  String get phaseFinding => 'Knochen finden';

  @override
  String get phaseHumanOrAnimal => 'Mensch oder Tier?';

  @override
  String get phaseWhichBone => 'Welcher Knochen?';

  @override
  String get phaseWhichPart => 'Welcher Teil?';

  @override
  String get phaseWholeOrBroken => 'Ganz oder zerbrochen?';

  @override
  String get phaseMarks => 'Spuren suchen';

  @override
  String get phaseWhichAnimal => 'Welches Tier?';

  @override
  String get phaseAgeSex => 'Alter und Geschlecht';

  @override
  String get phaseWriting => 'Bericht schreiben';

  @override
  String get unitCentimetres => 'Zentimeter';

  @override
  String get unitInches => 'Zoll';

  @override
  String get unitCm => 'cm';

  @override
  String get unitIn => 'in';

  @override
  String get atlasSkullBlurb => 'Cranium und Unterkiefer zusammen';

  @override
  String get atlasSkullSummary =>
      'Der vollständige knöcherne Kopf: das Cranium zusammen mit dem Unterkiefer. Insgesamt zweiundzwanzig Knochen, verbunden durch ineinandergreifende Nähte; nur der Unterkiefer ist frei beweglich.';

  @override
  String get atlasSkullLm1 => 'Kranz-, Pfeil- und Lambdanaht';

  @override
  String get atlasSkullLm2 =>
      'Augenhöhlen und die birnenförmige Nasenöffnung (Apertura piriformis)';

  @override
  String get atlasSkullLm3 => 'Foramen magnum an der Schädelbasis';

  @override
  String get atlasSkullLm4 => 'Warzenfortsätze hinter den Gehörgängen';

  @override
  String get atlasSkullSiding =>
      'Symmetrisch. Die Ausrichtung ergibt sich aus dem Stirnbein (vorn) und der Hinterhauptsschuppe (hinten).';

  @override
  String get atlasCraniumBlurb => 'Der Schädel ohne Unterkiefer';

  @override
  String get atlasCraniumSummary =>
      'Der Schädel ohne Unterkiefer. Umschließt und schützt das Gehirn; das Schädeldach besteht aus Stirn-, Scheitel-, Schläfen- und Hinterhauptsbein.';

  @override
  String get atlasCraniumLm1 =>
      'Überaugenwülste – bei männlichen Schädeln kräftiger';

  @override
  String get atlasCraniumLm2 => 'Nackenlinien am Hinterhauptsbein';

  @override
  String get atlasCraniumLm3 =>
      'Schläfenlinien, die über die Scheitelbeine ziehen';

  @override
  String get atlasCraniumLm4 => 'Äußerer Gehörgang';

  @override
  String get atlasCraniumSiding =>
      'Vollständig symmetrisch. Einzelne Schädeldachfragmente werden über den Verlauf der Nähte und das Muster der Hirnhautgefäßfurchen zugeordnet.';

  @override
  String get atlasCraniumAka => 'Calvaria (nur Schädeldach)';

  @override
  String get atlasMandibleBlurb => 'Unterkiefer; dicht und widerstandsfähig';

  @override
  String get atlasMandibleSummary =>
      'Der Unterkiefer – der einzige frei bewegliche Knochen des Schädels. Dicht und kompakt, daher übersteht er Bestattung und Brand besser als die meisten Knochen.';

  @override
  String get atlasMandibleLm1 => 'Protuberantia mentalis (das Kinn)';

  @override
  String get atlasMandibleLm2 =>
      'Kieferwinkel, wo Ast und Körper aufeinandertreffen';

  @override
  String get atlasMandibleLm3 =>
      'Gelenkfortsatz (Condylus) und Muskelfortsatz (Processus coronoideus)';

  @override
  String get atlasMandibleLm4 =>
      'Foramen mentale unterhalb der vorderen Backenzähne';

  @override
  String get atlasMandibleSiding =>
      'Vollständig symmetrisch. Eine Unterkieferhälfte wird daran zugeordnet, in welche Richtung der Ast aufsteigt und wohin sich die Zahnreihe krümmt.';

  @override
  String get atlasFemurBlurb =>
      'Oberschenkelknochen; bester Hinweis auf die Körpergröße';

  @override
  String get atlasFemurSummary =>
      'Der Oberschenkelknochen – der längste und stärkste Knochen des Körpers. Seine größte Länge hängt am engsten mit der Körpergröße zu Lebzeiten zusammen.';

  @override
  String get atlasFemurLm1 => 'Kugelförmiger Kopf mit der Fovea capitis';

  @override
  String get atlasFemurLm2 =>
      'Großer und kleiner Rollhügel (Trochanter major und minor)';

  @override
  String get atlasFemurLm3 => 'Linea aspera als Leiste an der Schaftrückseite';

  @override
  String get atlasFemurLm4 => 'Innerer und äußerer Gelenkknorren am Knie';

  @override
  String get atlasFemurSiding =>
      'Halte den Knochen aufrecht: Der Kopf zeigt nach innen, die Linea aspera nach hinten. Die Seite, zu der der Kopf zeigt, ist die Körperseite.';

  @override
  String get atlasTibiaBlurb => 'Schienbein; dreieckiger Schaft';

  @override
  String get atlasTibiaSummary =>
      'Das Schienbein, der innere und tragende Knochen des Unterschenkels. Sein dreieckiger Schaft ist selbst in Bruchstücken unverkennbar.';

  @override
  String get atlasTibiaLm1 =>
      'Schienbeinhöcker (Tuberositas tibiae) vorn am oberen Schaft';

  @override
  String get atlasTibiaLm2 => 'Scharfe Vorderkante';

  @override
  String get atlasTibiaLm3 => 'Innenknöchel am Sprunggelenk';

  @override
  String get atlasTibiaLm4 => 'Flache innere und äußere Gelenkknorren';

  @override
  String get atlasTibiaSiding =>
      'Der Innenknöchel ragt auf derselben Seite hervor wie die Körperseite, von der der Knochen stammt; der Schienbeinhöcker markiert die Vorderseite.';

  @override
  String get atlasHumerusBlurb =>
      'Oberarm, von der Schulter bis zum Ellenbogen';

  @override
  String get atlasHumerusSummary =>
      'Der Oberarmknochen, vom Schultergelenk bis zum Ellenbogen. In der Länge nur vom Oberschenkelknochen übertroffen.';

  @override
  String get atlasHumerusLm1 => 'Runder Kopf mit großem und kleinem Höcker';

  @override
  String get atlasHumerusLm2 => 'Tuberositas deltoidea in Schaftmitte';

  @override
  String get atlasHumerusLm3 => 'Fossa olecrani hinten am unteren Ende';

  @override
  String get atlasHumerusLm4 =>
      'Trochlea und Capitulum bilden das Ellenbogengelenk';

  @override
  String get atlasHumerusSiding =>
      'Stell ihn aufrecht, den Kopf zu dir gerichtet: Die Fossa olecrani liegt hinten, und der Kopf dreht sich nach innen zur Körpermitte.';

  @override
  String get atlasRadiusBlurb => 'Äußerer Unterarmknochen, auf der Daumenseite';

  @override
  String get atlasRadiusSummary =>
      'Der äußere Unterarmknochen auf der Daumenseite. Er dreht sich um die Elle und wendet so die Handfläche.';

  @override
  String get atlasRadiusLm1 => 'Scheibenförmiger Kopf am oberen Ende';

  @override
  String get atlasRadiusLm2 => 'Tuberositas radii direkt unter dem Hals';

  @override
  String get atlasRadiusLm3 => 'Breites, ausladendes unteres Ende';

  @override
  String get atlasRadiusLm4 => 'Griffelfortsatz am Handgelenk';

  @override
  String get atlasRadiusSiding =>
      'Der kleine Kopf liegt oben, das breite Ende unten; der Griffelfortsatz zeigt nach außen, weg von der Körpermitte.';

  @override
  String get atlasUlnaBlurb => 'Innerer Unterarmknochen; die Ellenbogenspitze';

  @override
  String get atlasUlnaSummary =>
      'Der innere Unterarmknochen auf der Kleinfingerseite. Bildet das Scharnier des Ellenbogens und ist der feste Partner, um den sich die Speiche dreht.';

  @override
  String get atlasUlnaLm1 => 'Olecranon – die Ellenbogenspitze';

  @override
  String get atlasUlnaLm2 =>
      'Incisura trochlearis, die den Oberarmknochen umgreift';

  @override
  String get atlasUlnaLm3 => 'Processus coronoideus unterhalb der Incisura';

  @override
  String get atlasUlnaLm4 =>
      'Schmaler Kopf am unteren Ende mit Griffelfortsatz';

  @override
  String get atlasUlnaSiding =>
      'Die Incisura trochlearis öffnet sich nach vorn; mit dem Olecranon oben und der Incisura zu dir gerichtet krümmt sich der Schaft zur Körperseite hin.';

  @override
  String get atlasScapulaBlurb => 'Schulterblatt; dünne dreieckige Platte';

  @override
  String get atlasScapulaSummary =>
      'Das Schulterblatt – eine dünne dreieckige Platte, die hinten auf dem Brustkorb aufliegt. So dünn, dass die Platte oft nur in Bruchstücken erhalten bleibt.';

  @override
  String get atlasScapulaLm1 => 'Schulterblattgräte quer über die Rückseite';

  @override
  String get atlasScapulaLm2 => 'Schulterhöhe (Acromion) an der Schulterspitze';

  @override
  String get atlasScapulaLm3 => 'Hakenförmiger Rabenschnabelfortsatz vorn';

  @override
  String get atlasScapulaLm4 => 'Gelenkpfanne, die den Oberarmkopf aufnimmt';

  @override
  String get atlasScapulaSiding =>
      'Die Gelenkpfanne zeigt nach außen, die Gräte liegt auf der Rückseite; die Seite, zu der die Pfanne zeigt, ist die Körperseite.';

  @override
  String get atlasOsCoxaBlurb => 'Hüftbein; bester Hinweis auf das Geschlecht';

  @override
  String get atlasOsCoxaSummary =>
      'Das Hüftbein: Darm-, Sitz- und Schambein, an der Hüftpfanne verwachsen. Der zuverlässigste einzelne Knochen, um Geschlecht und Alter Erwachsener zu schätzen.';

  @override
  String get atlasOsCoxaLm1 =>
      'Incisura ischiadica major – bei Frauen breit, bei Männern schmal';

  @override
  String get atlasOsCoxaLm2 => 'Schambogenwinkel und der ventrale Bogen';

  @override
  String get atlasOsCoxaLm3 =>
      'Facies auricularis, für das Sterbealter genutzt';

  @override
  String get atlasOsCoxaLm4 => 'Hüftpfanne, die den Oberschenkelkopf aufnimmt';

  @override
  String get atlasOsCoxaSiding =>
      'Richte die Darmbeinschaufel nach oben und die Hüftpfanne nach außen: Das Schambein liegt vorn, die Incisura ischiadica öffnet sich nach hinten.';

  @override
  String get atlasOsCoxaAka => 'Os innominatum, Hüftbein';

  @override
  String get atlasRib12Blurb => 'Atypische Rippen; flach und stark gekrümmt';

  @override
  String get atlasRib12Summary =>
      'Die ersten beiden Rippen sind atypisch. Rippe 1 ist die kürzeste, breiteste und am stärksten gekrümmte; Rippe 2 ist länger, aber ebenso abgeflacht.';

  @override
  String get atlasRib12Lm1 => 'Rippe 1 liegt flach, mit Ober- und Unterseite';

  @override
  String get atlasRib12Lm2 =>
      'Tuberculum musculi scaleni mit Furchen für die Schlüsselbeingefäße';

  @override
  String get atlasRib12Lm3 =>
      'Rippe 2 trägt eine Rauigkeit für den vorderen Sägemuskel';

  @override
  String get atlasRib12Lm4 => 'Eine einzelne Gelenkfläche am Kopf von Rippe 1';

  @override
  String get atlasRib12Siding =>
      'Leg die Rippe flach, den Kopf nach hinten: Die konkave Innenseite zeigt zur Körpermitte und verrät so die Seite.';

  @override
  String get atlasTypicalRibBlurb => 'Rippen 3–9; Kopf, Höcker, Rippenfurche';

  @override
  String get atlasTypicalRibSummary =>
      'Die Rippen 3 bis 9 folgen einem Bauplan: Kopf, Hals, Höcker und ein langer gebogener Körper, der sich am Rippenwinkel verdreht.';

  @override
  String get atlasTypicalRibLm1 => 'Zwei halbe Gelenkflächen am Kopf';

  @override
  String get atlasTypicalRibLm2 =>
      'Höcker, der mit einem Querfortsatz ein Gelenk bildet';

  @override
  String get atlasTypicalRibLm3 =>
      'Rippenwinkel, an dem der Schaft die Richtung ändert';

  @override
  String get atlasTypicalRibLm4 => 'Rippenfurche am inneren unteren Rand';

  @override
  String get atlasTypicalRibSiding =>
      'Die Rippenfurche verläuft am inneren unteren Rand; liegt die Furche unten und innen, zeigt der Kopf nach hinten und verrät die Seite.';

  @override
  String get atlasRib1112Blurb => 'Freie Rippen; kurz und vorn nicht befestigt';

  @override
  String get atlasRib1112Summary =>
      'Die freien Rippen. Kurz, spitz zulaufend und vorn nicht befestigt – deshalb fehlen ihnen die meisten Merkmale einer typischen Rippe.';

  @override
  String get atlasRib1112Lm1 => 'Eine einzelne Gelenkfläche am Kopf';

  @override
  String get atlasRib1112Lm2 => 'Kein Hals und kein Höcker';

  @override
  String get atlasRib1112Lm3 => 'Kaum oder keine Rippenfurche';

  @override
  String get atlasRib1112Lm4 => 'Spitzes vorderes Ende mit Knorpelkappe';

  @override
  String get atlasRib1112Siding =>
      'Die Krümmung allein verrät die Seite: Die konkave Fläche zeigt zur Körpermitte.';

  @override
  String get atlasCervicalBlurb =>
      'C1–C7; die einzigen mit Querfortsatzlöchern';

  @override
  String get atlasCervicalSummary =>
      'Die sieben Halswirbel, C1–C7. Die kleinsten Wirbelkörper der Wirbelsäule und die einzigen Wirbel mit Löchern in den Querfortsätzen.';

  @override
  String get atlasCervicalLm1 =>
      'Querfortsatzlöcher – kennzeichnend für diesen Abschnitt';

  @override
  String get atlasCervicalLm2 =>
      'C1 (Atlas) hat keinen Körper; C2 (Axis) trägt den Dens';

  @override
  String get atlasCervicalLm3 => 'Gespaltene Dornfortsätze an C2–C6';

  @override
  String get atlasCervicalLm4 => 'Großes dreieckiges Wirbelloch';

  @override
  String get atlasCervicalSiding =>
      'Symmetrisch. Die Position in der Reihe ergibt sich aus Dornfortsatz und Körpergröße; C7 hat den langen, ungespaltenen Dorn der „Vertebra prominens“.';

  @override
  String get atlasThoracicBlurb => 'T1–T12; tragen die Rippengelenkflächen';

  @override
  String get atlasThoracicSummary =>
      'Die zwölf Wirbel des oberen Rückens, T1–T12. Jeder bildet mit einem Rippenpaar ein Gelenk, und die Gelenkflächen dafür kennzeichnen diesen Abschnitt.';

  @override
  String get atlasThoracicLm1 =>
      'Rippengelenkflächen an Körper und Querfortsätzen';

  @override
  String get atlasThoracicLm2 => 'Herzförmige Wirbelkörper';

  @override
  String get atlasThoracicLm3 =>
      'Lange, steil nach unten geneigte Dornfortsätze';

  @override
  String get atlasThoracicLm4 => 'Rundes Wirbelloch';

  @override
  String get atlasThoracicSiding =>
      'Symmetrisch. Die Reihenfolge erkennt man an der Körpergröße und daran, wie weit der Dornfortsatz den Wirbel darunter überlappt.';

  @override
  String get atlasLumbarBlurb => 'L1–L5; die schwersten der Wirbelsäule';

  @override
  String get atlasLumbarSummary =>
      'Die fünf Wirbel des unteren Rückens, L1–L5. Die größten und kräftigsten der Wirbelsäule, gebaut für Last statt Beweglichkeit.';

  @override
  String get atlasLumbarLm1 => 'Massive nierenförmige Körper';

  @override
  String get atlasLumbarLm2 =>
      'Keine Querfortsatzlöcher und keine Rippengelenkflächen';

  @override
  String get atlasLumbarLm3 => 'Kurze, stumpfe, beilförmige Dornfortsätze';

  @override
  String get atlasLumbarLm4 =>
      'Processus mamillares an den oberen Gelenkfortsätzen';

  @override
  String get atlasLumbarSiding =>
      'Symmetrisch. L5 erkennt man an der Keilform – vorn höher als hinten –, wo er auf das Kreuzbein trifft.';

  @override
  String get phaseDoc1Title => 'Ist da ein Knochen?';

  @override
  String get phaseDoc1Detail =>
      'Zuerst prüft Ossia, ob überhaupt ein Knochen auf dem Foto ist, damit ein Stock oder ein Stein keine erfundene Antwort bekommt.';

  @override
  String get phaseDoc2Title => 'Mensch oder Tier?';

  @override
  String get phaseDoc2Detail =>
      'Dann entscheidet es, ob der Knochen von einem Menschen oder einem Tier stammt. Alles Weitere hängt von diesem Schritt ab.';

  @override
  String get phaseDoc3Title => 'Welcher Knochen?';

  @override
  String get phaseDoc3Detail =>
      'Sechzehn Knochenarten, vom Schädel und Kiefer bis zu Rippen, Wirbelsäule, Hüfte und Gliedmaßen. Du siehst die drei besten Vermutungen, nicht nur den Sieger.';

  @override
  String get phaseDoc4Title => 'Welcher Teil?';

  @override
  String get phaseDoc4Detail =>
      'Ob das Foto den ganzen Knochen zeigt, seine Mitte (den Schaft), ein Ende oder ein Bruchstück.';

  @override
  String get phaseDoc5Title => 'Ganz oder zerbrochen?';

  @override
  String get phaseDoc5Detail =>
      'Ein schnelles Ja oder Nein: Ist der Knochen vollständig oder nur ein Bruchstück?';

  @override
  String get phaseDoc6Title => 'Spuren und Schäden';

  @override
  String get phaseDoc6Detail =>
      'Brüche, Schnittspuren und Brandspuren werden jeweils einzeln geprüft, ein Knochen kann also alle drei zeigen.';

  @override
  String get phaseDoc7Title => 'Welches Tier?';

  @override
  String get phaseDoc7Detail =>
      'Bei Tierknochen: Säugetier, Vogel oder Reptil. Bei Säugetieren auch die Familie, etwa Hunde, Hirsche, Rinder, Schweine, Katzen, Bären, Hasen, Waschbären oder Pferde, oder ein Nagetier. Die Familie wird nur genannt, wenn der Knochen sie zeigen kann, etwa ein Schädel, ein Kiefer oder ein ganzer Beinknochen.';

  @override
  String get phaseDoc8Title => 'Alter und Geschlecht';

  @override
  String get phaseDoc8Detail =>
      'Nur bei menschlichen Knochen. Sieh das als Hinweis zum Überprüfen, nie als Antwort für sich allein.';

  @override
  String get phaseDoc9Title => 'Alles zusammen';

  @override
  String get phaseDoc9Detail =>
      'Fotos desselben Knochens von verschiedenen Seiten werden gemeinsam ausgewertet, und die gemessene Länge wird mit der üblichen Größe des Knochens verglichen. Beides hilft, wenn ein Foto allein unklar ist.';

  @override
  String get errNotReadyOnPhone =>
      'Ossia konnte auf diesem Handy nicht starten. Versuch es nochmal oder starte die App neu.';

  @override
  String get errPhotoUnreadable =>
      'Das Foto konnte nicht gelesen werden. Versuch es mit einem JPEG oder PNG.';

  @override
  String errPhotoNUnreadable(int number) {
    return 'Foto $number konnte nicht gelesen werden. Entferne es und versuch es nochmal.';
  }

  @override
  String get errReadingPhoto =>
      'Beim Lesen des Fotos ist etwas schiefgelaufen. Bitte versuch es nochmal.';

  @override
  String get errPhotoTryAnother =>
      'Das Foto konnte nicht gelesen werden. Versuch es mit einem anderen.';

  @override
  String get errBadOnlineAddress =>
      'Die Online-Adresse sieht nicht richtig aus. Prüf sie in den Einstellungen.';

  @override
  String get errThisDevice =>
      'Diese Adresse zeigt auf dieses Handy selbst. Gib stattdessen die Adresse ein, die auf dem Ossia-Computer angezeigt wird.';

  @override
  String errServerStatus(int code) {
    return 'Die Online-Analyse funktioniert gerade nicht (Fehler $code).';
  }

  @override
  String get errServerTooBig =>
      'Die Fotos sind zu groß zum Senden. Versuch es mit weniger Fotos.';

  @override
  String get errServerRejected =>
      'Die Online-Analyse hat diese Fotos nicht angenommen. Versuch es mit anderen Fotos.';

  @override
  String get errServerCouldntAnalyze =>
      'Die Online-Analyse konnte diese Fotos nicht auswerten. Versuch es mit anderen Fotos.';

  @override
  String get errTimeout =>
      'Die Online-Analyse hat zu lange gebraucht. Prüf deine Verbindung oder analysiere auf diesem Handy.';

  @override
  String get errUnreachable =>
      'Keine Verbindung zur Online-Analyse. Prüf dein Internet und die Online-Adresse in den Einstellungen.';

  @override
  String get errNotAReport =>
      'Etwas hat geantwortet, aber nicht mit einem Bericht. Prüf die Online-Adresse in den Einstellungen.';

  @override
  String get errGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuch es nochmal.';

  @override
  String get checkAddress => 'Adresse';

  @override
  String get checkReach => 'Erreichbar';

  @override
  String get checkServer => 'Ossia antwortet';

  @override
  String get checkModel => 'Bereit zum Analysieren';

  @override
  String get checkSpeed => 'Tempo';

  @override
  String get checkBadAddress => 'Das ist keine gültige Adresse';

  @override
  String checkAnsweredIn(int ms) {
    return 'Antwort in $ms ms';
  }

  @override
  String checkRunningFor(String time) {
    return 'Läuft seit $time';
  }

  @override
  String get checkNotReady =>
      'Läuft, ist aber noch nicht bereit zum Analysieren';

  @override
  String get checkReady => 'Bereit';

  @override
  String get checkLost => 'Verbindung verloren';

  @override
  String checkPing(int ms, String word) {
    return '$ms ms · $word';
  }

  @override
  String get pingSnappy => 'flott';

  @override
  String get pingGood => 'gut';

  @override
  String get pingSluggish => 'träge';

  @override
  String get pingSlow => 'langsam';

  @override
  String uptimeSeconds(int s) {
    return '$s s';
  }

  @override
  String uptimeMinutes(int m) {
    return '$m min';
  }

  @override
  String uptimeHours(int h, int m) {
    return '$h h $m min';
  }

  @override
  String uptimeDays(int d, int h) {
    return '$d T. $h h';
  }

  @override
  String get netBadAnswer => 'Ungültige Antwort';

  @override
  String netNoAnswer(int seconds) {
    return 'Keine Antwort innerhalb von $seconds Sekunden';
  }

  @override
  String get netNotFound =>
      'Diese Adresse wurde nicht gefunden. Prüf, ob sie richtig geschrieben und noch aktuell ist';

  @override
  String get netRefused => 'Unter dieser Adresse hat niemand geantwortet';

  @override
  String get netNoInternet => 'Keine Internetverbindung';

  @override
  String get netNotSecure => 'Keine sichere Verbindung möglich';

  @override
  String get netNotRunning =>
      'Die Adresse funktioniert, aber Ossia läuft dort nicht';

  @override
  String get netExpired => 'Diese Adresse ist abgelaufen';

  @override
  String netHttpError(int code) {
    return 'Die Antwort war ein Fehler ($code)';
  }

  @override
  String get netNotOssia => 'Etwas hat geantwortet, aber es ist nicht Ossia';

  @override
  String lenThing(String animal, String bone) {
    return '„$animal · $bone“';
  }

  @override
  String lenUsually(String thing, String min, String max) {
    return '$thing (meist $min–$max cm)';
  }

  @override
  String lenNeverOver(String thing, String max) {
    return '$thing (nie über $max cm)';
  }

  @override
  String lenOrThing(String first, String second) {
    return '$first oder $second';
  }

  @override
  String get lenNoBone =>
      'Es wurde kein Knochen gefunden, daher wurde die Länge nicht verwendet.';

  @override
  String get lenNoLength => 'Es wurde keine Länge eingegeben.';

  @override
  String get lenOnlyShaft =>
      'Das sieht nach der Mitte (dem Schaft) eines Knochens aus, daher lässt sich seine Länge nicht mit ganzen Knochen vergleichen.';

  @override
  String get lenOnlyEnd =>
      'Das sieht nach einem Ende eines Knochens aus, daher lässt sich seine Länge nicht mit ganzen Knochen vergleichen.';

  @override
  String get lenOnlyPiece =>
      'Das sieht nach einem Knochenbruchstück aus, daher lässt sich seine Länge nicht mit ganzen Knochen vergleichen.';

  @override
  String get lenOnlyPart =>
      'Das sieht nur nach einem Teil eines Knochens aus, daher lässt sich seine Länge nicht mit ganzen Knochen vergleichen.';

  @override
  String lenNoReference(String things) {
    return 'Für $things haben wir keine üblichen Längen, daher wurde die Länge nicht verwendet.';
  }

  @override
  String lenNoFit(String cm, String before, String after) {
    return '$cm cm passt weder zu $before noch zur nächstbesten Möglichkeit, $after, daher haben wir die Antwort des Fotos behalten. Der Knochen könnte von einem jungen Tier oder Menschen stammen, oder es lohnt sich, nochmal zu messen.';
  }

  @override
  String lenChangedTooLong(String cm, String before) {
    return '$cm cm ist zu lang für $before.';
  }

  @override
  String lenChangedTooShort(String cm, String before) {
    return '$cm cm ist zu kurz für $before.';
  }

  @override
  String lenChangedFitsBut(String cm, String before) {
    return '$cm cm passt zu $before, aber das Ausschließen anderer Möglichkeiten hat die Antwort verschoben.';
  }

  @override
  String lenChangedUnchecked(String cm, String before) {
    return '$cm cm lässt sich nicht mit $before abgleichen.';
  }

  @override
  String lenChangedNowFits(String after) {
    return 'Die Länge passt zu $after, daher hat sie die Antwort geändert.';
  }

  @override
  String lenChangedNotRuledOut(String after) {
    return '$after lässt sich über die Länge nicht ausschließen, daher hat die Länge die Antwort geändert.';
  }

  @override
  String lenNoUsual(String before) {
    return 'Für $before haben wir keine übliche Länge, daher konnte die Länge es nicht bestätigen. Sie half nur, die anderen Möglichkeiten abzuwägen.';
  }

  @override
  String lenNormal(String cm, String before) {
    return '$cm cm ist eine normale Länge für $before. Das stützt die Antwort.';
  }

  @override
  String lenShort(String cm, String before) {
    return '$cm cm ist kurz für $before, aber das Foto spricht trotzdem dafür. Der Knochen könnte von einem jungen Tier oder Menschen stammen, oder es lohnt sich, nochmal zu messen.';
  }

  @override
  String lenLong(String cm, String before) {
    return '$cm cm ist lang für $before, aber das Foto spricht trotzdem dafür. Es lohnt sich, nochmal zu messen.';
  }

  @override
  String lenPhotoAlone(String headline) {
    return 'Nur nach dem Foto war es $headline.';
  }

  @override
  String lenMeasuredOn(String thing, String animals) {
    return '$thing (gemessen an $animals)';
  }

  @override
  String get measuredBears => 'Schwarz- und Braunbären';

  @override
  String get measuredCattle => 'Rindern';

  @override
  String get measuredCat => 'Hauskatzen';

  @override
  String get measuredDogsFoxes =>
      'Haushunden (alle Rassen) sowie Rot- und Graufüchsen';

  @override
  String get measuredPigBoar => 'Hausschweinen und Wildschweinen';

  @override
  String get measuredCottontail => 'Florida-Waldkaninchen';

  @override
  String get measuredHorse => 'Pferden';

  @override
  String get measuredRaccoon => 'Waschbären';

  @override
  String get measuredDeer => 'Weißwedel- und Maultierhirschen';

  @override
  String get scanHeroTitle => 'Knochen gefunden?\nWir bestimmen ihn.';

  @override
  String get scanHeroBody =>
      'Fotografiere ihn oder lade ein Bild hoch. Wir sagen dir, welcher Knochen es ist, von wem er stammt und was ihm passiert ist.';

  @override
  String get scanSnap => 'Knochen fotografieren';

  @override
  String get scanUpload => 'Bild hochladen';

  @override
  String get scanTipsHeader => 'Profi-Tipps für ein klares Ergebnis';

  @override
  String get tipBackgroundTitle => 'Ohne Muster';

  @override
  String get tipBackgroundBody =>
      'Ein Laken oder ein Tisch, ohne Etiketten oder Schrift.';

  @override
  String get tipLightTitle => 'Weiches Licht';

  @override
  String get tipLightBody =>
      'Tageslicht ist am besten. Harte Schatten verstecken Details.';

  @override
  String get tipLengthTitle => 'Länge bekannt?';

  @override
  String get tipLengthBody =>
      'Trag sie vor der Analyse ein. Das macht die Schätzung genauer.';

  @override
  String get tipAnglesTitle => 'Mehrere Winkel';

  @override
  String get tipAnglesBody =>
      'Vorder- und Rückansicht knacken knifflige Knochen.';

  @override
  String get scanRecentFinds => 'Letzte Funde';

  @override
  String scanSavedCount(int count) {
    return '$count gespeichert';
  }

  @override
  String get scanNoFinds => 'Noch keine Funde';

  @override
  String get scanNoFindsBody =>
      'Deine gescannten Knochen sammeln sich genau hier.';

  @override
  String get linkNotReady => 'Nicht bereit';

  @override
  String get linkOnPhone => 'Auf dem Handy';

  @override
  String get linkConnecting => 'Verbinde…';

  @override
  String get linkOnline => 'Online';

  @override
  String linkOnlineMs(int ms) {
    return 'Online · $ms ms';
  }

  @override
  String get linkCantConnect => 'Keine Verbindung';

  @override
  String get toastLostConnection => 'Verbindung verloren';

  @override
  String get toastBackOnline => 'Wieder online';

  @override
  String get guideLongBone => 'Langer Knochen';

  @override
  String get guideSkull => 'Schädel';

  @override
  String get guideFlat => 'Flacher Knochen';

  @override
  String get guideSmall => 'Kleines Stück';

  @override
  String get guideLongBoneTip =>
      'Leg ihn flach hin und richte ihn an meinen knubbeligen Enden aus.';

  @override
  String get guideSkullTip =>
      'Von vorn fotografieren. Augenhöhlen in die gepunkteten Augen.';

  @override
  String get guideFlatTip =>
      'Leg ihn flach hin. Der ganze Umriss muss drauf, von Rand zu Rand.';

  @override
  String get guideSmallTip =>
      'Winziger Knochen? Geh nah ran, bis er den Umriss füllt.';

  @override
  String camHold(int cm) {
    return 'Ca. $cm cm Abstand · Umriss ausfüllen';
  }

  @override
  String get camTitle => 'KNOCHEN-CAM';

  @override
  String camAngle(int number) {
    return 'WINKEL #$number';
  }

  @override
  String get camClose => 'Kamera schließen';

  @override
  String get camFlash => 'Blitz';

  @override
  String get camZoom => 'Zoom';

  @override
  String get camSwitch => 'Kamera wechseln';

  @override
  String get camTakePhoto => 'Foto aufnehmen';

  @override
  String get camUploadFromLibrary => 'Aus der Galerie hochladen';

  @override
  String get camWarmingUp => 'Die Kamera wärmt sich auf…';

  @override
  String get camAnotherAngleTip =>
      'Gleicher Knochen, neue Seite. Dreh ihn um oder nimm ein Ende auf.';

  @override
  String get camShotFailed => 'Das Foto hat nicht geklappt. Nochmal?';

  @override
  String get camNoAccess => 'Kein Kamerazugriff';

  @override
  String get camNoAccessBody =>
      'Erlaube Ossia den Kamerazugriff in den Einstellungen deines Handys oder lade stattdessen ein Foto hoch.';

  @override
  String get camNapping => 'Die Kamera schläft';

  @override
  String get camNappingBody =>
      'Die Kamera ließ sich hier nicht starten. Stattdessen ein Foto hochladen?';

  @override
  String get reviewDropTitle => 'Diese Fotos verwerfen?';

  @override
  String reviewDropNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die $count Fotos dieses Knochens wurden noch nicht analysiert.',
      one: 'Das Foto dieses Knochens wurde noch nicht analysiert.',
    );
    return '$_temp0';
  }

  @override
  String get reviewDropRevising =>
      'Die hinzugefügten oder entfernten Winkel werden nicht analysiert. Der gespeicherte Bericht bleibt, wie er war.';

  @override
  String get reviewDropConfirm => 'Verwerfen';

  @override
  String get reviewTypeLength => 'Länge eintippen';

  @override
  String get reviewTypeLengthCm =>
      'Von Ende zu Ende, die längste gerade Linie, in Zentimetern.';

  @override
  String get reviewTypeLengthIn =>
      'Von Ende zu Ende, die längste gerade Linie, in Zoll.';

  @override
  String reviewExample(String example) {
    return 'z. B. $example';
  }

  @override
  String get reviewSetLength => 'Übernehmen';

  @override
  String get reviewRetake => 'Neu aufnehmen';

  @override
  String get reviewTitleRevising => 'Weitere Winkel';

  @override
  String reviewTitleAngles(int count) {
    return 'Ein Knochen, $count Winkel';
  }

  @override
  String get reviewNiceShot => 'Schönes Foto!';

  @override
  String get reviewLookingGood => 'Sieht gut aus?';

  @override
  String reviewMysteryBone(int number) {
    return 'Rätselknochen #$number';
  }

  @override
  String reviewAnalyzeCount(int count) {
    return '$count Fotos analysieren';
  }

  @override
  String get reviewSkipAnalyze => 'Ohne Länge los';

  @override
  String get reviewAnalyzeIt => 'Analysieren';

  @override
  String get reviewMoreAnglesQ => 'Weitere Winkel?';

  @override
  String get reviewAngles => 'Winkel';

  @override
  String get reviewOptional => 'OPTIONAL';

  @override
  String reviewAnglesOf(int count, int max) {
    return '$count VON $max';
  }

  @override
  String get reviewAnglesBodyOne =>
      'Gleicher Knochen, andere Seite. Die Rückseite, ein Ende oder eine Nahaufnahme knackt knifflige Fälle. Alle Fotos werden zusammen ausgewertet.';

  @override
  String reviewAnglesBodyMany(int count) {
    return 'Alle $count Fotos werden zusammen als ein Knochen ausgewertet. Tippe eins an, um es anzusehen, oder das Kreuz, um es zu entfernen.';
  }

  @override
  String get reviewSnap => 'Foto';

  @override
  String get reviewUpload => 'Galerie';

  @override
  String get reviewSnapHint => 'Weiteren Winkel aufnehmen';

  @override
  String get reviewUploadHint => 'Winkel aus der Galerie hinzufügen';

  @override
  String get reviewMaxPhotos => 'Mehr passen nicht in eine Analyse.';

  @override
  String reviewRemovePhoto(int number) {
    return 'Foto $number entfernen';
  }

  @override
  String get reviewHowLong => 'Wie lang ist er?';

  @override
  String get reviewLengthBody =>
      'Von Ende zu Ende gemessen? Schieb das Maßband. Kein Lineal zur Hand? Kein Problem, lass es weg. Die KI schätzt dann.';

  @override
  String get reviewEndToEnd => 'von Ende zu Ende';

  @override
  String get reviewWaitingNumber => 'wartet auf eine Zahl…';

  @override
  String get reviewTapToType => 'Tippe auf die Zahl, um sie genau einzugeben.';

  @override
  String get reviewFlickTape =>
      'Schieb das Maßband, um eine Länge einzustellen.';

  @override
  String get reviewClear => 'Löschen';

  @override
  String analyzingStep(int step, int total) {
    return 'Schritt $step/$total';
  }

  @override
  String analyzingPhotos(int count) {
    return '$count Fotos';
  }

  @override
  String get quipFinding => 'Ich spiele Verstecken mit deinem Knochen…';

  @override
  String get quipHumanOrAnimal => 'Mensch oder nicht? Die ganz großen Fragen.';

  @override
  String get quipWhichBone =>
      'Welcher Knochen ist das? Ich frage mein inneres Skelett.';

  @override
  String get quipWhichEnd => 'Ich finde heraus, welches Ende welches ist.';

  @override
  String get quipMissingBits => 'Ich prüfe, ob Stücke fehlen.';

  @override
  String get quipMarks =>
      'Ich suche nach Rissen, Schnitten und angekokelten Stellen.';

  @override
  String get quipWhose => 'Ich grenze ein, wem dieser Knochen gehörte.';

  @override
  String get quipAgeSex => 'Ich schätze Alter und Geschlecht, mit Respekt.';

  @override
  String get quipWriting => 'Ich schreibe alles zusammen. Fast geschafft!';

  @override
  String get analyzingFailedTitle => 'Tja, das ging schief';

  @override
  String get analyzingOnPhone => 'Auf diesem Handy analysieren';

  @override
  String get reportNameTitle => 'Fund benennen';

  @override
  String get reportNameBody =>
      'Irgendein Name, der dir hilft, ihn später wiederzufinden, etwa der Fundort.';

  @override
  String get reportNameExample => 'z. B. TR2-114';

  @override
  String get reportRename => 'Umbenennen';

  @override
  String get reportAddNote => 'Notiz hinzufügen';

  @override
  String get reportEditNote => 'Notiz bearbeiten';

  @override
  String get reportNoteBody =>
      'Alles, was das Foto nicht zeigen kann, etwa wo du ihn gefunden hast oder wie er sich in der Hand angefühlt hat.';

  @override
  String get reportNotePlaceholder => 'Geborgen aus Fläche 4, Abtrag 2…';

  @override
  String get reportCopied => 'Bericht kopiert';

  @override
  String get reportSavedToast => 'In der Sammlung gespeichert';

  @override
  String get reportDeleteTitle => 'Diese Analyse löschen?';

  @override
  String reportDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Der Bericht und seine $count Fotos werden von diesem Gerät entfernt.',
      one: 'Der Bericht und sein Foto werden von diesem Gerät entfernt.',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get reportOptions => 'Weitere Optionen';

  @override
  String get reportSheetTitle => 'Bericht';

  @override
  String get reportAddAngle => 'Weiteren Winkel hinzufügen';

  @override
  String get reportCopy => 'Bericht kopieren';

  @override
  String get reportDelete => 'Analyse löschen';

  @override
  String get reportSave => 'In der Sammlung speichern';

  @override
  String get reportAnalyzeAnother => 'Noch einen analysieren';

  @override
  String get confStrong => 'Stark';

  @override
  String get confGood => 'Gut';

  @override
  String get confModerate => 'Mittel';

  @override
  String get confWeak => 'Schwach';

  @override
  String get confVeryWeak => 'Sehr schwach';

  @override
  String get resultBoneDetected => 'Knochen erkannt';

  @override
  String get resultNoBoneFound => 'Kein Knochen gefunden';

  @override
  String resultAngles(int count) {
    return '$count Winkel';
  }

  @override
  String get resultHowSure => 'Wie sicher sind wir?';

  @override
  String get resultShakiest =>
      'Nur so sicher wie der wackeligste Schritt: den Knochen finden, Mensch und Tier unterscheiden, den Knochen benennen und bei Tieren das Tier.';

  @override
  String get resultCouldAlsoBe => 'Nicht sicher. Es könnte auch sein:';

  @override
  String get resultNoBoneTitle => 'Kein Knochen entdeckt';

  @override
  String get resultNoBoneBody =>
      'Wir konnten auf diesem Foto keinen Knochen finden. Versuch es mit einem schlichten Hintergrund und geh so nah ran, dass der Knochen fast das ganze Bild füllt.';

  @override
  String get resultIdentification => 'Bestimmung';

  @override
  String get resultHumanOrAnimal => 'Mensch oder Tier';

  @override
  String get resultWhichBone => 'Welcher Knochen';

  @override
  String resultTopGuesses(int count) {
    return 'Top $count Vermutungen';
  }

  @override
  String get resultOnlyGuess => 'Einzige Vermutung';

  @override
  String get resultWhichPart => 'Welcher Teil';

  @override
  String get resultWholeOrBroken => 'Ganz oder zerbrochen';

  @override
  String get resultCondition => 'Zustand';

  @override
  String get resultNoMarks => 'Keine Spuren gemeldet';

  @override
  String resultMarksFooter(String threshold) {
    return 'Jede Art von Spur wird einzeln geprüft, ein Knochen kann also mehrere zeigen. Alles ab $threshold wird gemeldet.';
  }

  @override
  String get resultAgeSex => 'Alter und Geschlecht';

  @override
  String get resultAgeGroup => 'Altersgruppe';

  @override
  String get resultSex => 'Geschlecht';

  @override
  String get resultAgeFooter =>
      'Alter und Geschlecht sind auf einem Foto am schwersten zu erkennen, und Ossia hat sie an wenigen Beispielen gelernt. Sieh sie als Hinweis zum Prüfen, nicht als Antwort.';

  @override
  String get resultWhichAnimal => 'Welches Tier';

  @override
  String get resultClosestMatch => 'Größte Ähnlichkeit';

  @override
  String get resultUndetermined => 'Unbestimmt';

  @override
  String get resultUndeterminedBody =>
      'Es sieht nach einem Tierknochen aus, aber keine Tiergruppe stach genug heraus, um sie zu nennen.';

  @override
  String get resultAnimalFooter =>
      'Bei Säugetieren nennt Ossia die Familie (etwa Hirsche oder Hunde), wenn der Knochen sie zeigt; sonst sagt es Säugetier, Vogel oder Reptil. Vergleiche mit einem bekannten Skelett, bevor du dich darauf verlässt.';

  @override
  String get resultMeasurements => 'Maße';

  @override
  String get resultLengthChanged => 'Länge hat die Antwort geändert';

  @override
  String get resultTypicalLength => 'Typische Länge';

  @override
  String get resultAiEstimate => 'KI-Schätzung';

  @override
  String resultTypicalFor(String thing) {
    return 'Bezug: $thing';
  }

  @override
  String resultLengthAbout(String value, String unit) {
    return 'ca. $value $unit';
  }

  @override
  String resultLengthRange(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get resultYourMeasurement => 'Deine Messung';

  @override
  String get resultInsideRange => 'Genau im typischen Bereich. Gut.';

  @override
  String get resultOutsideRange =>
      'Außerhalb des typischen Bereichs. Lohnt einen zweiten Blick.';

  @override
  String get resultInsideEstimate => 'Passt genau zur Schätzung. Gut.';

  @override
  String get resultOutsideEstimate =>
      'Weicht von der Schätzung ab. Lohnt einen zweiten Blick.';

  @override
  String get resultReference => 'Nachschlagen';

  @override
  String resultAtlasSubtitle(String region) {
    return '$region · worauf achten, und links oder rechts';
  }

  @override
  String get resultDisclaimer =>
      'Ossia liefert eine beste Schätzung, keine endgültige Antwort. Verlass dich bei medizinischen, rechtlichen oder polizeilichen Entscheidungen nicht darauf, ohne dass eine Fachperson den Knochen selbst prüft.';

  @override
  String get libTitle => 'Deine Sammlung';

  @override
  String get libEmptySubtitle => 'Leer. Noch.';

  @override
  String libBonesCollected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Knochen gesammelt',
      one: '1 Knochen gesammelt',
    );
    return '$_temp0';
  }

  @override
  String libHumanCount(int count) {
    return 'davon $count vom Menschen';
  }

  @override
  String get libSearchHint => 'Knochen durchsuchen';

  @override
  String get libClearSearch => 'Suche leeren';

  @override
  String get libFilterAll => 'Alle';

  @override
  String get libFilterHuman => 'Mensch';

  @override
  String get libFilterAnimal => 'Tier';

  @override
  String get libFilterFlagged => 'Markiert';

  @override
  String get libToday => 'Heute';

  @override
  String get libThisWeek => 'Diese Woche';

  @override
  String get libThisMonth => 'Diesen Monat';

  @override
  String get libEarlier => 'Früher';

  @override
  String get libEmptyTitle => 'Deine Sammlung ist leer';

  @override
  String get libEmptyBody =>
      'Jeder Knochen, den du scannst, landet hier mit Foto und Notizen. Ganz ohne Knochenarbeit.';

  @override
  String get libNoMatchTitle => 'Keine Treffer';

  @override
  String get libNoMatchBody =>
      'Versuch einen anderen Filter oder leere die Suche.';

  @override
  String atlasSubtitle(int count) {
    return '$count Knochen, die die KI auswendig kennt';
  }

  @override
  String get atlasHowCardTitle => 'So denkt die KI';

  @override
  String get atlasHowCardBody =>
      'Die neun Schritte, die jedes Foto durchläuft, und welchen du trauen kannst.';

  @override
  String get atlasLookFor => 'Worauf du achten kannst';

  @override
  String get atlasSidingTitle => 'Links oder rechts, und wo oben ist';

  @override
  String get howTitle => 'So funktioniert die Analyse';

  @override
  String get howHeading => 'Ein Foto, neun Fragen';

  @override
  String get howIntro =>
      'Ossia schaut sich dein Foto einmal an und beantwortet dabei neun Fragen gleichzeitig. Jede Antwort sagt, wie sicher sie ist, damit eine unsichere Antwort nicht den Rest verdirbt.';

  @override
  String get settingsAppLanguage => 'App-Sprache';

  @override
  String get settingsLanguageFooter =>
      'Du kannst auch jederzeit über den Globus oben auf jedem Tab wechseln.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingsAccent => 'Akzentfarbe';

  @override
  String get settingsAnalysis => 'Analyse';

  @override
  String get settingsOnDeviceBody =>
      'Ossia arbeitet direkt auf deinem Handy, auch ohne Empfang, und deine Fotos bleiben auf dem Handy.';

  @override
  String get settingsOnlineBody =>
      'Fotos werden an den Ossia-Computer unter der Adresse unten geschickt, und der Bericht kommt zu dir zurück.';

  @override
  String get settingsOnlineAddress => 'Online-Adresse';

  @override
  String get settingsOnlineAddressBody =>
      'Gib die Adresse ein, die auf dem Ossia-Computer angezeigt wird.';

  @override
  String get settingsStatus => 'Analyse-Status';

  @override
  String get settingsStatusSub => 'Ist sie bereit und verbunden?';

  @override
  String get settingsCutoff => 'Sicherheitsschwelle';

  @override
  String get settingsCutoffBody =>
      'Vermutungen darunter werden blass angezeigt.';

  @override
  String get settingsHideUnlikely => 'Unwahrscheinliches ausblenden';

  @override
  String get settingsHideUnlikelyBody =>
      'Andere mögliche Knochen nur zeigen, wenn sie über der Schwelle liegen.';

  @override
  String get settingsCapture => 'Aufnahme';

  @override
  String get settingsAutoSave => 'Analysen automatisch speichern';

  @override
  String get settingsAutoSaveBody =>
      'Wenn aus, bleibt ein Bericht nur, wenn du ihn speicherst.';

  @override
  String get settingsUnits => 'Maßeinheit';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsLibrary => 'Sammlung';

  @override
  String get settingsSavedCount => 'Gespeicherte Analysen';

  @override
  String get settingsCopyAll => 'Alle Berichte kopieren';

  @override
  String settingsCopiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Berichte kopiert',
      one: '1 Bericht kopiert',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleteAll => 'Alle Analysen löschen';

  @override
  String get settingsDeleteAllTitle => 'Alles löschen?';

  @override
  String settingsDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle $count gespeicherten Analysen und ihre Fotos werden von diesem Gerät entfernt. Das lässt sich nicht rückgängig machen.',
      one:
          'Die gespeicherte Analyse und ihre Fotos werden von diesem Gerät entfernt. Das lässt sich nicht rückgängig machen.',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleteAllConfirm => 'Alles löschen';

  @override
  String get settingsLibraryCleared => 'Sammlung geleert';

  @override
  String get settingsPrivacyFooter =>
      'Deine Berichte bleiben auf diesem Handy. Fotos werden nur verschickt, wenn du die Online-Analyse wählst.';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsAboutOssia => 'Über Ossia';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDisclaimer =>
      'Ossia hilft dir, Knochen zu bestimmen. Es ersetzt keine Fachperson, die sich den Knochen selbst ansieht.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutIntro =>
      'Fotografiere einen Knochen, und Ossia sagt dir, was es ist: welcher Knochen, Mensch oder Tier, welches Tier und welche Spuren er trägt. Jede Antwort zeigt, wie sicher sie ist, damit du selbst urteilen kannst.';

  @override
  String get aboutKnows => 'Was Ossia kennt';

  @override
  String get aboutKindsOfBone => 'Knochenarten';

  @override
  String get aboutAnimalGroups => 'Tiergruppen';

  @override
  String get aboutQuestions => 'Fragen pro Foto';

  @override
  String get aboutKnowsFooter =>
      'Ossia hat aus Tausenden beschrifteter Fotos gelernt, aber für manche Knochen und Tiere gab es nur wenige. Deshalb sagt es immer, wie sicher es ist.';

  @override
  String get aboutPrivacy => 'Datenschutz';

  @override
  String get aboutPhotos => 'Fotos';

  @override
  String get aboutPhotosBody =>
      'Bleiben auf diesem Handy. Werden nur verschickt, wenn du die Online-Analyse wählst.';

  @override
  String get aboutAnalytics => 'Nutzungsdaten';

  @override
  String get aboutAnalyticsBody => 'Keine erfasst.';

  @override
  String get aboutWarning =>
      'Die Ergebnisse sind eine beste Schätzung, keine endgültige Antwort. Nutze sie nicht für medizinische, rechtliche oder polizeiliche Entscheidungen, ohne dass eine Fachperson den Knochen selbst prüft.';

  @override
  String get statusYou => 'DU';

  @override
  String get statusNapping => 'SCHLÄFT';

  @override
  String get statusAllOnPhone => 'ALLES AUF DEINEM HANDY';

  @override
  String msShort(int ms) {
    return '$ms ms';
  }

  @override
  String statusChecked(String when) {
    return 'geprüft $when';
  }

  @override
  String secondsAgo(int count) {
    return 'vor $count s';
  }

  @override
  String get statusConnected => 'Verbunden';

  @override
  String statusConnectedBody(String ms) {
    return 'Die Online-Analyse antwortet in $ms ms. Deine Scans werden dort analysiert.';
  }

  @override
  String statusOfflineBody(String reason) {
    return '$reason. Prüf die Adresse und ob der Ossia-Computer eingeschaltet ist.';
  }

  @override
  String get statusNoAnswer => 'Keine Antwort';

  @override
  String get statusFailedTitle => 'Nicht startklar';

  @override
  String get statusFailedBody =>
      'Etwas hat Ossia daran gehindert, auf diesem Handy zu starten. Versuch es nochmal oder starte die App neu.';

  @override
  String get statusOnPhoneTitle => 'Analyse auf diesem Handy';

  @override
  String get statusOnPhoneBody =>
      'Funktioniert überall, auch ohne Empfang, und deine Fotos verlassen nie dein Handy.';

  @override
  String get statusConnectingBody => 'Prüfe, ob die Online-Analyse wach ist.';

  @override
  String get statusChecking => 'Wird geprüft…';

  @override
  String get statusCheckNow => 'Verbindung prüfen';

  @override
  String get statusChangeAddress => 'Adresse ändern';

  @override
  String get statusRunningFor => 'Läuft seit';

  @override
  String get statusHistory => 'Verbindungsverlauf';

  @override
  String get statusAutoPaused => 'Auto-Prüfung pausiert';

  @override
  String statusNextIn(int seconds) {
    return 'nächste in $seconds s';
  }

  @override
  String get statusNoChecks => 'Noch keine Prüfungen';

  @override
  String statusHistoryFooter(int seconds) {
    return 'Wird alle $seconds s geprüft, solange die App offen ist. Kürzere Balken bedeuten eine schnellere Verbindung.';
  }

  @override
  String get statusRow => 'Status';

  @override
  String get statusWakesUp => 'Wacht bei deinem ersten Scan auf';

  @override
  String get statusSleeping => 'Schläft';

  @override
  String get statusGettingReady => 'Wird vorbereitet…';

  @override
  String get statusCouldntStart => 'Start fehlgeschlagen';

  @override
  String get statusInternetNeeded => 'Internet nötig';

  @override
  String get statusNo => 'Nein';

  @override
  String get statusPhotosSent => 'Fotos verschickt';

  @override
  String get statusNever => 'Nie';

  @override
  String get statusGetReady => 'Jetzt vorbereiten';
}
