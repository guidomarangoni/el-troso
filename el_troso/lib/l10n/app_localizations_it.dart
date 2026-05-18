// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'El Troso';

  @override
  String get appTagline =>
      'Il sentiero dei tuoi ricordi resta vivo se lo ripercorri.';

  @override
  String get onbStart => 'Comincia';

  @override
  String onbStepLabel(int current, int total) {
    return '$current di $total';
  }

  @override
  String get onbBack => 'Indietro';

  @override
  String get onbNameQ => 'Come ti chiami?';

  @override
  String get onbNameHint => 'Il tuo nome';

  @override
  String get onbNameNext => 'Avanti';

  @override
  String get onbVocativeQ => 'E come vuoi che ti chiami?';

  @override
  String get onbVocativeName => 'Usa il mio nome';

  @override
  String get onbVocativeFormal => 'Signore / Signora';

  @override
  String get onbVocativeFormalValue => 'Signore';

  @override
  String get onbVocativeFamily => 'Nonno / Nonna';

  @override
  String get onbVocativeFamilyValue => 'Nonno';

  @override
  String get onbVocativeOther => 'Altro...';

  @override
  String get onbVocativeCustomHint => 'Come vuoi essere chiamato';

  @override
  String get onbDecadeQ => 'In che decennio sei nato/a?';

  @override
  String get onbDecadeOptional => 'Puoi anche non dirlo.';

  @override
  String onbDecadeLabel(String shortYear) {
    return 'Anni $shortYear';
  }

  @override
  String get onbDecadeSkip => 'Salta';

  @override
  String get onbDone => 'Ecco fatto';

  @override
  String homeGreeting(String name) {
    return 'Ciao $name,';
  }

  @override
  String get homeRecordCta => 'Racconta';

  @override
  String get homeWalkCta => 'Ripercorri';

  @override
  String get homeAskCta => 'Fai una domanda';

  @override
  String get recordPromptQ => 'Cosa vuoi raccontarmi?';

  @override
  String get recordMicCta => 'Tocca per parlare';

  @override
  String get recordSaveCta => 'Custodisci';

  @override
  String recordCharCounter(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n caratteri rimasti',
      one: '1 carattere rimasto',
    );
    return '$_temp0';
  }

  @override
  String get recordCharLimitReached =>
      'Hai raggiunto il limite. Prova a sintetizzare in meno parole.';

  @override
  String get recordSavedLabel =>
      'Ho custodito il tuo ricordo. Ora il tuo sentiero e\' piu\' vivo.';

  @override
  String get recordFollowupIntro => 'Un dettaglio in piu\' se ti va:';

  @override
  String get recordTagPrompt => 'Di cosa parla questo ricordo?';

  @override
  String get tagFamily => 'Famiglia';

  @override
  String get tagWork => 'Lavoro';

  @override
  String get tagTravel => 'Viaggi';

  @override
  String get tagHome => 'Casa';

  @override
  String get tagOther => 'Altro';

  @override
  String get walkerChipTellQ => 'Chi sta raccontando?';

  @override
  String get walkerChipWalkQ => 'Chi lo sta calpestando?';

  @override
  String walkerGiorgio(String name) {
    return '$name';
  }

  @override
  String get walkerChild => 'Il figlio / la figlia';

  @override
  String get walkerGrandchild => 'Un nipote';

  @override
  String get walkerFriend => 'Un amico';

  @override
  String get walkCtaLabel => 'Ripercorriamolo insieme';

  @override
  String get walkDoneLabel => 'Il sentiero e\' di nuovo vivo.';

  @override
  String get fadingEmptyState => 'Qualcosa sta sbiadendo. Vuoi tornarci?';

  @override
  String get askPromptQ => 'Cosa vuoi chiedermi?';

  @override
  String get askListening => 'Sto ascoltando...';

  @override
  String get sourceChipLabel => 'Ho usato questo ricordo';

  @override
  String get askTitle => 'Fai una domanda';

  @override
  String get askSubmitCta => 'Chiedi';

  @override
  String get askMicTooltip => 'Tocca per dettare la domanda';

  @override
  String get askRetrievingLabel => 'Sto cercando tra i tuoi ricordi...';

  @override
  String get askThinkingLabel => 'Sto pensando...';

  @override
  String get askSourcesHeader => 'Ho usato questi ricordi:';

  @override
  String get askNoMatchBody =>
      'Non ho trovato ricordi che parlino di questo. Prova a raccontarne uno correlato e poi chiedimi di nuovo.';

  @override
  String get ragFallback => 'Non mi ricordo bene.';

  @override
  String get errorTechnical => 'Mi sono fermato un momento. Riproviamo?';

  @override
  String get noMemoriesYet =>
      'Ancora nessun ricordo. Comincia raccontandone uno.';

  @override
  String get pathBeginsHere =>
      'Il tuo sentiero inizia qui. Fai il primo passo.';

  @override
  String get memoriesHeader => 'I tuoi ricordi';

  @override
  String get memoriesLoadError =>
      'Qualcosa e\' andato storto nel rileggere i ricordi.';

  @override
  String get memoryDateToday => 'oggi';

  @override
  String get memoryDateYesterday => 'ieri';

  @override
  String memoryDateDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String memoryDateWeeksAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n settimane fa',
      one: '1 settimana fa',
    );
    return '$_temp0';
  }

  @override
  String memoryDateMonthsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mesi fa',
      one: '1 mese fa',
    );
    return '$_temp0';
  }

  @override
  String memoryDateYearsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anni fa',
      one: '1 anno fa',
    );
    return '$_temp0';
  }

  @override
  String get memoryDetailTitle => 'Ricordo';

  @override
  String get memoryDetailNotFound => 'Non riesco a trovare questo ricordo.';

  @override
  String get walkInProgressLabel => 'Sto ripercorrendo...';

  @override
  String get walkStopCta => 'Fermati';

  @override
  String get walkBackHomeCta => 'Torna al sentiero';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsRestart => 'Ricomincia il sentiero';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageIt => 'Italiano';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get playgroundTitle => 'Playground (dev)';

  @override
  String get playgroundDescription =>
      'Pannello di test interno. Non visibile agli utenti finali.';

  @override
  String get memoryDeleteTitle => 'Dimenticare questo ricordo?';

  @override
  String get memoryDeleteBody =>
      'Se lo fai, non potremo più ripercorrerlo insieme. Sei sicuro?';

  @override
  String get memoryDeleteCancel => 'No, tienilo';

  @override
  String get memoryDeleteConfirm => 'Sì, dimenticalo';

  @override
  String get recordAddPhoto => 'Aggiungi foto';

  @override
  String get recordPhotoCamera => 'Scatta una foto';

  @override
  String get recordPhotoGallery => 'Scegli dalla galleria';

  @override
  String get recordDescribingImage => 'Sto guardando la foto...';

  @override
  String get recordImageAdded => 'Foto aggiunta';

  @override
  String get recordAudio => 'Registra audio';

  @override
  String get recordStopAudio => 'Ferma registrazione';

  @override
  String get recordTranscribing => 'Sto trascrivendo...';

  @override
  String get recordAudioAdded => 'Audio aggiunto';

  @override
  String get recordAudioReady => 'Audio originale salvato';

  @override
  String get carouselWelcomeTitle => 'El Troso';

  @override
  String get carouselWelcomeBody =>
      'Il sentiero dei tuoi ricordi\nresta vivo se lo ripercorri.';

  @override
  String get carouselWelcomeCta => 'Comincia il sentiero';

  @override
  String get carouselCompanionTitle => 'Un compagno per i tuoi ricordi';

  @override
  String get carouselCompanionBody =>
      'Racconta quello che vuoi ricordare — a voce, con le parole, o con una foto.\nEl Troso lo custodirà per te.';

  @override
  String get carouselRecordTitle => 'Raccontami un ricordo';

  @override
  String get carouselRecordBody =>
      'Parla, scrivi, o scatta una foto.\nIo ascolto e ricordo tutto al posto tuo.';

  @override
  String get carouselRediscoverTitle => 'Ripercorri il sentiero';

  @override
  String get carouselRediscoverBody =>
      'Quando vuoi, chiedi.\nIo ti rileggo i tuoi ricordi,\ncon la tua voce e le tue parole.';

  @override
  String get carouselPrivacyTitle => 'Tutto resta qui, con te';

  @override
  String get carouselPrivacyBody =>
      'Nessun dato esce dal tuo telefono.\nI tuoi ricordi sono solo tuoi —\nEl Troso funziona senza internet.';

  @override
  String get carouselPrivacyCta => 'Sono pronto';

  @override
  String get carouselSkip => 'Salta';

  @override
  String get carouselNext => 'Avanti';

  @override
  String get drawerHome => 'Casa';

  @override
  String get drawerRecord => 'Racconta un ricordo';

  @override
  String get drawerAsk => 'Fai una domanda';

  @override
  String get drawerOnboarding => 'Come funziona';

  @override
  String get drawerPlayground => 'Playground (dev)';

  @override
  String get drawerLanguage => 'Lingua';

  @override
  String get memoryTranslateCta => 'Traduci';

  @override
  String get memoryTranslating => 'Sto traducendo…';

  @override
  String get memoryTranslationLabel => 'Traduzione';

  @override
  String get memoryTranslateError =>
      'Non sono riuscito a tradurre. Riprova tra un momento.';

  @override
  String get memoryTranslateRedoCta => 'Traduci di nuovo';

  @override
  String get recordExitTitle => 'Vuoi uscire?';

  @override
  String get recordExitBody => 'Il ricordo non sarà custodito.';

  @override
  String get recordExitConfirm => 'Sì, esci';

  @override
  String get recordExitCancel => 'No, resta';

  @override
  String get homeWalkSection => 'Cammina sul sentiero';

  @override
  String get homeTrainSection => 'Allena la memoria';

  @override
  String get homeSubGreetingWithToday =>
      'oggi c\'è un ricordo che vale la pena ripercorrere.';

  @override
  String get homeSubGreetingNoToday =>
      'il sentiero è tutto fresco. Se vuoi, raccontami qualcosa.';

  @override
  String get homeYourMemories => 'I tuoi ricordi';

  @override
  String get homeGamesCta => 'Gioca';

  @override
  String get homeAppBarGamesTooltip => 'Allena la memoria';

  @override
  String get homeAppBarAskTooltip => 'Fai una domanda';

  @override
  String get homeGamesPickerTitle => 'Allena la memoria';

  @override
  String get homeTodayTitle => 'Oggi';

  @override
  String get homeTodayBody =>
      'C\'è un ricordo che sarebbe bello ripercorrere oggi.';

  @override
  String get homeTodayCta => 'Ripercorrilo ora';

  @override
  String get gameRecognizeTitle => 'Riconosci e racconta';

  @override
  String get gameRecognizeShort => 'Una foto, una storia';

  @override
  String get gamePhotoMatchTitle => 'Memoria delle foto';

  @override
  String get gamePhotoMatchShort => 'Trova le coppie';

  @override
  String homeMemoriesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ricordi nel sentiero',
      one: '1 ricordo nel sentiero',
      zero: 'Ancora nessun ricordo',
    );
    return '$_temp0';
  }

  @override
  String homeFadingCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stanno sbiadendo',
      one: 'Uno sta sbiadendo',
    );
    return '$_temp0';
  }

  @override
  String get recognizePromptQ =>
      'Riconosci questa foto? Raccontami cosa ricordi.';

  @override
  String get recognizeStartCta => 'Comincia a raccontare';

  @override
  String get recognizeRetryCta => 'Racconta ancora';

  @override
  String get recognizeStopCta => 'Ho finito';

  @override
  String get recognizeSendCta => 'Sentiamo cosa ne pensa';

  @override
  String get recognizeAnotherCta => 'Un\'altra foto';

  @override
  String get recognizeTypeHint => 'Scrivi qui, oppure tappa il microfono';

  @override
  String get gameGuessTitle => 'Indovina insieme';

  @override
  String get gameGuessShort => 'Una domanda, una risposta';

  @override
  String get gameGuessGenerating => 'Sto pensando a una domanda…';

  @override
  String get gameGuessAnswerHint =>
      'Scrivi qui la tua risposta, oppure tappa il microfono';

  @override
  String get gameGuessSpeakCta => 'Rispondi a voce';

  @override
  String get gameGuessSendCta => 'Vediamo';

  @override
  String get gameGuessAnotherCta => 'Un\'altra domanda';

  @override
  String get gameGuessEmptyBody =>
      'Per giocare servono ricordi raccontati. Aggiungi qualche ricordo più ricco e torna qui.';

  @override
  String get guessInfoTitle => 'Indovina insieme';

  @override
  String get guessInfoWhat =>
      'L\'app ti pone una domanda specifica su uno dei tuoi ricordi (un anno, un luogo, una persona, un evento). Tu rispondi a voce o per iscritto, e poi senti la risposta giusta presa dal ricordo.';

  @override
  String get guessInfoWhy =>
      'Rispondere a una domanda specifica è una forma di richiamo attivo: la memoria si consolida meglio interrogandola che rileggendola passivamente. Lo Spaced Retrieval Training, validato da RCT su pazienti con decadimento cognitivo lieve, è proprio questo — domanda breve, risposta, feedback caldo. Niente punteggi, niente errori sottolineati: se la risposta non c\'è, l\'app riporta gentilmente al fatto.';

  @override
  String get guessInfoSource1Label =>
      'USMART RCT (2017) — spaced retrieval training su tablet in MCI';

  @override
  String get guessInfoSource1Url => 'https://doi.org/10.1186/s13195-017-0290-6';

  @override
  String get guessInfoSource2Label =>
      'Roediger & Karpicke (2006) — testing effect, ricordare interrogando';

  @override
  String get guessInfoSource2Url =>
      'https://doi.org/10.1111/j.1467-9280.2006.01693.x';

  @override
  String get gameStoryTitle => 'Storia continua';

  @override
  String get gameStoryShort => 'Continuala tu';

  @override
  String get gameStoryPrompt => '…e poi cosa è successo?';

  @override
  String get gameStoryContinueHint =>
      'Continua tu il ricordo… (parla o scrivi)';

  @override
  String get gameStorySendCta => 'Vediamo come continua';

  @override
  String get gameStoryAnotherCta => 'Un altro ricordo';

  @override
  String get gameStoryFullMemoryLabel => 'Il ricordo completo';

  @override
  String get gameStoryEmptyBody =>
      'Per giocare servono ricordi un po\' lunghi (almeno due frasi). Aggiungi un ricordo più ricco e torna qui.';

  @override
  String get storyInfoTitle => 'Storia continua';

  @override
  String get storyInfoWhat =>
      'L\'app legge a voce le prime frasi di un tuo ricordo, poi ti chiede di continuarlo. Tu racconti come pensi sia andata, e l\'app ti dà un feedback caldo confrontando con il ricordo originale. Alla fine vedi il ricordo per intero.';

  @override
  String get storyInfoWhy =>
      'Continuare a voce un ricordo a partire da un cue narrativo è il modo più simile a come la memoria autobiografica funziona spontaneamente: non un quiz a domande chiuse, ma una storia che si srotola. La stimolazione narrativa guidata ha mostrato benefici sulla memoria episodica autobiografica in pazienti con decadimento lieve, soprattutto quando il materiale è personale.';

  @override
  String get storyInfoSource1Label =>
      'Cotelli et al. (2012) — riabilitazione cognitiva narrativa in MCI/AD';

  @override
  String get storyInfoSource1Url => 'https://pubmed.ncbi.nlm.nih.gov/22466023/';

  @override
  String get storyInfoSource2Label =>
      'Woods et al., Cochrane Review (2018) — reminiscence therapy in demenza';

  @override
  String get storyInfoSource2Url =>
      'https://doi.org/10.1002/14651858.CD001120.pub3';

  @override
  String get recognizeNoPhotosBody =>
      'Per giocare servono ricordi con una foto. Aggiungi prima una foto a un ricordo, poi torna qui.';

  @override
  String photoMatchPairs(int found, int total) {
    return '$found di $total coppie';
  }

  @override
  String photoMatchMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mosse',
      one: '1 mossa',
    );
    return '$_temp0';
  }

  @override
  String get photoMatchWonTitle => 'Sentiero ritrovato';

  @override
  String photoMatchWonBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hai trovato tutte le coppie in $n mosse.',
      one: 'Hai trovato tutte le coppie in 1 mossa.',
    );
    return '$_temp0';
  }

  @override
  String get photoMatchRetryCta => 'Un\'altra partita';

  @override
  String get photoMatchNotEnoughBody =>
      'Per giocare servono almeno sei ricordi con una foto. Racconta qualche ricordo in più e torna qui.';

  @override
  String photoMatchWonTtsWithName(String name) {
    return 'Bravissimo $name, hai ritrovato tutte le coppie. Le orme di questi ricordi tornano luminose.';
  }

  @override
  String get photoMatchWonTtsNoName =>
      'Bravissimo, hai ritrovato tutte le coppie. Le orme di questi ricordi tornano luminose.';

  @override
  String get legendFresh => 'appena calpestato';

  @override
  String get legendFading => 'sta sbiadendo';

  @override
  String get legendGhost => 'quasi dimenticato';

  @override
  String get walkConfirmedTitle => 'Hai ripercorso questo ricordo';

  @override
  String get walkConfirmedBody => 'Le orme tornano luminose.';

  @override
  String get onbSeedTitle => 'Vuoi cominciare con un libro di ricordi?';

  @override
  String get onbSeedBody =>
      'Sono le memorie di Giorgio, 86 anni, che ha raccontato la sua vita ai nipoti in un libro. Puoi guardarle, ripercorrerle, e cancellarle quando vuoi per cominciare il tuo sentiero.';

  @override
  String get onbSeedCtaYes => 'Sì, fammi vedere';

  @override
  String get onbSeedCtaNo => 'No, comincio io';

  @override
  String get onbSeedLoading => 'Sto preparando i ricordi di Giorgio...';

  @override
  String get modelLoadingTitle => 'Sto preparando il sentiero...';

  @override
  String get modelLoadingBody =>
      'Tutto resta nel tuo telefono. Niente esce di qui.';

  @override
  String get gameInfoWhatTitle => 'Di cosa si tratta';

  @override
  String get gameInfoWhyTitle => 'Perché funziona';

  @override
  String get gameInfoSourcesTitle => 'Fonti';

  @override
  String get gameInfoCloseCta => 'Ho capito';

  @override
  String get recognizeInfoTitle => 'Riconosci e racconta';

  @override
  String get recognizeInfoWhat =>
      'Vedi una foto del tuo album e racconti ad alta voce cosa ricordi. Non c\'è una risposta giusta o sbagliata: conta solo che la voce torni sul ricordo. Alla fine l\'app ti restituisce un piccolo riassunto di quello che hai detto.';

  @override
  String get recognizeInfoWhy =>
      'Far tornare a parole un ricordo davanti a uno stimolo familiare è il cuore della reminiscence therapy: una conversazione 1-a-1 tra una persona e un suo ricordo, mediata qui dall\'app invece che da un familiare. Le revisioni Cochrane mostrano benefici piccoli ma costanti su umore, cognizione e qualità della vita — soprattutto quando lo stimolo è autobiografico, non generico.';

  @override
  String get recognizeInfoSource1Label =>
      'Woods et al., Cochrane Review (2018) — reminiscence therapy in demenza';

  @override
  String get recognizeInfoSource1Url =>
      'https://doi.org/10.1002/14651858.CD001120.pub3';

  @override
  String get recognizeInfoSource2Label =>
      'Berry et al. (2014) — SenseCam e memoria autobiografica';

  @override
  String get recognizeInfoSource2Url =>
      'https://pubmed.ncbi.nlm.nih.gov/16194452/';

  @override
  String get photoMatchInfoTitle => 'Memoria delle foto';

  @override
  String get photoMatchInfoWhat =>
      'Un classico memory: 6 coppie di foto coperte, scopri due carte alla volta finché non le hai abbinate tutte. Le foto vengono dal tuo album personale — non sono icone qualunque ma volti, luoghi e momenti che già conosci.';

  @override
  String get photoMatchInfoWhy =>
      'La memoria di riconoscimento visivo resta relativamente conservata anche nel decadimento cognitivo lieve, e i giochi seri costruiti su materiale autobiografico personalizzato sono un ingaggio emotivo più forte di un memory generico. Niente magia: serve a stare un po\' di tempo dentro le proprie foto, in modo attivo.';

  @override
  String get photoMatchInfoSource1Label =>
      'JMIR Serious Games (2024) — meta-analisi giochi cognitivi in MCI/AD';

  @override
  String get photoMatchInfoSource1Url => 'https://games.jmir.org/2024/1/e55785';

  @override
  String get homeTodayInfoTitle => 'Oggi';

  @override
  String get homeTodayInfoWhat =>
      'Ogni giorno l\'app sceglie un ricordo che non ripercorri da un po\' e te lo propone in cima alla home. Se lo apri e lo riascolti, le sue \"orme\" tornano luminose e l\'app aspetta più giorni prima di riproportelo. Se lo lasci stare, torna prima.';

  @override
  String get homeTodayInfoWhy =>
      'Si chiama Spaced Retrieval Training: rinfrescare un\'informazione a intervalli che si allungano nel tempo (1, 3, 7, 14, 30 giorni) è una delle tecniche non-farmacologiche con le prove più solide per la memoria nel decadimento cognitivo lieve e nella demenza lieve. Funziona meglio quando il materiale è personale e quando l\'intervallo si adatta a come va il richiamo.';

  @override
  String get homeTodayInfoSource1Label =>
      'Hopper et al. (2013) — review di interventi spaced-retrieval';

  @override
  String get homeTodayInfoSource1Url =>
      'https://pubmed.ncbi.nlm.nih.gov/23886395/';

  @override
  String get homeTodayInfoSource2Label =>
      'USMART RCT (2017) — SRT su tablet in pazienti MCI';

  @override
  String get homeTodayInfoSource2Url =>
      'https://doi.org/10.1186/s13195-017-0290-6';
}
