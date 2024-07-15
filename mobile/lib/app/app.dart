import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wakDak/app/appLocalization.dart';
import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/address/addAddressCubit.dart';
import 'package:wakDak/cubit/address/addressCubit.dart';
import 'package:wakDak/cubit/address/cityDeliverableCubit.dart';
import 'package:wakDak/cubit/address/deliveryChargeCubit.dart';
import 'package:wakDak/cubit/address/isOrderDeliverableCubit.dart';
import 'package:wakDak/cubit/address/updateAddressCubit.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/auth/deleteMyAccountCubit.dart';
import 'package:wakDak/cubit/auth/referAndEarnCubit.dart';
import 'package:wakDak/cubit/auth/signInCubit.dart';
import 'package:wakDak/cubit/auth/signUpCubit.dart';
import 'package:wakDak/cubit/auth/socialSignUpCubit.dart';
import 'package:wakDak/cubit/branch/branchCubit.dart';
import 'package:wakDak/cubit/cart/clearCartCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/cart/manageCartCubit.dart';
import 'package:wakDak/cubit/cart/placeOrder.dart';
import 'package:wakDak/cubit/cart/removeFromCartCubit.dart';
import 'package:wakDak/cubit/favourite/favouriteProductsCubit.dart';
import 'package:wakDak/cubit/favourite/updateFavouriteProduct.dart';
import 'package:wakDak/cubit/helpAndSupport/ticketCubit.dart';
import 'package:wakDak/cubit/home/bestOffer/bestOfferCubit.dart';
import 'package:wakDak/cubit/home/cuisine/cuisineCubit.dart';
import 'package:wakDak/cubit/home/search/searchCubit.dart';
import 'package:wakDak/cubit/home/sections/sectionsCubit.dart';
import 'package:wakDak/cubit/home/sections/sectionsDetailCubit.dart';
import 'package:wakDak/cubit/home/slider/sliderOfferCubit.dart';
import 'package:wakDak/cubit/localization/appLocalizationCubit.dart';
import 'package:wakDak/cubit/notification/notificationCubit.dart';
import 'package:wakDak/cubit/order/activeOrderCubit.dart';
import 'package:wakDak/cubit/order/historyOrderCubit.dart';
import 'package:wakDak/cubit/order/orderAgainCubit.dart';
import 'package:wakDak/cubit/order/orderCubit.dart';
import 'package:wakDak/cubit/order/orderDetailCubit.dart';
import 'package:wakDak/cubit/order/orderLiveTrackingCubit.dart';
import 'package:wakDak/cubit/order/reOrderCubit.dart';
import 'package:wakDak/cubit/payment/GetWithdrawRequestCubit.dart';
import 'package:wakDak/cubit/payment/sendWithdrawRequestCubit.dart';
import 'package:wakDak/cubit/product/offlineCartCubit.dart';
import 'package:wakDak/cubit/product/productCubit.dart';
import 'package:wakDak/cubit/product/topRatedProductCubit.dart';
import 'package:wakDak/cubit/profileManagement/updateUserDetailsCubit.dart';
import 'package:wakDak/cubit/promoCode/promoCodeCubit.dart';
import 'package:wakDak/cubit/promoCode/validatePromoCodeCubit.dart';
import 'package:wakDak/cubit/rating/setRiderRatingCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/cubit/transaction/transactionCubit.dart';
import 'package:wakDak/data/repositories/address/addressRepository.dart';
import 'package:wakDak/data/repositories/auth/authRepository.dart';
import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/data/repositories/home/bestOffer/bestOfferRepository.dart';
import 'package:wakDak/data/repositories/home/slider/sliderRepository.dart';
import 'package:wakDak/data/repositories/order/orderRepository.dart';
import 'package:wakDak/data/repositories/payment/paymentRepository.dart';
import 'package:wakDak/data/repositories/product/productRepository.dart';
import 'package:wakDak/data/repositories/profileManagement/profileManagementRepository.dart';
import 'package:wakDak/data/repositories/promoCode/promoCodeRepository.dart';
import 'package:wakDak/data/repositories/rating/ratingRepository.dart';
import 'package:wakDak/data/repositories/settings/settingsRepository.dart';
import 'package:wakDak/data/repositories/systemConfig/systemConfigRepository.dart';
import 'package:wakDak/firebase_options.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/utils/appLanguages.dart';
import 'package:wakDak/utils/hiveBoxKey.dart';
import 'package:wakDak/utils/uiUtils.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<Widget> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark));
    initializedDownload();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {}
  }

  await Hive.initFlutter();
  await Hive.openBox(
      authBox); //auth box for storing all authentication related details
  await Hive.openBox(
      settingsBox); //settings box for storing all settings details
  await Hive.openBox(
      userDetailsBox); //userDetails box for storing all userDetails details
  await Hive.openBox(addressBox); //address box for storing all address details
  await Hive.openBox(
      searchAddressBox); //searchAddress box for storing all searchAddress details
  await Hive.openBox(
      searchProductKeyWordsBox); //searchAddress box for storing all searchAddress details

  return const MyApp();
}

Future<void> initializedDownload() async {
  await FlutterDownloader.initialize(debug: false);
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Providing global providers
      providers: [
        // Creating cubit/bloc that will be use in whole app or will be use in multiple screens
        BlocProvider<AppLocalizationCubit>(
            create: (_) => AppLocalizationCubit(SettingsRepository())),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
        BlocProvider<SignUpCubit>(create: (_) => SignUpCubit(AuthRepository())),
        BlocProvider<ReferAndEarnCubit>(
            create: (_) => ReferAndEarnCubit(AuthRepository())),
        BlocProvider<SignInCubit>(create: (_) => SignInCubit(AuthRepository())),
        BlocProvider<SocialSignUpCubit>(
            create: (_) => SocialSignUpCubit(AuthRepository())),
        BlocProvider<ProductCubit>(create: (_) => ProductCubit()),
        BlocProvider<BranchCubit>(create: (_) => BranchCubit()),
        BlocProvider<TopRatedProductCubit>(
            create: (_) => TopRatedProductCubit()),
        BlocProvider<CuisineCubit>(create: (_) => CuisineCubit()),
        BlocProvider<BestOfferCubit>(
            create: (_) => BestOfferCubit(BestOfferRepository())),
        BlocProvider<SliderCubit>(
            create: (_) => SliderCubit(SliderRepository())),
        BlocProvider<SectionsCubit>(create: (_) => SectionsCubit()),
        BlocProvider<SectionsDetailCubit>(create: (_) => SectionsDetailCubit()),
        BlocProvider<AddressCubit>(
            create: (_) => AddressCubit(AddressRepository())),
        BlocProvider<AddAddressCubit>(
            create: (_) => AddAddressCubit(AddressRepository())),
        BlocProvider<CityDeliverableCubit>(
            create: (_) => CityDeliverableCubit(AddressRepository())),
        BlocProvider<IsOrderDeliverableCubit>(
            create: (_) => IsOrderDeliverableCubit(AddressRepository())),
        BlocProvider<PromoCodeCubit>(create: (_) => PromoCodeCubit()),
        BlocProvider<ValidatePromoCodeCubit>(
            create: (_) => ValidatePromoCodeCubit(PromoCodeRepository())),
        BlocProvider<GetCartCubit>(
            create: (_) => GetCartCubit(CartRepository())),
        BlocProvider<ManageCartCubit>(
            create: (_) => ManageCartCubit(CartRepository())),
        BlocProvider<RemoveFromCartCubit>(
            create: (_) => RemoveFromCartCubit(CartRepository())),
        BlocProvider<OrderCubit>(create: (_) => OrderCubit()),
        BlocProvider<OrderAgainCubit>(create: (_) => OrderAgainCubit()),
        BlocProvider<PlaceOrderCubit>(
            create: (_) => PlaceOrderCubit(CartRepository())),
        BlocProvider<SearchCubit>(create: (_) => SearchCubit()),
        BlocProvider<SystemConfigCubit>(
            create: (_) => SystemConfigCubit(SystemConfigRepository())),
        BlocProvider<OrderDetailCubit>(
            create: (_) => OrderDetailCubit(OrderRepository())),
        BlocProvider<OrderLiveTrackingCubit>(
            create: (_) => OrderLiveTrackingCubit(OrderRepository())),
        BlocProvider<UpdateAddressCubit>(
            create: (_) => UpdateAddressCubit(AddressRepository())),
        BlocProvider<DeliveryChargeCubit>(
            create: (_) => DeliveryChargeCubit(AddressRepository())),
        BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(SettingsRepository())),
        BlocProvider<SetRiderRatingCubit>(
            create: (_) => SetRiderRatingCubit(RatingRepository())),
        BlocProvider<FavoriteProductsCubit>(
            create: (_) => FavoriteProductsCubit()),
        BlocProvider<UpdateProductFavoriteStatusCubit>(
            create: (_) => UpdateProductFavoriteStatusCubit()),
        BlocProvider<DeleteMyAccountCubit>(
            create: (_) => DeleteMyAccountCubit(AuthRepository())),
        BlocProvider<ClearCartCubit>(
            create: (_) => ClearCartCubit(CartRepository())),
        BlocProvider<OfflineCartCubit>(
            create: (_) => OfflineCartCubit(ProductRepository())),
        BlocProvider<SendWithdrawRequestCubit>(
            create: (_) => SendWithdrawRequestCubit(PaymentRepository())),
        BlocProvider<GetWithdrawRequestCubit>(
            create: (_) => GetWithdrawRequestCubit()),
        BlocProvider<TicketCubit>(create: (_) => TicketCubit()),
        BlocProvider<NotificationCubit>(create: (_) => NotificationCubit()),
        BlocProvider<ActiveOrderCubit>(create: (_) => ActiveOrderCubit()),
        BlocProvider<HistoryOrderCubit>(create: (_) => HistoryOrderCubit()),
        BlocProvider<ReOrderCubit>(
            create: (_) => ReOrderCubit(OrderRepository())),
        BlocProvider<UpdateUserDetailCubit>(
            create: (_) =>
                UpdateUserDetailCubit(ProfileManagementRepository())),
        BlocProvider<TransactionCubit>(create: (_) => TransactionCubit()),
      ],
      child: Builder(
        builder: (context) {
          final currentLanguage =
              context.watch<AppLocalizationCubit>().state.language;
          return MaterialApp(
            navigatorKey: navigatorKey,
            builder: (context, widget) {
              return ScrollConfiguration(
                  behavior: GlobalScrollBehavior(), child: widget!);
            },
            theme: ThemeData(
                useMaterial3: false,
                scaffoldBackgroundColor: onBackgroundColor,
                fontFamily: 'Quicksand',
                iconTheme: const IconThemeData(color: black),
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: primaryColor,
                      secondary: secondaryColor,
                      background: backgroundColor,
                      error: errorColor,
                      onPrimary: onPrimaryColor,
                      onSecondary: onSecondaryColor,
                      onBackground: onBackgroundColor,
                    )
                //visualDensity: VisualDensity.adaptivePlatformDensity, colorScheme: ColorScheme.fromSwatch(primarySwatch: ColorsRes.appColor_material).copyWith(secondary: ColorsRes.yellow),
                ),
            locale: currentLanguage,
            localizationsDelegates: const [
              AppLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: appLanguages.map((appLanguage) {
              return UiUtils.getLocaleFromLanguageCode(
                  appLanguage.languageCode);
            }).toList(),
            debugShowCheckedModeBanner: false,
            initialRoute: Routes.splash,
            onGenerateRoute: Routes.onGenerateRouted,
          );
        },
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
