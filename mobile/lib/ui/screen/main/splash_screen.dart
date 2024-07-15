import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/screen/settings/no_location_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  late double width, height;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  @override
  initState() {
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
            context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
          }));
    });
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    super.initState();
  }

  void navigateToNextScreen() async {
    //Reading from settingsCubit means we are just reading current value of settingsCubit
    //if settingsCubit will change in future it will not rebuild it's child
    final currentSettings = context.read<SettingsCubit>().state.settingsModel;
    //final currentAuthState = context.read<AuthCubit>().state;
    if (currentSettings!.showIntroSlider) {
      Navigator.of(context).pushReplacementNamed(Routes.introSlider);
    } else {
      if (currentSettings.skip) {
        Navigator.of(context).pushReplacementNamed(Routes.login, arguments: {'from': "splash"});
      } else {
        if (currentSettings.city.toString() != "" && currentSettings.city.toString() != "null") {
          Navigator.of(context).pushReplacementNamed(Routes.home);
        } else {
          await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (BuildContext context) => const NoLocationScreen(),
              ),
              (Route<dynamic> route) => false);
        }
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : BlocConsumer<SystemConfigCubit, SystemConfigState>(
              bloc: context.read<SystemConfigCubit>(),
              listener: (context, state) {
                if (state is SystemConfigFetchSuccess) {
                  navigateToNextScreen();
                }
                if (state is SystemConfigFetchFailure) {
                  print(state.errorCode);
                }
              },
              builder: (context, state) {
                if (state is SystemConfigFetchFailure) {
                  const SizedBox.shrink();
                }

                return Scaffold(
                    backgroundColor: splashBackgroundColor,
                    body: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: SvgPicture.asset(DesignConfig.setSvgPath("splash_logo")),
                      ),
                    ));
              }),
    );
  }
}
