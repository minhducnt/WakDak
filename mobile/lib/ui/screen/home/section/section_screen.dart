import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/home/sections/sectionsDetailCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/bottomSheetContainer.dart';
import 'package:wakDak/ui/widgets/brachCloseDialog.dart';
import 'package:wakDak/ui/widgets/noDataContainer.dart';
import 'package:wakDak/ui/widgets/productSectionContainer.dart';
import 'package:wakDak/ui/widgets/productUnavailableDialog.dart';
import 'package:wakDak/ui/widgets/simmer/myOrderSimmer.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class SectionScreen extends StatefulWidget {
  final String? title, sectionId;
  const SectionScreen({Key? key, this.title, this.sectionId}) : super(key: key);

  @override
  SectionScreenState createState() => SectionScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (_) => SectionScreen(title: arguments['title'] as String, sectionId: arguments['sectionId'] as String),
    );
  }
}

class SectionScreenState extends State<SectionScreen> with SingleTickerProviderStateMixin {
  double? width, height;
  ScrollController sectionController = ScrollController();

  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

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

    sectionController.addListener(sectionScrollListener);
    Future.delayed(Duration.zero, () async {
      if (mounted) {
        await sectionApiCall();
      }
    });

    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  sectionScrollListener() {
    if (sectionController.position.maxScrollExtent == sectionController.offset) {
      if (context.read<SectionsDetailCubit>().hasMoreData()) {
        context.read<SectionsDetailCubit>().fetchMoreSectionsDetailData(
            perPage,
            context.read<AuthCubit>().getId(),
            widget.sectionId,
            context.read<SettingsCubit>().state.settingsModel!.branchId);
      }
    }
  }

  addToCartBottomModelSheet(ProductDetails productList) {
    ProductDetails productDetailsModel = productList;
    Map<String, int> qtyData = {};
    int currentIndex = 0, qty = 0;
    List<bool> isChecked = List<bool>.filled(productDetailsModel.productAddOns!.length, false);
    String? productVariantId = productDetailsModel.variants![0].id;

    List<String> addOnIds = [];
    List<String> addOnQty = [];
    List<double> addOnPrice = [];
    List<String> productAddOnIds = [];
    for (int i = 0; i < productDetailsModel.variants![currentIndex].addOnsData!.length; i++) {
      productAddOnIds.add(productDetailsModel.variants![currentIndex].addOnsData![i].id!);
    }
    if (productDetailsModel.variants![currentIndex].cartCount != "0") {
      qty = int.parse(productDetailsModel.variants![currentIndex].cartCount!);
    } else {
      qty = int.parse(productDetailsModel.minimumOrderQuantity!);
    }
    qtyData[productVariantId!] = qty;
    bool descTextShowFlag = false;

    showModalBottomSheet(useSafeArea: true,
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
              from: "favourite");
        });
  }

  Widget noDataSection() {
    return NoDataContainer(
        image: "no_data",
        title: UiUtils.getTranslatedLabel(context, noSectionYetLabel),
        subTitle: UiUtils.getTranslatedLabel(context, noSectionYetSubTitleLabel),
        width: width!,
        height: height!);
  }

  Widget sectionData() {
    return BlocBuilder<SectionsDetailCubit, SectionsDetailState>(
        bloc: context.read<SectionsDetailCubit>(),
        builder: (context, state) {
          if (state is SectionsDetailProgress || state is SectionsDetailInitial) {
            return MyOrderSimmer(length: 5, width: width!, height: height!);
          }
          if (state is SectionsDetailFailure) {
            return noDataSection();
          }
          final sectionsList = (state as SectionsDetailSuccess).sectionsDetailList;
          final hasMore = state.hasMore;
          if (sectionsList.isEmpty) {
            return noDataSection();
          }

          return ListView.builder(
                  controller: sectionController,
                  itemCount: sectionsList.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    double? price;
                    double off = 0;
                    if (hasMore && index == (sectionsList.length)) {
                    } else {
                      price = double.parse(sectionsList[index].variants![0].specialPrice!);
                      if (price == 0) {
                        price = double.parse(sectionsList[index].variants![0].price!);
                      }

                      if (sectionsList[index].variants![0].specialPrice! != "0") {
                        off = (double.parse(sectionsList[index].variants![0].price!) - double.parse(sectionsList[index].variants![0].specialPrice!))
                            .toDouble();
                        off = off * 100 / double.parse(sectionsList[index].variants![0].price!).toDouble();
                      }
                    }
                    return hasMore && index == (sectionsList.length - 1)
                        ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                        : GestureDetector(
                        onTap: () {
                          if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
                            bool check = getStoreOpenStatus(sectionsList[index].startTime!, sectionsList[index].endTime!);
                            if (sectionsList[index].availableTime == "1") {
                              if (check == true) {
                                addToCartBottomModelSheet(
                                    context.read<GetCartCubit>().getProductDetailsData(sectionsList[index].id!, sectionsList[index])[0]);
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (_) => ProductUnavailableDialog(
                                        startTime: sectionsList[index].startTime,
                                        endTime: sectionsList[index].endTime,
                                        width: width,
                                        height: height));
                              }
                            } else {
                              addToCartBottomModelSheet(
                                  context.read<GetCartCubit>().getProductDetailsData(sectionsList[index].id!, sectionsList[index])[0]);
                            }
                          } else {
                            showDialog(
                                context: context,
                                builder: (_) => BranchCloseDialog(hours: "", minute: "", status: false, width: width!, height: height!));
                          }
                        },
                        child: ProductSectionContainer(
                            productDetails: sectionsList[index],
                            height: height!,
                            width: width,
                            productDetailsList: sectionsList,
                            price: price,
                            off: off,
                            from: "section",
                            axis: "vertical"),
                      );
        });
        });
  }

  sectionApiCall() {
    context.read<SectionsDetailCubit>().fetchSectionsDetail(
        perPage,
        context.read<AuthCubit>().getId(),
        widget.sectionId,
        context.read<SettingsCubit>().state.settingsModel!.branchId);
  }

  Future<void> refreshSectionList() async {
    await sectionApiCall();
  }

  @override
  void dispose() {
    sectionController.dispose();
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
              appBar: DesignConfig.appBar(context, width!, widget.title, const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
              body: SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: refreshSectionList,
                  color: Theme.of(context).colorScheme.primary,
                  child: Container(
                    width: width,
                    height: height,
                    child: sectionData(),
                  ),
                ),
              ),
            ),
    );
  }
}
