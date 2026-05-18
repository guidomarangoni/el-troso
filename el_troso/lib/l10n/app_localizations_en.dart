// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'El Troso';

  @override
  String get appTagline =>
      'The path of your memories stays alive when you walk it again.';

  @override
  String get onbStart => 'Start';

  @override
  String onbStepLabel(int current, int total) {
    return '$current of $total';
  }

  @override
  String get onbBack => 'Back';

  @override
  String get onbNameQ => 'What\'s your name?';

  @override
  String get onbNameHint => 'Your name';

  @override
  String get onbNameNext => 'Next';

  @override
  String get onbVocativeQ => 'And what should I call you?';

  @override
  String get onbVocativeName => 'Use my name';

  @override
  String get onbVocativeFormal => 'Sir / Madam';

  @override
  String get onbVocativeFormalValue => 'Sir';

  @override
  String get onbVocativeFamily => 'Grandpa / Grandma';

  @override
  String get onbVocativeFamilyValue => 'Grandpa';

  @override
  String get onbVocativeOther => 'Other...';

  @override
  String get onbVocativeCustomHint => 'How should I call you';

  @override
  String get onbDecadeQ => 'What decade were you born in?';

  @override
  String get onbDecadeOptional => 'You don\'t have to say.';

  @override
  String onbDecadeLabel(String shortYear) {
    return '${shortYear}s';
  }

  @override
  String get onbDecadeSkip => 'Skip';

  @override
  String get onbDone => 'All set';

  @override
  String homeGreeting(String name) {
    return 'Hi $name,';
  }

  @override
  String get homeRecordCta => 'Tell';

  @override
  String get homeWalkCta => 'Walk';

  @override
  String get homeAskCta => 'Ask a question';

  @override
  String get recordPromptQ => 'What would you like to tell me?';

  @override
  String get recordMicCta => 'Tap to speak';

  @override
  String get recordSaveCta => 'Keep it';

  @override
  String recordCharCounter(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n characters left',
      one: '1 character left',
    );
    return '$_temp0';
  }

  @override
  String get recordCharLimitReached =>
      'You\'ve reached the limit. Try to be more concise.';

  @override
  String get recordSavedLabel =>
      'I\'ve kept your memory safe. Your path is more alive now.';

  @override
  String get recordFollowupIntro => 'One more detail if you\'d like:';

  @override
  String get recordTagPrompt => 'What is this memory about?';

  @override
  String get tagFamily => 'Family';

  @override
  String get tagWork => 'Work';

  @override
  String get tagTravel => 'Travel';

  @override
  String get tagHome => 'Home';

  @override
  String get tagOther => 'Other';

  @override
  String get walkerChipTellQ => 'Who\'s telling it?';

  @override
  String get walkerChipWalkQ => 'Who\'s walking it?';

  @override
  String walkerGiorgio(String name) {
    return '$name';
  }

  @override
  String get walkerChild => 'Son / daughter';

  @override
  String get walkerGrandchild => 'A grandchild';

  @override
  String get walkerFriend => 'A friend';

  @override
  String get walkCtaLabel => 'Let\'s walk it again, together';

  @override
  String get walkDoneLabel => 'The path is alive again.';

  @override
  String get fadingEmptyState => 'Something is fading. Want to go back?';

  @override
  String get askPromptQ => 'What would you like to ask?';

  @override
  String get askListening => 'Listening...';

  @override
  String get sourceChipLabel => 'I used this memory';

  @override
  String get askTitle => 'Ask a question';

  @override
  String get askSubmitCta => 'Ask';

  @override
  String get askMicTooltip => 'Tap to dictate your question';

  @override
  String get askRetrievingLabel => 'Looking through your memories...';

  @override
  String get askThinkingLabel => 'Thinking...';

  @override
  String get askSourcesHeader => 'I used these memories:';

  @override
  String get askNoMatchBody =>
      'I couldn\'t find any memories about this. Try telling a related one first, then ask again.';

  @override
  String get ragFallback => 'I don\'t remember well.';

  @override
  String get errorTechnical => 'I paused for a moment. Shall we try again?';

  @override
  String get noMemoriesYet => 'No memories yet. Start by telling one.';

  @override
  String get pathBeginsHere => 'Your path begins here. Take the first step.';

  @override
  String get memoriesHeader => 'Your memories';

  @override
  String get memoriesLoadError => 'Something went wrong reading your memories.';

  @override
  String get memoryDateToday => 'today';

  @override
  String get memoryDateYesterday => 'yesterday';

  @override
  String memoryDateDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String memoryDateWeeksAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String memoryDateMonthsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String memoryDateYearsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get memoryDetailTitle => 'Memory';

  @override
  String get memoryDetailNotFound => 'I can\'t find this memory.';

  @override
  String get walkInProgressLabel => 'Walking it again...';

  @override
  String get walkStopCta => 'Stop';

  @override
  String get walkBackHomeCta => 'Back to the path';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsRestart => 'Start the path over';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageIt => 'Italiano';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get playgroundTitle => 'Playground (dev)';

  @override
  String get playgroundDescription =>
      'Internal test panel. Not visible to end users.';

  @override
  String get memoryDeleteTitle => 'Forget this memory?';

  @override
  String get memoryDeleteBody =>
      'If you do, we won\'t be able to walk it together anymore. Are you sure?';

  @override
  String get memoryDeleteCancel => 'No, keep it';

  @override
  String get memoryDeleteConfirm => 'Yes, forget it';

  @override
  String get recordAddPhoto => 'Add photo';

  @override
  String get recordPhotoCamera => 'Take a photo';

  @override
  String get recordPhotoGallery => 'Choose from gallery';

  @override
  String get recordDescribingImage => 'Looking at the photo...';

  @override
  String get recordImageAdded => 'Photo added';

  @override
  String get recordAudio => 'Record audio';

  @override
  String get recordStopAudio => 'Stop recording';

  @override
  String get recordTranscribing => 'Transcribing...';

  @override
  String get recordAudioAdded => 'Audio added';

  @override
  String get recordAudioReady => 'Original audio saved';

  @override
  String get carouselWelcomeTitle => 'El Troso';

  @override
  String get carouselWelcomeBody =>
      'The path of your memories\nstays alive when you walk it again.';

  @override
  String get carouselWelcomeCta => 'Start the trail';

  @override
  String get carouselCompanionTitle => 'A companion for your memories';

  @override
  String get carouselCompanionBody =>
      'Tell what you want to remember — by voice, with words, or with a photo.\nEl Troso will keep it safe for you.';

  @override
  String get carouselRecordTitle => 'Tell me a memory';

  @override
  String get carouselRecordBody =>
      'Speak, write, or take a photo.\nI listen and remember everything for you.';

  @override
  String get carouselRediscoverTitle => 'Walk the trail again';

  @override
  String get carouselRediscoverBody =>
      'Whenever you want, just ask.\nI\'ll read your memories back to you,\nin your voice and your words.';

  @override
  String get carouselPrivacyTitle => 'Everything stays here, with you';

  @override
  String get carouselPrivacyBody =>
      'No data leaves your phone.\nYour memories are yours alone —\nEl Troso works without the internet.';

  @override
  String get carouselPrivacyCta => 'I\'m ready';

  @override
  String get carouselSkip => 'Skip';

  @override
  String get carouselNext => 'Next';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerRecord => 'Tell a memory';

  @override
  String get drawerAsk => 'Ask a question';

  @override
  String get drawerOnboarding => 'How it works';

  @override
  String get drawerPlayground => 'Playground (dev)';

  @override
  String get drawerLanguage => 'Language';

  @override
  String get memoryTranslateCta => 'Translate';

  @override
  String get memoryTranslating => 'Translating…';

  @override
  String get memoryTranslationLabel => 'Translation';

  @override
  String get memoryTranslateError =>
      'Couldn\'t translate. Try again in a moment.';

  @override
  String get memoryTranslateRedoCta => 'Translate again';

  @override
  String get recordExitTitle => 'Leave?';

  @override
  String get recordExitBody => 'Your memory won\'t be saved.';

  @override
  String get recordExitConfirm => 'Yes, leave';

  @override
  String get recordExitCancel => 'No, stay';

  @override
  String get homeWalkSection => 'Walk the path';

  @override
  String get homeTrainSection => 'Train your memory';

  @override
  String get homeSubGreetingWithToday =>
      'there\'s a memory worth walking again today.';

  @override
  String get homeSubGreetingNoToday =>
      'the path is all fresh. Tell me something, if you like.';

  @override
  String get homeYourMemories => 'Your memories';

  @override
  String get homeGamesCta => 'Play';

  @override
  String get homeAppBarGamesTooltip => 'Train your memory';

  @override
  String get homeAppBarAskTooltip => 'Ask a question';

  @override
  String get homeGamesPickerTitle => 'Train your memory';

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeTodayBody => 'There\'s a memory worth walking again today.';

  @override
  String get homeTodayCta => 'Walk it now';

  @override
  String get gameRecognizeTitle => 'Recognize and tell';

  @override
  String get gameRecognizeShort => 'A photo, a story';

  @override
  String get gamePhotoMatchTitle => 'Photo memory';

  @override
  String get gamePhotoMatchShort => 'Find the pairs';

  @override
  String homeMemoriesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n memories in the path',
      one: '1 memory in the path',
      zero: 'No memories yet',
    );
    return '$_temp0';
  }

  @override
  String homeFadingCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n are fading',
      one: 'One is fading',
    );
    return '$_temp0';
  }

  @override
  String get recognizePromptQ =>
      'Do you recognize this photo? Tell me what you remember.';

  @override
  String get recognizeStartCta => 'Start telling';

  @override
  String get recognizeRetryCta => 'Tell again';

  @override
  String get recognizeStopCta => 'I\'m done';

  @override
  String get recognizeSendCta => 'Let\'s see what it thinks';

  @override
  String get recognizeAnotherCta => 'Another photo';

  @override
  String get recognizeTypeHint => 'Type here, or tap the microphone';

  @override
  String get gameGuessTitle => 'Guess together';

  @override
  String get gameGuessShort => 'One question, one answer';

  @override
  String get gameGuessGenerating => 'I\'m thinking of a question…';

  @override
  String get gameGuessAnswerHint => 'Type your answer, or tap the microphone';

  @override
  String get gameGuessSpeakCta => 'Answer with voice';

  @override
  String get gameGuessSendCta => 'Let\'s see';

  @override
  String get gameGuessAnotherCta => 'Another question';

  @override
  String get gameGuessEmptyBody =>
      'To play you need a few memories. Add some richer memories and come back.';

  @override
  String get guessInfoTitle => 'Guess together';

  @override
  String get guessInfoWhat =>
      'The app asks you a specific question about one of your memories (a year, a place, a person, an event). You answer with voice or text, then you hear the right answer taken from the memory.';

  @override
  String get guessInfoWhy =>
      'Answering a specific question is active recall: memory consolidates better when you interrogate it rather than rereading passively. Spaced Retrieval Training, validated by RCTs in people with mild cognitive impairment, is exactly this — short question, answer, warm feedback. No scores, no underlined mistakes: if the answer isn\'t there, the app gently brings you back to the fact.';

  @override
  String get guessInfoSource1Label =>
      'USMART RCT (2017) — tablet-based spaced retrieval training in MCI';

  @override
  String get guessInfoSource1Url => 'https://doi.org/10.1186/s13195-017-0290-6';

  @override
  String get guessInfoSource2Label =>
      'Roediger & Karpicke (2006) — testing effect, remember by asking';

  @override
  String get guessInfoSource2Url =>
      'https://doi.org/10.1111/j.1467-9280.2006.01693.x';

  @override
  String get gameStoryTitle => 'Continue the story';

  @override
  String get gameStoryShort => 'You finish it';

  @override
  String get gameStoryPrompt => '…and then what happened?';

  @override
  String get gameStoryContinueHint =>
      'You continue the memory… (speak or type)';

  @override
  String get gameStorySendCta => 'Let\'s see how it goes';

  @override
  String get gameStoryAnotherCta => 'Another memory';

  @override
  String get gameStoryFullMemoryLabel => 'The full memory';

  @override
  String get gameStoryEmptyBody =>
      'To play you need memories that are a bit long (at least two sentences). Add a richer memory and come back.';

  @override
  String get storyInfoTitle => 'Continue the story';

  @override
  String get storyInfoWhat =>
      'The app reads aloud the first sentences of one of your memories, then asks you to continue it. You tell how you think it went, and the app gives you warm feedback comparing with the original memory. At the end you see the full memory.';

  @override
  String get storyInfoWhy =>
      'Continuing a memory aloud from a narrative cue is the closest thing to how autobiographical memory naturally unfolds: not a closed quiz, but a story that unrolls. Guided narrative stimulation has shown benefits on episodic autobiographical memory in people with mild cognitive impairment, especially when the material is personal.';

  @override
  String get storyInfoSource1Label =>
      'Cotelli et al. (2012) — narrative cognitive rehabilitation in MCI/AD';

  @override
  String get storyInfoSource1Url => 'https://pubmed.ncbi.nlm.nih.gov/22466023/';

  @override
  String get storyInfoSource2Label =>
      'Woods et al., Cochrane Review (2018) — reminiscence therapy in dementia';

  @override
  String get storyInfoSource2Url =>
      'https://doi.org/10.1002/14651858.CD001120.pub3';

  @override
  String get recognizeNoPhotosBody =>
      'To play you need memories with a photo. Add a photo to a memory first, then come back here.';

  @override
  String photoMatchPairs(int found, int total) {
    return '$found of $total pairs';
  }

  @override
  String photoMatchMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String get photoMatchWonTitle => 'Path retraced';

  @override
  String photoMatchWonBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'You found all pairs in $n moves.',
      one: 'You found all pairs in 1 move.',
    );
    return '$_temp0';
  }

  @override
  String get photoMatchRetryCta => 'Play again';

  @override
  String get photoMatchNotEnoughBody =>
      'To play you need at least six memories with a photo. Tell a few more memories, then come back.';

  @override
  String photoMatchWonTtsWithName(String name) {
    return 'Well done $name, you\'ve found all the pairs. The footprints of these memories shine again.';
  }

  @override
  String get photoMatchWonTtsNoName =>
      'Well done, you\'ve found all the pairs. The footprints of these memories shine again.';

  @override
  String get legendFresh => 'just walked';

  @override
  String get legendFading => 'fading';

  @override
  String get legendGhost => 'almost forgotten';

  @override
  String get walkConfirmedTitle => 'You walked this memory';

  @override
  String get walkConfirmedBody => 'The footprints brighten again.';

  @override
  String get onbSeedTitle => 'Want to start with a book of memories?';

  @override
  String get onbSeedBody =>
      'These are the memories of Giorgio, 86 years old, who told his life to his grandchildren in a book. You can look through them, walk them again, and delete them whenever you want to start your own path.';

  @override
  String get onbSeedCtaYes => 'Yes, show me';

  @override
  String get onbSeedCtaNo => 'No, I\'ll start fresh';

  @override
  String get onbSeedLoading => 'Preparing Giorgio\'s memories...';

  @override
  String get modelLoadingTitle => 'Preparing the path...';

  @override
  String get modelLoadingBody =>
      'Everything stays on your phone. Nothing leaves.';

  @override
  String get gameInfoWhatTitle => 'What it is';

  @override
  String get gameInfoWhyTitle => 'Why it works';

  @override
  String get gameInfoSourcesTitle => 'Sources';

  @override
  String get gameInfoCloseCta => 'Got it';

  @override
  String get recognizeInfoTitle => 'Recognize and tell';

  @override
  String get recognizeInfoWhat =>
      'You see a photo from your album and you say out loud what you remember. There\'s no right or wrong answer: what matters is that your voice goes back to the memory. At the end the app gives you a small recap of what you said.';

  @override
  String get recognizeInfoWhy =>
      'Putting a memory back into words while looking at a familiar cue is the core of reminiscence therapy: a one-to-one conversation between a person and their own memory, mediated here by the app instead of a relative. Cochrane reviews show small but consistent benefits on mood, cognition and quality of life — especially when the cue is autobiographical, not generic.';

  @override
  String get recognizeInfoSource1Label =>
      'Woods et al., Cochrane Review (2018) — reminiscence therapy in dementia';

  @override
  String get recognizeInfoSource1Url =>
      'https://doi.org/10.1002/14651858.CD001120.pub3';

  @override
  String get recognizeInfoSource2Label =>
      'Berry et al. (2014) — SenseCam and autobiographical memory';

  @override
  String get recognizeInfoSource2Url =>
      'https://pubmed.ncbi.nlm.nih.gov/16194452/';

  @override
  String get photoMatchInfoTitle => 'Photo memory';

  @override
  String get photoMatchInfoWhat =>
      'A classic memory game: 6 face-down pairs of photos, you flip two cards at a time until you\'ve matched them all. The photos come from your own album — not generic icons but faces, places and moments you already know.';

  @override
  String get photoMatchInfoWhy =>
      'Visual recognition memory is relatively preserved even in mild cognitive impairment, and serious games built on personalized autobiographical material are a stronger emotional engager than a generic memory game. No magic: it\'s about spending some active time inside your own photos.';

  @override
  String get photoMatchInfoSource1Label =>
      'JMIR Serious Games (2024) — meta-analysis of cognitive games in MCI/AD';

  @override
  String get photoMatchInfoSource1Url => 'https://games.jmir.org/2024/1/e55785';

  @override
  String get homeTodayInfoTitle => 'Today';

  @override
  String get homeTodayInfoWhat =>
      'Every day the app picks a memory you haven\'t walked in a while and shows it at the top of the home. If you open it and walk it again, its \"footprints\" brighten and the app waits longer before suggesting it again. If you leave it, it comes back sooner.';

  @override
  String get homeTodayInfoWhy =>
      'It\'s called Spaced Retrieval Training: refreshing a piece of information at intervals that grow over time (1, 3, 7, 14, 30 days) is one of the non-pharmacological techniques with the strongest evidence for memory in mild cognitive impairment and mild dementia. It works best when the material is personal and when the interval adapts to how recall is going.';

  @override
  String get homeTodayInfoSource1Label =>
      'Hopper et al. (2013) — review of spaced-retrieval interventions';

  @override
  String get homeTodayInfoSource1Url =>
      'https://pubmed.ncbi.nlm.nih.gov/23886395/';

  @override
  String get homeTodayInfoSource2Label =>
      'USMART RCT (2017) — tablet-based SRT in MCI patients';

  @override
  String get homeTodayInfoSource2Url =>
      'https://doi.org/10.1186/s13195-017-0290-6';
}
