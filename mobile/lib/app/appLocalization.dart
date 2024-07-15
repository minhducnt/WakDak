import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:wakDak/utils/appLanguages.dart';
import 'package:wakDak/utils/uiUtils.dart';

//For localization of app
class AppLocalization {
  final Locale locale;

  // It will hold key of text and it's values in given language
  late Map<String, String> _localizedValues;

  AppLocalization(this.locale);

  // To access app localization instance any where in app using context
  static AppLocalization? of(BuildContext context) {
    return Localizations.of(context, AppLocalization);
  }

  // To load json(language) from assets
  Future loadJson() async {
    String languageJsonName = locale.countryCode == null ? locale.languageCode : "${locale.languageCode}-${locale.countryCode}";
    String jsonStringValues = await rootBundle.loadString('assets/languages/$languageJsonName.json');
    //value from root bundle will be encoded string
    Map<String, dynamic> mappedJson = json.decode(jsonStringValues);

    _localizedValues = mappedJson.map((key, value) => MapEntry(key, value.toString()));
  }

  // To get translated value of given title/key
  String? getTranslatedValues(String? key) {
    return _localizedValues[key!];
  }

  // Need to declare custom delegate
  static const LocalizationsDelegate<AppLocalization> delegate = _AppLocalizationDelegate();
}

// Custom app delegate
class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  // Providing all supported languages
  @override
  bool isSupported(Locale locale) {
    // Checks if the given locale is supported by the application
    return appLanguages
        .map(
          (appLanguage) => UiUtils.getLocaleFromLanguageCode(appLanguage.languageCode),
        )
        .toList()
        .contains(locale);
  }

  // Load languageCode.json files
  @override
  Future<AppLocalization> load(Locale locale) async {
    AppLocalization localization = AppLocalization(locale);
    await localization.loadJson();
    return localization;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) {
    return false;
  }
}
