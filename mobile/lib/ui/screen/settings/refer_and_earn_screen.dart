import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/styles/dotted_border.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({Key? key}) : super(key: key);

  @override
  ReferAndEarnScreenState createState() => ReferAndEarnScreenState();
}

class ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : Scaffold(
              appBar: DesignConfig.appBar(context, width, UiUtils.getTranslatedLabel(context, referralAndEarnCodeLabel),
                  const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
              bottomNavigationBar: context.read<SystemConfigCubit>().getReferCode().isEmpty
                  ? const SizedBox()
                  : ButtonContainer(
                      color: Theme.of(context).colorScheme.onPrimary,
                      height: height,
                      width: width,
                      text: UiUtils.getTranslatedLabel(context, shareAppLabel),
                      start: width / 40.0,
                      end: width / 40.0,
                      bottom: height / 55.0,
                      top: 0,
                      status: false,
                      borderColor: Theme.of(context).colorScheme.onPrimary,
                      textColor: white,
                      onPressed: () {
                        var str =
                            "$appName\nRefer Code:${context.read<SystemConfigCubit>().getReferCode()}\n${UiUtils.getTranslatedLabel(context, appFindLabel)}$androidLink$packageName\n\n${UiUtils.getTranslatedLabel(context, iosLabel)}\n$iosLink$iosPackage";
                        Share.share(str);
                      },
                    ),
              body: Container(
                margin: EdgeInsetsDirectional.only(top: height / 80.0),
                decoration: DesignConfig.boxDecorationContainerHalf(Theme.of(context).colorScheme.onBackground),
                width: width,
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsetsDirectional.only(start: width / 20.0, end: width / 20.0, top: height / 99.0),
                  width: width,
                  child: SingleChildScrollView(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                      SvgPicture.asset(
                        DesignConfig.setSvgPath("refer_and_earn"),
                        height: height / 3.0,
                        width: height / 3.0,
                        fit: BoxFit.scaleDown,
                      ),
                      SizedBox(height: height / 25.0),
                      Text(UiUtils.getTranslatedLabel(context, referralAndEarnCodeLabel),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.39)),
                      SizedBox(height: height / 80.0),
                      Text(UiUtils.getTranslatedLabel(context, referralAndEarnCodeSubTitleLabel),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.39)),
                      SizedBox(height: height / 55.0),
                      Text(UiUtils.getTranslatedLabel(context, yourCodeLabel),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, letterSpacing: -0.21, fontWeight: FontWeight.w600)),
                      context.read<SystemConfigCubit>().getReferCode().isEmpty
                          ? const SizedBox()
                          : InkWell(
                              child: Container(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.10),
                                  margin: EdgeInsetsDirectional.only(start: width / 60.0, top: height / 80.0),
                                  child: DottedBorder(
                                      color: Theme.of(context).colorScheme.secondary,
                                      dashPattern: const [8, 4],
                                      padding: const EdgeInsets.all(8),
                                      strokeWidth: 1,
                                      strokeCap: StrokeCap.round,
                                      borderType: BorderType.RRect,
                                      radius: const Radius.circular(5.0),
                                      child: Text(context.read<SystemConfigCubit>().getReferCode(),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                                color: Theme.of(context).colorScheme.secondary,
                                              )))),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: context.read<SystemConfigCubit>().getReferCode()));
                                UiUtils.setSnackBar(StringsRes.refercodeCopiedToClipboard, context, false, type: "1");
                              },
                            ),
                    ]),
                  ),
                ),
              )),
    );
  }
}
