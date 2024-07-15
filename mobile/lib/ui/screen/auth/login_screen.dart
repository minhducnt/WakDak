import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
//import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:location_geocoder/location_geocoder.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/auth/referAndEarnCubit.dart';
import 'package:wakDak/cubit/auth/socialSignUpCubit.dart';
import 'package:wakDak/cubit/cart/manageCartCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/ui/screen/auth/otp_verify_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/screen/settings/no_location_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/ui/widgets/buttonWithImageContainer.dart';
import 'package:wakDak/ui/widgets/keyboardOverlay.dart';
import 'package:wakDak/ui/widgets/locationDialog.dart';
import 'package:wakDak/ui/widgets/smallButtonContainer.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({Key? key, this.from}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
  static Route<LoginScreen> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (_) => LoginScreen(
        from: arguments['from'] as String,
      ),
    );
  }
}

class LoginScreenState extends State<LoginScreen> {
  GlobalKey<ScaffoldState>? scaffoldKey;
  GlobalKey<FormState> _formKey = GlobalKey();
  late double width, height;
  TextEditingController phoneNumberController =
      TextEditingController(text: "9876543212");
  TextEditingController passwordController = TextEditingController(text: "");
  String? countryCode = defaultCountryCode;
  FocusNode numberFocusNode = FocusNode();
  FocusNode numberFocusNodeAndroid = FocusNode();
  bool obscure = true, status = false, iAccept = false, skipStatus = false;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  var db = DatabaseHelper();
  Random rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  String referCode = "", socialLoginType = "";
  late LocatitonGeocoder geocoder = LocatitonGeocoder(placeSearchApiKey);
  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    referCode = getRandomString(8);
    numberFocusNode.addListener(() {
      bool hasFocus = numberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    scaffoldKey = GlobalKey<ScaffoldState>();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    passwordController.dispose();
    numberFocusNode.dispose();
    numberFocusNodeAndroid.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  locationEnableDialog() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return LocationDialog(width: width, height: height, from: "skip");
        });
  }

  getUserLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      getUserLocation();
    } else if (permission == LocationPermission.denied) {
      print(permission.toString());
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        locationEnableDialog();
      } else {
        getUserLocation();
      }
    } else {
      try {
        if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
          demoModeAddressDefault(context, "0");
          if (widget.from != "") {
            appDataRefresh(context);
          }
          skipStatus = true;
          context.read<SettingsCubit>().changeShowSkip();
          await Future.delayed(
              Duration.zero,
              () => Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.home, (Route<dynamic> route) => false));
        } else {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

          final placemarks = await geocoder.findAddressesFromCoordinates(
              Coordinates(position.latitude, position.longitude));
          String? location =
              "${placemarks.first.addressLine},${placemarks.first.locality},${placemarks.first.postalCode},${placemarks.first.countryName}";
          //final placemarks = await GeocodingPlatform.instance.placemarkFromCoordinates(position.latitude, position.longitude);
          //String? location = "${placemarks.first.name},${placemarks.first.subLocality},${placemarks.first.locality},${placemarks.first.country}";
          if (await Permission.location.serviceStatus.isEnabled) {
            if (mounted) {
              setState(() async {
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "0");
                } else {
                  setAddressForDisplayData(
                      context,
                      "0",
                      placemarks.first.locality.toString(),
                      position.latitude.toString(),
                      position.longitude.toString(),
                      location.toString().replaceAll(",,", ","));
                }
                if (context
                            .read<SettingsCubit>()
                            .state
                            .settingsModel!
                            .city
                            .toString() !=
                        "" &&
                    context
                            .read<SettingsCubit>()
                            .state
                            .settingsModel!
                            .city
                            .toString() !=
                        "null") {
                  if (await Permission.location.serviceStatus.isEnabled) {
                    if (widget.from != "") {
                      appDataRefresh(context);
                    }
                    skipStatus = true;
                    context.read<SettingsCubit>().changeShowSkip();
                    await Future.delayed(
                        Duration.zero,
                        () => Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.home, (Route<dynamic> route) => false));
                  } else {
                    getUserLocation();
                    skipStatus = false;
                  }
                } else {
                  getUserLocation();
                  skipStatus = false;
                }
              });
            }
          } else {
            if (widget.from == "splash") {
              getUserLocation();
              skipStatus = false;
            } else {}
          }
        }
      } catch (e) {
        if (widget.from == "splash") {
          getUserLocation();
          setState(() {
            skipStatus = false;
          });
        } else {
          if (widget.from != "") {
            appDataRefresh(context);
          }
          setState(() {
            skipStatus = true;
          });
          context.read<SettingsCubit>().changeShowSkip();
          await Future.delayed(
              Duration.zero,
              () => Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.home, (Route<dynamic> route) => false));
        }
      }
    }
  }

  Future<void> offCartAdd() async {
    List cartOffList = await db.getOffCart();

    if (cartOffList.isNotEmpty) {
      for (int i = 0; i < cartOffList.length; i++) {
        if (!mounted) return;
        context.read<ManageCartCubit>().manageCartUser(
            userId: context.read<AuthCubit>().getId(),
            productVariantId: cartOffList[i]["VID"],
            isSavedForLater: "0",
            qty: cartOffList[i]["QTY"],
            addOnId: cartOffList[i]["ADDONID"].isNotEmpty
                ? cartOffList[i]["ADDONID"]
                : "",
            addOnQty: cartOffList[i]["ADDONQTY"].isNotEmpty
                ? cartOffList[i]["ADDONQTY"]
                : "",
            branchId: context.read<SettingsCubit>().getSettings().branchId);
      }
    }
  }

  navigationPageHome() async {
    if (widget.from == "splash") {
      if (context.read<SettingsCubit>().state.settingsModel!.city.toString() !=
              "" &&
          context.read<SettingsCubit>().state.settingsModel!.city.toString() !=
              "null") {
        await Future.delayed(
            Duration.zero,
            () => Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.home, (Route<dynamic> route) => false));
      } else {
        await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) => const NoLocationScreen(),
            ),
            (Route<dynamic> route) => false);
      }
    } else if (widget.from == "logout" || widget.from == "delete") {
      await Future.delayed(
          Duration.zero,
          () => Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.home, (Route<dynamic> route) => false));
    } else {
      await Future.delayed(
        const Duration(seconds: 1),
      );
      if (!mounted) return;

      Navigator.of(context).pop();
    }
  }

  Widget socialLogin() {
    return BlocConsumer<ReferAndEarnCubit, ReferAndEarnState>(
        bloc: context.read<ReferAndEarnCubit>(),
        listener: (context, state) async {
          if (state is ReferAndEarnFailure) {
            print(state.errorCode);
          }
          if (state is ReferAndEarnSuccess) {
            print("success");
            if (socialLoginType == "apple") {
              context.read<SocialSignUpCubit>().socialSocialSignUpUser(
                  authProvider: AuthProviders.apple,
                  friendCode: "",
                  referCode: referCode);
            } else if (socialLoginType == "google") {
              context.read<SocialSignUpCubit>().socialSocialSignUpUser(
                  authProvider: AuthProviders.google,
                  friendCode: "",
                  referCode: referCode);
            }
          }
        },
        builder: (context, state) {
          return BlocConsumer<SocialSignUpCubit, SocialSignUpState>(
            bloc: context.read<SocialSignUpCubit>(),
            listener: (context, state) async {
              if (state is SocialSignUpFailure) {
                if (state.errorMessage == defaultErrorMessage) {
                } else {
                  UiUtils.setSnackBar(state.errorMessage, context, false,
                      type: "2");
                }
              }
              if (state is SocialSignUpSuccess) {
                context.read<AuthCubit>().statusUpdateAuth(state.authModel);
                offCartAdd().then((value) {
                  db.clearCart();
                  navigationPageHome();
                });
              }
            },
            builder: (context, state) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                context.read<SystemConfigCubit>().isGoogleLoginEnable() == "1"
                    ? ButtonImageContainer(
                        color: textFieldBackground,
                        height: height,
                        width: width,
                        text: UiUtils.getTranslatedLabel(
                            context, continueWithGoogleLabel),
                        bottom: 0,
                        start: 0,
                        end: 0,
                        top: height / 30.0,
                        status: status,
                        borderColor: textFieldBorder,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          if (iAccept == true) {
                            context
                                .read<ReferAndEarnCubit>()
                                .fetchReferAndEarn(referCode);
                            status = false;
                            setState(() {
                              socialLoginType = "google";
                            });
                          } else {
                            UiUtils.setSnackBar(
                                StringsRes.pleaseAcceptTermCondition,
                                context,
                                false,
                                type: "2");
                          }
                        },
                        widget:
                            SvgPicture.asset(DesignConfig.setSvgPath("google")))
                    : const SizedBox.shrink(),
                Platform.isIOS &&
                        context
                                .read<SystemConfigCubit>()
                                .isAppleLoginEnable() ==
                            "1"
                    ? ButtonImageContainer(
                        color: textFieldBackground,
                        height: height,
                        width: width,
                        text: UiUtils.getTranslatedLabel(
                            context, continueWithAppleLabel),
                        bottom: 0,
                        start: 0,
                        end: 0,
                        top: height / 30.0,
                        status: status,
                        borderColor: textFieldBorder,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          if (iAccept == true) {
                            context
                                .read<ReferAndEarnCubit>()
                                .fetchReferAndEarn(referCode);
                            status = false;
                            socialLoginType = "apple";
                          } else {
                            UiUtils.setSnackBar(
                                StringsRes.pleaseAcceptTermCondition,
                                context,
                                false,
                                type: "2");
                          }
                        },
                        widget:
                            SvgPicture.asset(DesignConfig.setSvgPath("apple")))
                    : const SizedBox(),
              ]);
            },
          );
        });
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
          : Scaffold(
              key: scaffoldKey,
              bottomNavigationBar: Padding(
                padding: EdgeInsetsDirectional.only(
                    start: width / 20.0,
                    end: width / 20.0,
                    bottom: height / 40.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: grayLightColor,
                      ),
                      child: Checkbox(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(color: textFieldBackground)),
                          value: iAccept,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            setState(() {
                              iAccept = val!;
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          fillColor: MaterialStatePropertyAll(iAccept == true
                              ? Theme.of(context).colorScheme.secondary
                              : textFieldBackground),
                          checkColor:
                              Theme.of(context).colorScheme.onBackground,
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: -4)),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: UiUtils.getTranslatedLabel(
                              context, byClickingYouAgreeToOurLabel),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 14.0,
                              fontFamily: 'Quicksand'),
                          children: [
                            TextSpan(
                                text:
                                    "  ${UiUtils.getTranslatedLabel(context, termsOfServiceLabel)}",
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Quicksand'),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).pushNamed(
                                        Routes.appSettings,
                                        arguments: termsAndConditionsKey);
                                  }),
                            TextSpan(
                                text:
                                    " ${UiUtils.getTranslatedLabel(context, andTheLabel)} ",
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Quicksand')),
                            TextSpan(
                                text: UiUtils.getTranslatedLabel(
                                    context, privacyPolicyLbLabel),
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Quicksand'),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).pushNamed(
                                        Routes.appSettings,
                                        arguments: privacyPolicyKey);
                                  }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: BlocBuilder<SystemConfigCubit, SystemConfigState>(
                builder: (context, state) {
                  return CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    slivers: [
                      SliverAppBar(
                        shadowColor: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.1),
                        backgroundColor:
                            Theme.of(context).colorScheme.onBackground,
                        systemOverlayStyle: SystemUiOverlayStyle.dark,
                        automaticallyImplyLeading: false,
                        iconTheme: IconThemeData(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        centerTitle: false,
                        flexibleSpace: DesignConfig.appBarWihoutBackbutton(
                            context,
                            width,
                            "",
                            const PreferredSize(
                                preferredSize: Size.zero, child: SizedBox())),
                        floating: false,
                        pinned: true,
                        title: Text(
                            UiUtils.getTranslatedLabel(context, loginLabel),
                            style: TextStyle(
                                fontSize: 18.0,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w700)),
                        actions: [
                          skipStatus == true
                              ? Lottie.asset(
                                  DesignConfig.setLottiePath("addressProgress"))
                              : SizedBox(
                                  width: width / 5.0,
                                  child: SmallButtonContainer(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    height: height,
                                    width: width,
                                    text: UiUtils.getTranslatedLabel(
                                        context, skipLabel),
                                    start: 0,
                                    end: width / 20.0,
                                    bottom: height / 80.0,
                                    top: height / 80.0,
                                    radius: 5.0,
                                    status: false,
                                    borderColor:
                                        Theme.of(context).colorScheme.primary,
                                    textColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    onTap: () {
                                      setState(() {
                                        skipStatus = true;
                                      });
                                      getUserLocation();
                                    },
                                  ),
                                )
                        ],
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                              top: height / 20.0,
                              start: width / 20.0,
                              end: height / 40.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: height / 20.0),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      UiUtils.getTranslatedLabel(
                                          context, loginTitleLabel),
                                      style: TextStyle(
                                          decoration: TextDecoration.none,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 32.0,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  SizedBox(height: height / 80.0),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      UiUtils.getTranslatedLabel(
                                          context, loginSubTitleLabel),
                                      style: TextStyle(
                                          decoration: TextDecoration.none,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  SizedBox(height: height / 15.0),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      UiUtils.getTranslatedLabel(context,
                                          weWillSendAVerificationCodeToThisNumberLabel),
                                      style: TextStyle(
                                          decoration: TextDecoration.none,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  SizedBox(height: height / 40.0),
                                  context
                                              .read<SystemConfigCubit>()
                                              .isOtpLoginEnable() ==
                                          "1"
                                      ? IntlPhoneField(
                                          controller: phoneNumberController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          textInputAction: TextInputAction.done,
                                          dropdownIcon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: textFieldBackground,
                                            contentPadding:
                                                const EdgeInsets.only(
                                                    top: 15, bottom: 15),
                                            focusedBorder:
                                                DesignConfig.outlineInputBorder(
                                                    textFieldBorder, 4.0),
                                            focusedErrorBorder:
                                                DesignConfig.outlineInputBorder(
                                                    textFieldBorder, 4.0),
                                            errorBorder:
                                                DesignConfig.outlineInputBorder(
                                                    textFieldBorder, 4.0),
                                            enabledBorder:
                                                DesignConfig.outlineInputBorder(
                                                    textFieldBorder, 4.0),
                                            focusColor: white,
                                            counterStyle: const TextStyle(
                                                color: white, fontSize: 0),
                                            border: InputBorder.none,
                                            hintText:
                                                UiUtils.getTranslatedLabel(
                                                    context,
                                                    enterPhoneNumberLabel),
                                            labelStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontSize: 16.0,
                                            ),
                                            hintStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          flagsButtonMargin:
                                              EdgeInsets.all(width / 40.0),
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          keyboardType: TextInputType.number,
                                          focusNode: Platform.isIOS
                                              ? numberFocusNode
                                              : numberFocusNodeAndroid,
                                          dropdownIconPosition:
                                              IconPosition.trailing,
                                          dropdownTextStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w500),
                                          initialCountryCode:
                                              defaultIsoCountryCode,
                                          showCountryFlag: false,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w500),
                                          textAlign:
                                              Directionality.of(context) ==
                                                      ui.TextDirection.rtl
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                          onChanged: (phone) {
                                            print(phone.completeNumber);
                                            setState(() {
                                              countryCode = phone.countryCode;
                                            });
                                          },
                                          onCountryChanged: ((value) {
                                            setState(() {
                                              print(value.dialCode);
                                              countryCode = value.dialCode;
                                              defaultIsoCountryCode =
                                                  value.code;
                                            });
                                          }),
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                        )
                                      : const SizedBox.shrink(),
                                  context
                                              .read<SystemConfigCubit>()
                                              .isOtpLoginEnable() ==
                                          "1"
                                      ? SizedBox(
                                          width: width,
                                          child: ButtonContainer(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            height: height,
                                            width: width,
                                            text: UiUtils.getTranslatedLabel(
                                                context, loginLabel),
                                            bottom: height / 30.0,
                                            start: 0,
                                            end: 0,
                                            top: height / 60.0,
                                            status: status,
                                            borderColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            textColor: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            onPressed: () {
                                              if (iAccept == true) {
                                                if (!_formKey.currentState!
                                                    .validate()) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (BuildContext
                                                              context) =>
                                                          OtpVerifyScreen(
                                                        mobileNumber:
                                                            phoneNumberController
                                                                .text,
                                                        countryCode:
                                                            countryCode,
                                                        from: widget.from,
                                                      ),
                                                    ),
                                                  );
                                                  status = false;
                                                }
                                              } else {
                                                UiUtils.setSnackBar(
                                                    StringsRes
                                                        .pleaseAcceptTermCondition,
                                                    context,
                                                    false,
                                                    type: "2");
                                              }
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  context
                                              .read<SystemConfigCubit>()
                                              .isOtpLoginEnable() ==
                                          "1"
                                      ? Row(children: [
                                          Expanded(
                                              child:
                                                  DesignConfig.dividerSolid()),
                                          SizedBox(width: width / 40.0),
                                          Text(
                                            UiUtils.getTranslatedLabel(
                                                context, orSignInWithLabel),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: width / 40.0),
                                          Expanded(
                                              child:
                                                  DesignConfig.dividerSolid()),
                                        ])
                                      : const SizedBox.shrink(),
                                  socialLogin(),
                                ]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )),
    );
  }
}
