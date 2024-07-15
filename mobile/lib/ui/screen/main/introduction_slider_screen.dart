import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/data/model/introduction_slider_model.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class IntroductionSliderScreen extends StatefulWidget {
  const IntroductionSliderScreen({Key? key}) : super(key: key);

  @override
  IntroductionSliderScreenState createState() => IntroductionSliderScreenState();
}

class IntroductionSliderScreenState extends State<IntroductionSliderScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int currentIndex = 0;
  double? height, width;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  double endProgress = 0.05;
  List<IntroductionSliderModel> introductionSliderList = [];

  @override
  void initState() {
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    Future.delayed(const Duration(microseconds: 1000), () {
      introductionData();
    });
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  List<T?> map<T>(List list, Function handler) {
    List<T?> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  void onNext(int index) {
    setState(() {
      if (currentIndex < 2) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  introductionData() {
    introductionSliderList = [
      IntroductionSliderModel(
        id: 1,
        title: UiUtils.getTranslatedLabel(context, introTitle1Label),
        subTitle: UiUtils.getTranslatedLabel(context, introSubTitle1Label),
        image: "intro_1",
      ),
      IntroductionSliderModel(
        id: 2,
        title: UiUtils.getTranslatedLabel(context, introTitle2Label),
        subTitle: UiUtils.getTranslatedLabel(context, introSubTitle2Label),
        image: "intro_2",
      ),
      IntroductionSliderModel(
        id: 1,
        title: UiUtils.getTranslatedLabel(context, introTitle3Label),
        subTitle: UiUtils.getTranslatedLabel(context, introSubTitle3Label),
        image: "intro_3",
      ),
    ];
  }

  Widget _slider() {
    return PageView.builder(
      itemCount: introductionSliderList.length,
      scrollDirection: Axis.horizontal,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsetsDirectional.only(top: height! / 10.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: height! / 1.88,
                padding: EdgeInsetsDirectional.only(bottom: height! / 18.0),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0, right: width! / 24, left: width! / 24,
                      child: Text(
                        introductionSliderList[currentIndex].title!,
                        style: TextStyle(
                            fontSize: 30,
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Positioned(
                      left: 0, right: 0, bottom: height! / 35.0,
                      child: SvgPicture.asset(DesignConfig.setSvgPath(
                          introductionSliderList[index].image!)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(top: height! / 30.0, bottom: height! / 40.0, start: width! / 20.0, end: width! / 20.0),
                child: Text(
                  introductionSliderList[currentIndex].subTitle!,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500, height: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          : SafeArea(bottom: Platform.isIOS? true : false,top: false,
            child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.onBackground,
                bottomNavigationBar: Padding(
                  padding: EdgeInsetsDirectional.only(bottom: height! / 50.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      currentIndex == 2
                          ? const SizedBox.shrink()
                          : ButtonContainer(
                              color: Theme.of(context).colorScheme.onBackground,
                              height: height,
                              width: width,
                              text: UiUtils.getTranslatedLabel(context, skipLabel),
                              top: 0,
                              bottom: 0,
                              start: width! / 40.0,
                              end: width! / 40.0,
                              status: false,
                              borderColor: Theme.of(context).colorScheme.onBackground,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                              onPressed: () {
                                _pageController.jumpToPage(2);
                              },
                            ),
                      const Spacer(),
                      SizedBox(
                        width: width! / 2.2,
                        child: ButtonContainer(
                          color: Theme.of(context).colorScheme.primary,
                          height: height,
                          width: width,
                          text:
                              currentIndex == 2 ? UiUtils.getTranslatedLabel(context, getStartedLabel) : UiUtils.getTranslatedLabel(context, nextLabel),
                          top: 0,
                          bottom: 0,
                          start: width! / 40.0,
                          end: width! / 40.0,
                          status: false,
                          borderColor: Theme.of(context).colorScheme.background,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          onPressed: () {
                            if (currentIndex == 2) {
                              context.read<SettingsCubit>().changeShowIntroSlider();
                              Navigator.of(context).pushReplacementNamed(Routes.login, arguments: {'from': 'splash'});
                            } else {
                              if (currentIndex == 0) {
                                _pageController.jumpToPage(1);
                              } else {
                                _pageController.jumpToPage(2);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                body: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: <Widget>[
                      Container(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), height: height! / 1.6),
                      _slider(),
                    ],
                  ),
                ),
              ),
          ),
    );
  }
}
