// El Troso - mappe locale UI → codici per servizi voce (build 42).
//
// La locale UI di Flutter è un `Locale('it')` o `Locale('en')`. STT
// e TTS però vogliono codici BCP 47 con regione esplicita: 'it_IT' /
// 'en_US' per speech_to_text, 'it-IT' / 'en-US' per flutter_tts.
//
// Centralizziamo la mappatura qui per evitare divergenze tra i 6 call
// site STT (record, ask, onboarding, G2, G3, G5) e i ~10 speak() TTS.

import 'package:flutter/material.dart';

/// localeId per `speech_to_text` (`startListening(localeId: ...)`).
/// Default 'it_IT' se la lingua non è gestita.
String sttLocaleId(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return 'en_US';
    case 'it':
    default:
      return 'it_IT';
  }
}

/// Codice lingua per `flutter_tts.setLanguage(...)`.
/// Default 'it-IT' se la lingua non è gestita.
String ttsLanguageCode(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return 'en-US';
    case 'it':
    default:
      return 'it-IT';
  }
}

/// Variante che parte da una stringa codice ISO ('it' / 'en').
/// Usata per parlare un ricordo nella sua `originalLang`.
String ttsLanguageCodeFromIso(String iso) {
  switch (iso) {
    case 'en':
      return 'en-US';
    case 'it':
    default:
      return 'it-IT';
  }
}
