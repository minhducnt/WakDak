import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location_geocoder/location_geocoder.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/address/addressCubit.dart';
import 'package:wakDak/cubit/address/cityDeliverableCubit.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/cart/getQuantityCubit.dart';
import 'package:wakDak/cubit/favourite/favouriteProductsCubit.dart';
import 'package:wakDak/cubit/home/bestOffer/bestOfferCubit.dart';
import 'package:wakDak/cubit/home/cuisine/cuisineCubit.dart';
import 'package:wakDak/cubit/home/sections/sectionsCubit.dart';
import 'package:wakDak/cubit/home/slider/sliderOfferCubit.dart';
import 'package:wakDak/cubit/order/activeOrderCubit.dart';
import 'package:wakDak/cubit/order/historyOrderCubit.dart';
import 'package:wakDak/cubit/order/orderAgainCubit.dart';
import 'package:wakDak/cubit/order/reOrderCubit.dart';
import 'package:wakDak/cubit/product/productCubit.dart';
import 'package:wakDak/cubit/product/topRatedProductCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/addressModel.dart';
import 'package:wakDak/data/model/cuisineModel.dart';
import 'package:wakDak/data/model/orderModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/order/orderRepository.dart';
import 'package:wakDak/ui/screen/auth/login_screen.dart';
import 'package:wakDak/ui/screen/cart/cart_screen.dart';
import 'package:wakDak/ui/screen/home/slider/slider_screen.dart';
import 'package:wakDak/ui/screen/home/topBrand/top_brand_screen.dart';
import 'package:wakDak/ui/screen/settings/maintenance_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/screen/settings/no_location_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/bottomSheetContainer.dart';
import 'package:wakDak/ui/widgets/brachCloseDialog.dart';
import 'package:wakDak/ui/widgets/cuisineContainer.dart';
import 'package:wakDak/ui/widgets/forceUpdateDialog.dart';
import 'package:wakDak/ui/widgets/locationDialog.dart';
import 'package:wakDak/ui/widgets/offerImageContainer.dart';
import 'package:wakDak/ui/widgets/productContainer.dart';
import 'package:wakDak/ui/widgets/productSectionContainer.dart';
import 'package:wakDak/ui/widgets/productUnavailableDialog.dart';
import 'package:wakDak/ui/widgets/searchBarContainer.dart';
import 'package:wakDak/ui/widgets/simmer/cuisineSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/homeSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/productSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/sectionSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/sliderSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/topAndActiveOrderSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/topBrandSimmer.dart';
import 'package:wakDak/ui/widgets/smallButtonContainer.dart';
import 'package:wakDak/ui/widgets/topBrandContainer.dart';
import 'package:wakDak/ui/widgets/voiceSearchContainer.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/hiveBoxKey.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/notificationUtility.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

List<Map<String, dynamic>> searchAddressData = [];

final searchAddressBoxData = Hive.box(searchAddressBox);
StreamController? streamController;

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  TextEditingController locationSearchController = TextEditingController(text: "");
  TextEditingController enableLocationController = TextEditingController(text: "");
  String searchText = '';
  double? width, height;
  final PageController _pageController = PageController(
    initialPage: 0,
  );
  int _currentPage = 0, _currentPageOrderAgain = 0, _currentPageActiveOrder = 0;
  final ScrollController _scrollBottomBarController = ScrollController();
  bool isScrollingDown = false;
  double bottomBarHeight = 75;
  final Geolocator geolocator = Geolocator();
  String? currentAddress = "";
  String showMessage = "";
  List<String> variance = [];
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  List<ProductDetails> productList = [];
  List<ProductDetails> topProductList = [];
  List<ProductDetails> sectionProductList = [];
  List<CuisineModel> cuisineList = [];
  RegExp regex = RegExp(r'([^\d]00)(?=[^\d]|$)');
  bool? showBottom = false;
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: placeSearchApiKey);
  var db = DatabaseHelper();
  late LocatitonGeocoder geocoder = LocatitonGeocoder(placeSearchApiKey);
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

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

    if (context.read<SettingsCubit>().state.settingsModel!.city.toString() != "" &&
        context.read<SettingsCubit>().state.settingsModel!.city.toString() != "null") {
      locationDialog();
    } else {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) => const NoLocationScreen(),
            ),
            (Route<dynamic> route) => false);
      });
    }

    //Check for Force Update
    _initPackageInfo().then((value) {
      Future.delayed(Duration.zero, () {
        forceUpdateDialog();
      });
    });

    //Check if Currently in Maintenance or Not
    isMaintenance();

    //Check User Active Deactive Status
    userStatus();

    //search Address Data Load
    loadSearchAddressData();
    setStreamConfig();

    final pushNotificationService = NotificationUtility(context: context);
    pushNotificationService.initLocalNotification();
    pushNotificationService.setupInteractedMessage();
  }

  setStreamConfig() {
    streamController = StreamController<String>.broadcast();
    streamController!.stream.listen((data) {
      print("streamNotification recive::::::$data");
      if (data == "1") {
        context.read<HistoryOrderCubit>().fetchHistoryOrder(perPage, context.read<AuthCubit>().getId(), "", "$deliveredKey,$cancelledKey", "");
        context
            .read<ActiveOrderCubit>()
            .fetchActiveOrder(perPage, context.read<AuthCubit>().getId(), "", "$outForDeliveryKey,$preparingKey,$readyForPickupKey", "0");
        context
            .read<OrderAgainCubit>()
            .fetchOrderAgain(perPage, context.read<AuthCubit>().getId(), "", deliveredKey, context.read<SettingsCubit>().getSettings().branchId);
      }
    });
  }

  apiCall() {
    Future.delayed(Duration.zero, () {
      if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
      } else {
        context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
        context
            .read<GetCartCubit>()
            .getCartUser(userId: context.read<AuthCubit>().getId(), branchId: context.read<SettingsCubit>().getSettings().branchId);
        Future.delayed(Duration.zero, () async {
          if (mounted) {
            context
                .read<FavoriteProductsCubit>()
                .getFavoriteProducts(context.read<AuthCubit>().getId(), productsKey, context.read<SettingsCubit>().getSettings().branchId);
          }
        });
        Future.delayed(Duration.zero, () {
          context
              .read<ActiveOrderCubit>()
              .fetchActiveOrder(perPage, context.read<AuthCubit>().getId(), "", "$outForDeliveryKey,$preparingKey,$readyForPickupKey", "0");
          context.read<OrderAgainCubit>().fetchOrderAgain((int.parse(perPage) - 5).toString(), context.read<AuthCubit>().getId(), "", deliveredKey,
              context.read<SettingsCubit>().getSettings().branchId);
        });
      }
      if (context.read<SystemConfigCubit>().state is! SystemConfigFetchSuccess) {
        context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
      }
    });
    context.read<SliderCubit>().fetchSlider(context.read<SettingsCubit>().getSettings().branchId);
    context.read<CuisineCubit>().fetchCuisine(perPage, "", context.read<SettingsCubit>().getSettings().branchId);
    context.read<BestOfferCubit>().fetchBestOffer(context.read<SettingsCubit>().getSettings().branchId);
  }

// Get all items from the database
  void loadSearchAddressData() {
    final data = searchAddressBoxData.keys.map((key) {
      final value = searchAddressBoxData.get(key);
      return {"key": key, "city": value["city"], "latitude": value['latitude'], "longitude": value['longitude'], "address": value['address']};
    }).toList();

    setState(() {
      searchAddressData = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
    print(searchAddressData.length);
  }

  // add Search Address in Database
  Future<void> addSearchAddress(Map<String, dynamic> newItem) async {
    await searchAddressBoxData.add(newItem);
    loadSearchAddressData(); // update the UI
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> getSearchAddress(int key) {
    final item = searchAddressBoxData.get(key);
    return item;
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  isMaintenance() {
    if (context.read<SystemConfigCubit>().isAppMaintenance() == "1") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const MaintenanceScreen(),
        ),
      );
    } else {}
  }

  userStatus() {
    if (context.read<AuthCubit>().getActive() == "0") {
      Future.delayed(Duration.zero, () {
        userActiveStatus(context);
      });
    } else {}
  }

  forceUpdateDialog() {
    if (context.read<SystemConfigCubit>().isForceUpdateEnable() == "1") {
      if (Platform.isIOS) {
        if (context.read<SystemConfigCubit>().getCurrentVersionIos() != _packageInfo.version) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return ForceUpdateDialog(width: width!, height: height!);
              });
        }
      } else {
        if (context.read<SystemConfigCubit>().getCurrentVersionAndroid() != _packageInfo.version) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return ForceUpdateDialog(width: width!, height: height!);
              });
        }
      }
    } else {}
  }

  locationDialog() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      // Use location.
      getUserLocation();
    } else {
      // Use location.
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.onBackground,
              shape: DesignConfig.setRounded(16.0),
              child: contentBox(context),
            );
          });
    }
  }

  Future userActiveStatus(BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(UiUtils.getTranslatedLabel(context, userNotActiveLabel),
              textAlign: TextAlign.start,
              maxLines: 2,
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Text(UiUtils.getTranslatedLabel(context, okLabel),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
              onPressed: () {
                if (context.read<AuthCubit>().getType() == "google") {
                  context.read<AuthCubit>().signOut(AuthProviders.google);
                } else {
                  context.read<AuthCubit>().signOut(AuthProviders.apple);
                }
                Navigator.of(context)
                    .pushAndRemoveUntil(CupertinoPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
              },
            )
          ],
        );
      },
    );
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
          }).whenComplete(() async {
        if (context.read<SettingsCubit>().state.settingsModel!.city.toString().isNotEmpty) {
          await context.read<CityDeliverableCubit>().fetchCityDeliverable(
              context.read<SettingsCubit>().state.settingsModel!.city.toString(),
              context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
              context.read<SettingsCubit>().state.settingsModel!.longitude.toString());
        }
      });
    }
  }

  getUserLocation() async {
    try {
      if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
        demoModeAddressDefault(context, "1");
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
              if (placemarks.first.subLocality == "" || placemarks.first.subLocality.toString().isEmpty) {
                currentAddress = "${placemarks.first.locality}";
              } else {
                currentAddress = "${placemarks.first.subLocality}, ${placemarks.first.locality}";
              }
              if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                demoModeAddressDefault(context, "0");
              } else {
                setAddressForDisplayData(context, "0", placemarks.first.locality.toString(), position.latitude.toString(),
                    position.longitude.toString(), location.toString().replaceAll(",,", ","));
              }

              if (searchAddressData.isNotEmpty) {
              } else {
                if (searchAddressData.contains(location.toString().replaceAll(",,", ","))) {
                } else {
                  addSearchAddress({
                    "city": placemarks.first.locality.toString(),
                    "latitude": position.latitude.toString(),
                    "longitude": position.longitude.toString(),
                    "address": location.toString().replaceAll(",,", ",")
                  });
                }
              }
              if (context.read<SettingsCubit>().state.settingsModel!.city.toString() != "" &&
                  context.read<SettingsCubit>().state.settingsModel!.city.toString() != "null") {
                if (await Permission.location.serviceStatus.isEnabled) {
                  if (mounted) {
                    if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                      context.read<CityDeliverableCubit>().fetchCityDeliverable("Hồ Chí Minh", "10.748464045004656", "106.61634673550695");
                    } else {
                      context
                          .read<CityDeliverableCubit>()
                          .fetchCityDeliverable(placemarks.first.locality, position.latitude.toString(), position.longitude.toString());
                    }
                  }
                } else {
                  if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                    context.read<CityDeliverableCubit>().fetchCityDeliverable("Hồ Chí Minh", "10.748464045004656", "106.61634673550695");
                  } else {
                    context.read<CityDeliverableCubit>().fetchCityDeliverable(
                        context.read<SettingsCubit>().state.settingsModel!.city.toString(),
                        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
                        context.read<SettingsCubit>().state.settingsModel!.longitude.toString());
                  }
                }
              } else {
                getUserLocation();
              }
            });
          }
        } else {
          setState(() {
            if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
              context.read<CityDeliverableCubit>().fetchCityDeliverable("Hồ Chí Minh", "10.748464045004656", "106.61634673550695");
            } else {
              context.read<CityDeliverableCubit>().fetchCityDeliverable(
                  context.read<SettingsCubit>().state.settingsModel!.city.toString(),
                  context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
                  context.read<SettingsCubit>().state.settingsModel!.longitude.toString());
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
            context.read<CityDeliverableCubit>().fetchCityDeliverable("Hồ Chí Minh", "10.748464045004656", "106.61634673550695");
          } else {
            context.read<CityDeliverableCubit>().fetchCityDeliverable(
                context.read<SettingsCubit>().state.settingsModel!.city.toString(),
                context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
                context.read<SettingsCubit>().state.settingsModel!.longitude.toString());
          }
          print(context.read<SettingsCubit>().state.settingsModel!.address.toString());
        });
      }
    }
  }

  Widget deliveryLocation() {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 3.0),
                child: Container(
                  width: 220, // specify your desired width
                  child: Text(
                    state.settingsModel!.city.toString().replaceAll("null", ""),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w600, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              SizedBox(width: height! / 99.0),
              SizedBox(
                width: width! / 1.75,
                child: Text(
                  state.settingsModel!.address.toString().replaceAll("null", ""),
                  style: const TextStyle(color: lightFont, fontSize: 12, overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
              ),
            ]);
      },
    );
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
                addSearchAddress({
                  "city": localities.join("").toString(),
                  "latitude": detail.result.geometry!.location.lat.toString(),
                  "longitude": detail.result.geometry!.location.lng.toString(),
                  "address": detail.result.formattedAddress!.toString()
                }).then((value) => Navigator.pop(context));
              });
            }
            locationSearchController.selection = TextSelection.fromPosition(TextPosition(offset: p.description!.length));
            locationSearchController.clear();
          },
          textStyle: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
    );
  }

  locationBottomModelSheetShow() {
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
                        currentAddress.toString() == ""
                            ? UiUtils.getTranslatedLabel(context, usingGPSLabel)
                            : currentAddress.toString().replaceAll("null,", "").replaceAll("null", ""),
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.normal),
                      ),
                    ),
                    onTap: () async {
                      if (await Permission.location.serviceStatus.isEnabled) {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed(Routes.address, arguments: {'from': 'change', 'addressModel': AddressModel()});
                      } else {
                        getUserLocation();
                        Navigator.pop(context);
                      }
                    },
                  ),
                  SizedBox(height: height! / 40.0),
                  searchAddressData.isNotEmpty
                      ? Padding(
                          padding: EdgeInsetsDirectional.only(top: height! / 60.0, bottom: 5.0),
                          child: Text(
                            UiUtils.getTranslatedLabel(context, recentSearchesLabel),
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600),
                          ),
                        )
                      : const SizedBox(),
                  Column(mainAxisSize: MainAxisSize.min, children: searchAddress()),
                ],
              ),
            ),
          );
        });
  }

  searchAddress() {
    return List.generate(
        // the list of items
        searchAddressData.length, (index) {
      final currentItem = searchAddressData[index];
      return ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          dense: true,
          visualDensity: VisualDensity.comfortable,
          horizontalTitleGap: 0.0,
          title: Text(currentItem['city'].toString().replaceAll("null", ""),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
          subtitle: Text(currentItem['address'].toString().replaceAll("null", "").replaceAll(",,", ","),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          leading: Icon(Icons.history_sharp, color: Theme.of(context).colorScheme.secondary),
          onTap: () {
            if (mounted) {
              setState(() {
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "1");
                } else {
                  setAddressForDisplayData(context, "1", currentItem['city'].toString(), currentItem['latitude'].toString(),
                      currentItem['longitude'].toString(), currentItem['address'].toString());
                }
              });
            }
            Navigator.pop(context);
          });
    });
  }

  addToCartBottomModelSheet(ProductDetails productList) async {
    ProductDetails productDetailsModel = productList;
    Map<String, int> qtyData = {};
    int currentIndex = 0, qty = 0;
    List<bool> isChecked = List<bool>.filled(productDetailsModel.productAddOns!.length, false);
    String? productVariantId = productDetailsModel.variants![currentIndex].id;

    List<String> addOnIds = [];
    List<String> addOnQty = [];
    List<double> addOnPrice = [];
    List<String> productAddOnIds = [];
    List<String> productAddOnId = [];
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      productAddOnId = (await db.getVariantItemData(productDetailsModel.id!, productVariantId!))!;

      productAddOnIds = productAddOnId.toString().replaceAll("[", "").replaceAll("]", "").split(",");
    } else {
      for (int i = 0; i < productDetailsModel.variants![currentIndex].addOnsData!.length; i++) {
        productAddOnIds.add(productDetailsModel.variants![currentIndex].addOnsData![i].id!);
      }
    }

    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      qty = int.parse((await db.checkCartItemExists(productDetailsModel.id!, productVariantId!))!);
      if (qty == 0) {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      } else {
        print(qty);

        qtyData[productVariantId] = qty;
      }
    } else {
      if (productDetailsModel.variants![currentIndex].cartCount != "0") {
        qty = int.parse(productDetailsModel.variants![currentIndex].cartCount!);
      } else {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      }
    }
    qtyData[productVariantId!] = qty;
    bool descTextShowFlag = false;

    showModalBottomSheet(
        useSafeArea: true,
        isDismissible: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return BottomSheetContainer(
              productDetailsModel: productDetailsModel,
              isChecked: isChecked,
              height: height!,
              width: width!,
              productVariantId: productVariantId,
              addOnIds: addOnIds,
              addOnPrice: addOnPrice,
              addOnQty: addOnQty,
              productAddOnIds: productAddOnIds,
              qtyData: qtyData,
              currentIndex: currentIndex,
              descTextShowFlag: descTextShowFlag,
              qty: qty,
              from: "home");
        });
  }

  Widget homeList() {
    return Container(
      margin: EdgeInsetsDirectional.only(top: height! / 80.0),
      color: Theme.of(context).colorScheme.onBackground,
      child:
          Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const SliderScreen(),
        topCuisine(),
        (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
            ? const SizedBox.shrink()
            : activeOrder(),
        hotDeal(),
        (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
            ? const SizedBox.shrink()
            : orderAgain(),
        popularDishes(),
        recommendedForYou(),
        //SizedBox(height: height! / 50.0),
        topDeal(),
        SizedBox(height: height! / 99.0),
      ]),
    );
  }

  Widget searchBar() {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(Routes.search);
      },
      child: SearchBarContainer(width: width!, height: height!, title: UiUtils.getTranslatedLabel(context, searchDishLabel)),
    );
  }

  Widget topCuisine() {
    return BlocConsumer<CuisineCubit, CuisineState>(
        bloc: context.read<CuisineCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CuisineProgress || state is CuisineInitial) {
            return CuisineSimmer(length: 3, height: height! / 4.9, width: width!);
          }
          if (state is CuisineFailure) {
            return const SizedBox();
          }
          cuisineList = (state as CuisineSuccess).cuisineList;

          return Container(
            padding: EdgeInsetsDirectional.only(bottom: height! / 80.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 50.0, bottom: height! / 60.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                            height: height! / 40.0,
                            width: width! / 80.0),
                        SizedBox(width: width! / 80.0),
                        Text(UiUtils.getTranslatedLabel(context, deliciousCuisineLabel),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.cuisine);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(UiUtils.getTranslatedLabel(context, showAllLabel),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w500)),
                          SizedBox(width: width! / 80.0),
                          Icon(Icons.arrow_circle_right_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))
                        ],
                      ),
                    ),
                  ]),
                ),
                cuisineList.isEmpty
                    ? const SizedBox()
                    : GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        crossAxisCount: 3,
                        childAspectRatio: 1.20,
                        mainAxisSpacing: height! / 80.0,
                        crossAxisSpacing: width! / 50.0,
                        children: List.generate(
                          cuisineList.length > 6 ? 6 : cuisineList.length,
                          (index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(Routes.cuisineDetail,
                                    arguments: {'categoryId': cuisineList[index].id!, 'name': cuisineList[index].text!});
                              },
                              child: CuisineContainer(cuisineList: cuisineList, index: index, width: width!, height: height!),
                            );
                          },
                        ))
              ],
            ),
          );
        });
  }

  orderSlidePage(int page) {
    setState(() {
      _currentPageOrderAgain = page;
    });
  }

  activeOrderSlidePage(int page) {
    setState(() {
      _currentPageActiveOrder = page;
    });
  }

  Widget orderAgain() {
    return BlocConsumer<OrderAgainCubit, OrderAgainState>(
        bloc: context.read<OrderAgainCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is OrderAgainProgress || state is OrderAgainInitial) {
            return TopAndActiveOrderSimmer(length: 1, width: width!, height: height!, from: "orderAgain");
          }
          if (state is OrderAgainFailure) {
            return (state.errorMessage.toString() == "No Order(s) Found !" || state.errorStatusCode.toString() == tokenExpireCode)
                ? Container()
                : Container();
          }
          final orderList = (state as OrderAgainSuccess).orderList;
          return orderList.isEmpty
              ? Container()
              : Container(
                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary.withOpacity(0.10), 0),
                  padding: EdgeInsetsDirectional.only(bottom: height! / 70.0, top: height! / 80.0),
                  margin: EdgeInsetsDirectional.only(top: height! / 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 70.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                                height: height! / 40.0,
                                width: width! / 80.0),
                            SizedBox(width: width! / 80.0),
                            Text(UiUtils.getTranslatedLabel(context, becauseYouOrderedLabel),
                                textAlign: TextAlign.start,
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: height! / 6.0,
                        child: PageView(
                          scrollDirection: Axis.horizontal,
                          allowImplicitScrolling: true,
                          onPageChanged: (num) {
                            orderSlidePage(num);
                          },
                          children: List.generate(orderList.length > 5 ? 5 : orderList.length, (index) {
                            return BlocProvider(
                              create: (context) => ReOrderCubit(OrderRepository()),
                              child: Builder(builder: (context) {
                                return GestureDetector(
                                  onTap: () {
                                    print(orderList[index].activeStatus);
                                    Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
                                      'id': orderList[index].id!,
                                      'riderId': orderList[index].riderId!,
                                      'riderName': orderList[index].riderName!,
                                      'riderRating': orderList[index].riderRating!,
                                      'riderImage': orderList[index].riderImage!,
                                      'riderMobile': orderList[index].riderMobile!,
                                      'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                      'isSelfPickup': orderList[index].isSelfPickUp!,
                                      'from': orderList[index].activeStatus == "delivered" ? 'orderDeliverd' : 'orderDetail'
                                    });
                                  },
                                  child: Container(
                                      padding: EdgeInsetsDirectional.only(start: width! / 40.0, top: 0, end: 0),
                                      width: width! / 1.09,
                                      margin: EdgeInsetsDirectional.only(
                                          top: height! / 50.0, start: width! / 20.0, end: width! / 40.0, bottom: height! / 99.0),
                                      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
                                      child: Container(
                                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 5.0),
                                        padding:
                                            EdgeInsetsDirectional.only(start: 0.0, top: height! / 99.0, end: width! / 40.0, bottom: height! / 99.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                                child: ColorFiltered(
                                                  colorFilter: context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                      ? const ColorFilter.mode(
                                                          Colors.transparent,
                                                          BlendMode.multiply,
                                                        )
                                                      : const ColorFilter.mode(
                                                          Colors.grey,
                                                          BlendMode.saturation,
                                                        ),
                                                  child: ShaderMask(
                                                      shaderCallback: (Rect bounds) {
                                                        return LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [shaderColor, shaderColor],
                                                        ).createShader(bounds);
                                                      },
                                                      blendMode: BlendMode.darken,
                                                      child: DesignConfig.imageWidgets(orderList[index].orderItems![0].image!,
                                                          /* height! / 6.5 */ 100, /* width!/3.0 */ 100, "2")),
                                                )),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional.only(start: width! / 60.0),
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: List.generate(
                                                              orderList[index].orderItems!.length > 1 ? 1 : orderList[index].orderItems!.length, (i) {
                                                            OrderItems data = orderList[index].orderItems![i];
                                                            return Container(
                                                              padding: EdgeInsetsDirectional.only(bottom: 5.0),
                                                              width: width!,
                                                              margin: EdgeInsetsDirectional.only(top: 5.0, end: width! / 60.0),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  data.indicator == "1"
                                                                      ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 14, height: 15)
                                                                      : data.indicator == "2"
                                                                          ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"),
                                                                              width: 14, height: 15)
                                                                          : const SizedBox(height: 15, width: 15.0),
                                                                  const SizedBox(width: 5.0),
                                                                  Text(
                                                                    "${data.quantity!} x ",
                                                                    textAlign: Directionality.of(context) == ui.TextDirection.rtl
                                                                        ? TextAlign.right
                                                                        : TextAlign.left,
                                                                    style: TextStyle(
                                                                        color: Theme.of(context).colorScheme.onPrimary,
                                                                        fontSize: 14,
                                                                        fontWeight: FontWeight.w700,
                                                                        overflow: TextOverflow.ellipsis),
                                                                    maxLines: 1,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      data.name!,
                                                                      textAlign: Directionality.of(context) == ui.TextDirection.rtl
                                                                          ? TextAlign.right
                                                                          : TextAlign.left,
                                                                      style: TextStyle(
                                                                          color: Theme.of(context).colorScheme.onPrimary,
                                                                          fontSize: 14,
                                                                          fontWeight: FontWeight.w700,
                                                                          overflow: TextOverflow.ellipsis),
                                                                      maxLines: 1,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          })),
                                                      orderList[index].orderItems!.length > 1
                                                          ? Align(
                                                              alignment: Alignment.topLeft,
                                                              child: Text(
                                                                  "${orderList[index].orderItems!.length - 1} ${StringsRes.plusSymbol} ${UiUtils.getTranslatedLabel(context, moreLabel)}",
                                                                  style: TextStyle(
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.w400,
                                                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))))
                                                          : SizedBox(height: height! / 50.0),
                                                      SizedBox(height: height! / 80.0),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          Column(
                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(UiUtils.getTranslatedLabel(context, youOrderedLabel),
                                                                  textAlign: TextAlign.start,
                                                                  style: TextStyle(
                                                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w500,
                                                                  )),
                                                              Text(convertToAgo(context, DateTime.parse(orderList[index].dateAdded.toString()), 1)!,
                                                                  textAlign: TextAlign.start,
                                                                  style: TextStyle(
                                                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.normal,
                                                                  )),
                                                            ],
                                                          ),
                                                          const Spacer(),
                                                          FittedBox(
                                                            fit: BoxFit.fitWidth,
                                                            child: BlocConsumer<ReOrderCubit, ReOrderState>(
                                                                bloc: context.read<ReOrderCubit>(),
                                                                listener: (context, state) {
                                                                  if (state is ReOrderSuccess) {
                                                                    Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => const CartScreen(
                                                                          from: 'home',
                                                                        ),
                                                                      ),
                                                                    );
                                                                  } else if (state is ReOrderFailure) {
                                                                    UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                                                  }
                                                                },
                                                                builder: (context, state) {
                                                                  return SmallButtonContainer(
                                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                                                                    height: height!,
                                                                    width: width! / 1.5,
                                                                    text: UiUtils.getTranslatedLabel(context, reOrderLabel),
                                                                    start: width! / 99.0,
                                                                    end: 0,
                                                                    bottom: 0,
                                                                    top: 0,
                                                                    radius: 4.0,
                                                                    status: false,
                                                                    borderColor: Theme.of(context).colorScheme.primary,
                                                                    textColor: Theme.of(context).colorScheme.primary,
                                                                    onTap: () {
                                                                      context.read<ReOrderCubit>().reOrder(orderId: orderList[index].id);
                                                                    },
                                                                  );
                                                                }),
                                                          ),
                                                        ],
                                                      ),
                                                    ]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                );
                              }),
                            );
                          }),
                        ),
                      ),
                      orderList.length > 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: orderList
                                  .map((item) => Container(
                                        width: _currentPageOrderAgain == orderList.indexOf(item) ? 16.0 : 8.0,
                                        height: 8.0,
                                        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                                        decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                            color: _currentPageOrderAgain == orderList.indexOf(item)
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.primary.withOpacity(0.50)),
                                      ))
                                  .toList(),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                );
        });
  }

  Widget activeOrder() {
    return BlocConsumer<ActiveOrderCubit, ActiveOrderState>(
        bloc: context.read<ActiveOrderCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is ActiveOrderProgress || state is ActiveOrderInitial) {
            return const SizedBox();
          }
          if (state is ActiveOrderFailure) {
            return (state.errorMessage.toString() == "No Order(s) Found !" || state.errorStatusCode.toString() == tokenExpireCode)
                ? Container()
                : Container();
          }
          final orderList = (state as ActiveOrderSuccess).activeOrderList;
          return orderList.isEmpty
              ? Container()
              : Container(
                  width: width,
                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary.withOpacity(0.10), 0),
                  margin: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0),
                  padding: EdgeInsetsDirectional.only(top: height! / 40.0, bottom: height! / 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 2),
                                height: height! / 40.0,
                                width: width! / 80.0),
                            SizedBox(width: width! / 80.0),
                            Text(UiUtils.getTranslatedLabel(context, activeOrderedLabel),
                                textAlign: TextAlign.start,
                                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: height! / 9.5,
                        child: PageView(
                          scrollDirection: Axis.horizontal,
                          allowImplicitScrolling: true,
                          onPageChanged: (num) {
                            activeOrderSlidePage(num);
                          },
                          children: List.generate(orderList.length > 5 ? 5 : orderList.length, (index) {
                            return Builder(builder: (context) {
                              OrderItems data = orderList[index].orderItems![0];
                              var status = "";
                              if (orderList[index].activeStatus == deliveredKey) {
                                status = UiUtils.getTranslatedLabel(context, deliveredLabel);
                              } else if (orderList[index].activeStatus == pendingKey) {
                                status = UiUtils.getTranslatedLabel(context, pendingLbLabel);
                              } else if (orderList[index].activeStatus == waitingKey) {
                                status = UiUtils.getTranslatedLabel(context, awaitingLbLabel);
                              } else if (orderList[index].activeStatus == outForDeliveryKey) {
                                status = UiUtils.getTranslatedLabel(context, outForDeliveryLbLabel);
                              } else if (orderList[index].activeStatus == confirmedKey) {
                                status = UiUtils.getTranslatedLabel(context, confirmedLbLabel);
                              } else if (orderList[index].activeStatus == cancelledKey) {
                                status = UiUtils.getTranslatedLabel(context, cancelledsLabel);
                              } else if (orderList[index].activeStatus == preparingKey) {
                                status = UiUtils.getTranslatedLabel(context, preparingLbLabel);
                              } else if (orderList[index].activeStatus == readyForPickupKey) {
                                status = UiUtils.getTranslatedLabel(context, readyForPickupLbLabel);
                              } else {
                                status = "";
                              }
                              return GestureDetector(
                                onTap: () {
                                  print(orderList[index].activeStatus);
                                  Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
                                    'id': orderList[index].id!,
                                    'riderId': orderList[index].riderId!,
                                    'riderName': orderList[index].riderName!,
                                    'riderRating': orderList[index].riderRating!,
                                    'riderImage': orderList[index].riderImage!,
                                    'riderMobile': orderList[index].riderMobile!,
                                    'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                    'isSelfPickup': orderList[index].isSelfPickUp!,
                                    'from': orderList[index].activeStatus == "delivered" ? 'orderDeliverd' : 'orderDetail'
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsetsDirectional.only(
                                      start: width! / 25.0, end: width! / 25.0, top: height! / 99.0, bottom: height! / 99.0),
                                  width: width!,
                                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 8.0),
                                  margin: EdgeInsetsDirectional.only(end: width! / 20.0, start: width! / 20.0, top: height! / 40.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                          DesignConfig.setSvgPath(orderList[index].activeStatus == preparingKey
                                              ? "order_prepared"
                                              : orderList[index].activeStatus == readyForPickupKey
                                                  ? "order_place"
                                                  : orderList[index].activeStatus == outForDeliveryKey
                                                      ? "order_of_for_delivery"
                                                      : ""),
                                          width: 24,
                                          height: 24,
                                          colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn)),
                                      SizedBox(width: width! / 40.0),
                                      Expanded(
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data.name!,
                                                textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    overflow: TextOverflow.ellipsis),
                                                maxLines: 1,
                                              ),
                                              Text("${UiUtils.getTranslatedLabel(context, yourOrderIsLabel)} $status",
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  )),
                                            ]),
                                      ),
                                      (orderList[index].activeStatus == outForDeliveryKey)
                                          ? FittedBox(
                                              fit: BoxFit.fitWidth,
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).pushNamed(Routes.orderTracking, arguments: {
                                                    'id': orderList[index].id!,
                                                    'riderId': orderList[index].riderId!,
                                                    'riderName': orderList[index].riderName!,
                                                    'riderRating': orderList[index].riderRating!,
                                                    'riderImage': orderList[index].riderImage!,
                                                    'riderMobile': orderList[index].riderMobile!,
                                                    'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                                    'latitude': double.parse(orderList[index].latitude!),
                                                    'longitude': double.parse(orderList[index].longitude!),
                                                    'latitudeRes': double.parse(orderList[index].branchModel!.latitude!),
                                                    'longitudeRes': double.parse(orderList[index].branchModel!.longitude!),
                                                    'orderAddress': orderList[index].address,
                                                    'partnerAddress': context.read<SettingsCubit>().getSettings().branchAddress,
                                                    'isTracking': orderList[index].activeStatus == outForDeliveryKey ? true : false
                                                  });
                                                },
                                                child: Padding(
                                                    padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                                    child: Icon(Icons.arrow_circle_right_rounded,
                                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))),
                                              ))
                                          : const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              );
                            });
                          }),
                        ),
                      ),
                      orderList.length > 1 ? SizedBox(height: height! / 80.0) : SizedBox.shrink(),
                      orderList.length > 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: orderList
                                  .map((item) => Container(
                                        width: _currentPageActiveOrder == orderList.indexOf(item) ? 16.0 : 8.0,
                                        height: 8.0,
                                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                        decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                            color: _currentPageActiveOrder == orderList.indexOf(item)
                                                ? Theme.of(context).colorScheme.secondary
                                                : Theme.of(context).colorScheme.secondary.withOpacity(0.50)),
                                      ))
                                  .toList(),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                );
        });
  }

  Widget topDeal() {
    return BlocConsumer<SectionsCubit, SectionsState>(
        bloc: context.read<SectionsCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is SectionsProgress || state is SectionsInitial) {
            return SectionSimmer(length: 5, width: width!, height: height!);
          }
          if (state is SectionsFailure) {
            return const SizedBox();
          }
          final sectionsList = (state as SectionsSuccess).sectionsList;
          final hasMore = state.hasMore;
          return sectionsList.isEmpty
              ? const SizedBox()
              : Column(
                  children: List.generate(sectionsList.length, (index) {
                  sectionProductList = sectionsList[index].productDetails!;
                  return hasMore && index == (sectionsList.length - 1)
                      ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                      : sectionsList[index].productDetails!.isEmpty
                          ? const SizedBox()
                          : Container(
                              padding: EdgeInsetsDirectional.only(top: height! / 80.0),
                              margin: EdgeInsetsDirectional.only(top: height! / 70.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sectionsList[index].productDetails!.isEmpty
                                      ? Container()
                                      : Padding(
                                          padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
                                          child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                                                        height: height! / 40.0,
                                                        width: width! / 80.0),
                                                    SizedBox(width: width! / 80.0),
                                                    Text(sectionsList[index].title!,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                            color: Theme.of(context).colorScheme.onPrimary,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w700)),
                                                  ],
                                                ),
                                                const Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.of(context).pushNamed(Routes.section,
                                                        arguments: {'title': sectionsList[index].title!, 'sectionId': sectionsList[index].id!});
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(UiUtils.getTranslatedLabel(context, showAllLabel),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500)),
                                                      SizedBox(width: width! / 80.0),
                                                      Icon(Icons.arrow_circle_right_rounded,
                                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))
                                                    ],
                                                  ),
                                                ),
                                              ]),
                                        ),
                                  sectionsList[index].productDetails!.isEmpty
                                      ? Container()
                                      : (index.isEven)
                                          ? SizedBox(
                                              height: height! / 3.4,
                                              width: width!,
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: List.generate(sectionsList[index].productDetails!.length, (i) {
                                                    double price = double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!);
                                                    if (price == 0) {
                                                      price = double.parse(sectionsList[index].productDetails![i].variants![0].price!);
                                                    }

                                                    double off = 0;
                                                    if (sectionsList[index].productDetails![i].variants![0].specialPrice! != "0") {
                                                      off = (double.parse(sectionsList[index].productDetails![i].variants![0].price!) -
                                                              double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!))
                                                          .toDouble();
                                                      off = off *
                                                          100 /
                                                          double.parse(sectionsList[index].productDetails![i].variants![0].price!).toDouble();
                                                    }

                                                    return GestureDetector(
                                                      onTap: () {
                                                        if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
                                                          bool check = getStoreOpenStatus(sectionsList[index].productDetails![i].startTime!,
                                                              sectionsList[index].productDetails![i].endTime!);
                                                          if (sectionsList[index].productDetails![i].availableTime == "1") {
                                                            if (check == true) {
                                                              addToCartBottomModelSheet(context.read<GetCartCubit>().getProductDetailsData(
                                                                  sectionsList[index].productDetails![i].id!,
                                                                  sectionsList[index].productDetails![i])[0]);
                                                            } else {
                                                              showDialog(
                                                                  context: context,
                                                                  builder: (_) => ProductUnavailableDialog(
                                                                      startTime: sectionsList[index].productDetails![i].startTime,
                                                                      endTime: sectionsList[index].productDetails![i].endTime,
                                                                      width: width,
                                                                      height: height));
                                                            }
                                                          } else {
                                                            addToCartBottomModelSheet(context.read<GetCartCubit>().getProductDetailsData(
                                                                sectionsList[index].productDetails![i].id!,
                                                                sectionsList[index].productDetails![i])[0]);
                                                          }
                                                        } else {
                                                          showDialog(
                                                              context: context,
                                                              builder: (_) => BranchCloseDialog(
                                                                  hours: "", minute: "", status: false, width: width!, height: height!));
                                                        }
                                                      },
                                                      child: ProductSectionContainer(
                                                          productDetails: sectionsList[index].productDetails![i],
                                                          height: height!,
                                                          width: width,
                                                          productDetailsList: sectionsList[index].productDetails!,
                                                          price: price,
                                                          off: off,
                                                          from: "home",
                                                          axis: "horizontal"),
                                                    );
                                                  }),
                                                ),
                                              ))
                                          : SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: Column(
                                                  children: List.generate(sectionsList[index].productDetails!.length, (i) {
                                                double price = double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!);
                                                if (price == 0) {
                                                  price = double.parse(sectionsList[index].productDetails![i].variants![0].price!);
                                                }

                                                double off = 0;
                                                if (sectionsList[index].productDetails![i].variants![0].specialPrice! != "0") {
                                                  off = (double.parse(sectionsList[index].productDetails![i].variants![0].price!) -
                                                          double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!))
                                                      .toDouble();
                                                  off =
                                                      off * 100 / double.parse(sectionsList[index].productDetails![i].variants![0].price!).toDouble();
                                                }

                                                return GestureDetector(
                                                  onTap: () {
                                                    if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
                                                      bool check = getStoreOpenStatus(sectionsList[index].productDetails![i].startTime!,
                                                          sectionsList[index].productDetails![i].endTime!);
                                                      if (sectionsList[index].productDetails![i].availableTime == "1") {
                                                        if (check == true) {
                                                          addToCartBottomModelSheet(context.read<GetCartCubit>().getProductDetailsData(
                                                              sectionsList[index].productDetails![i].id!, sectionsList[index].productDetails![i])[0]);
                                                        } else {
                                                          showDialog(
                                                              context: context,
                                                              builder: (_) => ProductUnavailableDialog(
                                                                  startTime: sectionsList[index].productDetails![i].startTime,
                                                                  endTime: sectionsList[index].productDetails![i].endTime,
                                                                  width: width,
                                                                  height: height));
                                                        }
                                                      } else {
                                                        addToCartBottomModelSheet(context.read<GetCartCubit>().getProductDetailsData(
                                                            sectionsList[index].productDetails![i].id!, sectionsList[index].productDetails![i])[0]);
                                                      }
                                                    } else {
                                                      showDialog(
                                                          context: context,
                                                          builder: (_) => BranchCloseDialog(
                                                              hours: "", minute: "", status: false, width: width!, height: height!));
                                                    }
                                                  },
                                                  child: ProductSectionContainer(
                                                      productDetails: sectionsList[index].productDetails![i],
                                                      height: height!,
                                                      width: width,
                                                      productDetailsList: sectionsList[index].productDetails!,
                                                      price: price,
                                                      off: off,
                                                      from: "home",
                                                      axis: "vertical"),
                                                );
                                              })),
                                            ),
                                ],
                              ),
                            );
                }));
        });
  }

  Widget hotDeal() {
    return BlocConsumer<BestOfferCubit, BestOfferState>(
        bloc: context.read<BestOfferCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is BestOfferProgress || state is BestOfferInitial) {
            return SliderSimmer(width: width!, height: height!);
          }
          if (state is BestOfferFailure) {
            return SizedBox.shrink();
          }
          final bestOfferList = (state as BestOfferSuccess).bestOfferList;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 80.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                          height: height! / 40.0,
                          width: width! / 80.0),
                      SizedBox(width: width! / 80.0),
                      Text(UiUtils.getTranslatedLabel(context, hotDealLabel),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(Routes.bestOffer);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(UiUtils.getTranslatedLabel(context, showAllLabel),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w500)),
                        SizedBox(width: width! / 80.0),
                        Icon(Icons.arrow_circle_right_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))
                      ],
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 60.0),
                child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    crossAxisCount: 2,
                    childAspectRatio: 0.86,
                    mainAxisSpacing: height! / 80.0,
                    crossAxisSpacing: width! / 40.0,
                    children: List.generate(
                      bestOfferList.length > 4 ? 4 : bestOfferList.length,
                      (index) {
                        return OfferImageContainer(index: index, bestOfferList: bestOfferList, height: height!, width: width!);
                      },
                    )),
              ),
            ],
          );
        });
  }

  Widget slider() {
    return BlocConsumer<SliderCubit, SliderState>(
        bloc: context.read<SliderCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is SliderProgress || state is SliderInitial) {
            return SliderSimmer(width: width!, height: height!);
          }
          if (state is SliderFailure) {
            return const SizedBox();
          }
          final sliderList = (state as SliderSuccess).sliderList;
          return sliderList.isEmpty
              ? const SizedBox()
              : Column(
                  children: [
                    CarouselSlider(
                        items: sliderList
                            .map((item) => GestureDetector(
                                  onTap: () {
                                    if (item.type == "default") {
                                    } else if (item.type == "categories") {
                                      Navigator.of(context)
                                          .pushNamed(Routes.cuisineDetail, arguments: {'categoryId': item.data![0].id!, 'name': item.data![0].text!});
                                    } else if (item.type == "products") {
                                      Navigator.of(context).pushNamed(Routes.menu);
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: 10.0),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                      child: DesignConfig.imageWidgets(item.image!, height! / 5.0, width!, "2"),
                                    ),
                                  ),
                                ))
                            .toList(),
                        options: CarouselOptions(
                          autoPlay: true,
                          enlargeCenterPage: true,
                          reverse: false,
                          viewportFraction: 1,
                          autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                          aspectRatio: 2.2,
                          initialPage: 0,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sliderList
                          .map((item) => Container(
                                width: _currentPage == sliderList.indexOf(item) ? 15.0 : 6.0,
                                height: 6.0,
                                margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(3.0)),
                                    color: _currentPage == sliderList.indexOf(item)
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.secondary),
                              ))
                          .toList(),
                    ),
                  ],
                );
        });
  }

  Widget popularDishes() {
    return BlocConsumer<TopRatedProductCubit, TopRatedProductState>(
        bloc: context.read<TopRatedProductCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is TopRatedProductProgress || state is TopRatedProductInitial) {
            return TopBrandSimmer(width: width!, height: height! / 3.2, length: 2);
          }
          if (state is TopRatedProductFailure) {
            return const SizedBox();
          }
          topProductList = (state as TopRatedProductSuccess).topRatedProductList;

          return Container(
            margin: EdgeInsetsDirectional.only(top: height! / 60.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 80.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                            height: height! / 40.0,
                            width: width! / 80.0),
                        SizedBox(width: width! / 80.0),
                        Text(UiUtils.getTranslatedLabel(context, popularDishesLabel),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) => const TopBrandScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(UiUtils.getTranslatedLabel(context, showAllLabel),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w500)),
                          SizedBox(width: width! / 80.0),
                          Icon(Icons.arrow_circle_right_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))
                        ],
                      ),
                    ),
                  ]),
                ),
                SizedBox(height: height! / 99.0),
                topProductList.isEmpty
                    ? const SizedBox()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              topProductList.length > 5 ? 5 : topProductList.length,
                              (index) {
                                ProductDetails dataItem = topProductList[index];
                                double price = double.parse(dataItem.variants![0].specialPrice!);
                                if (price == 0) {
                                  price = double.parse(dataItem.variants![0].price!);
                                }
                                double off = 0;
                                if (dataItem.variants![0].specialPrice! != "0") {
                                  off = (double.parse(dataItem.variants![0].price!) - double.parse(dataItem.variants![0].specialPrice!)).toDouble();
                                  off = off * 100 / double.parse(dataItem.variants![0].price!).toDouble();
                                }
                                return TopBrandContainer(
                                    index: index,
                                    topProductList: topProductList,
                                    height: height!,
                                    width: width!,
                                    from: "home",
                                    price: price,
                                    off: off);
                              },
                            )),
                      ),
              ],
            ),
          );
        });
  }

  Widget recommendedForYou() {
    return BlocConsumer<ProductCubit, ProductState>(
        bloc: context.read<ProductCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is ProductProgress || state is ProductInitial) {
            return ProductSimmer(length: 5, width: width!, height: height!);
          }
          if (state is ProductFailure) {
            return const SizedBox();
          }
          productList = (state as ProductSuccess).productList;
          final hasMore = state.hasMore;
          return productList.isEmpty
              ? const SizedBox()
              : Container(
                  margin: EdgeInsetsDirectional.only(top: height! / 70.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 80.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                                  height: height! / 40.0,
                                  width: width! / 80.0),
                              SizedBox(width: width! / 80.0),
                              Text(UiUtils.getTranslatedLabel(context, delightfulDishesLabel),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed(Routes.menu);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(UiUtils.getTranslatedLabel(context, showAllLabel),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w500)),
                                SizedBox(width: width! / 80.0),
                                Icon(Icons.arrow_circle_right_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))
                              ],
                            ),
                          ),
                        ]),
                      ),
                      productList.isEmpty
                          ? const SizedBox()
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: productList.length > 5 ? 5 : productList.length,
                              itemBuilder: (BuildContext context, index) {
                                ProductDetails dataItem = productList[index];
                                double price = double.parse(dataItem.variants![0].specialPrice!);
                                if (price == 0) {
                                  price = double.parse(dataItem.variants![0].price!);
                                }
                                double off = 0;
                                if (dataItem.variants![0].specialPrice! != "0") {
                                  off = (double.parse(dataItem.variants![0].price!) - double.parse(dataItem.variants![0].specialPrice!)).toDouble();
                                  off = off * 100 / double.parse(dataItem.variants![0].price!).toDouble();
                                }
                                return hasMore && productList.isEmpty && index == (productList.length - 1)
                                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                                    : BlocProvider(
                                        create: (context) => GetQuantityCubit(),
                                        child: ProductContainer(
                                            productDetails: productList[index],
                                            height: height!,
                                            width: width!,
                                            price: price,
                                            off: off,
                                            productList: productList,
                                            index: index,
                                            from: "home"),
                                      );
                              }),
                    ],
                  ),
                );
        });
  }

  Future<void> refreshList() async {
    await context.read<CityDeliverableCubit>().fetchCityDeliverable(
        context.read<SettingsCubit>().state.settingsModel!.city.toString(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollBottomBarController.removeListener(() {});
    locationSearchController.dispose();
    _scrollBottomBarController.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Widget enterLocationSearch() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        locationBottomModelSheetShow();
      },
      child: Container(
        width: width,
        margin: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 45.0, start: width! / 20.0, end: width! / 20.0),
        padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, top: height! / 80.0, bottom: height! / 80.0),
        decoration: DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
        child: Text(UiUtils.getTranslatedLabel(context, enterLocationAreaCityEtcLabel),
            style: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76))),
      ),
    );
  }

  contentBox(context) {
    return Container(
      padding: EdgeInsets.only(top: height! / 40.0),
      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(UiUtils.getTranslatedLabel(context, deviceLocationIsOffLabel),
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600, fontStyle: FontStyle.normal, fontSize: 14.0),
              textAlign: TextAlign.left),
          SizedBox(
            height: height! / 80.0,
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
            child: Text(UiUtils.getTranslatedLabel(context, deviceLocationIsOffSubTitleLabel),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 14.0, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(
            height: 22,
          ),
          enterLocationSearch(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              getUserLocation();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: width! / 99.0),
                Text(UiUtils.getTranslatedLabel(context, enableDeviceLocationLabel),
                    style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(height: height! / 40.0),
        ],
      ),
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
            : Scaffold(
                extendBody: true,
                backgroundColor: Theme.of(context).colorScheme.onBackground,
                bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return BlocConsumer<GetCartCubit, GetCartState>(
                          bloc: context.read<GetCartCubit>(),
                          listener: (context, state) {
                            if (state is GetCartSuccess) {}
                          },
                          builder: (context, state) {
                            if (state is GetCartProgress || state is GetCartInitial || state is GetCartFailure) {
                              return const SizedBox();
                            }

                            if (state is GetCartSuccess) {
                              return Container(
                                margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 40.0),
                                width: width,
                                padding:
                                    EdgeInsetsDirectional.only(top: height! / 55.0, bottom: height! / 55.0, start: width! / 20.0, end: width! / 20.0),
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 100.0),
                                child: Row(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text("${state.cartModel.totalQuantity} ${UiUtils.getTranslatedLabel(context, itemTagLabel)} | ",
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style:
                                                TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                        Text(
                                            context.read<SystemConfigCubit>().getCurrency() +
                                                (double.parse(state.cartModel.subTotal.toString())).toStringAsFixed(2),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            style:
                                                TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                        onTap: () {
                                          clearAll();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (BuildContext context) => const CartScreen(
                                                from: 'home',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(UiUtils.getTranslatedLabel(context, viewCartLabel),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w500))),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          });
                    }
                    return BlocConsumer<SettingsCubit, SettingsState>(
                        bloc: context.read<SettingsCubit>(),
                        listener: (context, state) {},
                        builder: (context, state) {
                          return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) &&
                                  (state.settingsModel!.cartCount.toString() == "0" ||
                                      state.settingsModel!.cartCount.toString() == "" ||
                                      state.settingsModel!.cartCount.toString() == "0.0") &&
                                  (state.settingsModel!.cartTotal.toString() == "0" ||
                                      state.settingsModel!.cartTotal.toString() == "" ||
                                      state.settingsModel!.cartTotal.toString() == "0.0" ||
                                      state.settingsModel!.cartTotal.toString() == "0.00")
                              ? Container(
                                  height: 0.0,
                                )
                              : Container(
                                  margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 40.0),
                                  width: width,
                                  padding: EdgeInsetsDirectional.only(
                                      top: height! / 55.0, bottom: height! / 55.0, start: width! / 20.0, end: width! / 20.0),
                                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 100.0),
                                  child: Row(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text("${state.settingsModel!.cartCount} ${UiUtils.getTranslatedLabel(context, itemTagLabel)} | ",
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                          Text(
                                              context.read<SystemConfigCubit>().getCurrency() + state.settingsModel!.cartTotal.toString() == ""
                                                  ? "0"
                                                  : double.parse(state.settingsModel!.cartTotal.toString()).toStringAsFixed(2),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                          onTap: () {
                                            clearAll();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (BuildContext context) => const CartScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(UiUtils.getTranslatedLabel(context, viewCartLabel),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                );
                        });
                  },
                ),
                body: SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                      onRefresh: refreshList,
                      color: Theme.of(context).colorScheme.primary,
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: Container(
                              margin: EdgeInsetsDirectional.only(start: width! / 25.0, end: width! / 20.0),
                              color: Theme.of(context).colorScheme.onBackground,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        InkWell(
                                            onTap: () {
                                              locationBottomModelSheetShow();
                                            },
                                            child: Container(
                                                width: 24.0,
                                                height: 24.0,
                                                margin: EdgeInsetsDirectional.only(top: height! / 60.0, bottom: height! / 99.0, end: width! / 40.0),
                                                child: SvgPicture.asset(
                                                  DesignConfig.setSvgPath("location_pin"),
                                                  width: 18.0,
                                                  height: 18.0,
                                                ))),
                                        InkWell(
                                          onTap: () {
                                            locationBottomModelSheetShow();
                                          },
                                          child: deliveryLocation(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context).pushNamed(Routes.notification);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.all(8.0),
                                          child: CircleAvatar(
                                              radius: 16.0,
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              child: SvgPicture.asset(DesignConfig.setSvgPath("notification"),
                                                  width: 16.0,
                                                  height: 16.0,
                                                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn))),
                                        ),
                                      ),
                                      BlocBuilder<AuthCubit, AuthState>(
                                          bloc: context.read<AuthCubit>(),
                                          builder: (context, state) {
                                            if (state is Authenticated) {
                                              return InkWell(
                                                onTap: () {
                                                  Navigator.of(context).pushNamed(Routes.account);
                                                },
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Theme.of(context).colorScheme.onBackground,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    child: ClipOval(child: DesignConfig.imageWidgets(state.authModel.image!, 30, 30, "1")),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return InkWell(
                                                onTap: () {
                                                  Navigator.of(context).pushNamed(Routes.account);
                                                },
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Theme.of(context).colorScheme.onBackground,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    child: ClipOval(
                                                        child: DesignConfig.imageWidgets(DesignConfig.setPngPath('profile_pic'), 30, 30, "1")),
                                                  ),
                                                ),
                                              );
                                            }
                                          }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverAppBar(
                            automaticallyImplyLeading: false,
                            shadowColor: Colors.transparent,
                            backgroundColor: Theme.of(context).colorScheme.onBackground,
                            systemOverlayStyle: SystemUiOverlayStyle.dark,
                            iconTheme: const IconThemeData(
                              color: black,
                            ),
                            /* flexibleSpace: DesignConfig.appBarWihoutBackbutton(context, width, "", const PreferredSize(
                                preferredSize: Size.zero,child:SizedBox())), */
                            floating: false,
                            pinned: true,
                            title: Padding(
                              padding: EdgeInsetsDirectional.only(bottom: height! / 99, top: height! / 99),
                              child: Row(
                                children: [
                                  Expanded(child: searchBar()),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(Routes.search);
                                    },
                                    child: VoiceSearchContainer(
                                      width: width!,
                                      height: height!,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return BlocConsumer<CityDeliverableCubit, CityDeliverableState>(
                                    bloc: context.read<CityDeliverableCubit>(),
                                    listener: (context, state) {
                                      if (state is CityDeliverableSuccess) {
                                        context.read<SettingsCubit>().setCityId(state.cityId.toString());
                                        if (state.branchModel.isNotEmpty) {
                                          context.read<SettingsCubit>().setBranchId(state.branchModel[0].branchId!);

                                          context.read<SettingsCubit>().setBranchLatitude(state.branchModel[0].latitude!);
                                          context.read<SettingsCubit>().setBranchLongitude(state.branchModel[0].longitude!);
                                          context.read<SettingsCubit>().setBranchAddress(state.branchModel[0].address!);
                                          context.read<SettingsCubit>().setDeliverOrder(state.branchModel[0].deliverOrder!);
                                          context.read<SettingsCubit>().setSelfPickup(state.branchModel[0].selfPickup!);
                                          context.read<SettingsCubit>().setIsBranchOpen(state.branchModel[0].isBranchOpen!);
                                        } else {
                                          context.read<SettingsCubit>().setBranchId("");

                                          context.read<SettingsCubit>().setBranchLatitude("");
                                          context.read<SettingsCubit>().setBranchLongitude("");
                                          context.read<SettingsCubit>().setBranchAddress("");
                                          context.read<SettingsCubit>().setDeliverOrder("");
                                          context.read<SettingsCubit>().setSelfPickup("");
                                          context.read<SettingsCubit>().setIsBranchOpen("");
                                        }

                                        apiCall();
                                        context.read<ProductCubit>().fetchProduct(perPage, context.read<AuthCubit>().getId(),
                                            context.read<SettingsCubit>().getSettings().branchId, "", "", "", "");
                                        context.read<TopRatedProductCubit>().fetchTopRatedProduct(
                                            perPage, "1", context.read<AuthCubit>().getId(), context.read<SettingsCubit>().getSettings().branchId);
                                        context.read<SectionsCubit>().fetchSections(perPage, context.read<AuthCubit>().getId(), "",
                                            context.read<SettingsCubit>().state.settingsModel!.branchId);
                                      }
                                    },
                                    builder: (context, state) {
                                      if (state is CityDeliverableProgress || state is CityDeliverableInitial) {
                                        return HomeSimmer(
                                          width: width,
                                          height: height,
                                        );
                                      }
                                      if (state is CityDeliverableFailure) {
                                        return SingleChildScrollView(
                                          child: Column(children: [
                                            SizedBox(height: height! / 40.0),
                                            SvgPicture.asset(
                                              DesignConfig.setSvgPath("location"),
                                              height: height! / 3.0,
                                              width: height! / 3.0,
                                              fit: BoxFit.scaleDown,
                                            ),
                                            SizedBox(height: height! / 20.0),
                                            Text(
                                              UiUtils.getTranslatedLabel(context, isnTAvailableLable),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.secondary, fontSize: 26, fontWeight: FontWeight.w700),
                                              maxLines: 2,
                                            ),
                                            const SizedBox(height: 5.0),
                                            Padding(
                                              padding: EdgeInsets.only(left: width! / 15.0, right: width! / 15.0),
                                              child: Text(UiUtils.getTranslatedLabel(context, sorryWeAreNotDeliveryFoodOnCurrentLocationLabel),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(height: 5.0),
                                            GestureDetector(
                                                onTap: () {
                                                  locationBottomModelSheetShow();
                                                },
                                                child: Container(
                                                    margin: EdgeInsetsDirectional.only(top: height! / 12.0),
                                                    padding: EdgeInsetsDirectional.only(
                                                        top: height! / 70.0, bottom: 12.0, start: width! / 20.0, end: width! / 20.0),
                                                    decoration: DesignConfig.boxDecorationContainerBorder(
                                                        Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary, 4.0),
                                                    child: Text(UiUtils.getTranslatedLabel(context, tryDifferentLocationLabel),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                            color: Theme.of(context).colorScheme.onPrimary,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500)))),
                                          ]),
                                        );
                                      }
                                      if (state is CityDeliverableSuccess) {
                                        if (state.branchModel.isEmpty) {
                                          return SingleChildScrollView(
                                            child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  SizedBox(height: height! / 10.0),
                                                  SvgPicture.asset(
                                                    DesignConfig.setSvgPath("location"),
                                                    height: height! / 3.0,
                                                    width: height! / 3.0,
                                                    fit: BoxFit.scaleDown,
                                                  ),
                                                  SizedBox(height: height! / 20.0),
                                                  Text(
                                                    UiUtils.getTranslatedLabel(context, isnTAvailableLable),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.secondary, fontSize: 26, fontWeight: FontWeight.w700),
                                                    maxLines: 2,
                                                  ),
                                                  const SizedBox(height: 5.0),
                                                  Padding(
                                                    padding: EdgeInsets.only(left: width! / 15.0, right: width! / 15.0),
                                                    child: Text(UiUtils.getTranslatedLabel(context, sorryWeAreNotDeliveryFoodOnCurrentBranchLabel),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                            color: Theme.of(context).colorScheme.onPrimary,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600)),
                                                  ),
                                                ]),
                                          );
                                        }
                                      }
                                      return homeList();
                                    });
                              },
                              childCount: 1,
                            ),
                          ),
                        ],
                      )),
                ),
              ));
  }
}
