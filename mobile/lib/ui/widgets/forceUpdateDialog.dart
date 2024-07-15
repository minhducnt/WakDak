import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class ForceUpdateDialog extends StatefulWidget {
  final double? width, height;
  const ForceUpdateDialog({Key? key, required this.width, required this.height}) : super(key: key);

  @override
  _ForceUpdateDialogState createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: DesignConfig.setRounded(16.0),
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding:
              EdgeInsets.only(left: widget.width! / 20.0, top: widget.height! / 40.0, right: widget.width! / 20.0, bottom: widget.height! / 40.0),
          margin: EdgeInsets.only(top: widget.height! / 18.0),
          decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(UiUtils.getTranslatedLabel(context, newVersionAvailableLabel),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(
                height: 15,
              ),
              Text(UiUtils.getTranslatedLabel(context, newVersionAvailableSubTitleLabel),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(
                height: 22,
              ),
              GestureDetector(
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    String url = "";
                    if (Platform.isAndroid) {
                      url = androidLink + packageName;
                    } else {
                      url = iosLink + iosAppId;
                    }
                    if (url.isEmpty) {
                      UiUtils.setSnackBar(StringsRes.failedToGetAppUrl, context, false, type: "1");
                      return;
                    }
                    bool canLaunchUrl = await canLaunchUrlString(url);
                    if (canLaunchUrl) {
                      launchUrlString(url, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    UiUtils.setSnackBar(StringsRes.failedToGetAppUrl, context, false, type: "2");
                  }
                },
                child: Container(
                    margin: EdgeInsetsDirectional.only(top: widget.height! / 99.0, end: widget.width! / 99.0),
                    width: widget.width!,
                    padding: EdgeInsetsDirectional.only(
                      top: widget.height! / 99.0,
                      bottom: widget.height! / 99.0,
                    ),
                    decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary.withOpacity(0.11), 4.0),
                    child: Text(UiUtils.getTranslatedLabel(context, yesLabel),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w600))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
