import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/rating/deleteRatingCubit.dart';
import 'package:wakDak/cubit/rating/getProductRatingCubit.dart';
import 'package:wakDak/data/repositories/rating/ratingRepository.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/simmer/productSimmer.dart';
import 'package:wakDak/ui/widgets/smallButtonContainer.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class ProductRatingDetailScreen extends StatefulWidget {
  final String? productId;
  const ProductRatingDetailScreen({Key? key, this.productId}) : super(key: key);

  @override
  ProductRatingDetailScreenState createState() => ProductRatingDetailScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(providers: [
              BlocProvider<GetProductRatingCubit>(
                create: (_) => GetProductRatingCubit(),
                child: ProductRatingDetailScreen(productId: arguments['productId']),
              ),
              BlocProvider<DeleteRatingCubit>(
                create: (_) => DeleteRatingCubit(RatingRepository()),
                child: ProductRatingDetailScreen(productId: arguments['productId']),
              )
            ], child: ProductRatingDetailScreen(productId: arguments['productId'])));
  }
}

class ProductRatingDetailScreenState extends State<ProductRatingDetailScreen> {
  double? width, height;
  ScrollController controller = ScrollController();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String? cuisineLength = "";
  RegExp regex = RegExp(r'([^\d]00)(?=[^\d]|$)');
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
    controller.addListener(scrollListener);
    Future.delayed(Duration.zero, () {
      context.read<GetProductRatingCubit>().fetchGetProductRating(perPage, widget.productId!);
    });
    super.initState();
  }

  scrollListener() {
    if (controller.position.maxScrollExtent == controller.offset) {
      if (context.read<GetProductRatingCubit>().hasMoreData()) {
        context.read<GetProductRatingCubit>().fetchMoreGetProductRatingData(perPage, widget.productId!);
      }
    }
  }

  Widget getProductRating() {
    return BlocConsumer<GetProductRatingCubit, GetProductRatingState>(
        bloc: context.read<GetProductRatingCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is GetProductRatingProgress || state is GetProductRatingInitial) {
            return ProductSimmer(length: 5, width: width!, height: height!);
          }
          if (state is GetProductRatingFailure) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(height: height! / 20.0),
                Text(UiUtils.getTranslatedLabel(context, noReviewFoundLabel),
                    textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 28)),
                const SizedBox(height: 5.0),
                Text(UiUtils.getTranslatedLabel(context, noReviewSubTitleLabel),
                    textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: lightFont, fontSize: 14)),
              ]),
            );
          }
          final productRatingList = (state as GetProductRatingSuccess).productRatingList;
          final hasMore = state.hasMore;
          return productRatingList.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    SizedBox(height: height! / 20.0),
                    Text(UiUtils.getTranslatedLabel(context, noReviewFoundLabel),
                        textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 28)),
                    const SizedBox(height: 5.0),
                    Text(UiUtils.getTranslatedLabel(context, noReviewSubTitleLabel),
                        textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: lightFont, fontSize: 14)),
                  ]),
                )
              : SizedBox(
                  height: height! / 1.2,
                  child: ListView.builder(
                      shrinkWrap: true,
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      itemCount: productRatingList.length,
                      padding: EdgeInsetsDirectional.zero,
                      itemBuilder: (BuildContext context, index) {
                        print(productRatingList[index].images!.length);
                        var inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                        var inputDate = inputFormat.parse(productRatingList[index].dataAdded!.toString());

                        var outputFormat = DateFormat('dd,MMM yyyy hh:mm a');
                        var outputDate = outputFormat.format(inputDate);
                        return hasMore && productRatingList.isEmpty && index == (productRatingList.length - 1)
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                            : Container(
                                padding:
                                    EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0, end: width! / 20.0, bottom: height! / 99.0),
                                width: width!,
                                margin: EdgeInsetsDirectional.only(top: index == 0 ? 0.0 : height! / 52.0),
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.only(start: width! / 60.0),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            ClipOval(child: DesignConfig.imageWidgets(productRatingList[index].userProfile!, 35, 35, "2")),
                                            const SizedBox(width: 10.0),
                                            Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(productRatingList[index].userName!,
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.normal,
                                                      )),
                                                  Text(outputDate,
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          overflow: TextOverflow.ellipsis),
                                                      maxLines: 1),
                                                ]),
                                            const Spacer(),
                                            Container(
                                                padding: const EdgeInsetsDirectional.only(top: 2, bottom: 2, start: 4.5, end: 4.5),
                                                decoration: DesignConfig.boxDecorationContainerBorder(yellowColor, yellowColor.withOpacity(0.10), 5),
                                                margin: EdgeInsetsDirectional.only(start: width! / 20.0),
                                                child: Row(
                                                  children: [
                                                    RatingBar.builder(
                                                      itemSize: 10.9,
                                                      glowColor: Theme.of(context).colorScheme.onBackground,
                                                      initialRating: double.parse(productRatingList[index].rating!),
                                                      minRating: 1,
                                                      direction: Axis.horizontal,
                                                      allowHalfRating: true,
                                                      itemCount: 5,
                                                      ignoreGestures: true,
                                                      itemPadding: const EdgeInsetsDirectional.only(end: 2.0),
                                                      itemBuilder: (context, _) => const Icon(
                                                        Icons.star,
                                                        color: yellowColor,
                                                      ),
                                                      onRatingUpdate: (ratings) {
                                                        print(ratings);
                                                      },
                                                    ),
                                                    Text(" | ${productRatingList[index].rating!}",
                                                        textAlign: TextAlign.left,
                                                        style: const TextStyle(
                                                            color: grayLightColor,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w400,
                                                            fontStyle: FontStyle.normal)),
                                                  ],
                                                ))
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            top: height! / 80.0,
                                            bottom: height! / 80.0,
                                          ),
                                          child: DesignConfig.divider(),
                                        ),
                                        SizedBox(height: height! / 80.0),
                                        productRatingList[index].comment!.isNotEmpty
                                            ? Text(UiUtils.getTranslatedLabel(context, overallReviewLabel),
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    fontStyle: FontStyle.normal,
                                                    overflow: TextOverflow.ellipsis),
                                                maxLines: 1)
                                            : const SizedBox(),
                                        SizedBox(height: height! / 80.0),
                                        productRatingList[index].comment!.isNotEmpty
                                            ? Text(productRatingList[index].comment!,
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                    overflow: TextOverflow.ellipsis),
                                                maxLines: 1)
                                            : const SizedBox(),
                                        const SizedBox(height: 2.0),
                                        productRatingList[index].images!.isEmpty
                                            ? const SizedBox()
                                            : Container(
                                                height: 65.0,
                                                alignment: Alignment.topLeft,
                                                margin: EdgeInsetsDirectional.only(top: height! / 80.0),
                                                child: ListView.builder(
                                                    shrinkWrap: true,
                                                    physics: const AlwaysScrollableScrollPhysics(),
                                                    itemCount: productRatingList[index].images!.length,
                                                    scrollDirection: Axis.horizontal,
                                                    itemBuilder: (context, i) {
                                                      return Padding(
                                                        padding: const EdgeInsetsDirectional.only(end: 10.0),
                                                        child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(4.0),
                                                            child: DesignConfig.imageWidgets(productRatingList[index].images![i], 65, 65, "2")),
                                                      );
                                                    })),
                                        context.read<AuthCubit>().getId() == productRatingList[index].userId!
                                            ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                BlocConsumer<DeleteRatingCubit, DeleteRatingState>(
                                                    bloc: context.read<DeleteRatingCubit>(),
                                                    listener: (context, state) {
                                                      if (state is DeleteRatingSuccess) {
                                                        UiUtils.setSnackBar(StringsRes.deleteSuccessFully, context, false, type: "1");
                                                      }
                                                    },
                                                    builder: (context, state) {
                                                      return SmallButtonContainer(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        height: height,
                                                        width: width,
                                                        text: UiUtils.getTranslatedLabel(context, deleteLabel),
                                                        start: 0,
                                                        end: width! / 99.0,
                                                        bottom: height! / 80.0,
                                                        top: height! / 99.0,
                                                        radius: 5.0,
                                                        status: false,
                                                        borderColor: Theme.of(context).colorScheme.primary,
                                                        textColor: Theme.of(context).colorScheme.onPrimary,
                                                        onTap: () {
                                                          context.read<DeleteRatingCubit>().deleteProductRating(productRatingList[index].id!);
                                                          productRatingList.removeWhere((element) => element.id == productRatingList[index].id!);
                                                        },
                                                      );
                                                    })
                                              ])
                                            : const SizedBox(),
                                      ]),
                                ));
                      }));
        });
  }

  Future<void> refreshList() async {
    context.read<GetProductRatingCubit>().fetchGetProductRating(
          perPage,
          widget.productId!,
        );
  }

  @override
  void dispose() {
    controller.dispose();
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
              backgroundColor: Theme.of(context).colorScheme.background,
              appBar: DesignConfig.appBar(context, width, UiUtils.getTranslatedLabel(context, reviewsLabel),
                  const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
              body: SizedBox(
                height: height!,
                width: width,
                child: RefreshIndicator(
                    onRefresh: refreshList,
                    color: Theme.of(context).colorScheme.primary,
                    child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: getProductRating())),
              ),
            ),
    );
  }
}
