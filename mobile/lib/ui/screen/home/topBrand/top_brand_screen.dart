import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/product/topRatedProductCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/simmer/topBrandSimmer.dart';
import 'package:wakDak/ui/widgets/topBrandContainer.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class TopBrandScreen extends StatefulWidget {
  const TopBrandScreen({Key? key}) : super(key: key);

  @override
  TopBrandScreenState createState() => TopBrandScreenState();
}

class TopBrandScreenState extends State<TopBrandScreen> {
  double? width, height;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  ScrollController topRestaurantController = ScrollController();
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
    topRestaurantController.addListener(topRestaurantScrollListener);
    topRestaurantApi();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  topRestaurantApi() {
    context.read<TopRatedProductCubit>().fetchTopRatedProduct(
        perPage,
        "1",
        context.read<AuthCubit>().getId(),
        context.read<SettingsCubit>().getSettings().branchId);
  }

  topRestaurantScrollListener() {
    if (topRestaurantController.position.maxScrollExtent == topRestaurantController.offset) {
      if (context.read<TopRatedProductCubit>().hasMoreData()) {
        context.read<TopRatedProductCubit>().fetchMoreTopRatedProductData(
            perPage,
            "1",
            context.read<AuthCubit>().getId(),
            context.read<SettingsCubit>().getSettings().branchId);
      }
    }
  }

  Widget topBrand() {
    return BlocConsumer<TopRatedProductCubit, TopRatedProductState>(
        bloc: context.read<TopRatedProductCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is TopRatedProductProgress || state is TopRatedProductInitial) {
            return TopBrandSimmer(width: width!, height: height!, length: 6);
          }
          if (state is TopRatedProductFailure) {
            return Center(
                child: Text(
              state.errorMessage.toString(),
              textAlign: TextAlign.center,
            ));
          }
          final topProductList = (state as TopRatedProductSuccess).topRatedProductList;
          final hasMore = state.hasMore;
          return GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsetsDirectional.only(end: width! / 20.0),
              crossAxisCount: 2,
              childAspectRatio: 0.61,
              
              controller: topRestaurantController,
              children: List.generate(topProductList.length, (index) {
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
                return hasMore && index == (topProductList.length - 1)
                    ? Center(
                        child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ))
                    : InkWell(
                        onTap: () {
                          
                          Navigator.of(context).pushNamed(Routes.menu);
                        },
                        child: TopBrandContainer(
                            index: index, topProductList: topProductList, height: height!, width: width!, from: "home", price: price, off: off),
                      );
              }));
        });
  }

  Future<void> refreshList() async {
    topRestaurantApi();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
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
          : Scaffold(
              appBar: DesignConfig.appBar(context, width, UiUtils.getTranslatedLabel(context, popularDishesLabel),
                  const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
              body: RefreshIndicator(
                  onRefresh: refreshList,
                  color: Theme.of(context).colorScheme.primary,
                  child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: topBrand())),
            ),
    );
  }
}
