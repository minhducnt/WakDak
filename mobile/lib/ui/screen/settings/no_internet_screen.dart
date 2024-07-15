import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class NoInternetScreen extends StatefulWidget {
  final Function? onTapRetry;
  const NoInternetScreen({Key? key, this.onTapRetry}) : super(key: key);

  @override
  NoInternetScreenState createState() => NoInternetScreenState();
}

class NoInternetScreenState extends State<NoInternetScreen> {
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
              body: Container(
              margin: EdgeInsetsDirectional.only(start: width / 10.0, end: width / 10.0, top: height / 5.0),
              width: width,
              child: Column(children: [
                SvgPicture.asset(DesignConfig.setSvgPath("connection_lost")),
                SizedBox(height: height / 20.0),
                Text(
                  UiUtils.getTranslatedLabel(context, noInternetLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 26, fontWeight: FontWeight.w700),
                  maxLines: 2,
                ),
                SizedBox(height: height / 80.0),
                Text(UiUtils.getTranslatedLabel(context, noInternetSubTitleLabel),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 14, fontWeight: FontWeight.w500)),
                InkWell(
                    onTap: () {
                      setState(() {});
                      Future.delayed(const Duration(seconds: 3), () {
                        CheckInternet.initConnectivity();
                        setState(() {});
                      });
                    },
                    child: Container(
                        margin: EdgeInsetsDirectional.only(top: height / 10.0),
                        padding: EdgeInsetsDirectional.only(top: height / 70.0, bottom: 10.0, start: width / 20.0, end: width / 20.0),
                        decoration: DesignConfig.boxDecorationContainerBorder(
                            Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary, 4.0),
                        child: Text(UiUtils.getTranslatedLabel(context, tryAgainLabel),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w500)))),
              ]),
            )),
    );
  }
}
