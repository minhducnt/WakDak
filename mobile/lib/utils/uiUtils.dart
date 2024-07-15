import 'package:flutter/material.dart';
import 'package:wakDak/app/appLocalization.dart';
import 'package:wakDak/ui/styles/color.dart';

class UiUtils {
  static void setSnackBar(String msg, BuildContext context, bool showAction,
      {Function? onPressedAction, Duration? duration, required String type}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: showAction ? TextAlign.start : TextAlign.start,
          maxLines: 3,
          style: const TextStyle(
            color: white,
            fontSize: 12.0,
            fontWeight: FontWeight.normal,
          )),
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 2),
      backgroundColor: type == "1"
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.error,
      action: showAction
          ? SnackBarAction(
              label: "Retry",
              onPressed: onPressedAction as void Function(),
              textColor: white,
            )
          : null,
      elevation: 2.0,
    ));
  }

  static Locale getLocaleFromLanguageCode(String languageCode) {
    List<String> result = languageCode.split("-");
    return result.length == 1
        ? Locale(result.first)
        : Locale(result.first, result.last);
  }

  static String getTranslatedLabel(BuildContext context, String labelKey) {
    return (AppLocalization.of(context)!.getTranslatedValues(labelKey) ??
            labelKey)
        .trim();
  }

  static String? validatePass(String value, String? msg1, String? msg2) {
    if (value.isEmpty) {
      return msg1;
    }
    return value.length <= 5 ? msg2 : null;
  }

  static String? validateEmail(String value, String? msg1, String? msg2) {
    if (value.isEmpty) {
      return msg1;
    } else if (!RegExp(
            r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)"
            r"*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+"
            r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
        .hasMatch(value)) {
      return msg2;
    } else {
      return null;
    }
  }
}
