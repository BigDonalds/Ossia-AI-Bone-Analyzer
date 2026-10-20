import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
  ];

  /// The app name. Keep it as it is
  ///
  /// In en, this message translates to:
  /// **'Ossia'**
  String get appName;

  /// Tab: take or pick photos of a bone
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get tabScan;

  /// Tab: every bone you have saved
  ///
  /// In en, this message translates to:
  /// **'Stash'**
  String get tabStash;

  /// Tab: a guide to each bone the app knows
  ///
  /// In en, this message translates to:
  /// **'Atlas'**
  String get tabAtlas;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Read out by screen readers for the dimmed area behind a pop-up
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Playful "cancel" on yes/no pop-ups
  ///
  /// In en, this message translates to:
  /// **'Nah'**
  String get nah;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Analyze photos on the phone itself, no internet needed
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get engineOnDevice;

  /// Analyze photos on a computer over the internet
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get engineServer;

  /// Read out by screen readers before the chosen engine
  ///
  /// In en, this message translates to:
  /// **'Analyze on'**
  String get engineAnalyzeOn;

  /// No description provided for @engineWorksOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get engineWorksOffline;

  /// No description provided for @engineUsesInternet.
  ///
  /// In en, this message translates to:
  /// **'Uses internet'**
  String get engineUsesInternet;

  /// A date and a time together, e.g. "Oct 16, 2026 at 3:05 PM"
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String dateAtTime(String date, String time);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String hoursAgo(int count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Accent colour name: bright yellow
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get accentSunny;

  /// Accent colour name: yellow-green
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get accentLime;

  /// Accent colour name: bright pink
  ///
  /// In en, this message translates to:
  /// **'Bubblegum'**
  String get accentBubblegum;

  /// Accent colour name: orange
  ///
  /// In en, this message translates to:
  /// **'Tangerine'**
  String get accentTangerine;

  /// Accent colour name: light purple
  ///
  /// In en, this message translates to:
  /// **'Grape'**
  String get accentGrape;

  /// Accent colour name: light blue
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get accentSky;

  /// Big title on the very first screen
  ///
  /// In en, this message translates to:
  /// **'Which language should Ossia speak?'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We picked your phone\'s language. Change it here, or any time with the globe at the top.'**
  String get welcomeSubtitle;

  /// Shown instead when the phone uses a language Ossia does not speak
  ///
  /// In en, this message translates to:
  /// **'Pick one here. You can change it any time with the globe at the top.'**
  String get welcomeSubtitleNoMatch;

  /// Button that saves the language and opens the app
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get welcomeContinue;

  /// One line on each language card, always written in that card's own language
  ///
  /// In en, this message translates to:
  /// **'Bones, explained in English'**
  String get languageCardLine;

  /// Small tag on the language your phone uses
  ///
  /// In en, this message translates to:
  /// **'From your phone'**
  String get languageFromPhone;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Read out by screen readers for the globe button
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get globeTooltip;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a language'**
  String get languageSheetTitle;

  /// No description provided for @languageSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything switches straight away, saved finds too.'**
  String get languageSheetMessage;

  /// Option: always use the phone's own language
  ///
  /// In en, this message translates to:
  /// **'Match my phone'**
  String get languageMatchPhone;

  /// Under "Match my phone". {language} is one of the three names below
  ///
  /// In en, this message translates to:
  /// **'Right now that\'s {language}'**
  String languageMatchPhoneHint(String language);

  /// Settings value when the app follows the phone's language. {language} is one of the three names below
  ///
  /// In en, this message translates to:
  /// **'Phone ({language})'**
  String languageFollowingPhone(String language);

  /// The language's name inside a sentence, e.g. "Right now that's English"
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// The language's name inside a sentence, e.g. "Right now that's German"
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageNameGerman;

  /// The language's name inside a sentence, e.g. "Right now that's Arabic"
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageNameArabic;

  /// Little pop-up after switching, always in the new language
  ///
  /// In en, this message translates to:
  /// **'Ossia speaks English now'**
  String get languageNowSpeaking;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Skull'**
  String get boneSkull;

  /// What the bone is, in everyday words; shown after the name
  ///
  /// In en, this message translates to:
  /// **'the whole head'**
  String get boneSkullMeaning;

  /// Bone type name: the skull without the lower jaw
  ///
  /// In en, this message translates to:
  /// **'Cranium'**
  String get boneCranium;

  /// No description provided for @boneCraniumMeaning.
  ///
  /// In en, this message translates to:
  /// **'the skull without the lower jaw'**
  String get boneCraniumMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Mandible'**
  String get boneMandible;

  /// No description provided for @boneMandibleMeaning.
  ///
  /// In en, this message translates to:
  /// **'the lower jaw'**
  String get boneMandibleMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Femur'**
  String get boneFemur;

  /// No description provided for @boneFemurMeaning.
  ///
  /// In en, this message translates to:
  /// **'the thigh bone'**
  String get boneFemurMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Tibia'**
  String get boneTibia;

  /// No description provided for @boneTibiaMeaning.
  ///
  /// In en, this message translates to:
  /// **'the shin bone'**
  String get boneTibiaMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Humerus'**
  String get boneHumerus;

  /// No description provided for @boneHumerusMeaning.
  ///
  /// In en, this message translates to:
  /// **'the upper arm or upper front-leg bone'**
  String get boneHumerusMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get boneRadius;

  /// No description provided for @boneRadiusMeaning.
  ///
  /// In en, this message translates to:
  /// **'a forearm or lower front-leg bone'**
  String get boneRadiusMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Ulna'**
  String get boneUlna;

  /// No description provided for @boneUlnaMeaning.
  ///
  /// In en, this message translates to:
  /// **'a forearm or lower front-leg bone, with the elbow point'**
  String get boneUlnaMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Scapula'**
  String get boneScapula;

  /// No description provided for @boneScapulaMeaning.
  ///
  /// In en, this message translates to:
  /// **'the shoulder blade'**
  String get boneScapulaMeaning;

  /// Bone type name: the hip bone
  ///
  /// In en, this message translates to:
  /// **'Os Coxa'**
  String get boneOsCoxa;

  /// No description provided for @boneOsCoxaMeaning.
  ///
  /// In en, this message translates to:
  /// **'the hip bone'**
  String get boneOsCoxaMeaning;

  /// Bone type name: the first two ribs
  ///
  /// In en, this message translates to:
  /// **'Ribs 1–2'**
  String get boneRib12;

  /// No description provided for @boneRib12Meaning.
  ///
  /// In en, this message translates to:
  /// **'one of the top two ribs'**
  String get boneRib12Meaning;

  /// Bone type name: ribs 3 to 9
  ///
  /// In en, this message translates to:
  /// **'Typical Rib'**
  String get boneTypicalRib;

  /// No description provided for @boneTypicalRibMeaning.
  ///
  /// In en, this message translates to:
  /// **'a rib from the middle of the chest'**
  String get boneTypicalRibMeaning;

  /// Bone type name: the last two ribs
  ///
  /// In en, this message translates to:
  /// **'Ribs 11–12'**
  String get boneRib1112;

  /// No description provided for @boneRib1112Meaning.
  ///
  /// In en, this message translates to:
  /// **'one of the bottom two ribs'**
  String get boneRib1112Meaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Cervical Vertebrae'**
  String get boneCervical;

  /// No description provided for @boneCervicalMeaning.
  ///
  /// In en, this message translates to:
  /// **'a neck bone'**
  String get boneCervicalMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Thoracic Vertebrae'**
  String get boneThoracic;

  /// No description provided for @boneThoracicMeaning.
  ///
  /// In en, this message translates to:
  /// **'a bone from the upper back'**
  String get boneThoracicMeaning;

  /// Bone type name
  ///
  /// In en, this message translates to:
  /// **'Lumbar Vertebrae'**
  String get boneLumbar;

  /// No description provided for @boneLumbarMeaning.
  ///
  /// In en, this message translates to:
  /// **'a bone from the lower back'**
  String get boneLumbarMeaning;

  /// Headline when no bone type was found
  ///
  /// In en, this message translates to:
  /// **'Unidentified'**
  String get boneUnidentified;

  /// Headline when the photo shows no bone
  ///
  /// In en, this message translates to:
  /// **'No bone detected'**
  String get noBoneDetected;

  /// No description provided for @animalHuman.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get animalHuman;

  /// No description provided for @animalHumanMeaning.
  ///
  /// In en, this message translates to:
  /// **'a person'**
  String get animalHumanMeaning;

  /// Animal family name (Canidae)
  ///
  /// In en, this message translates to:
  /// **'Canid'**
  String get animalCanid;

  /// No description provided for @animalCanidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the dog family (dogs, wolves, coyotes and foxes)'**
  String get animalCanidMeaning;

  /// Animal family name (Cervidae)
  ///
  /// In en, this message translates to:
  /// **'Cervid'**
  String get animalCervid;

  /// No description provided for @animalCervidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the deer family (deer, elk, moose and caribou)'**
  String get animalCervidMeaning;

  /// Animal family name (Bovidae)
  ///
  /// In en, this message translates to:
  /// **'Bovid'**
  String get animalBovid;

  /// No description provided for @animalBovidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the cattle family (cows, bison, sheep, goats and antelope)'**
  String get animalBovidMeaning;

  /// Animal family name (Suidae)
  ///
  /// In en, this message translates to:
  /// **'Suid'**
  String get animalSuid;

  /// No description provided for @animalSuidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the pig family (pigs, wild boar and warthogs)'**
  String get animalSuidMeaning;

  /// Animal family name (Felidae)
  ///
  /// In en, this message translates to:
  /// **'Felid'**
  String get animalFelid;

  /// No description provided for @animalFelidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the cat family (house cats, bobcats, cougars and lions)'**
  String get animalFelidMeaning;

  /// Animal family name (Ursidae)
  ///
  /// In en, this message translates to:
  /// **'Ursid'**
  String get animalUrsid;

  /// No description provided for @animalUrsidMeaning.
  ///
  /// In en, this message translates to:
  /// **'bears'**
  String get animalUrsidMeaning;

  /// Animal family name (Leporidae)
  ///
  /// In en, this message translates to:
  /// **'Leporid'**
  String get animalLeporid;

  /// No description provided for @animalLeporidMeaning.
  ///
  /// In en, this message translates to:
  /// **'rabbits and hares'**
  String get animalLeporidMeaning;

  /// Animal family name (Procyonidae)
  ///
  /// In en, this message translates to:
  /// **'Procyonid'**
  String get animalProcyonid;

  /// No description provided for @animalProcyonidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the raccoon family (raccoons, coatis and ringtails)'**
  String get animalProcyonidMeaning;

  /// Animal family name (Equidae)
  ///
  /// In en, this message translates to:
  /// **'Equid'**
  String get animalEquid;

  /// No description provided for @animalEquidMeaning.
  ///
  /// In en, this message translates to:
  /// **'the horse family (horses, donkeys and zebras)'**
  String get animalEquidMeaning;

  /// Animal group name (Rodentia)
  ///
  /// In en, this message translates to:
  /// **'Rodent'**
  String get animalRodent;

  /// No description provided for @animalRodentMeaning.
  ///
  /// In en, this message translates to:
  /// **'rats, mice, squirrels, beavers and their kin'**
  String get animalRodentMeaning;

  /// No description provided for @animalMammal.
  ///
  /// In en, this message translates to:
  /// **'Mammal'**
  String get animalMammal;

  /// No description provided for @animalOtherMammalMeaning.
  ///
  /// In en, this message translates to:
  /// **'an animal with fur that feeds its young milk, from a family Ossia doesn\'t name, like a skunk or opossum'**
  String get animalOtherMammalMeaning;

  /// No description provided for @animalMammalMeaning.
  ///
  /// In en, this message translates to:
  /// **'an animal with fur that feeds its young milk. This bone doesn\'t show which family'**
  String get animalMammalMeaning;

  /// No description provided for @animalBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get animalBird;

  /// No description provided for @animalBirdMeaning.
  ///
  /// In en, this message translates to:
  /// **'any bird, from sparrows to ostriches'**
  String get animalBirdMeaning;

  /// No description provided for @animalReptile.
  ///
  /// In en, this message translates to:
  /// **'Reptile'**
  String get animalReptile;

  /// No description provided for @animalReptileMeaning.
  ///
  /// In en, this message translates to:
  /// **'turtles, snakes, lizards and crocodiles'**
  String get animalReptileMeaning;

  /// An animal bone with no animal group named
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get animalUnnamed;

  /// No description provided for @animalUnnamedMeaning.
  ///
  /// In en, this message translates to:
  /// **'an animal bone that no animal group stood out for'**
  String get animalUnnamedMeaning;

  /// No description provided for @partComplete.
  ///
  /// In en, this message translates to:
  /// **'Whole bone'**
  String get partComplete;

  /// No description provided for @partShaft.
  ///
  /// In en, this message translates to:
  /// **'Middle (shaft)'**
  String get partShaft;

  /// The end of a limb bone nearer the body
  ///
  /// In en, this message translates to:
  /// **'Near end'**
  String get partProximal;

  /// The end of a limb bone further from the body
  ///
  /// In en, this message translates to:
  /// **'Far end'**
  String get partDistal;

  /// No description provided for @partFragment.
  ///
  /// In en, this message translates to:
  /// **'Broken piece'**
  String get partFragment;

  /// The bone is whole
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get statusComplete;

  /// The bone is only a fragment
  ///
  /// In en, this message translates to:
  /// **'Broken'**
  String get statusFragment;

  /// No description provided for @conditionWholeButBroken.
  ///
  /// In en, this message translates to:
  /// **'Whole bone, but broken'**
  String get conditionWholeButBroken;

  /// A part of the bone that is broken off, e.g. "Near end, broken"
  ///
  /// In en, this message translates to:
  /// **'{part}, broken'**
  String conditionPartBroken(String part);

  /// No description provided for @damageFracture.
  ///
  /// In en, this message translates to:
  /// **'Fracture'**
  String get damageFracture;

  /// No description provided for @damageCutMarks.
  ///
  /// In en, this message translates to:
  /// **'Cut marks'**
  String get damageCutMarks;

  /// No description provided for @damageBurnSigns.
  ///
  /// In en, this message translates to:
  /// **'Burn signs'**
  String get damageBurnSigns;

  /// No description provided for @ageAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get ageAdult;

  /// A child or teenager
  ///
  /// In en, this message translates to:
  /// **'Juvenile'**
  String get ageJuvenile;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// No description provided for @sourceOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get sourceOnDevice;

  /// No description provided for @sourceServer.
  ///
  /// In en, this message translates to:
  /// **'Your server'**
  String get sourceServer;

  /// No description provided for @regionCranial.
  ///
  /// In en, this message translates to:
  /// **'Cranial'**
  String get regionCranial;

  /// No description provided for @regionAxial.
  ///
  /// In en, this message translates to:
  /// **'Axial'**
  String get regionAxial;

  /// No description provided for @regionThoracic.
  ///
  /// In en, this message translates to:
  /// **'Thoracic'**
  String get regionThoracic;

  /// No description provided for @regionUpperLimb.
  ///
  /// In en, this message translates to:
  /// **'Upper limb'**
  String get regionUpperLimb;

  /// No description provided for @regionLowerLimb.
  ///
  /// In en, this message translates to:
  /// **'Lower limb'**
  String get regionLowerLimb;

  /// No description provided for @regionGirdle.
  ///
  /// In en, this message translates to:
  /// **'Girdle'**
  String get regionGirdle;

  /// No description provided for @phaseFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding the bone'**
  String get phaseFinding;

  /// No description provided for @phaseHumanOrAnimal.
  ///
  /// In en, this message translates to:
  /// **'Human or animal?'**
  String get phaseHumanOrAnimal;

  /// No description provided for @phaseWhichBone.
  ///
  /// In en, this message translates to:
  /// **'Which bone?'**
  String get phaseWhichBone;

  /// No description provided for @phaseWhichPart.
  ///
  /// In en, this message translates to:
  /// **'Which part?'**
  String get phaseWhichPart;

  /// No description provided for @phaseWholeOrBroken.
  ///
  /// In en, this message translates to:
  /// **'Whole or broken?'**
  String get phaseWholeOrBroken;

  /// No description provided for @phaseMarks.
  ///
  /// In en, this message translates to:
  /// **'Looking for marks'**
  String get phaseMarks;

  /// No description provided for @phaseWhichAnimal.
  ///
  /// In en, this message translates to:
  /// **'Which animal?'**
  String get phaseWhichAnimal;

  /// No description provided for @phaseAgeSex.
  ///
  /// In en, this message translates to:
  /// **'Age and sex'**
  String get phaseAgeSex;

  /// No description provided for @phaseWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing it up'**
  String get phaseWriting;

  /// No description provided for @unitCentimetres.
  ///
  /// In en, this message translates to:
  /// **'Centimetres'**
  String get unitCentimetres;

  /// No description provided for @unitInches.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get unitInches;

  /// Short symbol for centimetres
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// Short symbol for inches
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get unitIn;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Cranium and mandible together'**
  String get atlasSkullBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The complete bony head: the cranium together with the mandible. Twenty-two bones in all, joined by interlocking sutures; only the mandible articulates freely.'**
  String get atlasSkullSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Coronal, sagittal and lambdoid sutures'**
  String get atlasSkullLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Orbits and the piriform (nasal) aperture'**
  String get atlasSkullLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Foramen magnum on the basicranium'**
  String get atlasSkullLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Mastoid processes behind the ear canals'**
  String get atlasSkullLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Symmetrical. Orientation comes from the frontal bone (anterior) and the occipital squama (posterior).'**
  String get atlasSkullSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'The skull without its jaw'**
  String get atlasCraniumBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The skull with the mandible removed. Encloses and protects the brain; the vault is made of frontal, parietal, temporal and occipital bones.'**
  String get atlasCraniumSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Supraorbital ridges — heavier in male crania'**
  String get atlasCraniumLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Nuchal lines on the occipital'**
  String get atlasCraniumLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Temporal lines sweeping across the parietals'**
  String get atlasCraniumLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'External auditory meatus'**
  String get atlasCraniumLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Symmetrical when complete. Isolated vault fragments are sided by suture direction and meningeal groove patterning.'**
  String get atlasCraniumSiding;

  /// Atlas: another name for this bone
  ///
  /// In en, this message translates to:
  /// **'Calvarium (vault only)'**
  String get atlasCraniumAka;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Lower jaw; dense and durable'**
  String get atlasMandibleBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The lower jaw — the only freely mobile bone of the skull. Dense and compact, so it survives burial and burning better than most.'**
  String get atlasMandibleSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Mental protuberance (the chin)'**
  String get atlasMandibleLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Gonial angle where ramus meets body'**
  String get atlasMandibleLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Mandibular condyle and coronoid process'**
  String get atlasMandibleLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Mental foramen below the premolars'**
  String get atlasMandibleLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Symmetrical when whole. A half-mandible is sided by the direction the ramus rises and by which way the tooth row curves.'**
  String get atlasMandibleSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Thigh bone; best stature indicator'**
  String get atlasFemurBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The thigh bone — the longest and strongest bone in the body. Its maximum length carries the tightest correlation with living stature.'**
  String get atlasFemurSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Spherical head with the fovea capitis'**
  String get atlasFemurLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Greater and lesser trochanters'**
  String get atlasFemurLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Linea aspera ridging the posterior shaft'**
  String get atlasFemurLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Medial and lateral condyles at the knee'**
  String get atlasFemurLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Hold the bone upright: the head points medially and the linea aspera faces posteriorly. The side the head points to is the side of the body.'**
  String get atlasFemurSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Shin bone; triangular shaft'**
  String get atlasTibiaBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The shin bone, medial and weight-bearing in the lower leg. Its triangular shaft is distinctive even in fragments.'**
  String get atlasTibiaSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Tibial tuberosity on the anterior proximal shaft'**
  String get atlasTibiaLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Sharp anterior crest'**
  String get atlasTibiaLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Medial malleolus at the ankle'**
  String get atlasTibiaLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Flat medial and lateral condyles'**
  String get atlasTibiaLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'The medial malleolus projects on the same side as the body it came from; the tibial tuberosity marks the front.'**
  String get atlasTibiaSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Upper arm, shoulder to elbow'**
  String get atlasHumerusBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The upper arm bone, running from the shoulder joint to the elbow. Second only to the femur in length.'**
  String get atlasHumerusSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Rounded head with greater and lesser tubercles'**
  String get atlasHumerusLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Deltoid tuberosity mid-shaft'**
  String get atlasHumerusLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Olecranon fossa on the posterior distal end'**
  String get atlasHumerusLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Trochlea and capitulum forming the elbow'**
  String get atlasHumerusLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Stand it upright with the head facing you: the olecranon fossa sits posteriorly, and the head turns medially toward the body midline.'**
  String get atlasHumerusSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Lateral forearm, on the thumb side'**
  String get atlasRadiusBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The lateral forearm bone, on the thumb side. It rotates over the ulna to turn the palm.'**
  String get atlasRadiusSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Disc-shaped proximal head'**
  String get atlasRadiusLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Radial tuberosity just below the neck'**
  String get atlasRadiusLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Broad, flared distal end'**
  String get atlasRadiusLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Styloid process at the wrist'**
  String get atlasRadiusLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'The small head is proximal and the broad end distal; the styloid process points laterally, away from the midline.'**
  String get atlasRadiusSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Medial forearm; point of the elbow'**
  String get atlasUlnaBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The medial forearm bone, on the little-finger side. Forms the hinge of the elbow and is the stable partner the radius rotates around.'**
  String get atlasUlnaSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Olecranon process — the point of the elbow'**
  String get atlasUlnaLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Trochlear notch gripping the humerus'**
  String get atlasUlnaLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Coronoid process below the notch'**
  String get atlasUlnaLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Slender distal head with styloid process'**
  String get atlasUlnaLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'The trochlear notch opens anteriorly; with the olecranon up and the notch facing you, the shaft curves toward the body side.'**
  String get atlasUlnaSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Shoulder blade; thin triangular plate'**
  String get atlasScapulaBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The shoulder blade — a thin triangular plate riding on the back of the ribcage. Thin enough that the blade often survives only as fragments.'**
  String get atlasScapulaSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Spine running across the posterior surface'**
  String get atlasScapulaLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Acromion process at the shoulder tip'**
  String get atlasScapulaLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Hooked coracoid process anteriorly'**
  String get atlasScapulaLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Glenoid fossa receiving the humeral head'**
  String get atlasScapulaLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'The glenoid fossa faces laterally and the spine sits on the posterior surface; the side the fossa faces is the side of the body.'**
  String get atlasScapulaSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Hip bone; best indicator of sex'**
  String get atlasOsCoxaBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The hip bone: ilium, ischium and pubis fused at the acetabulum. The single most reliable element for estimating sex and adult age.'**
  String get atlasOsCoxaSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Greater sciatic notch — broad in females, narrow in males'**
  String get atlasOsCoxaLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Subpubic angle and the ventral arc'**
  String get atlasOsCoxaLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Auricular surface, used for age-at-death'**
  String get atlasOsCoxaLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Acetabulum receiving the femoral head'**
  String get atlasOsCoxaLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Point the iliac blade up and the acetabulum out: the pubis sits anteriorly and the sciatic notch opens posteriorly.'**
  String get atlasOsCoxaSiding;

  /// Atlas: another name for this bone
  ///
  /// In en, this message translates to:
  /// **'Innominate, hip bone'**
  String get atlasOsCoxaAka;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Atypical ribs; flat and sharply curved'**
  String get atlasRib12Blurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The first two ribs are atypical. Rib 1 is the shortest, broadest and most sharply curved; rib 2 is longer but keeps the same flattened set.'**
  String get atlasRib12Summary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Rib 1 lies flat, with superior and inferior surfaces'**
  String get atlasRib12Lm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Scalene tubercle with grooves for the subclavian vessels'**
  String get atlasRib12Lm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Rib 2 carries a tuberosity for serratus anterior'**
  String get atlasRib12Lm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Single articular facet on the head of rib 1'**
  String get atlasRib12Lm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Lay the rib flat with the head backward: the concave inner surface faces the midline, giving the side.'**
  String get atlasRib12Siding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Ribs 3–9; head, tubercle, costal groove'**
  String get atlasTypicalRibBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'Ribs 3 through 9 share one plan: a head, neck, tubercle and a long curving body that twists at the angle.'**
  String get atlasTypicalRibSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Two demifacets on the head'**
  String get atlasTypicalRibLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Tubercle articulating with a transverse process'**
  String get atlasTypicalRibLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Angle where the shaft changes direction'**
  String get atlasTypicalRibLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Costal groove along the inner inferior border'**
  String get atlasTypicalRibLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'The costal groove runs on the internal inferior edge; with the groove down and inside, the head points to the back and gives the side.'**
  String get atlasTypicalRibSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'Floating ribs; short and unattached'**
  String get atlasRib1112Blurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The floating ribs. Short, tapering and unattached at the front, which is why they lack most of the features a typical rib carries.'**
  String get atlasRib1112Summary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Single articular facet on the head'**
  String get atlasRib1112Lm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'No neck and no tubercle'**
  String get atlasRib1112Lm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Little or no costal groove'**
  String get atlasRib1112Lm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Pointed, cartilage-tipped anterior end'**
  String get atlasRib1112Lm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Curvature alone gives the side: the concave surface faces the midline.'**
  String get atlasRib1112Siding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'C1–C7; the only ones with transverse foramina'**
  String get atlasCervicalBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The seven neck vertebrae, C1–C7. Smallest bodies in the column and the only vertebrae with holes in the transverse processes.'**
  String get atlasCervicalSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Transverse foramina — diagnostic for the region'**
  String get atlasCervicalLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'C1 (atlas) has no body; C2 (axis) carries the dens'**
  String get atlasCervicalLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Bifid spinous processes on C2–C6'**
  String get atlasCervicalLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Large triangular vertebral foramen'**
  String get atlasCervicalLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Symmetrical. Position in the series is read from the spinous process and body size; C7 has the long, unsplit \"prominens\" spine.'**
  String get atlasCervicalSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'T1–T12; carry the costal facets'**
  String get atlasThoracicBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The twelve vertebrae of the upper back, T1–T12. Each one articulates with a pair of ribs, and the facets for those ribs identify the region.'**
  String get atlasThoracicSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Costal facets on the body and transverse processes'**
  String get atlasThoracicLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Heart-shaped vertebral bodies'**
  String get atlasThoracicLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Long spinous processes angled steeply downward'**
  String get atlasThoracicLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Circular vertebral foramen'**
  String get atlasThoracicLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Symmetrical. Sequence is judged from body size and how far the spinous process overlaps the vertebra below.'**
  String get atlasThoracicSiding;

  /// Atlas: one line under the bone name in the list
  ///
  /// In en, this message translates to:
  /// **'L1–L5; the heaviest in the column'**
  String get atlasLumbarBlurb;

  /// Atlas, anatomy text for experts. Keep the Latin terms where your language uses them
  ///
  /// In en, this message translates to:
  /// **'The five vertebrae of the lower back, L1–L5. The largest and most robust in the column, built for load rather than movement.'**
  String get atlasLumbarSummary;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Massive kidney-shaped bodies'**
  String get atlasLumbarLm1;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'No transverse foramina and no costal facets'**
  String get atlasLumbarLm2;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Short, blunt, hatchet-shaped spinous processes'**
  String get atlasLumbarLm3;

  /// Atlas: one thing an expert looks for on this bone
  ///
  /// In en, this message translates to:
  /// **'Mammillary processes on the superior articular facets'**
  String get atlasLumbarLm4;

  /// Atlas: how to tell left from right, or the place in a series
  ///
  /// In en, this message translates to:
  /// **'Symmetrical. L5 is recognised by its wedge shape, deeper in front than behind, where it meets the sacrum.'**
  String get atlasLumbarSiding;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Is there a bone?'**
  String get phaseDoc1Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'First Ossia checks there\'s a bone in the photo at all, so a stick or a stone doesn\'t get a made-up answer.'**
  String get phaseDoc1Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Human or animal?'**
  String get phaseDoc2Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'Next it decides whether the bone came from a person or an animal. Everything after depends on this step.'**
  String get phaseDoc2Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Which bone?'**
  String get phaseDoc3Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'Sixteen kinds of bone, from the skull and jaw to the ribs, spine, hip and limbs. You see its top three guesses, not just the winner.'**
  String get phaseDoc3Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Which part?'**
  String get phaseDoc4Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'Whether the photo shows the whole bone, its middle (the shaft), one end, or a broken piece.'**
  String get phaseDoc4Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Whole or broken?'**
  String get phaseDoc5Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'A quick yes or no: is the bone complete, or only a fragment?'**
  String get phaseDoc5Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Marks and damage'**
  String get phaseDoc6Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'Breaks, cut marks and burning are each checked on their own, so one bone can show all three.'**
  String get phaseDoc6Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Which animal?'**
  String get phaseDoc7Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'For animal bones: mammal, bird or reptile. For mammals, also the family, like the dog, deer, cattle, pig, cat, bear, rabbit, raccoon or horse family, or a rodent. The family is only named when the bone can show it, such as a skull, a jaw or a whole leg bone.'**
  String get phaseDoc7Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Age and sex'**
  String get phaseDoc8Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'For human bones only. Treat these as a hint to check, never as an answer on their own.'**
  String get phaseDoc8Detail;

  /// How analysis works: step title
  ///
  /// In en, this message translates to:
  /// **'Putting it together'**
  String get phaseDoc9Title;

  /// How analysis works: what this step does
  ///
  /// In en, this message translates to:
  /// **'Photos of the same bone from different sides are read together, and the length you measured is checked against the bone\'s usual size. Both help when one photo alone is unclear.'**
  String get phaseDoc9Detail;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Ossia couldn\'t get ready on this phone. Try again, or restart the app.'**
  String get errNotReadyOnPhone;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that photo. Try a JPEG or PNG.'**
  String get errPhotoUnreadable;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read photo {number}. Remove it and try again.'**
  String errPhotoNUnreadable(int number);

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Something went wrong reading that photo. Please try again.'**
  String get errReadingPhoto;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that photo. Try another one.'**
  String get errPhotoTryAnother;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'The online address doesn\'t look right. Check it in Settings.'**
  String get errBadOnlineAddress;

  /// Someone typed "localhost" as the online address on a phone
  ///
  /// In en, this message translates to:
  /// **'That address points back at this phone. Type the address shown on the Ossia computer instead.'**
  String get errThisDevice;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Online analysis isn\'t working right now (error {code}).'**
  String errServerStatus(int code);

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'The photos are too big to send. Try fewer photos.'**
  String get errServerTooBig;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'The online analysis didn\'t accept these photos. Try other photos.'**
  String get errServerRejected;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'The online analysis couldn\'t read these photos. Try other photos.'**
  String get errServerCouldntAnalyze;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Online analysis took too long to answer. Check your connection, or analyze on this phone.'**
  String get errTimeout;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect for online analysis. Check your internet and the online address in Settings.'**
  String get errUnreachable;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Something answered, but not with a report. Check the online address in Settings.'**
  String get errNotAReport;

  /// Shown when a scan fails
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// Connection checklist: one step
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get checkAddress;

  /// Connection checklist: one step
  ///
  /// In en, this message translates to:
  /// **'Reaching it'**
  String get checkReach;

  /// Connection checklist: one step
  ///
  /// In en, this message translates to:
  /// **'Ossia answering'**
  String get checkServer;

  /// Connection checklist: one step
  ///
  /// In en, this message translates to:
  /// **'Ready to analyze'**
  String get checkModel;

  /// Connection checklist: one step
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get checkSpeed;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a valid address'**
  String get checkBadAddress;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Answered in {ms} ms'**
  String checkAnsweredIn(int ms);

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Running for {time}'**
  String checkRunningFor(String time);

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'It\'s on, but not ready to analyze yet'**
  String get checkNotReady;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get checkReady;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Lost the connection'**
  String get checkLost;

  /// Connection checklist: result of a step, e.g. "120 ms · snappy"
  ///
  /// In en, this message translates to:
  /// **'{ms} ms · {word}'**
  String checkPing(int ms, String word);

  /// How fast the connection is: very fast
  ///
  /// In en, this message translates to:
  /// **'snappy'**
  String get pingSnappy;

  /// How fast the connection is: fine
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get pingGood;

  /// How fast the connection is: a bit slow
  ///
  /// In en, this message translates to:
  /// **'sluggish'**
  String get pingSluggish;

  /// How fast the connection is: slow
  ///
  /// In en, this message translates to:
  /// **'slow'**
  String get pingSlow;

  /// How long the server has run, very short units: seconds
  ///
  /// In en, this message translates to:
  /// **'{s}s'**
  String uptimeSeconds(int s);

  /// Short units: minutes
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String uptimeMinutes(int m);

  /// Short units: hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String uptimeHours(int h, int m);

  /// Short units: days and hours
  ///
  /// In en, this message translates to:
  /// **'{d}d {h}h'**
  String uptimeDays(int d, int h);

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Bad answer'**
  String get netBadAnswer;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'No answer within {seconds} seconds'**
  String netNoAnswer(int seconds);

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'That address wasn\'t found. Check it\'s typed right and still current'**
  String get netNotFound;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Nothing answered at that address'**
  String get netRefused;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get netNoInternet;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make a secure connection'**
  String get netNotSecure;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'The address works, but Ossia isn\'t running behind it'**
  String get netNotRunning;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'That address has expired'**
  String get netExpired;

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'It answered with an error ({code})'**
  String netHttpError(int code);

  /// Connection checklist: result of a step
  ///
  /// In en, this message translates to:
  /// **'Something answered, but it isn\'t Ossia'**
  String get netNotOssia;

  /// An animal and a bone named inside a length note, e.g. „Mensch · Femur“
  ///
  /// In en, this message translates to:
  /// **'\"{animal} {bone}\"'**
  String lenThing(String animal, String bone);

  /// The usual length range after a bone name
  ///
  /// In en, this message translates to:
  /// **'{thing} (usually {min}–{max} cm)'**
  String lenUsually(String thing, String min, String max);

  /// The longest a bone ever is, after its name
  ///
  /// In en, this message translates to:
  /// **'{thing} (never over {max} cm)'**
  String lenNeverOver(String thing, String max);

  /// Two bone names
  ///
  /// In en, this message translates to:
  /// **'{first} or {second}'**
  String lenOrThing(String first, String second);

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'No bone was found, so the length wasn\'t used.'**
  String get lenNoBone;

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'No length was entered.'**
  String get lenNoLength;

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'This looks like the middle (shaft) of a bone, so its length can\'t be compared with whole bones.'**
  String get lenOnlyShaft;

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'This looks like one end of a bone, so its length can\'t be compared with whole bones.'**
  String get lenOnlyEnd;

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'This looks like a broken piece of bone, so its length can\'t be compared with whole bones.'**
  String get lenOnlyPiece;

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'This looks like only part of a bone, so its length can\'t be compared with whole bones.'**
  String get lenOnlyPart;

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'We don\'t have usual lengths for {things}, so the length wasn\'t used.'**
  String lenNoReference(String things);

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'{cm} cm doesn\'t fit {before} or the next closest option, {after}, so we kept the photo\'s answer. It could be from a young animal or person, or worth measuring again.'**
  String lenNoFit(String cm, String before, String after);

  /// A note on a report about the length the person measured (first half; one of the next two follows it)
  ///
  /// In en, this message translates to:
  /// **'{cm} cm is too long for {before}.'**
  String lenChangedTooLong(String cm, String before);

  /// A note on a report about the length the person measured (first half)
  ///
  /// In en, this message translates to:
  /// **'{cm} cm is too short for {before}.'**
  String lenChangedTooShort(String cm, String before);

  /// A note on a report about the length the person measured (first half)
  ///
  /// In en, this message translates to:
  /// **'{cm} cm fits {before}, but ruling out other options shifted the answer.'**
  String lenChangedFitsBut(String cm, String before);

  /// A note on a report about the length the person measured (first half)
  ///
  /// In en, this message translates to:
  /// **'{cm} cm can\'t be checked against {before}.'**
  String lenChangedUnchecked(String cm, String before);

  /// A note on a report about the length the person measured (second half)
  ///
  /// In en, this message translates to:
  /// **'It fits {after}, so the length changed the answer.'**
  String lenChangedNowFits(String after);

  /// A note on a report about the length the person measured (second half)
  ///
  /// In en, this message translates to:
  /// **'{after} can\'t be ruled out by length, so the length changed the answer.'**
  String lenChangedNotRuledOut(String after);

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'We don\'t have a usual length for {before}, so the length couldn\'t confirm it. It only helped weigh up the other options.'**
  String lenNoUsual(String before);

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'{cm} cm is a normal length for {before}, which backs up the answer.'**
  String lenNormal(String cm, String before);

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'{cm} cm is short for {before}, but the photo still points to it. It could be from a young animal or person, or worth measuring again.'**
  String lenShort(String cm, String before);

  /// A note on a report about the length the person measured
  ///
  /// In en, this message translates to:
  /// **'{cm} cm is long for {before}, but the photo still points to it. Worth measuring again.'**
  String lenLong(String cm, String before);

  /// After a length note, when the length changed the answer
  ///
  /// In en, this message translates to:
  /// **'From the photo alone, it was {headline}.'**
  String lenPhotoAlone(String headline);

  /// Under "Typical length": which animals the range was measured on
  ///
  /// In en, this message translates to:
  /// **'{thing} (measured on {animals})'**
  String lenMeasuredOn(String thing, String animals);

  /// No description provided for @measuredBears.
  ///
  /// In en, this message translates to:
  /// **'black and brown bear'**
  String get measuredBears;

  /// German: dative plural, after "gemessen an"
  ///
  /// In en, this message translates to:
  /// **'cattle'**
  String get measuredCattle;

  /// No description provided for @measuredCat.
  ///
  /// In en, this message translates to:
  /// **'domestic cat'**
  String get measuredCat;

  /// No description provided for @measuredDogsFoxes.
  ///
  /// In en, this message translates to:
  /// **'domestic dogs (all breeds) and red and gray fox'**
  String get measuredDogsFoxes;

  /// No description provided for @measuredPigBoar.
  ///
  /// In en, this message translates to:
  /// **'domestic pig and wild boar'**
  String get measuredPigBoar;

  /// No description provided for @measuredCottontail.
  ///
  /// In en, this message translates to:
  /// **'eastern cottontail'**
  String get measuredCottontail;

  /// No description provided for @measuredHorse.
  ///
  /// In en, this message translates to:
  /// **'horse'**
  String get measuredHorse;

  /// No description provided for @measuredRaccoon.
  ///
  /// In en, this message translates to:
  /// **'raccoon'**
  String get measuredRaccoon;

  /// No description provided for @measuredDeer.
  ///
  /// In en, this message translates to:
  /// **'white-tailed and mule deer'**
  String get measuredDeer;

  /// Big title on the yellow card on the home screen. Keep the line break.
  ///
  /// In en, this message translates to:
  /// **'Found a bone?\nLet’s ID it.'**
  String get scanHeroTitle;

  /// No description provided for @scanHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Snap it or upload it. We’ll tell you what it is, whose it was and what happened to it.'**
  String get scanHeroBody;

  /// Main button: opens the camera
  ///
  /// In en, this message translates to:
  /// **'Snap a bone'**
  String get scanSnap;

  /// Button: pick a photo from the phone
  ///
  /// In en, this message translates to:
  /// **'Upload a pic'**
  String get scanUpload;

  /// No description provided for @scanTipsHeader.
  ///
  /// In en, this message translates to:
  /// **'Pro tips for a clean read'**
  String get scanTipsHeader;

  /// Tip card title. Keep it short, it is on one line.
  ///
  /// In en, this message translates to:
  /// **'Plain background'**
  String get tipBackgroundTitle;

  /// No description provided for @tipBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'A sheet or a table. No patterns, labels or writing.'**
  String get tipBackgroundBody;

  /// Tip card title. Keep it short, it is on one line.
  ///
  /// In en, this message translates to:
  /// **'Soft light'**
  String get tipLightTitle;

  /// No description provided for @tipLightBody.
  ///
  /// In en, this message translates to:
  /// **'Daylight is best. Harsh shadows hide details.'**
  String get tipLightBody;

  /// Tip card title. Keep it short, it is on one line.
  ///
  /// In en, this message translates to:
  /// **'Know the length?'**
  String get tipLengthTitle;

  /// No description provided for @tipLengthBody.
  ///
  /// In en, this message translates to:
  /// **'Add it before analyzing. It sharpens the guess.'**
  String get tipLengthBody;

  /// Tip card title. Keep it short, it is on one line.
  ///
  /// In en, this message translates to:
  /// **'Try a few angles'**
  String get tipAnglesTitle;

  /// No description provided for @tipAnglesBody.
  ///
  /// In en, this message translates to:
  /// **'Front and back views solve tricky bones.'**
  String get tipAnglesBody;

  /// No description provided for @scanRecentFinds.
  ///
  /// In en, this message translates to:
  /// **'Recent finds'**
  String get scanRecentFinds;

  /// Small sticker next to "Recent finds"
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String scanSavedCount(int count);

  /// No description provided for @scanNoFinds.
  ///
  /// In en, this message translates to:
  /// **'No finds yet'**
  String get scanNoFinds;

  /// No description provided for @scanNoFindsBody.
  ///
  /// In en, this message translates to:
  /// **'Your scanned bones will pile up right here.'**
  String get scanNoFindsBody;

  /// Connection pill: the model on the phone failed to load
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get linkNotReady;

  /// Connection pill: scans run on the phone. A small pill: keep it short
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get linkOnPhone;

  /// Connection pill: checking the online server
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get linkConnecting;

  /// Connection pill: the online server answers
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get linkOnline;

  /// Connection pill with how fast the server answered
  ///
  /// In en, this message translates to:
  /// **'Online · {ms} ms'**
  String linkOnlineMs(int ms);

  /// Connection pill: the online server does not answer
  ///
  /// In en, this message translates to:
  /// **'Can’t connect'**
  String get linkCantConnect;

  /// Pop-up when the online server stops answering
  ///
  /// In en, this message translates to:
  /// **'Lost the connection'**
  String get toastLostConnection;

  /// Pop-up when the online server answers again
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get toastBackOnline;

  /// Camera outline choice: femur, humerus, tibia
  ///
  /// In en, this message translates to:
  /// **'Long bone'**
  String get guideLongBone;

  /// Camera outline choice: cranium, jaw
  ///
  /// In en, this message translates to:
  /// **'Skull'**
  String get guideSkull;

  /// Camera outline choice: shoulder blade, hip bone, rib
  ///
  /// In en, this message translates to:
  /// **'Flat bone'**
  String get guideFlat;

  /// Camera outline choice: vertebra, fragment
  ///
  /// In en, this message translates to:
  /// **'Small bit'**
  String get guideSmall;

  /// The cartoon bone speaking; the long-bone outline is its own shape
  ///
  /// In en, this message translates to:
  /// **'Lay it flat and line it up with my knobby ends.'**
  String get guideLongBoneTip;

  /// No description provided for @guideSkullTip.
  ///
  /// In en, this message translates to:
  /// **'Face it straight on. Eye sockets in the dotted eyes.'**
  String get guideSkullTip;

  /// No description provided for @guideFlatTip.
  ///
  /// In en, this message translates to:
  /// **'Lay it flat. Get the whole outline in, edge to edge.'**
  String get guideFlatTip;

  /// No description provided for @guideSmallTip.
  ///
  /// In en, this message translates to:
  /// **'Tiny bone? Get up close till it fills the outline.'**
  String get guideSmallTip;

  /// Chip in the camera: how far to hold the phone
  ///
  /// In en, this message translates to:
  /// **'Hold ~{cm} cm away · fill the outline'**
  String camHold(int cm);

  /// Sticker at the top of the camera
  ///
  /// In en, this message translates to:
  /// **'BONE CAM'**
  String get camTitle;

  /// Sticker at the top of the camera when adding another photo of the same bone
  ///
  /// In en, this message translates to:
  /// **'ANGLE #{number}'**
  String camAngle(int number);

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Close camera'**
  String get camClose;

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get camFlash;

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get camZoom;

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get camSwitch;

  /// Read out by screen readers for the big shutter button
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get camTakePhoto;

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Upload from library'**
  String get camUploadFromLibrary;

  /// No description provided for @camWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming up the camera…'**
  String get camWarmingUp;

  /// No description provided for @camAnotherAngleTip.
  ///
  /// In en, this message translates to:
  /// **'Same bone, new side. Flip it over, or get one of the ends.'**
  String get camAnotherAngleTip;

  /// No description provided for @camShotFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t take that one. Try again?'**
  String get camShotFailed;

  /// No description provided for @camNoAccess.
  ///
  /// In en, this message translates to:
  /// **'No camera access'**
  String get camNoAccess;

  /// No description provided for @camNoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access for Ossia in your phone settings, or upload a photo instead.'**
  String get camNoAccessBody;

  /// Title when the camera could not start
  ///
  /// In en, this message translates to:
  /// **'Camera is napping'**
  String get camNapping;

  /// No description provided for @camNappingBody.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start the camera here. Upload a photo instead?'**
  String get camNappingBody;

  /// Camera button that turns the automatic photo on and off
  ///
  /// In en, this message translates to:
  /// **'Auto snap'**
  String get camAuto;

  /// Mascot tip right after auto snap is turned on
  ///
  /// In en, this message translates to:
  /// **'Auto snap is on. Get the bone in the frame and hold still.'**
  String get camAutoOnTip;

  /// Mascot tip right after auto snap is turned off
  ///
  /// In en, this message translates to:
  /// **'Auto snap is off. Tap the big button to take the photo.'**
  String get camAutoOffTip;

  /// Sticker that pops onto the camera frame when a bone is in view
  ///
  /// In en, this message translates to:
  /// **'BONE SPOTTED!'**
  String get camAutoSpotted;

  /// Mascot tip when a bone is in view but the phone is moving
  ///
  /// In en, this message translates to:
  /// **'Got it! Now hold the phone still.'**
  String get camAutoFound;

  /// Mascot tip while the phone is still and the auto photo is counting down
  ///
  /// In en, this message translates to:
  /// **'Perfect, hold it right there…'**
  String get camAutoHolding;

  /// Big stamp at the moment the auto photo is taken
  ///
  /// In en, this message translates to:
  /// **'SNAP!'**
  String get camAutoSnapped;

  /// Mascot tip after coming back to the camera from a photo, before auto snap will fire again
  ///
  /// In en, this message translates to:
  /// **'Move the phone a little to take another.'**
  String get camAutoRearm;

  /// Question when leaving the photo check screen after adding or removing photos
  ///
  /// In en, this message translates to:
  /// **'Drop these photos?'**
  String get reviewDropTitle;

  /// No description provided for @reviewDropNew.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This bone’s photo hasn’t been analyzed yet.} other{The {count} photos of this bone haven’t been analyzed yet.}}'**
  String reviewDropNew(int count);

  /// Same question, when adding angles to a find that was already analysed
  ///
  /// In en, this message translates to:
  /// **'The angles you added or removed won’t be analyzed. The saved report stays as it was.'**
  String get reviewDropRevising;

  /// Red button that leaves without analysing
  ///
  /// In en, this message translates to:
  /// **'Drop them'**
  String get reviewDropConfirm;

  /// Title of the box for typing a length
  ///
  /// In en, this message translates to:
  /// **'Type the length'**
  String get reviewTypeLength;

  /// No description provided for @reviewTypeLengthCm.
  ///
  /// In en, this message translates to:
  /// **'End to end, the longest straight line, in centimetres.'**
  String get reviewTypeLengthCm;

  /// No description provided for @reviewTypeLengthIn.
  ///
  /// In en, this message translates to:
  /// **'End to end, the longest straight line, in inches.'**
  String get reviewTypeLengthIn;

  /// Grey hint inside the empty length box
  ///
  /// In en, this message translates to:
  /// **'e.g. {example}'**
  String reviewExample(String example);

  /// Button that saves the typed length
  ///
  /// In en, this message translates to:
  /// **'Set length'**
  String get reviewSetLength;

  /// Button: go back to the camera and take the photo again
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get reviewRetake;

  /// Screen title when adding photos to a saved find
  ///
  /// In en, this message translates to:
  /// **'More angles'**
  String get reviewTitleRevising;

  /// Screen title; count is always 2 or more
  ///
  /// In en, this message translates to:
  /// **'One bone, {count} angles'**
  String reviewTitleAngles(int count);

  /// Screen title right after taking a photo
  ///
  /// In en, this message translates to:
  /// **'Nice shot!'**
  String get reviewNiceShot;

  /// Screen title after picking a photo from the phone
  ///
  /// In en, this message translates to:
  /// **'Looking good?'**
  String get reviewLookingGood;

  /// Playful caption under the photo, like a polaroid label
  ///
  /// In en, this message translates to:
  /// **'mystery bone #{number}'**
  String reviewMysteryBone(int number);

  /// Main button; count is always 2 or more
  ///
  /// In en, this message translates to:
  /// **'Analyze {count} photos'**
  String reviewAnalyzeCount(int count);

  /// Main button when no length was given. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Skip & analyze'**
  String get reviewSkipAnalyze;

  /// Main button. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Analyze it'**
  String get reviewAnalyzeIt;

  /// Card title when there is one photo
  ///
  /// In en, this message translates to:
  /// **'More angles?'**
  String get reviewMoreAnglesQ;

  /// Card title when there are several photos
  ///
  /// In en, this message translates to:
  /// **'Angles'**
  String get reviewAngles;

  /// Small tilted sticker. Capitals where the language has them.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL'**
  String get reviewOptional;

  /// Small sticker: photos used out of the most allowed
  ///
  /// In en, this message translates to:
  /// **'{count} OF {max}'**
  String reviewAnglesOf(int count, int max);

  /// No description provided for @reviewAnglesBodyOne.
  ///
  /// In en, this message translates to:
  /// **'Same bone, another side. The back, an end or a close-up can crack a tricky one. Every photo gets read together.'**
  String get reviewAnglesBodyOne;

  /// count is always 2 or more
  ///
  /// In en, this message translates to:
  /// **'All {count} photos are read together as one bone. Tap one to look at it, or the cross to drop it.'**
  String reviewAnglesBodyMany(int count);

  /// Tiny tile under the photos: take another photo. One short word.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get reviewSnap;

  /// Tiny tile under the photos: add photos from the phone. One short word.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get reviewUpload;

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Take another angle'**
  String get reviewSnapHint;

  /// Read out by screen readers
  ///
  /// In en, this message translates to:
  /// **'Add angles from the library'**
  String get reviewUploadHint;

  /// Shown when the most photos are already added
  ///
  /// In en, this message translates to:
  /// **'That’s the most one analysis takes.'**
  String get reviewMaxPhotos;

  /// Read out by screen readers for the small cross on a photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo {number}'**
  String reviewRemovePhoto(int number);

  /// Card title about the bone’s length
  ///
  /// In en, this message translates to:
  /// **'How long is it?'**
  String get reviewHowLong;

  /// No description provided for @reviewLengthBody.
  ///
  /// In en, this message translates to:
  /// **'Measured it end to end? Flick the tape. No ruler handy? Skip it, no biggie. The AI will guess.'**
  String get reviewLengthBody;

  /// Small caption above the cartoon bone that stretches
  ///
  /// In en, this message translates to:
  /// **'end to end'**
  String get reviewEndToEnd;

  /// Small caption above the cartoon bone before a length is set
  ///
  /// In en, this message translates to:
  /// **'waiting for a number…'**
  String get reviewWaitingNumber;

  /// No description provided for @reviewTapToType.
  ///
  /// In en, this message translates to:
  /// **'Tap the number to type it exactly.'**
  String get reviewTapToType;

  /// No description provided for @reviewFlickTape.
  ///
  /// In en, this message translates to:
  /// **'Flick the tape to set a length.'**
  String get reviewFlickTape;

  /// Small button that removes the length
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reviewClear;

  /// Small sticker at the top while analysing
  ///
  /// In en, this message translates to:
  /// **'Step {step}/{total}'**
  String analyzingStep(int step, int total);

  /// Sticker on the photo stack; count is always 2 or more
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String analyzingPhotos(int count);

  /// Joke line for the stage that finds the bone in the photo
  ///
  /// In en, this message translates to:
  /// **'Playing hide and seek with your bone…'**
  String get quipFinding;

  /// Joke line for the human-or-animal stage
  ///
  /// In en, this message translates to:
  /// **'Human or not? Asking the big questions.'**
  String get quipHumanOrAnimal;

  /// Joke line for the which-bone stage
  ///
  /// In en, this message translates to:
  /// **'Which bone is this? Consulting my inner skeleton.'**
  String get quipWhichBone;

  /// Joke line for the which-part stage
  ///
  /// In en, this message translates to:
  /// **'Figuring out which end is which.'**
  String get quipWhichEnd;

  /// Joke line for the whole-or-broken stage
  ///
  /// In en, this message translates to:
  /// **'Checking if any bits went missing.'**
  String get quipMissingBits;

  /// Joke line for the marks stage (fractures, cut marks, burning)
  ///
  /// In en, this message translates to:
  /// **'Looking for cracks, cuts and crispy bits.'**
  String get quipMarks;

  /// Joke line for the which-animal stage
  ///
  /// In en, this message translates to:
  /// **'Narrowing down whose bone this was.'**
  String get quipWhose;

  /// Joke line for the age-and-sex stage
  ///
  /// In en, this message translates to:
  /// **'Estimating age and sex, respectfully.'**
  String get quipAgeSex;

  /// Joke line for the last stage
  ///
  /// In en, this message translates to:
  /// **'Writing it all up. Almost there!'**
  String get quipWriting;

  /// Big title when the analysis failed
  ///
  /// In en, this message translates to:
  /// **'Welp, that broke'**
  String get analyzingFailedTitle;

  /// Button offered when the online server cannot be reached
  ///
  /// In en, this message translates to:
  /// **'Analyze on this phone'**
  String get analyzingOnPhone;

  /// Title of the box for naming a saved bone
  ///
  /// In en, this message translates to:
  /// **'Name this find'**
  String get reportNameTitle;

  /// No description provided for @reportNameBody.
  ///
  /// In en, this message translates to:
  /// **'Any name that helps you find it later, like where it turned up.'**
  String get reportNameBody;

  /// Grey hint inside the empty name box: a dig label like an archaeologist would write
  ///
  /// In en, this message translates to:
  /// **'e.g. TR2-114'**
  String get reportNameExample;

  /// No description provided for @reportRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get reportRename;

  /// No description provided for @reportAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get reportAddNote;

  /// No description provided for @reportEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get reportEditNote;

  /// No description provided for @reportNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Anything the photo can’t show, like where you found it or how it felt in your hand.'**
  String get reportNoteBody;

  /// Grey example inside the empty note box, in the style of a dig record
  ///
  /// In en, this message translates to:
  /// **'Recovered from unit 4, spit 2…'**
  String get reportNotePlaceholder;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get reportCopied;

  /// Short message after saving; the Library is the Stash tab
  ///
  /// In en, this message translates to:
  /// **'Saved to Library'**
  String get reportSavedToast;

  /// No description provided for @reportDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this analysis?'**
  String get reportDeleteTitle;

  /// No description provided for @reportDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The report and its photograph are removed from this device.} other{The report and its {count} photos are removed from this device.}}'**
  String reportDeleteBody(int count);

  /// Red button that deletes
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Read out by screen readers for the ••• button
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get reportOptions;

  /// Title of the options sheet
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportSheetTitle;

  /// No description provided for @reportAddAngle.
  ///
  /// In en, this message translates to:
  /// **'Add another angle'**
  String get reportAddAngle;

  /// No description provided for @reportCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get reportCopy;

  /// No description provided for @reportDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete analysis'**
  String get reportDelete;

  /// Main button; the Library is the Stash tab
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get reportSave;

  /// No description provided for @reportAnalyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyze Another'**
  String get reportAnalyzeAnother;

  /// How sure the answer is. Arabic: describes الثقة
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get confStrong;

  /// No description provided for @confGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get confGood;

  /// No description provided for @confModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get confModerate;

  /// No description provided for @confWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get confWeak;

  /// No description provided for @confVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very weak'**
  String get confVeryWeak;

  /// Sticker above the answer
  ///
  /// In en, this message translates to:
  /// **'Bone detected'**
  String get resultBoneDetected;

  /// Sticker above the answer
  ///
  /// In en, this message translates to:
  /// **'No bone found'**
  String get resultNoBoneFound;

  /// Sticker: how many photos of the bone were read; always 2 or more
  ///
  /// In en, this message translates to:
  /// **'{count} angles'**
  String resultAngles(int count);

  /// Sticker in place of the angle count when some photos showed no bone; only those that did were read
  ///
  /// In en, this message translates to:
  /// **'Bone in {seen} of {count} photos'**
  String resultAnglesWithBone(int seen, int count);

  /// Title of the box with the big percentage under the answer
  ///
  /// In en, this message translates to:
  /// **'How sure is this answer?'**
  String get resultHowSure;

  /// Small grey text under the list of steps (Bone or not, Human or animal, Which bone, Which animal), each with its own percentage
  ///
  /// In en, this message translates to:
  /// **'The answer is only as good as its weakest step, so the score above is the lowest of these.'**
  String get resultHowSureSteps;

  /// Small grey text under the percentage when no bone was found
  ///
  /// In en, this message translates to:
  /// **'How sure the app is that this photo shows no bone.'**
  String get resultHowSureNone;

  /// First step in the list under the percentage: was a bone found at all
  ///
  /// In en, this message translates to:
  /// **'Bone or not'**
  String get resultStepBone;

  /// Above a few other possible answers with their chances
  ///
  /// In en, this message translates to:
  /// **'Not certain. It could also be:'**
  String get resultCouldAlsoBe;

  /// No description provided for @resultNoBoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No bone spotted'**
  String get resultNoBoneTitle;

  /// No description provided for @resultNoBoneBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find a bone in this photo. Try a plain background, and get close enough that the bone fills most of the picture.'**
  String get resultNoBoneBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get resultIdentification;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Human or animal'**
  String get resultHumanOrAnimal;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Which bone'**
  String get resultWhichBone;

  /// Small grey text beside "Which bone"; count is 2 or more
  ///
  /// In en, this message translates to:
  /// **'Top {count} guesses'**
  String resultTopGuesses(int count);

  /// No description provided for @resultOnlyGuess.
  ///
  /// In en, this message translates to:
  /// **'Only guess'**
  String get resultOnlyGuess;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Which part'**
  String get resultWhichPart;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Whole or broken'**
  String get resultWholeOrBroken;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get resultCondition;

  /// Sticker when no damage was found
  ///
  /// In en, this message translates to:
  /// **'No marks flagged'**
  String get resultNoMarks;

  /// No description provided for @resultMarksFooter.
  ///
  /// In en, this message translates to:
  /// **'Each kind of mark is checked on its own, so a bone can show more than one. Anything at {threshold} or more is flagged.'**
  String resultMarksFooter(String threshold);

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Age and sex'**
  String get resultAgeSex;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Age group'**
  String get resultAgeGroup;

  /// Row label: male or female
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get resultSex;

  /// No description provided for @resultAgeFooter.
  ///
  /// In en, this message translates to:
  /// **'Age and sex are the hardest things to read from a photo, and Ossia learned them from few examples. Treat them as a hint to check, not an answer.'**
  String get resultAgeFooter;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Which animal'**
  String get resultWhichAnimal;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Closest match'**
  String get resultClosestMatch;

  /// No description provided for @resultUndetermined.
  ///
  /// In en, this message translates to:
  /// **'Undetermined'**
  String get resultUndetermined;

  /// No description provided for @resultUndeterminedBody.
  ///
  /// In en, this message translates to:
  /// **'It looks like an animal bone, but no animal group stood out enough to name.'**
  String get resultUndeterminedBody;

  /// No description provided for @resultAnimalFooter.
  ///
  /// In en, this message translates to:
  /// **'For mammals, Ossia names the family (like the deer or dog family) when the bone shows it; otherwise it says mammal, bird or reptile. Compare with a known skeleton before relying on it.'**
  String get resultAnimalFooter;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get resultMeasurements;

  /// Sticker when the measured length changed which bone or animal was picked
  ///
  /// In en, this message translates to:
  /// **'Length changed the answer'**
  String get resultLengthChanged;

  /// Row label: length range from books
  ///
  /// In en, this message translates to:
  /// **'Typical length'**
  String get resultTypicalLength;

  /// Row label: length the AI guessed
  ///
  /// In en, this message translates to:
  /// **'AI estimate'**
  String get resultAiEstimate;

  /// Under "Typical length": which bone the range belongs to
  ///
  /// In en, this message translates to:
  /// **'For a {thing}'**
  String resultTypicalFor(String thing);

  /// A single estimated length
  ///
  /// In en, this message translates to:
  /// **'~{value} {unit}'**
  String resultLengthAbout(String value, String unit);

  /// A length range
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} {unit}'**
  String resultLengthRange(String min, String max, String unit);

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Your measurement'**
  String get resultYourMeasurement;

  /// No description provided for @resultInsideRange.
  ///
  /// In en, this message translates to:
  /// **'Right inside the typical range. Nice.'**
  String get resultInsideRange;

  /// No description provided for @resultOutsideRange.
  ///
  /// In en, this message translates to:
  /// **'Outside the typical range. Worth a second look.'**
  String get resultOutsideRange;

  /// No description provided for @resultInsideEstimate.
  ///
  /// In en, this message translates to:
  /// **'Right inside the estimate. Nice.'**
  String get resultInsideEstimate;

  /// No description provided for @resultOutsideEstimate.
  ///
  /// In en, this message translates to:
  /// **'Outside the estimate. Worth a second look.'**
  String get resultOutsideEstimate;

  /// Section title above a link to the bone’s Atlas page
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get resultReference;

  /// Under the bone’s name in the Atlas link
  ///
  /// In en, this message translates to:
  /// **'{region} · what to look for, and left or right'**
  String resultAtlasSubtitle(String region);

  /// Shown at the bottom of every report
  ///
  /// In en, this message translates to:
  /// **'Ossia gives a best guess, not a final answer. Don’t rely on it for medical, legal or police decisions without a bone expert checking the bone in person.'**
  String get resultDisclaimer;

  /// Big title at the top of the Stash tab
  ///
  /// In en, this message translates to:
  /// **'Your stash'**
  String get libTitle;

  /// Line under the title when nothing is saved
  ///
  /// In en, this message translates to:
  /// **'Empty. For now.'**
  String get libEmptySubtitle;

  /// Line under the title, followed by how many are human
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bone collected} other{{count} bones collected}}'**
  String libBonesCollected(int count);

  /// Follows the count of saved bones: how many of them are human
  ///
  /// In en, this message translates to:
  /// **'{count} human'**
  String libHumanCount(int count);

  /// Grey hint in the empty search box
  ///
  /// In en, this message translates to:
  /// **'Search your bones'**
  String get libSearchHint;

  /// Read out by screen readers for the small cross in the search box
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get libClearSearch;

  /// Filter button. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libFilterAll;

  /// Filter button: only human bones. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get libFilterHuman;

  /// Filter button: only animal bones. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get libFilterAnimal;

  /// Filter button: only bones with marks flagged (fracture, cut marks, burning). Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get libFilterFlagged;

  /// Heading over finds saved today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get libToday;

  /// Heading over finds saved in the last 7 days
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get libThisWeek;

  /// Heading over finds saved in the last 30 days
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get libThisMonth;

  /// Heading over older finds
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get libEarlier;

  /// No description provided for @libEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your stash is empty'**
  String get libEmptyTitle;

  /// Ends on a bone pun; a light joke in your language is welcome
  ///
  /// In en, this message translates to:
  /// **'Every bone you scan lands here with its photo and notes. No bones about it.'**
  String get libEmptyBody;

  /// No description provided for @libNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get libNoMatchTitle;

  /// No description provided for @libNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or clear the search.'**
  String get libNoMatchBody;

  /// Line under the Atlas title
  ///
  /// In en, this message translates to:
  /// **'{count} bones the AI knows by heart'**
  String atlasSubtitle(int count);

  /// Card at the top of the Atlas that opens "How analysis works"
  ///
  /// In en, this message translates to:
  /// **'How the AI thinks'**
  String get atlasHowCardTitle;

  /// No description provided for @atlasHowCardBody.
  ///
  /// In en, this message translates to:
  /// **'The nine passes every photo goes through, and which ones to trust.'**
  String get atlasHowCardBody;

  /// Heading on a bone page, over the list of features
  ///
  /// In en, this message translates to:
  /// **'What to look for'**
  String get atlasLookFor;

  /// Heading on a bone page
  ///
  /// In en, this message translates to:
  /// **'Left or right, and which way up'**
  String get atlasSidingTitle;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'How analysis works'**
  String get howTitle;

  /// No description provided for @howHeading.
  ///
  /// In en, this message translates to:
  /// **'One photo, nine questions'**
  String get howHeading;

  /// No description provided for @howIntro.
  ///
  /// In en, this message translates to:
  /// **'Ossia looks at your photo once and answers nine questions about it at the same time. Each answer comes with how sure it is, so one unsure answer doesn’t spoil the rest.'**
  String get howIntro;

  /// Row in the Language group
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsLanguageFooter.
  ///
  /// In en, this message translates to:
  /// **'You can also switch any time with the globe at the top of each tab.'**
  String get settingsLanguageFooter;

  /// Group heading
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Light or dark look
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme option: follow the phone. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// The app's highlight colour
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsAccent;

  /// Group heading
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get settingsAnalysis;

  /// No description provided for @settingsOnDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Ossia works right on your phone, even with no signal, and your photos stay on your phone.'**
  String get settingsOnDeviceBody;

  /// No description provided for @settingsOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'Photos are sent to the Ossia computer at the address below, and the report comes back to you.'**
  String get settingsOnlineBody;

  /// The web address of the computer that analyses photos online
  ///
  /// In en, this message translates to:
  /// **'Online address'**
  String get settingsOnlineAddress;

  /// No description provided for @settingsOnlineAddressBody.
  ///
  /// In en, this message translates to:
  /// **'Type the address shown on the Ossia computer.'**
  String get settingsOnlineAddressBody;

  /// Row that opens the status screen
  ///
  /// In en, this message translates to:
  /// **'Analyzer status'**
  String get settingsStatus;

  /// No description provided for @settingsStatusSub.
  ///
  /// In en, this message translates to:
  /// **'Is it ready, and is it connected'**
  String get settingsStatusSub;

  /// A percentage: guesses less sure than this are shown faded
  ///
  /// In en, this message translates to:
  /// **'Confidence cutoff'**
  String get settingsCutoff;

  /// No description provided for @settingsCutoffBody.
  ///
  /// In en, this message translates to:
  /// **'Guesses below this are shown faded.'**
  String get settingsCutoffBody;

  /// No description provided for @settingsHideUnlikely.
  ///
  /// In en, this message translates to:
  /// **'Hide unlikely guesses'**
  String get settingsHideUnlikely;

  /// No description provided for @settingsHideUnlikelyBody.
  ///
  /// In en, this message translates to:
  /// **'Only show other possible bones when they are above the cutoff.'**
  String get settingsHideUnlikelyBody;

  /// Group heading
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get settingsCapture;

  /// No description provided for @settingsAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Save analyses automatically'**
  String get settingsAutoSave;

  /// No description provided for @settingsAutoSaveBody.
  ///
  /// In en, this message translates to:
  /// **'Off means each report is kept only if you save it.'**
  String get settingsAutoSaveBody;

  /// Settings switch for the automatic camera photo
  ///
  /// In en, this message translates to:
  /// **'Auto snap'**
  String get settingsAutoSnap;

  /// Explains the auto snap switch
  ///
  /// In en, this message translates to:
  /// **'The camera takes the photo by itself once it sees a bone and the phone is still.'**
  String get settingsAutoSnapBody;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Measurement units'**
  String get settingsUnits;

  /// Little vibrations when tapping
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHaptics;

  /// Group heading; it is the same thing as the Stash tab
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrary;

  /// No description provided for @settingsSavedCount.
  ///
  /// In en, this message translates to:
  /// **'Saved analyses'**
  String get settingsSavedCount;

  /// No description provided for @settingsCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all reports'**
  String get settingsCopyAll;

  /// No description provided for @settingsCopiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report copied} other{{count} reports copied}}'**
  String settingsCopiedCount(int count);

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all analyses'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get settingsDeleteAllTitle;

  /// No description provided for @settingsDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The saved analysis and its photographs are removed from this device. This cannot be undone.} other{All {count} saved analyses and their photographs are removed from this device. This cannot be undone.}}'**
  String settingsDeleteAllBody(int count);

  /// Red button
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get settingsDeleteAllConfirm;

  /// Short message after deleting everything
  ///
  /// In en, this message translates to:
  /// **'Library cleared'**
  String get settingsLibraryCleared;

  /// No description provided for @settingsPrivacyFooter.
  ///
  /// In en, this message translates to:
  /// **'Your reports stay on this phone. Photos are only sent out when you choose Online analysis.'**
  String get settingsPrivacyFooter;

  /// Group heading, and the About screen's title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutOssia.
  ///
  /// In en, this message translates to:
  /// **'About Ossia'**
  String get settingsAboutOssia;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Ossia helps you identify bones. It is not a replacement for an expert looking at the bone in person.'**
  String get settingsDisclaimer;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutIntro.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of a bone and Ossia tells you what it is: which bone, human or animal, which animal, and any marks on it. Every answer shows how sure it is, so you can judge it for yourself.'**
  String get aboutIntro;

  /// Group heading
  ///
  /// In en, this message translates to:
  /// **'What Ossia knows'**
  String get aboutKnows;

  /// No description provided for @aboutKindsOfBone.
  ///
  /// In en, this message translates to:
  /// **'Kinds of bone'**
  String get aboutKindsOfBone;

  /// No description provided for @aboutAnimalGroups.
  ///
  /// In en, this message translates to:
  /// **'Animal groups'**
  String get aboutAnimalGroups;

  /// No description provided for @aboutQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions per photo'**
  String get aboutQuestions;

  /// No description provided for @aboutKnowsFooter.
  ///
  /// In en, this message translates to:
  /// **'Ossia learned from thousands of labelled photos, but some bones and animals had only a few. That is why it always tells you how sure it is.'**
  String get aboutKnowsFooter;

  /// Group heading
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aboutPrivacy;

  /// No description provided for @aboutPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photographs'**
  String get aboutPhotos;

  /// No description provided for @aboutPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone. Only sent out when you choose Online analysis.'**
  String get aboutPhotosBody;

  /// Tracking of how the app is used
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get aboutAnalytics;

  /// No description provided for @aboutAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'None collected.'**
  String get aboutAnalyticsBody;

  /// No description provided for @aboutWarning.
  ///
  /// In en, this message translates to:
  /// **'Results are a best guess, not a final answer. Don’t use them for medical, legal or police decisions without a bone expert checking the bone in person.'**
  String get aboutWarning;

  /// Small label in capitals under a drawing at the top of the status screen. Keep it very short. Under the phone.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get statusYou;

  /// Small label in capitals under a drawing at the top of the status screen. Keep it very short. Under the computer, when online analysis is switched off.
  ///
  /// In en, this message translates to:
  /// **'NAPPING'**
  String get statusNapping;

  /// Small label in capitals under a drawing at the top of the status screen. Keep it very short. When analysing on the phone.
  ///
  /// In en, this message translates to:
  /// **'ALL ON YOUR PHONE'**
  String get statusAllOnPhone;

  /// Milliseconds, in a small bubble
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String msShort(int ms);

  /// When the connection was last checked, e.g. "checked 5 min ago"
  ///
  /// In en, this message translates to:
  /// **'checked {when}'**
  String statusChecked(String when);

  /// Seconds ago, very short
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String secondsAgo(int count);

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Online analysis is answering in {ms} ms. Your scans will be analyzed there.'**
  String statusConnectedBody(String ms);

  /// The reason is one of the connection problems, e.g. "Nothing answered at that address"
  ///
  /// In en, this message translates to:
  /// **'{reason}. Check the address, and that the Ossia computer is switched on.'**
  String statusOfflineBody(String reason);

  /// No description provided for @statusNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get statusNoAnswer;

  /// No description provided for @statusFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t get ready'**
  String get statusFailedTitle;

  /// No description provided for @statusFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Something stopped Ossia from starting on this phone. Try again, or restart the app.'**
  String get statusFailedBody;

  /// No description provided for @statusOnPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing on this phone'**
  String get statusOnPhoneTitle;

  /// No description provided for @statusOnPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Works anywhere, even with no signal, and your photos never leave your phone.'**
  String get statusOnPhoneBody;

  /// No description provided for @statusConnectingBody.
  ///
  /// In en, this message translates to:
  /// **'Checking that online analysis is awake.'**
  String get statusConnectingBody;

  /// Button while a check runs
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get statusChecking;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get statusCheckNow;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Change address'**
  String get statusChangeAddress;

  /// Tile label; the value under it is e.g. "2h 5m"
  ///
  /// In en, this message translates to:
  /// **'Running for'**
  String get statusRunningFor;

  /// No description provided for @statusHistory.
  ///
  /// In en, this message translates to:
  /// **'Connection history'**
  String get statusHistory;

  /// No description provided for @statusAutoPaused.
  ///
  /// In en, this message translates to:
  /// **'auto-check paused'**
  String get statusAutoPaused;

  /// Countdown to the next automatic check
  ///
  /// In en, this message translates to:
  /// **'next in {seconds}s'**
  String statusNextIn(int seconds);

  /// No description provided for @statusNoChecks.
  ///
  /// In en, this message translates to:
  /// **'No checks yet'**
  String get statusNoChecks;

  /// The number is always 30
  ///
  /// In en, this message translates to:
  /// **'Checked every {seconds}s while the app is open. Shorter bars mean a faster connection.'**
  String statusHistoryFooter(int seconds);

  /// No description provided for @statusRow.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusRow;

  /// No description provided for @statusWakesUp.
  ///
  /// In en, this message translates to:
  /// **'Wakes up on your first scan'**
  String get statusWakesUp;

  /// No description provided for @statusSleeping.
  ///
  /// In en, this message translates to:
  /// **'Sleeping'**
  String get statusSleeping;

  /// No description provided for @statusGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get statusGettingReady;

  /// No description provided for @statusCouldntStart.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start'**
  String get statusCouldntStart;

  /// No description provided for @statusInternetNeeded.
  ///
  /// In en, this message translates to:
  /// **'Internet needed'**
  String get statusInternetNeeded;

  /// No description provided for @statusNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get statusNo;

  /// No description provided for @statusPhotosSent.
  ///
  /// In en, this message translates to:
  /// **'Photos sent anywhere'**
  String get statusPhotosSent;

  /// No description provided for @statusNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get statusNever;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Get it ready now'**
  String get statusGetReady;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
