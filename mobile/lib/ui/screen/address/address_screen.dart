import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:location_geocoder/location_geocoder.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/address/addAddressCubit.dart';
import 'package:wakDak/cubit/address/addressCubit.dart';
import 'package:wakDak/cubit/address/updateAddressCubit.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/addressModel.dart';
import 'package:wakDak/data/repositories/address/addressRepository.dart';
import 'package:wakDak/ui/screen/home/home_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/ui/widgets/keyboardOverlay.dart';
import 'package:wakDak/ui/widgets/locationDialog.dart';
import 'package:wakDak/ui/widgets/pinAnimation.dart';
import 'package:wakDak/ui/widgets/simmer/mapLoadSimmer.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

//import 'package:geocoding/geocoding.dart';
//import 'package:location_geocoder/location_geocoder.dart';

class AddressScreen extends StatefulWidget {
  final AddressModel? addressModel;
  final String? from;
  const AddressScreen({Key? key, this.addressModel, this.from}) : super(key: key);

  @override
  _AddressScreenState createState() => _AddressScreenState();
  static Route<AddressScreen> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (context) => MultiBlocProvider(providers: [
        BlocProvider<AddAddressCubit>(
          create: (_) => AddAddressCubit(
            AddressRepository(),
          ),
        ),
        BlocProvider<UpdateAddressCubit>(
          create: (_) => UpdateAddressCubit(
            AddressRepository(),
          ),
        )
      ], child: AddressScreen(addressModel: arguments['addressModel'], from: arguments['from'])),
    );
  }
}

class _AddressScreenState extends State<AddressScreen> {
  LatLng? latlong;
  late CameraPosition _cameraPosition;
  GoogleMapController? _controller;
  TextEditingController locationController = TextEditingController();
  final Set<Marker> _markers = {};
  double? width, height;
  String? locationStatus = officeKey;
  late Position position;
  TextEditingController areaRoadApartmentNameController = TextEditingController(text: "");
  TextEditingController addressController = TextEditingController(text: "");
  TextEditingController alternateMobileNumberController = TextEditingController(text: "");
  TextEditingController phoneNumberController = TextEditingController(text: "");
  TextEditingController landmarkController = TextEditingController(text: "");
  TextEditingController cityController = TextEditingController(text: "");
  TextEditingController pinCodeController = TextEditingController(text: "");
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: placeSearchApiKey);
  TextEditingController locationSearchController = TextEditingController(text: "");
  String? states, country, pincode, latitude, longitude, address, city, area;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String? checkStatusFirstTime = "1";
  bool markerMove = false;
  String? countryCode = defaultCountryCode, alternetNumbercountryCode = defaultCountryCode;
  FocusNode numberFocusNode = FocusNode();
  FocusNode numberFocusNodeAndroid = FocusNode();
  FocusNode alternetNumberFocusNode = FocusNode();
  FocusNode alternetNumberFocusNodeAndroid = FocusNode();
  late LocatitonGeocoder geocoder = LocatitonGeocoder(placeSearchApiKey);
  GlobalKey<FormState> _formKey = GlobalKey();
  locationEnableDialog() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return LocationDialog(width: width, height: height);
        });
  }

  getUserLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();

      getUserLocation();
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        locationEnableDialog();
      } else {
        getUserLocation();
      }
    } else {
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final placemarks = await geocoder.findAddressesFromCoordinates(Coordinates(position.latitude, position.longitude));
        //final placemarks = await GeocodingPlatform.instance.placemarkFromCoordinates(position.latitude, position.longitude);
        //String? location = "${placemarks.first.name},${placemarks.first.subLocality},${placemarks.first.locality},${placemarks.first.country}";
        print("detail:$placemarks");

        if (mounted) {
          if (widget.from == "updateAddress") {
            setState(() {
              latlong = LatLng(double.parse(widget.addressModel!.latitude!), double.parse(widget.addressModel!.longitude!));

              _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
              if (_controller != null) {
                _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
              }
              states = widget.addressModel!.state!;
              country = widget.addressModel!.country!;
              pincode = widget.addressModel!.pincode!;
              latitude = widget.addressModel!.latitude!.toString();
              longitude = widget.addressModel!.longitude!.toString();
              area = widget.addressModel!.area!;
              areaRoadApartmentNameController.text = widget.addressModel!.area!;
              cityController.text = widget.addressModel!.city!;
              addressController = TextEditingController(text: widget.addressModel!.address.toString());
              if (areaRoadApartmentNameController.text.trim().isEmpty) {
                areaRoadApartmentNameController.text = widget.addressModel!.area!;
                areaRoadApartmentNameController.selection =
                    TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
              }
              if (cityController.text.trim().isEmpty) {
                cityController.text = widget.addressModel!.city!;
                cityController.selection = TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
              }
              address = widget.addressModel!.address!;
              city = widget.addressModel!.city!;

              locationController.text =
                  "${widget.addressModel!.address!},${widget.addressModel!.area!},${widget.addressModel!.city},${widget.addressModel!.state!},${widget.addressModel!.pincode!}";
              _markers.add(Marker(
                markerId: const MarkerId("Marker"),
                position: LatLng(double.parse(widget.addressModel!.latitude!), double.parse(widget.addressModel!.longitude!)),
              ));
            });
          } else {
            setState(() {
              latlong = LatLng(position.latitude, position.longitude);

              _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
              if (_controller != null) {
                _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
              }

              states = /* placemarks.first.administrativeArea??"";// */placemarks.first.adminArea ?? "";
              country = /* placemarks.first.country??"";// */placemarks.first.countryName ?? "";
              pincode = placemarks.first.postalCode ?? "";
              latitude = position.latitude.toString();
              longitude = position.longitude.toString();
              if (areaRoadApartmentNameController.text.trim().isEmpty) {
                areaRoadApartmentNameController.text = placemarks.first.subLocality ?? "";
                areaRoadApartmentNameController.selection =
                    TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
              }
              if (cityController.text.trim().isEmpty) {
                cityController.text = placemarks.first.locality ?? "";
                cityController.selection = TextSelection.fromPosition(TextPosition(offset: cityController.text.length));
              }
              address = /* location.replaceAll(",,", ",") */placemarks.first.addressLine ?? "";
              addressController = TextEditingController(text: placemarks.first.addressLine.toString() /* location.replaceAll(",,", ",") */);
              city = placemarks.first.locality ?? "";
              //cityController.text = placemarks.first.locality!;
              print("states:$states,country:$country,pincode:$pincode,latitude:$latitude,longitude:${longitude}city:$city");
              //locationController.text = address1;
              locationController.text = /* location.replaceAll(",,", ",") */ placemarks.first.addressLine.toString();
              _markers.add(Marker(
                markerId: const MarkerId("Marker"),
                position: LatLng(position.latitude, position.longitude),
              ));
            });
          }
        }
      } catch (e) {
        print("detail:$e");
        getUserLocation();
      }
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cityController.clear();
    });
    _cameraPosition = const CameraPosition(target: LatLng(0, 0), zoom: 14.4746);
    getUserLocation();
    if (widget.from == "updateAddress") {
      locationStatus = widget.addressModel!.type!; //locationStatus
      alternateMobileNumberController = TextEditingController(text: widget.addressModel!.alternateMobile!);
      phoneNumberController = TextEditingController(text: widget.addressModel!.mobile);
      countryCode = widget.addressModel!.countryCode;
      areaRoadApartmentNameController = TextEditingController(text: widget.addressModel!.area!);
      addressController = TextEditingController(text: widget.addressModel!.address!);
      cityController = TextEditingController(text: widget.addressModel!.city!);
      landmarkController = TextEditingController(text: widget.addressModel!.landmark!);
      pinCodeController = TextEditingController(text: widget.addressModel!.pincode!);
    } else {
      phoneNumberController = TextEditingController(text: context.read<AuthCubit>().getMobile());
    }
    numberFocusNode.addListener(() {
      bool hasFocus = numberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    alternetNumberFocusNode.addListener(() {
      bool hasFocus = alternetNumberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    loadSearchAddressData();
  }

  // Get all items from the database
  loadSearchAddressData() {
    final data = searchAddressBoxData.keys.map((key) {
      final value = searchAddressBoxData.get(key);
      return {"key": key, "city": value["city"], "latitude": value['latitude'], "longitude": value['longitude'], "address": value['address']};
    }).toList();

    setState(() {
      searchAddressData = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  // add Search Address in Database
  Future<void> addSearchAddress(Map<String, dynamic> newItem) async {
    await searchAddressBoxData.add(newItem);
    loadSearchAddressData(); // update the UI
  }

  completeAddressShow() {
    showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      addressField(),
                      areaRoadApartmentNameField(),
                      mobileNumberField(),
                      alternateMobileNumberField(),
                      landmarkField(),
                      cityField(),
                      pincode == "" ? pinCodeField() : Container(),
                      
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                        child: Text(UiUtils.getTranslatedLabel(context, tagThisLocationForLaterLabel),
                            style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
                      ),
                      tagLocation(setState),
                      widget.from == "updateAddress"
                          ? BlocConsumer<UpdateAddressCubit, UpdateAddressState>(
                              bloc: context.read<UpdateAddressCubit>(),
                              listener: (context, state) {
                                if (state is UpdateAddressSuccess) {
                                  context.read<AddressCubit>().editAddress(state.addressModel);
                                  Navigator.pop(context);
                                  Future.delayed(const Duration(microseconds: 1000)).then((value) {
                                    Navigator.pop(context);
                                  });
                                }
                                if (state is UpdateAddressFailure) {
                                  Navigator.pop(context);
                                  UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                }
                              },
                              builder: (context, state) {
                                return SizedBox(
                                  width: width!,
                                  child: ButtonContainer(
                                    color: Theme.of(context).colorScheme.primary,
                                    height: height,
                                    width: width,
                                    text: state is UpdateAddressProgress
                                        ? UiUtils.getTranslatedLabel(context, updateIngLocationLabel)
                                        : UiUtils.getTranslatedLabel(context, updateLocationLabel),
                                    start: width! / 40.0,
                                    end: width! / 40.0,
                                    bottom: height! / 55.0,
                                    top: 0,
                                    status: (state is UpdateAddressProgress) ? true : false,
                                    borderColor: Theme.of(context).colorScheme.primary,
                                    textColor: Theme.of(context).colorScheme.onPrimary,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        if (state is UpdateAddressProgress) {
                                        } else {
                                          context.read<UpdateAddressCubit>().fetchUpdateAddress(
                                                widget.addressModel!.id!,
                                                context.read<AuthCubit>().getId(),
                                                phoneNumberController.text.toString(),
                                                addressController.text,
                                                cityController.text,
                                                latitude ?? "",
                                                longitude ?? "",
                                                areaRoadApartmentNameController.text,
                                                locationStatus,
                                                context.read<AuthCubit>().getName(),
                                                countryCode.toString().replaceAll("+", ""),
                                                alternetNumbercountryCode.toString().replaceAll("+", ""),
                                                alternateMobileNumberController.text.toString(),
                                                landmarkController.text,
                                                pincode == "" ? pinCodeController.text : pincode!,
                                                states ?? "",
                                                country ?? "",
                                                "0",
                                              );
                                        }
                                      }
                                    },
                                  ),
                                );
                              })
                          : BlocConsumer<AddAddressCubit, AddAddressState>(
                              bloc: context.read<AddAddressCubit>(),
                              listener: (context, state) {
                                if (state is AddAddressSuccess) {
                                  context.read<AddressCubit>().addAddress(state.addressModel);
                                  if (widget.from == "login") {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) => const HomeScreen(),
                                      ),
                                    );
                                  } else {
                                    
                                    Navigator.pop(context);
                                    Future.delayed(const Duration(microseconds: 1000)).then((value) {
                                      Navigator.pop(context);
                                    });
                                    
                                  }
                                }
                                if (state is AddAddressFailure) {
                                  Navigator.pop(context);
                                  
                                  UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                }
                              },
                              builder: (context, state) {
                                return SizedBox(
                                  width: width!,
                                  child: ButtonContainer(
                                    color: Theme.of(context).colorScheme.primary,
                                    height: height,
                                    width: width,
                                    text: state is AddAddressProgress
                                        ? UiUtils.getTranslatedLabel(context, addingLocationLabel)
                                        : UiUtils.getTranslatedLabel(context, confirmLocationLabel),
                                    start: width! / 40.0,
                                    end: width! / 40.0,
                                    bottom: height! / 55.0,
                                    top: 0,
                                    status: (state is AddAddressProgress) ? true : false,
                                    borderColor: Theme.of(context).colorScheme.primary,
                                    textColor: Theme.of(context).colorScheme.onPrimary,
                                    onPressed: () {
                                      _formKey.currentState!.save();
                                      if (_formKey.currentState!.validate()) {
                                        if (state is AddAddressProgress) {
                                        } else {
                                          context.read<AddAddressCubit>().fetchAddAddress(
                                                context.read<AuthCubit>().getId(),
                                                phoneNumberController.text.toString(),
                                                addressController.text,
                                                cityController.text,
                                                latitude ?? "",
                                                longitude ?? "",
                                                areaRoadApartmentNameController.text,
                                                locationStatus,
                                                context.read<AuthCubit>().getName(),
                                                countryCode.toString(),
                                                alternetNumbercountryCode.toString(),
                                                alternateMobileNumberController.text,
                                                landmarkController.text,
                                                pincode == "" ? pinCodeController.text : pincode!,
                                                states ?? "",
                                                country ?? "",
                                                widget.from == "login" ? "1" : "0",
                                              );
                                        }
                                      }
                                    },
                                  ),
                                );
                              }),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    locationController.clear();
    areaRoadApartmentNameController.clear();
    addressController.clear();
    cityController.clear();
    landmarkController.clear();
    pinCodeController.clear();
    alternateMobileNumberController.clear();
    _controller!.dispose();
    locationController.dispose();
    areaRoadApartmentNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    alternateMobileNumberController.dispose();
    pinCodeController.dispose();
    landmarkController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Widget cityField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextFormField(
          validator: (value) {
            if (value!.isEmpty) {
              return UiUtils.getTranslatedLabel(context, enterCityLabel);
            }
            return null;
          },
          controller: cityController,
          cursorColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, cityLabel), UiUtils.getTranslatedLabel(context, enterCityLabel), width!, context),
          keyboardType: TextInputType.text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget pinCodeField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextFormField(
          controller: pinCodeController,
          cursorColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
          textInputAction: TextInputAction.done,
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, pinCodeLabel), UiUtils.getTranslatedLabel(context, enterpinCodeLabel), width!, context),
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget addressField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextFormField(
          validator: (value) {
            if (value!.isEmpty) {
              return UiUtils.getTranslatedLabel(context, enterAddressLabel);
            }
            return null;
          },
          controller: addressController,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, addressLabel), UiUtils.getTranslatedLabel(context, enterAddressLabel), width!, context),
          keyboardType: TextInputType.text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget areaRoadApartmentNameField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return UiUtils.getTranslatedLabel(context, enterAreaRoadApartmentNameLabel);
            }
            return null;
          },
          controller: areaRoadApartmentNameController,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, areaRoadApartmentNameLabel),
              UiUtils.getTranslatedLabel(context, enterAreaRoadApartmentNameLabel), width!, context),
          keyboardType: TextInputType.text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget alternateMobileNumberField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 80.0,
          end: width! / 20.0,
        ),
        child: IntlPhoneField(
          //autovalidateMode: /* context.read<AuthCubit>().getMobile()!=""? */AutovalidateMode.onUserInteraction,
          controller: alternateMobileNumberController, disableLengthCheck: alternateMobileNumberController.text.toString() == "" ? true : false,
          autovalidateMode: AutovalidateMode.disabled,
          textInputAction: TextInputAction.done, showDropdownIcon: false,
          dropdownIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.background,
            contentPadding: const EdgeInsets.only(top: 15, bottom: 15),
            focusedErrorBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(width: 1.0, color: textFieldBorder)),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            focusColor: white,
            counterStyle: const TextStyle(color: white, fontSize: 0),
            border: InputBorder.none,
            hintText: UiUtils.getTranslatedLabel(context, enterAlternateMobileNumberLabel),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            //contentPadding: EdgeInsets.zero,
          ),
          flagsButtonMargin: EdgeInsets.all(width! / 40.0),
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          focusNode: Platform.isIOS ? alternetNumberFocusNode : alternetNumberFocusNodeAndroid,
          dropdownIconPosition: IconPosition.trailing,
          initialCountryCode: defaultIsoCountryAlternateCode,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
          onChanged: (phone) {
            setState(() {
              //print(phone.completeNumber);
              alternetNumbercountryCode = phone.countryCode;
            });
          },
          onCountryChanged: ((value) {
            setState(() {
              print(value.dialCode);
              alternetNumbercountryCode = value.dialCode;
              defaultIsoCountryAlternateCode = value.code;
            });
          }),
        ));
  }

  Widget mobileNumberField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 80.0,
          end: width! / 20.0,
        ),
        child: IntlPhoneField(
          controller: phoneNumberController,
          textInputAction: TextInputAction.done,
          dropdownIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76)),
          decoration: InputDecoration(
            filled: true,
            fillColor: textFieldBackground,
            contentPadding: const EdgeInsets.only(top: 15, bottom: 15),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            focusedErrorBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(width: 1.0, color: textFieldBorder)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            focusColor: white,
            counterStyle: const TextStyle(color: white, fontSize: 0),
            border: InputBorder.none,
            hintText: UiUtils.getTranslatedLabel(context, enterPhoneNumberLabel),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            //contentPadding: EdgeInsets.zero,
          ),
          enabled: context.read<AuthCubit>().getMobile() != "" ? false : true,
          flagsButtonMargin: EdgeInsets.all(width! / 40.0),
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          focusNode: Platform.isIOS ? numberFocusNode : numberFocusNodeAndroid,
          dropdownIconPosition: IconPosition.trailing,
          initialCountryCode: defaultIsoCountryCode,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
          onChanged: (phone) {
            setState(() {
              //print(phone.completeNumber);
              countryCode = phone.countryCode;
            });
          },
          onCountryChanged: ((value) {
            setState(() {
              print(value.dialCode);
              countryCode = value.dialCode;
              alternetNumbercountryCode = value.code;
            });
          }),
        ));
  }

  Widget landmarkField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextField(
          controller: landmarkController,
          cursorColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, landmarkLabel), UiUtils.getTranslatedLabel(context, enterLandmarkLabel), width!, context),
          keyboardType: TextInputType.text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget tagLocation(StateSetter setState) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: width! / 40.0, top: height! / 99.0, start: width! / 40.0, bottom: height! / 99.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Expanded(
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                setState(() {
                  locationStatus = homeKey;
                });
              },
              child: Container(
                  width: width,
                  padding: EdgeInsetsDirectional.only(
                    top: height! / 99.0,
                    bottom: height! / 99.0,
                  ),
                  decoration: locationStatus == homeKey
                      ? DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 4.0)
                      : DesignConfig.boxDecorationContainerBorder(
                          Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondary.withOpacity(0.1), 4.0,
                          status: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(DesignConfig.setSvgPath("home_address"),
                          fit: BoxFit.scaleDown,
                          height: 20,
                          width: 20,
                          colorFilter:
                              ColorFilter.mode(locationStatus == homeKey ? white : Theme.of(context).colorScheme.secondary, BlendMode.srcIn)),
                      const SizedBox(width: 5.0),
                      Text(UiUtils.getTranslatedLabel(context, homeLabel),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                              color: locationStatus == homeKey ? white : Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ))),
        ),
        Expanded(
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                setState(() {
                  locationStatus = officeKey;
                });
              },
              child: Container(
                  width: width!,
                  padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0),
                  decoration: locationStatus == officeKey
                      ? DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 4.0)
                      : DesignConfig.boxDecorationContainerBorder(
                          Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondary.withOpacity(0.1), 4.0,
                          status: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        DesignConfig.setSvgPath("work_address"),
                        fit: BoxFit.scaleDown,
                        height: 20,
                        width: 20,
                        colorFilter: ColorFilter.mode(locationStatus == officeKey ? white : Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 5.0),
                      Text(UiUtils.getTranslatedLabel(context, officeLabel),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                              color: locationStatus == officeKey ? white : Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ))),
        ),
        Expanded(
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                setState(() {
                  locationStatus = otherKey;
                });
              },
              child: Container(
                  width: width!,
                  padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0),
                  decoration: locationStatus == otherKey
                      ? DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 4.0)
                      : DesignConfig.boxDecorationContainerBorder(
                          Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondary.withOpacity(0.1), 4.0,
                          status: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(DesignConfig.setSvgPath("other_address"),
                          fit: BoxFit.scaleDown,
                          height: 20,
                          width: 20,
                          colorFilter:
                              ColorFilter.mode(locationStatus == otherKey ? white : Theme.of(context).colorScheme.secondary, BlendMode.srcIn)),
                      const SizedBox(width: 5),
                      Text(UiUtils.getTranslatedLabel(context, otherLabel),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                              color: locationStatus == otherKey ? white : Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ))),
        ),
      ]),
    );
  }

  Widget locationChange() {
    return Container(
        margin: const EdgeInsetsDirectional.only(bottom: 10.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SvgPicture.asset(DesignConfig.setSvgPath("other_address")),
          SizedBox(width: height! / 99.0),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.toString(),
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  addressController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSecondary, overflow: TextOverflow.ellipsis
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          )
        ]));
  }

  placesAutoCompleteTextField() {
    return Container(
      margin: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 45.0, end: width! / 25.0, start: width! / 40.0),
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
          getPlaceDetailWithLatLng: (p) async {},
          itemClick: (p) async {
            locationSearchController.text = p.description!;
            PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!); 
            List<dynamic> localities = detail.result.addressComponents.where((entry) => entry.types.contains('locality')).toList().map((entry) => entry.longName).toList();
            latlong = LatLng(double.parse(detail.result.geometry!.location.lat.toString()), double.parse(detail.result.geometry!.location.lng.toString()));
            final placemarks = await geocoder.findAddressesFromCoordinates(Coordinates(latlong!.latitude, latlong!.longitude));
            //final placemarks = await GeocodingPlatform.instance.placemarkFromCoordinates(latlong!.latitude, latlong!.longitude);
            //String? location = "${placemarks.first.name},${placemarks.first.subLocality},${placemarks.first.locality},${placemarks.first.country}";
            if (mounted) {
              setState(() {
                if (widget.from == "location" || widget.from == "change") {
                  List<dynamic> localities = detail.result.addressComponents
                      .where((entry) => entry.types.contains('locality'))
                      .toList()
                      .map((entry) => entry.longName)
                      .toList();
                  setAddressForDisplayData(context, "1", localities.join("").toString(), detail.result.geometry!.location.lat.toString(),
                      detail.result.geometry!.location.lng.toString(), detail.result.formattedAddress!.toString());
                  addSearchAddress({
                    "city": localities.join("").toString(),
                    "latitude": detail.result.geometry!.location.lat.toString(),
                    "longitude": detail.result.geometry!.location.lng.toString(),
                    "address": detail.result.formattedAddress!.toString()
                  }).then((value) => Navigator.pop(context));
                } else {
                  _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
                  if (_controller != null) {
                    _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                  }
                  states = /* placemarks.first.administrativeArea??"";// */placemarks.first.adminArea ?? "";
                  country = /* placemarks.first.country??"";// */placemarks.first.countryName ?? "";
                  pincode = placemarks.first.postalCode ?? "";
                  latitude = detail.result.geometry!.location.lat.toString();
                  longitude = detail.result.geometry!.location.lng.toString();
                  area = placemarks.first.subLocality ?? "";
                  areaRoadApartmentNameController.text = placemarks.first.subLocality ?? "";
                  cityController.text = localities.join("").toString();
                  setState(() {
                    addressController.text = detail.result.formattedAddress!.toString();
                  });
                  addressController = TextEditingController(text: detail.result.formattedAddress!.toString());
                  areaRoadApartmentNameController.text = placemarks.first.subLocality ?? "";
                  cityController.text = localities.join("").toString();
                  address = detail.result.formattedAddress!.toString();
                  city = localities.join("").toString();
                  FocusScope.of(context).unfocus();
                  locationController.text = detail.result.formattedAddress!.toString();
                }
              });
            }
            locationSearchController.clear();
            setState(() {
              markerMove = true;
            });
          },
          textStyle: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
    );
  }

  void _checkPermission(Function callback, BuildContext context) async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => locationEnableDialog());
    } else {
      callback();
      latlong = LatLng(position.latitude, position.longitude);
      _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
      if (_controller != null) {
        _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
      }
      setState(() {
        markerMove = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return _connectionStatus == connectivityCheck
        ? const NoInternetScreen()
        : WillPopScope(
            onWillPop: () {
              Future.delayed(const Duration(microseconds: 1000)).then((value) {
                Navigator.pop(context);
              });
              return Future.value(false);
            },
            child: Scaffold(
                resizeToAvoidBottomInset: true,
                appBar: DesignConfig.appBar(context, width!, UiUtils.getTranslatedLabel(context, deliveryAddressLabel),
                    const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
                body: Stack(children: [
                  SizedBox(
                    height: height! / 1.7,
                    child: (latlong != null)
                        ? Stack(
                            children: [
                              SafeArea(
                                child: GoogleMap(
                                    onCameraMove: (position) {
                                      _cameraPosition = position;
                                    },
                                    onCameraIdle: () {
                                      if (markerMove == false) {
                                        if (latlong == LatLng(_cameraPosition.target.latitude, _cameraPosition.target.longitude)) {
                                        } else {
                                          getLocation();
                                        }
                                      }
                                    }, 
                                    zoomControlsEnabled: false,
                                    minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                                    compassEnabled: false,
                                    indoorViewEnabled: true,
                                    mapToolbarEnabled: true,
                                    myLocationButtonEnabled: false,
                                    mapType: MapType.normal,
                                    initialCameraPosition: _cameraPosition,
                                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{}
                                      ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()..onUpdate = (dragUpdateDetails) {
                                      }))
                                      ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()..onStart = (dragUpdateDetails) {
                                      }))
                                      ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
                                      ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()
                                        ..onDown = (dragUpdateDetails) {
                                          if (markerMove == false) {
                                          } else {
                                            setState(() {
                                              markerMove = false;
                                            });
                                          }
                                        })),
                                    onMapCreated: (GoogleMapController controller) {
                                      Future.delayed(const Duration(milliseconds: 500)).then((value) {
                                        _controller = (controller);
                                        _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                                      });
                                    },
                                    onTap: (latLng) {
                                      _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                                      if(markerMove == false){}else{
                                      setState(() {
                                        markerMove = false;
                                      });
                                      }
                                    }),
                              ),
                              PinAnimation(color: Theme.of(context).colorScheme.primary),
                              Center(child: SvgPicture.asset(DesignConfig.setSvgPath('other_address'), width: 35, height: 35)),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: width! / 90.0,
                                top: height! / 2.0,
                                child: InkWell(
                                  onTap: () => _checkPermission(() async {}, context),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    margin: const EdgeInsetsDirectional.only(end: 10),
                                    decoration:
                                        DesignConfig.boxDecorationContainerBorder(lightFont, Theme.of(context).colorScheme.onBackground, 10.0),
                                    child: Icon(
                                      Icons.my_location,
                                      color: Theme.of(context).colorScheme.secondary,
                                      size: 35,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        : MapLoadSimmer(width: width!, height: height!),
                  ),
                  
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsetsDirectional.only(top: height! / 1.70),
                      
                      width: width,
                      child: Container(
                        alignment: Alignment.topCenter,
                        margin: EdgeInsetsDirectional.only(
                          top: height! / 30.0,
                          start: width! / 20.0,
                          end: width! / 20.0,
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsetsDirectional.zero,
                          child: latlong != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(UiUtils.getTranslatedLabel(context, selectDeliveryLocationLabel),
                                          style:
                                              TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(top: height! / 60.0, bottom: height! / 40.0),
                                        child: DesignConfig.dividerSolid(),
                                      ),
                                      locationChange(),
                                      
                                      SizedBox(
                                        width: width!,
                                        child: ButtonContainer(
                                          color: Theme.of(context).colorScheme.primary,
                                          height: height,
                                          width: width,
                                          text: (widget.from == "location" || widget.from == "change")
                                              ? UiUtils.getTranslatedLabel(context, confirmLocationLabel)
                                              : UiUtils.getTranslatedLabel(context, enterCompleteAddressLocationLabel),
                                          start: 0,
                                          end: 0,
                                          bottom: height! / 80.0,
                                          top: height! / 80.0,
                                          status: false,
                                          borderColor: Theme.of(context).colorScheme.primary,
                                          textColor: Theme.of(context).colorScheme.onPrimary,
                                          onPressed: () {
                                            if (widget.from == "location" || widget.from == "change") {
                                              if (city == "") {
                                                UiUtils.setSnackBar(StringsRes.sorryWeAreNotDeliveryFoodOnCurrentLocation, context, false, type: "2");
                                              } else {
                                                if (mounted) {
                                                  setState(() {
                                                    if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                                                      demoModeAddressDefault(context, "1");
                                                    } else {
                                                      setAddressForDisplayData(context, "1", city.toString(), latitude!.toString(),
                                                          longitude!.toString(), address.toString());
                                                    }
                                                    
                                                    Future.delayed(Duration.zero, () {
                                                      addSearchAddress({
                                                        "city": city.toString(),
                                                        "latitude": latitude.toString(),
                                                        "longitude": longitude.toString(),
                                                        "address": address.toString()
                                                      }).then((value) {
                                                        if (widget.from == "location") {
                                                          context.read<SettingsCubit>().changeShowSkip();
                                                          Navigator.of(context).pushNamedAndRemoveUntil(
                                                              Routes.home, (Route<dynamic> route) => false);
                                                        } else {
                                                          Navigator.pop(context);
                                                        }
                                                      });
                                                    });
                                                    
                                                  });
                                                }
                                              }
                                            } else {
                                              completeAddressShow();
                                            }
                                          },
                                        ),
                                      ),
                                    ])
                              : MapDataLoadSimmer(width: width!, height: height!),
                        ),
                      ),
                    ),
                  ),
                  Positioned.directional(textDirection: Directionality.of(context), top: height ! / 99.0,start: 0, end: 0,  child: placesAutoCompleteTextField()),
                  
                ])),
          );
  }

  Set<Marker> myMarker() {
    _markers.clear();
    _markers.add(Marker(
      onDrag: (value) {},
      onDragStart: (value) {},
      onDragEnd: (value) {},
      markerId: MarkerId(Random().nextInt(10000).toString()),
      visible: false,
      position: LatLng(latlong!.latitude, latlong!.longitude),
      draggable: true,
    ));
    return _markers;
  }

  Future<void> getLocation() async {
    latlong = LatLng(_cameraPosition.target.latitude, _cameraPosition.target.longitude);
    final placemarks = await geocoder.findAddressesFromCoordinates(Coordinates(latlong!.latitude, latlong!.longitude));
    //final placemarks = await GeocodingPlatform.instance.placemarkFromCoordinates(latlong!.latitude, latlong!.longitude);
    //String? location = "${placemarks.first.name},${placemarks.first.subLocality},${placemarks.first.locality},${placemarks.first.country}";
    states = /* placemarks.first.administrativeArea??"";// */placemarks.first.adminArea ?? "";
    country = /* placemarks.first.country??"";// */placemarks.first.countryName ?? "";
    pincode = placemarks.first.postalCode ?? "";
    latitude = latlong!.latitude.toString();
    longitude = latlong!.longitude.toString();
    area = placemarks.first.subLocality ?? "";
    areaRoadApartmentNameController.text = placemarks.first.subLocality ?? "";
    address = /* location.replaceAll(",,", ","); */placemarks.first.addressLine ?? "";
    addressController = TextEditingController(text: placemarks.first.addressLine.toString() /* location.replaceAll(",,", ",") */);
    city = placemarks.first.locality ?? "";
    cityController.text = placemarks.first.locality ?? "";
    locationController.text = placemarks.first.addressLine.toString() /* location.replaceAll(",,", ",") */;
    if (mounted) setState(() {});
  }
}
