import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/address/addressCubit.dart';
import 'package:wakDak/cubit/address/cityDeliverableCubit.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/favourite/favouriteProductsCubit.dart';
import 'package:wakDak/cubit/home/sections/sectionsCubit.dart';
import 'package:wakDak/cubit/localization/appLocalizationCubit.dart';
import 'package:wakDak/cubit/order/activeOrderCubit.dart';
import 'package:wakDak/cubit/order/orderCubit.dart';
import 'package:wakDak/cubit/product/productCubit.dart';
import 'package:wakDak/cubit/product/topRatedProductCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/ui/screen/cart/cart_screen.dart';
import 'package:wakDak/ui/screen/settings/maintenance_screen.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';

//* Config App
const String appName = "WakDak";

// Android
const String packageName = "com.wakdak.wakdakCustomer";
const String androidLink = 'https://play.google.com/store/apps/details?id=';

// iOS
const String iosPackage = 'com.wakdak.wakdakCustomer';
const String iosLink = 'https://apps.apple.com/id';
const String iosAppId = '6459792955';

String shareAndroidAppLink =
    'Delicious food at your fingertips! Order food effortlessly via  ${appName}. $androidLink$packageName';
String shareiOSAppLink =
    'Delicious food at your fingertips! Order food effortlessly via  ${appName}. $iosLink$iosAppId';

//* Database related constants

// Add your database url
const String databaseUrl = 'https://wakdak.wuaze.com/app/v1/api/';
const String perPage = "10";
String defaultIsoCountryCode = 'VN';
String defaultIsoCountryAlternateCode = 'EN';
const String defaultCountryCode = '84';

const String googleAPiKeyAndroid = "AIzaSyBKXbM0YUOrbnwAQEBUgojAHUM9trEHRoQ";
const String googleAPiKeyIos = "AIzaSyBnHSLck4ikoo8K56PLJvWfkggyIXduACU";
const String placeSearchApiKey = "AIzaSyBoxHdxbbNozjbIy2d9GHTyZatLJfyimjA";

const String defaultErrorMessage = "Something went wrong!!";
const String connectivityCheck = "ConnectivityResult.none";
const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
const String tokenExpireCode = "102";

// By default language of the app
const String defaultLanguageCode = "en";

// Stripe payment method message
const String transactionSuccessful = "Transaction successful";
const String transactionPending = "Transaction pending";
const String transactionFailed = "Transaction failed";
const String transactionCancelled = "Transaction cancelled";

// Strip payment required data
const String merchantCountryCodeData = "IN";
const String merchantDisplayNameData = "Test";
const String merchantIdentifierData = "App Identifier";

getUserLocation() async {
  LocationPermission permission;

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openLocationSettings();

    getUserLocation();
  } else if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      await Geolocator.openLocationSettings();

      getUserLocation();
    } else {
      getUserLocation();
    }
  } else {}
}

appDataRefresh(BuildContext context) async {
  Future.delayed(Duration.zero, () async {
    await context.read<FavoriteProductsCubit>().getFavoriteProducts(
        context.read<AuthCubit>().getId(),
        productsKey,
        context.read<SettingsCubit>().getSettings().branchId);
  });
  Future.delayed(Duration.zero, () async {
    context
        .read<SystemConfigCubit>()
        .getSystemConfig(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    await context.read<ProductCubit>().fetchProduct(
        perPage,
        context.read<AuthCubit>().getId(),
        context.read<SettingsCubit>().getSettings().branchId,
        "",
        "",
        "",
        "");
  });
  Future.delayed(Duration.zero, () async {
    await context.read<TopRatedProductCubit>().fetchTopRatedProduct(
        perPage,
        "1",
        context.read<AuthCubit>().getId(),
        context.read<SettingsCubit>().getSettings().branchId);
  });
  Future.delayed(Duration.zero, () async {
    await context.read<SectionsCubit>().fetchSections(
        perPage,
        context.read<AuthCubit>().getId(),
        "",
        context.read<SettingsCubit>().state.settingsModel!.branchId);
  });

  Future.delayed(Duration.zero, () async {
    await context.read<GetCartCubit>().getCartUser(
        userId: context.read<AuthCubit>().getId(),
        branchId: context.read<SettingsCubit>().getSettings().branchId);
  });
  Future.delayed(Duration.zero, () async {
    await context
        .read<AddressCubit>()
        .fetchAddress(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    await context
        .read<SystemConfigCubit>()
        .getSystemConfig(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    context
        .read<AddressCubit>()
        .fetchAddress(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    context.read<OrderCubit>().fetchOrder(
        perPage, context.read<AuthCubit>().getId(), "", deliveredKey);
    context.read<ActiveOrderCubit>().fetchActiveOrder(
        perPage,
        context.read<AuthCubit>().getId(),
        "",
        "$outForDeliveryKey,$preparingKey",
        "0");
  });
}

isMaintenance(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (BuildContext context) => const MaintenanceScreen(),
    ),
  );
}

// Clear OfflineCart Data
clearOffLineCart(BuildContext context) {
  context.read<SettingsCubit>().setCartCount("0");
  context.read<SettingsCubit>().setCartTotal("0");
  //context.read<SettingsCubit>().setBranchId("");
}

// Predefined reason of order cancel
List<String> reasonList = [
  "Delay in delivery",
  "Order by mistake",
  "Other",
];

// When jwt key expire reLogin
reLogin(BuildContext context) {
  if (context.read<AuthCubit>().getType() == "google") {
    context.read<AuthCubit>().signOut(AuthProviders.google);
  } else {
    context.read<AuthCubit>().signOut(AuthProviders.apple);
  }
  clearOffLineCart(context);
  Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.login, (Route<dynamic> route) => false,
      arguments: {'from': 'logout'});
}

clearAll() {
  taxPercentage = 0;
  deliveryCharge = 0;
  deliveryTip = 0;
  promoAmt = 0;
  remWalBal = 0;
  walletBalanceUsed = 0;
  paymentMethod = '';
  promoCode = '';
  isPromoValid = false;
  isUseWallet = false;
  isPayLayShow = true;
  selectedMethod = null;
  orderTypeIndex = 0;
}

bool getStoreOpenStatus(String openTime, String closeTime) {
  bool result = false;

  DateTime now = DateTime.now();
  int nowHour = now.hour;
  int nowMin = now.minute;

  print('Now: H$nowHour M$nowMin $now');

  var openTimes = openTime.split(":");
  int openHour = int.parse(openTimes[0]);
  int openMin = int.parse(openTimes[1]);

  print('OpenTimes: H$openHour M$openMin $openTime');

  var closeTimes = closeTime.split(":");
  int closeHour = int.parse(closeTimes[0]);
  int closeMin = int.parse(closeTimes[1]);

  print('CloseTimes: H$closeHour M$closeMin $closeTime');

  TimeOfDay nowTime = TimeOfDay.now(); // or DateTime object
  TimeOfDay openingTime =
      TimeOfDay(hour: openHour, minute: openMin); // or leave as DateTime object
  TimeOfDay closingTime = TimeOfDay(
      hour: closeHour, minute: closeMin); // or leave as DateTime object

  int shopOpenTimeInSeconds = openingTime.hour * 60 + openingTime.minute;
  int shopCloseTimeInSeconds = closingTime.hour * 60 + closingTime.minute;
  int timeNowInSeconds = nowTime.hour * 60 + nowTime.minute;

  if (shopOpenTimeInSeconds <= timeNowInSeconds &&
      timeNowInSeconds <= shopCloseTimeInSeconds) {
    // OPEN;
    result = true;
  } else {
    // CLOSED;
    result = false;
  }

  print('time: $result');

  return result;
}

String? convertToAgo(BuildContext context, DateTime input, int from) {
  Duration diff = DateTime.now().difference(input);
  bool isNegative = diff.isNegative;
  if (diff.inDays >= 1 || (isNegative && diff.inDays < 1)) {
    if (from == 0) {
      var newFormat = DateFormat("MMM dd, yyyy");
      final newsDate1 = newFormat.format(input);
      return newsDate1;
    } else if (from == 1) {
      return "${diff.inDays} ${'Days'} ${'Ago'}";
    } else if (from == 2) {
      var newFormat = DateFormat("dd MMMM yyyy HH:mm:ss");
      final newsDate1 = newFormat.format(input);
      return newsDate1;
    }
  } else if (diff.inHours >= 1 || (isNegative && diff.inMinutes < 1)) {
    if (input.minute == 00) {
      return "${diff.inHours} ${'hours'} ${'ago'}";
    } else {
      if (from == 2) {
        return "${'about'} ${diff.inHours} ${'hours'} ${input.minute} ${'minutes'} ${'ago'}";
      } else {
        return "${diff.inHours} ${'hours'} ${input.minute} ${'minutes'} ${'ago'}";
      }
    }
  } else if (diff.inMinutes >= 1 || (isNegative && diff.inMinutes < 1)) {
    return "${diff.inMinutes} ${'minutes'} ${'ago'}";
  } else if (diff.inSeconds >= 1) {
    return "${diff.inSeconds} ${'seconds'} ${'ago'}";
  } else {
    return 'justNow';
  }
  return null;
}

demoModeAddressDefault(BuildContext context, String ifDelivery) async {
  // Get the current language
  Locale currentLanguage = context.read<AppLocalizationCubit>().state.language;

  // Get current location
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  double latitude = position.latitude;
  double longitude = position.longitude;

  List<Placemark> placeMarks = await placemarkFromCoordinates(
      latitude, longitude,
      localeIdentifier: currentLanguage.languageCode);

  Placemark placeMark = placeMarks[0];

  String street = '${placeMark.street}, ${placeMark.subAdministrativeArea}';
  String address = '${placeMark.country}';
  String addressWithCity =
      '${placeMark.administrativeArea}, ${placeMark.country}';

  // Set values
  if (ifDelivery == "1") {
    context.read<CityDeliverableCubit>().fetchCityDeliverable(
        address, latitude.toString(), longitude.toString());
  }
  context.read<SettingsCubit>().setCity(street);
  context.read<SettingsCubit>().setLatitude(latitude.toString());
  context.read<SettingsCubit>().setLongitude(longitude.toString());
  context.read<SettingsCubit>().setAddress(addressWithCity);
}

setAddressForDisplayData(BuildContext context, String ifDelivery, String city,
    String latitude, String longitude, String address) {
  if (ifDelivery == "1") {
    context
        .read<CityDeliverableCubit>()
        .fetchCityDeliverable(city.toString(), latitude, longitude);
  }
  context.read<SettingsCubit>().setCity(city.toString());
  context.read<SettingsCubit>().setLatitude(latitude.toString());
  context.read<SettingsCubit>().setLongitude(longitude.toString());
  context.read<SettingsCubit>().setAddress(address.toString());
}
