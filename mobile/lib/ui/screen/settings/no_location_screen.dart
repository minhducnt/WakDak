import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/addressModel.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/ui/widgets/locationDialog.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';
//import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:location_geocoder/location_geocoder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakDak/utils/internetConnectivity.dart';

class NoLocationScreen extends StatefulWidget {
  const NoLocationScreen({Key? key}) : super(key: key);

  @override
  NoLocationScreenState createState() => NoLocationScreenState();
}

class NoLocationScreenState extends State<NoLocationScreen> {
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  double? width, height;
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: placeSearchApiKey);
  TextEditingController locationSearchController = TextEditingController(text: "");
  String? currentAddress = "";
  late LocatitonGeocoder geocoder = LocatitonGeocoder(placeSearchApiKey);
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
    locationSearchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  locationEnableDialog() async {
    if (context.read<SettingsCubit>().state.settingsModel!.city.toString() == "" &&
        context.read<SettingsCubit>().state.settingsModel!.city.toString() == "null") {
      // Use location.
      getUserLocation();
    } else {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return LocationDialog(width: width, height: height);
          });
    }
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
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        locationEnableDialog();
      } else {
        getUserLocation();
      }
    } else {
      try {
        if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
          demoModeAddressDefault(context, "0");
          context.read<SettingsCubit>().changeShowSkip();
          Navigator.of(context).pushReplacementNamed(Routes.home);
        } else {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          final placemarks = await geocoder.findAddressesFromCoordinates(Coordinates(position.latitude, position.longitude));
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
                  setAddressForDisplayData(context, "0", placemarks.first.locality.toString(), position.latitude.toString(),
                      position.longitude.toString(), location.toString().replaceAll(",,", ","));
                }
                if (context.read<SettingsCubit>().state.settingsModel!.city.toString() != "" &&
                    context.read<SettingsCubit>().state.settingsModel!.city.toString() != "null") {
                  if (await Permission.location.serviceStatus.isEnabled) {
                    context.read<SettingsCubit>().changeShowSkip();
                    Navigator.of(context).pushReplacementNamed(Routes.home);
                  } else {
                    getUserLocation();
                  }
                } else {
                  getUserLocation();
                }
              });
            }
          } else {
            getUserLocation();
          }
        }
      } catch (e) {
        getUserLocation();
      }
    }
  }

  getCurrentUserLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      getCurrentUserLocation();
    } else if (permission == LocationPermission.denied) {
      print(permission.toString());
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        locationEnableDialog();
      } else {
        getCurrentUserLocation();
      }
    } else {
      try {
        if (await Permission.location.serviceStatus.isEnabled) {
          if (mounted) {
            Navigator.pop(context);
            Navigator.of(context).pushNamed(Routes.address, arguments: {'from': 'location', 'addressModel': AddressModel()});
          }
        } else {
          getCurrentUserLocation();
        }
      } catch (e) {
        getCurrentUserLocation();
      }
    }
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
              body: Container(
              alignment: Alignment.center,
              margin: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
              width: width,
              child: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  SvgPicture.asset(
                    DesignConfig.setSvgPath("Location_get"),
                    height: height! / 3.0,
                    width: height! / 3.0,
                    fit: BoxFit.scaleDown,
                  ),
                  SizedBox(height: height! / 20.0),
                  Text(
                    UiUtils.getTranslatedLabel(context, noLocationTitleLabel),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                    maxLines: 2,
                  ),
                  SizedBox(height: height! / 60.0),
                  Text(UiUtils.getTranslatedLabel(context, noLocationDescriptionLabel),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
                  SizedBox(
                    width: width,
                    child: ButtonContainer(
                      color: Theme.of(context).colorScheme.primary,
                      height: height,
                      width: width,
                      text: UiUtils.getTranslatedLabel(context, noLocationEnableLabel),
                      bottom: height! / 99.0,
                      start: 0,
                      end: 0,
                      top: height! / 20.0,
                      status: false,
                      borderColor: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      onPressed: () {
                        getUserLocation();
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: ButtonContainer(
                      color: Theme.of(context).colorScheme.onBackground,
                      height: height,
                      width: width,
                      text: UiUtils.getTranslatedLabel(context, noLocationManuallyLabel),
                      bottom: height! / 99.0,
                      start: 0,
                      end: 0,
                      top: height! / 99.0,
                      status: false,
                      borderColor: Theme.of(context).colorScheme.onBackground,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      onPressed: () {
                        showLocationBottomModelSheet();
                      },
                    ),
                  ),
                ]),
              ),
            )),
    );
  }

  showLocationBottomModelSheet() {
    showModalBottomSheet(
        showDragHandle: true,
        isDismissible: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (context) {
          return Container(
            height: (height! / 1.5),
            padding: EdgeInsets.only(left: width! / 15.0, right: width! / 15.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  placesAutoCompleteTextField(),
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                    child: Row(children: [
                      Expanded(child: DesignConfig.dividerSolid()),
                      SizedBox(width: width! / 40.0),
                      Text(
                        UiUtils.getTranslatedLabel(context, orLabel),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: width! / 40.0),
                      Expanded(child: DesignConfig.dividerSolid()),
                    ]),
                  ),
                  ListTile(
                    visualDensity: const VisualDensity(vertical: -4),
                    minLeadingWidth: 0,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.secondary),
                    title: Text(UiUtils.getTranslatedLabel(context, useCurrentLocationLabel),
                        style: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 5.0),
                      child: Text(
                        currentAddress.toString() == "" ? UiUtils.getTranslatedLabel(context, usingGPSLabel) : currentAddress.toString(),
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.normal),
                      ),
                    ),
                    onTap: () async {
                      getCurrentUserLocation();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  placesAutoCompleteTextField() {
    return Container(
      margin: EdgeInsets.only(top: height! / 60.0, bottom: height! / 45.0),
      child: GooglePlaceAutoCompleteTextField(
          boxDecoration: DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
          textEditingController: locationSearchController,
          googleAPIKey: placeSearchApiKey,
          inputDecoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsetsDirectional.zero,
              hintText: UiUtils.getTranslatedLabel(context, enterLocationAreaCityEtcLabel),
              hintStyle: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
          debounceTime: 600,
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (p) async {
            PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
            if (mounted) {
              setState(() {
                List<dynamic> localities = detail.result.addressComponents
                    .where((entry) => entry.types.contains('locality'))
                    .toList()
                    .map((entry) => entry.longName)
                    .toList();
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "1");
                } else {
                  setAddressForDisplayData(context, "1", localities.join("").toString(), detail.result.geometry!.location.lat.toString(),
                      detail.result.geometry!.location.lng.toString(), detail.result.formattedAddress!.toString());
                }
              });
            }
          },
          itemClick: (p) async {
            locationSearchController.text = p.description!;
            PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
            if (mounted) {
              setState(() {
                List<dynamic> localities = detail.result.addressComponents
                    .where((entry) => entry.types.contains('locality'))
                    .toList()
                    .map((entry) => entry.longName)
                    .toList();
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "1");
                } else {
                  setAddressForDisplayData(context, "1", localities.join("").toString(), detail.result.geometry!.location.lat.toString(),
                      detail.result.geometry!.location.lng.toString(), detail.result.formattedAddress!.toString());
                }
                Navigator.pop(context);
                context.read<SettingsCubit>().changeShowSkip();
                Future.delayed(Duration.zero, () {
                  Navigator.of(context).pushReplacementNamed(Routes.home);
                });
              });
            }
            locationSearchController.selection = TextSelection.fromPosition(TextPosition(offset: p.description!.length));
          },
          textStyle: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
    );
  }
}
