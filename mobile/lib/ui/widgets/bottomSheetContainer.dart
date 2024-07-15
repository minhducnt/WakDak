// ignore_for_file: must_be_immutable

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/cart/manageCartCubit.dart';
import 'package:wakDak/cubit/favourite/favouriteProductsCubit.dart';
import 'package:wakDak/cubit/favourite/updateFavouriteProduct.dart';
import 'package:wakDak/cubit/product/offlineCartCubit.dart';
import 'package:wakDak/cubit/promoCode/validatePromoCodeCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/productAddOnsModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/model/variantsModel.dart';
import 'package:wakDak/ui/screen/cart/cart_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/dashLine.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

import '../../utils/apiBodyParameterLabels.dart';

class BottomSheetContainer extends StatefulWidget {
  final ProductDetails productDetailsModel;
  Map<String, int> qtyData = {};
  int? currentIndex = 0, qty = 0;
  final List<bool> isChecked;
  String? productVariantId, from;
  List<String> addOnIds = [];
  List<String> addOnQty = [];
  List<double> addOnPrice = [];
  List<String> productAddOnIds = [];
  bool? descTextShowFlag = false;
  final double? width, height;

  BottomSheetContainer(
      {Key? key,
      required this.productDetailsModel,
      this.width,
      this.height,
      required this.addOnIds,
      required this.addOnQty,
      required this.addOnPrice,
      required this.productAddOnIds,
      required this.isChecked,
      this.productVariantId,
      this.descTextShowFlag,
      required this.qtyData,
      this.currentIndex,
      this.qty,
      this.from})
      : super(key: key);

  @override
  State<BottomSheetContainer> createState() => _BottomSheetContainerState();
}

class _BottomSheetContainerState extends State<BottomSheetContainer> {
  var db = DatabaseHelper();
  bool status = false;
  int QtyData = 0, qty = 0;
  int cartQty = 0;
  @override
  void initState() {
    super.initState();
    QtyData = widget.qtyData[widget.productVariantId!] ?? 0;
    qty = widget.qty ?? 0;
    cartQty = widget.qtyData[widget.productVariantId!] ?? 0;
  }

  Future<void> getOffLineCart(String variantId) async {
    if (mounted) {
      if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
        productVariant = (await db.getCart());
        productVariantData = (await db.getCartData());
        if (productVariant!.isEmpty) {
        } else {
          productVariantId = productVariant!['VID'];
          productAddOnId = productVariant!['ADDONID'].toString().replaceAll("[", "").replaceAll("]", "").split(",");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      for (int q = 0; q < widget.productDetailsModel.variants!.length; q++) {
        if (widget.productVariantId == widget.productDetailsModel.variants![q].id!) {
          widget.currentIndex = q;
        }
      }
      double priceCurrent = double.parse(widget.productDetailsModel.variants![widget.currentIndex!].specialPrice!);
      if (priceCurrent == 0) {
        priceCurrent = double.parse(widget.productDetailsModel.variants![widget.currentIndex!].price!);
      }

      double offCurrent = 0;
      if (widget.productDetailsModel.variants![widget.currentIndex!].specialPrice! != "0") {
        offCurrent = (double.parse(widget.productDetailsModel.variants![widget.currentIndex!].price!) -
                double.parse(widget.productDetailsModel.variants![widget.currentIndex!].specialPrice!))
            .toDouble();
        offCurrent = offCurrent * 100 / double.parse(widget.productDetailsModel.variants![widget.currentIndex!].price!).toDouble();
      }
      widget.productVariantId = widget.productDetailsModel.variants![widget.currentIndex!].id;
      return BlocProvider<UpdateProductFavoriteStatusCubit>(
        create: (context) => UpdateProductFavoriteStatusCubit(),
        child: Builder(builder: (context) {
          return LayoutBuilder(
            builder: (context, BoxConstraints boxConstraints) {
              var span = TextSpan(
                text: widget.productDetailsModel.shortDescription!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    letterSpacing: 0.1));
            var tp = TextPainter(maxLines: 2, textDirection: Directionality.of(context), text: span); // trigger it to layout
            tp.layout(maxWidth: boxConstraints.maxWidth);
            // whether the text overflowed or not
            var exceeded = tp.didExceedMaxLines;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: widget.width! / 30.0,
                                end: widget.width! / 30.0,
                              ),
                              child: Stack(
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
                                        child: DesignConfig.imageWidgets(widget.productDetailsModel.image!, 90, 90, "2"),
                                      )),
                                ],
                              ),
                            ),
                            Expanded(
                                child: Padding(
                              padding: EdgeInsetsDirectional.only(start: widget.width! / 99.0, end: widget.width! / 20.0),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        widget.productDetailsModel.indicator == "1"
                                            ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 15, height: 15)
                                            : widget.productDetailsModel.indicator == "2"
                                                ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"), width: 15, height: 15)
                                                : const SizedBox(),
                                        widget.productDetailsModel.noOfRatings == "0"
                                            ? const SizedBox()
                                            : Padding(
                                                padding: const EdgeInsetsDirectional.only(start: 8.0),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.of(context)
                                                        .pushNamed(Routes.productRatingDetail, arguments: {'productId': widget.productDetailsModel.id!});
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsetsDirectional.all(4.0),
                                                    decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 2),
                                                    child: Row(
                                                      children: [
                                                        SvgPicture.asset(DesignConfig.setSvgPath("rating"),
                                                            fit: BoxFit.scaleDown, width: 7.0, height: 12.3),
                                                        const SizedBox(width: 3.4),
                                                        Text(
                                                          double.parse(widget.productDetailsModel.rating!).toStringAsFixed(1),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              color: Theme.of(context).colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        const Spacer(),
                                        BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                                          return BlocBuilder<FavoriteProductsCubit, FavoriteProductsState>(
                                              bloc: context.read<FavoriteProductsCubit>(),
                                              builder: (context, favoriteProductState) {
                                                if (favoriteProductState is FavoriteProductsFetchSuccess) {
                                                  //check if restaurant is favorite or not
                                                  bool isProductFavorite =
                                                      context.read<FavoriteProductsCubit>().isProductFavorite(widget.productDetailsModel.id!);
                                                  return BlocConsumer<UpdateProductFavoriteStatusCubit, UpdateProductFavoriteStatusState>(
                                                    bloc: context.read<UpdateProductFavoriteStatusCubit>(),
                                                    listener: ((context, state) {
                                                      if (state is UpdateProductFavoriteStatusSuccess) {
                                                        
                                                        if (state.wasFavoriteProductProcess) {
                                                          context.read<FavoriteProductsCubit>().addFavoriteProduct(state.product);
                                                        } else {
                                                          
                                                          context.read<FavoriteProductsCubit>().removeFavoriteProduct(state.product);
                                                        }
                                                      }
                                                    }),
                                                    builder: (context, state) {
                                                      if (state is UpdateProductFavoriteStatusInProgress) {
                                                        return Container(
                                                            margin: const EdgeInsetsDirectional.only(end: 10.0),
                                                            height: widget.height! / 27,
                                                            width: widget.width! / 14,
                                                            padding: const EdgeInsets.all(4.0),
                                                            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.error));
                                                      }
                                                      return InkWell(
                                                          onTap: () {
                                                            if (state is UpdateProductFavoriteStatusInProgress) {
                                                              return;
                                                            }
                                                            if (isProductFavorite) {
                                                              context.read<UpdateProductFavoriteStatusCubit>().unFavoriteProduct(
                                                                  userId: context.read<AuthCubit>().getId(),
                                                                  type: productsKey,
                                                                  product: widget.productDetailsModel,
                                                                  branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                            } else {
                                                              
                                                              context.read<UpdateProductFavoriteStatusCubit>().favoriteProduct(
                                                                  userId: context.read<AuthCubit>().getId(),
                                                                  type: productsKey,
                                                                  product: widget.productDetailsModel,
                                                                  branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                            }
                                                          },
                                                          child: isProductFavorite
                                                              ? Container(
                                                                  padding: EdgeInsetsDirectional.all(4.0),
                                                                  alignment: Alignment.center,
                                                                  child: SvgPicture.asset(DesignConfig.setSvgPath("wishlist-filled"),
                                                                      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.error, BlendMode.srcIn),
                                                                      width: 18.0,
                                                                      height: 18))
                                                              : Container(
                                                                  padding: EdgeInsetsDirectional.all(4.0),
                                                                  alignment: Alignment.center,
                                                                  child: SvgPicture.asset(DesignConfig.setSvgPath("wishlist1"),
                                                                      colorFilter:
                                                                          ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                                                      width: 18.0,
                                                                      height: 18)));
                                                    },
                                                  );
                                                }
                                                //if some how failed to fetch favorite products or still fetching the products
                                                return InkWell(
                                                    onTap: () {
                                                      if (context.read<AuthCubit>().state is AuthInitial ||
                                                          context.read<AuthCubit>().state is Unauthenticated) {
                                                        Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'product'}).then((value) {
                                                          appDataRefresh(context);
                                                        });
                                                        return;
                                                      }
                                                    },
                                                    child: Container(
                                                        padding: EdgeInsetsDirectional.all(4.0),
                                                        alignment: Alignment.center,
                                                        child: SvgPicture.asset(DesignConfig.setSvgPath("wishlist1"),
                                                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                                            width: 20.0,
                                                            height: 20)));
                                              });
                                        }),
                                      ],
                                    ),
                                    SizedBox(height: widget.productDetailsModel.highlights!.isEmpty?6.0:2.0),
                                    Text(widget.productDetailsModel.categoryName!,
                                        textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                        )),
                                    const SizedBox(height: 6.0),
                                    Text(widget.productDetailsModel.name!,
                                        textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontStyle: FontStyle.normal,
                                            overflow: TextOverflow.ellipsis),
                                        maxLines: 2),
                                    widget.productDetailsModel.highlights!.isEmpty?const SizedBox.shrink():const SizedBox(height: 6.0),
                                    widget.productDetailsModel.highlights!.isEmpty? const SizedBox.shrink():Text(widget.productDetailsModel.highlights!.join(","),
                                        textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                          fontStyle: FontStyle.normal, overflow: TextOverflow.ellipsis
                                        ), maxLines: 1),
                                  ]),
                            ))
                          ],
                        ),
                        SizedBox(height: widget.height! / 99.0),
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: widget.width! / 25.0, end: widget.width! / 25.0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: widget.height! / 99.0),
                                Text(
                                  widget.productDetailsModel.shortDescription!,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                                  maxLines: widget.descTextShowFlag! ? null : 2,
                                ),
                                exceeded?Container(
                                  alignment: Alignment.topLeft,
                                  padding: const EdgeInsetsDirectional.only(end: 10),
                                  child: InkWell(
                                    onTap: () {
                                      
                                      setState(() {
                                        widget.descTextShowFlag = !widget.descTextShowFlag!;
                                      });
                                    },
                                    child: widget.descTextShowFlag!
                                        ? Text(
                                            UiUtils.getTranslatedLabel(context, readLessLabel),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.secondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          )
                                        : Text(UiUtils.getTranslatedLabel(context, readMoreLabel),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.secondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.normal,
                                            )),
                                  ),
                                ) : const SizedBox.shrink(),
                                SizedBox(height: widget.height! / 80.0),
                              ]),
                        ),
                        widget.productDetailsModel.attributes!.isEmpty && widget.productDetailsModel.productAddOns!.isEmpty
                            ? const SizedBox.shrink()
                            : Container(
                                margin: EdgeInsetsDirectional.only(start: widget.width! / 30.0, end: widget.width! / 30.0),
                                padding: EdgeInsetsDirectional.only(bottom: widget.height! / 80.0),
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.background, 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget.productDetailsModel.attributes!.isEmpty
                                        ? Container()
                                        : Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: widget.width! / 25.0, end: widget.width! / 25.0, top: widget.height! / 40.0),
                                            child: Row(
                                              children: [
                                                Text(UiUtils.getTranslatedLabel(context, variationLabel),
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.normal)),
                                              ],
                                            ),
                                          ),
                                    widget.productDetailsModel.attributes!.isEmpty
                                        ? Container()
                                        : Padding(
                                            padding: EdgeInsetsDirectional.only(
                                              bottom: widget.height! / 99.0,
                                              top: widget.height! / 80.0,
                                            ),
                                            child: DashLineView(
                                              fillRate: 0.5,
                                              direction: Axis.horizontal,
                                            ),
                                          ),
                                    widget.productDetailsModel.attributes!.isEmpty
                                        ? Container()
                                        : Padding(
                                            padding: EdgeInsetsDirectional.only(start: widget.width! / 25.0, end: widget.width! / 25.0),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: List.generate(widget.productDetailsModel.variants!.length, (index) {
                                                  VariantsModel data = widget.productDetailsModel.variants![index];
                                                  double price = double.parse(data.specialPrice!);
                                                  if (price == 0) {
                                                    price = double.parse(data.price!);
                                                  }

                                                  double off = 0;
                                                  if (data.specialPrice! != "0") {
                                                    off = (double.parse(data.price!) - double.parse(data.specialPrice!)).toDouble();
                                                    off = off * 100 / double.parse(data.price!).toDouble();
                                                  }
                                                  return Theme(
                                                    data: Theme.of(context).copyWith(
                                                        unselectedWidgetColor: Theme.of(context).colorScheme.secondary,
                                                        disabledColor: Theme.of(context).colorScheme.secondary),
                                                    child: RadioListTile(
                                                      contentPadding: EdgeInsets.zero,
                                                      dense: true,
                                                      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                                      activeColor: Theme.of(context).colorScheme.primary,
                                                      controlAffinity: ListTileControlAffinity.trailing,
                                                      value: index,
                                                      groupValue: widget.currentIndex,
                                                      title: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(data.variantValues!,
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w400,
                                                                  fontStyle: FontStyle.normal)),
                                                          const Spacer(),
                                                          Row(
                                                            children: [
                                                              Text(context.read<SystemConfigCubit>().getCurrency() + price.toString(),
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                      color: Theme.of(context).colorScheme.secondary,
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w400,
                                                                      fontStyle: FontStyle.normal)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      onChanged: (int? value) {
                                                        widget.currentIndex = value!;
                                                        widget.productVariantId = widget.productDetailsModel.variants![value].id!;
                                                        if (widget.qtyData.containsKey(widget.productVariantId)) {
                                                          widget.qty = widget.qtyData[widget.productVariantId] ?? 1;
                                                        } else {
                                                          int newQty = 0;
                                                          if (widget.productDetailsModel.variants![value].cartCount != "0") {
                                                            newQty = int.parse(widget.productDetailsModel.variants![value].cartCount!);
                                                          } else {
                                                            newQty = int.parse(widget.productDetailsModel.minimumOrderQuantity!);
                                                          }
                                                          widget.qtyData[widget.productVariantId!] = newQty;
                                                          widget.qty = newQty;
                                                        }
                                                        setState(() {
                                                          
                                                        });
                                                      },
                                                    ),
                                                  );
                                                })),
                                          ),
                                    widget.productDetailsModel.productAddOns!.isEmpty
                                        ? Container()
                                        : Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: widget.width! / 25.0, end: widget.width! / 25.0, top: widget.height! / 40.0),
                                            child: Text(UiUtils.getTranslatedLabel(context, extraAddOnLabel),
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal)),
                                          ),
                                    widget.productDetailsModel.productAddOns!.isEmpty
                                        ? Container()
                                        : Padding(
                                            padding: EdgeInsetsDirectional.only(
                                              bottom: widget.height! / 80.0,
                                              top: widget.height! / 80.0,
                                            ),
                                            child: DashLineView(
                                              fillRate: 0.5,
                                              direction: Axis.horizontal,
                                            ),
                                          ),
                                    widget.productDetailsModel.productAddOns!.isEmpty
                                        ? Container()
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(widget.productDetailsModel.productAddOns!.length, (index) {
                                              ProductAddOnsModel data = widget.productDetailsModel.productAddOns![index];
                                              if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
                                                if (widget.productAddOnIds.contains(data.id)) {
                                                  widget.isChecked[index] = true;
                                                  if (!widget.addOnIds.contains(data.id!)) {
                                                    widget.addOnIds.add(data.id!);
                                                    widget.addOnQty.add(widget.qtyData[widget.productVariantId!].toString());

                                                    widget.addOnPrice.add(double.parse(data.price!));
                                                  }
                                                } else {
                                                  widget.isChecked[index] = false;
                                                }
                                              } else {
                                                if (widget.productAddOnIds.contains(data.id)) {
                                                  widget.isChecked[index] = true;
                                                  if (!widget.addOnIds.contains(data.id!)) {
                                                    widget.addOnIds.add(data.id!);
                                                    widget.addOnQty.add(widget.qtyData[widget.productVariantId!].toString());

                                                    widget.addOnPrice.add(double.parse(data.price!));
                                                  }
                                                } else {
                                                  widget.isChecked[index] = false;
                                                }
                                              }
                                              return Container(
                                                  margin: EdgeInsetsDirectional.only(
                                                    start: widget.width! / 25.0,
                                                    end: widget.width! / 25.0,
                                                  ),
                                                  child: CheckboxListTile(
                                                      side: MaterialStateBorderSide.resolveWith(
                                                        (states) =>
                                                            BorderSide(width: 1.0, color: Theme.of(context).colorScheme.secondary, strokeAlign: 5),
                                                      ),
                                                      contentPadding: EdgeInsets.zero,
                                                      dense: true,
                                                      checkColor: Theme.of(context).colorScheme.onPrimary,
                                                      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                                      activeColor: Theme.of(context).colorScheme.primary,
                                                      title: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          SizedBox(
                                                              width: widget.width! / 2.0,
                                                              child: Text(
                                                                data.title!,
                                                                textAlign: TextAlign.start,
                                                                style: TextStyle(
                                                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w400,
                                                                    fontStyle: FontStyle.normal),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              )),
                                                          const Spacer(),
                                                          Text(context.read<SystemConfigCubit>().getCurrency() + data.price!,
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                  color: Theme.of(context).colorScheme.secondary,
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w400,
                                                                  fontStyle: FontStyle.normal)),
                                                        ],
                                                      ),
                                                      value: widget.isChecked[index],
                                                      onChanged: (val) {
                                                        setState(
                                                          () {
                                                            widget.isChecked[index] = val!;
                                                            print(
                                                                "index:${val}--$index--${widget.isChecked[index]}--${widget.isChecked.length}--${widget.isChecked}--${widget.addOnIds}");
                                                            if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
                                                              if (widget.isChecked[index] == false) {
                                                                widget.addOnIds.remove(data.id);
                                                                widget.productAddOnIds.remove(data.id);
                                                                widget.addOnQty.remove(data.id);
                                                                widget.addOnPrice.remove(data.id);
                                                              } else {
                                                                widget.productAddOnIds.add(data.id!);
                                                                if (!widget.addOnIds.contains(data.id!)) {
                                                                  widget.addOnIds.add(data.id!);
                                                                  widget.addOnQty.add(widget.qtyData[widget.productVariantId!].toString());

                                                                  widget.addOnPrice.add(double.parse(data.price!));
                                                                }
                                                              }
                                                            } else {
                                                              if (widget.isChecked[index] == false) {
                                                                widget.addOnIds.remove(data.id);
                                                                widget.productAddOnIds.remove(data.id);
                                                                widget.addOnQty.remove(data.id);
                                                                widget.addOnPrice.remove(data.id);
                                                              } else {
                                                                widget.productAddOnIds.add(data.id!);
                                                                if (!widget.addOnIds.contains(data.id!)) {
                                                                  widget.addOnIds.add(data.id!);
                                                                  widget.addOnQty.add(widget.qtyData[widget.productVariantId!].toString());

                                                                  widget.addOnPrice.add(double.parse(data.price!));
                                                                }
                                                              }
                                                            }
                                                          },
                                                        );
                                                      }));
                                            }),
                                          )
                                  ],
                                ),
                              )
                      ],
                    ),
                  ),
                  BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                    var sum = 0.0;
                    for (var i = 0; i < widget.productDetailsModel.productAddOns!.length; i++) {
                      if (widget.productAddOnIds.contains(widget.productDetailsModel.productAddOns![i].id)) {
                        sum += double.parse(widget.productDetailsModel.productAddOns![i].price!) * widget.qtyData[widget.productVariantId!]!;
                      }
                    }
                    double overAllTotal = ((priceCurrent * widget.qtyData[widget.productVariantId!]!) + sum);
                    

                    return Container(
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsetsDirectional.only(
                          start: widget.width! / 25.0, end: widget.width! / 25.0, top: widget.height! / 55.0, bottom: widget.height! / 55.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: widget.width! / 3.6,
                            padding: EdgeInsetsDirectional.zero,
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 4.0),
                            child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      padding: EdgeInsetsDirectional.only(top: widget.height! / 55.0, bottom: widget.height! / 55.0),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: qty > 1
                                          ? () {
                                              setState(() {
                                                if (widget.productDetailsModel.totalAllowedQuantity != "" &&
                                                    qty <= int.parse(widget.productDetailsModel.minimumOrderQuantity!)) {
                                                  qty = int.parse(widget.productDetailsModel.minimumOrderQuantity!);
                                                } else {
                                                  qty = qty - 1;
                                                }
                                                widget.qtyData[widget.productVariantId!] = qty;
                                                QtyData = qty;
                                              });
                                            }
                                          : null,
                                      icon: Container(
                                          decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 2.0),
                                          child: Icon(Icons.remove, color: Theme.of(context).colorScheme.onPrimary))),
                                  const Spacer(),
                                  Text(QtyData.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.normal,
                                      )),
                                  const Spacer(),
                                  IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() {
                                          if (widget.productDetailsModel.totalAllowedQuantity != "" &&
                                              qty >= int.parse(widget.productDetailsModel.totalAllowedQuantity!)) {
                                            qty = int.parse(widget.productDetailsModel.totalAllowedQuantity!);
                                            Navigator.pop(context);
                                            UiUtils.setSnackBar(
                                                "${StringsRes.minimumQuantityAllowed} ${widget.productDetailsModel.totalAllowedQuantity!}",
                                                context,
                                                false,
                                                type: "2");
                                          } else {
                                            qty = (qty + 1);
                                          }
                                          widget.qtyData[widget.productVariantId!] = qty;
                                          QtyData = qty;
                                        });
                                      },
                                      icon: Container(
                                          decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 2.0),
                                          child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary))),
                                ]),
                          ),
                          Expanded(
                            child: widget.productDetailsModel.variants![widget.currentIndex!].availability == "1" ||
                                    widget.productDetailsModel.variants![widget.currentIndex!].availability == ""
                                ? BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                                    return BlocConsumer<ManageCartCubit, ManageCartState>(
                                        bloc: context.read<ManageCartCubit>(),
                                        listener: (context, state) {
                                          print(state.toString());
                                          if (state is ManageCartSuccess) {
                                            status = false;
                                            if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                              return;
                                            } else {
                                              final currentCartModel = context.read<GetCartCubit>().getCartModel();

                                              context.read<GetCartCubit>().updateCartList(currentCartModel.updateCart(
                                                  state.data,
                                                  (/* int.parse(currentCartModel.totalQuantity ?? '0') +  */int.parse(state.totalQuantity!)).toString(),
                                                  state.subTotal,
                                                  state.taxPercentage,
                                                  state.taxAmount,
                                                  state.overallAmount,
                                                  List.from(state.variantId ?? [])..addAll(currentCartModel.variantId ?? [])));

                                              print(currentCartModel.variantId);
                                              Navigator.pop(context);
                                              if(promoCode!=""){
                                              context.read<ValidatePromoCodeCubit>().getValidatePromoCode(promoCode, context.read<AuthCubit>().getId(),
                                                  state.overallAmount!.toStringAsFixed(2), context.read<SettingsCubit>().getSettings().branchId);
                                              }

                                              if (widget.productDetailsModel.variants![widget.currentIndex!].cartCount! ==
                                                  widget.qtyData[widget.productVariantId!].toString()) {
                                              } else {}
                                            }
                                          } else if (state is ManageCartFailure) {
                                            status = false;
                                            if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                              return;
                                            } else {
                                              Navigator.pop(context);

                                              UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                            }
                                          }
                                        },
                                        builder: (context, state) {
                                          return BlocConsumer<OfflineCartCubit, OfflineCartState>(
                                              bloc: context.read<OfflineCartCubit>(),
                                              listener: (context, state) {
                                                if (state is OfflineCartProgress) {
                                                  
                                                } else if (state is OfflineCartSuccess) {
                                                  if (context.read<AuthCubit>().state is AuthInitial ||
                                                      context.read<AuthCubit>().state is Unauthenticated) {}
                                                }
                                              },
                                              builder: (context, state) {
                                                return ButtonContainer(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                  height: widget.height,
                                                  width: widget.width,
                                                  text:
                                                      "${(cartQty == widget.qtyData[widget.productVariantId!]) ? UiUtils.getTranslatedLabel(context, addToCartLabel) : UiUtils.getTranslatedLabel(context, updateToCartLabel)} (${context.read<SystemConfigCubit>().getCurrency() + overAllTotal.toStringAsFixed(2)})",
                                                  top: 0,
                                                  bottom: 0,
                                                  start: widget.width! / 40.0,
                                                  end: 0,
                                                  status: status,
                                                  borderColor: Theme.of(context).colorScheme.onPrimary,
                                                  textColor: white,
                                                  onPressed: () {
                                                    widget.addOnQty.clear();
                                                    for (int qty = 0; qty < widget.addOnIds.length; qty++) {
                                                      widget.addOnQty.add(/* widget.from == "cart"
                                                          ?  */widget.qtyData[widget.productVariantId!].toString()
                                                         /*  : (int.parse(widget.productDetailsModel.variants![widget.currentIndex!].cartCount!) +
                                                                  int.parse(widget.qtyData[widget.productVariantId!].toString()))
                                                              .toString() */);
                                                    }
                                                    if (widget.qty == 0) {
                                                      Navigator.pop(context);
                                                      UiUtils.setSnackBar(StringsRes.quantityMessage, context, false, type: "2");
                                                    } else {
                                                      if (context.read<AuthCubit>().state is AuthInitial ||
                                                          context.read<AuthCubit>().state is Unauthenticated) {
                                                        print(
                                                            "=======${context.read<SettingsCubit>().state.settingsModel!.branchId.toString()} ${widget.productDetailsModel.branchId}");
                                                        if (context.read<SettingsCubit>().state.settingsModel!.branchId.toString() ==
                                                                widget.productDetailsModel.branchId ||
                                                            context.read<SettingsCubit>().state.settingsModel!.cartCount.toString() == "0" ||
                                                            context.read<SettingsCubit>().state.settingsModel!.cartCount.toString() == "") {
                                                          db
                                                              .insertCart(
                                                                  widget.productDetailsModel.id!,
                                                                  widget.productVariantId!,
                                                                  widget.qtyData[widget.productVariantId!].toString(),
                                                                  widget.addOnIds.isNotEmpty ? widget.addOnIds.join(",").toString() : "",
                                                                  widget.addOnQty.isNotEmpty ? widget.addOnQty.join(",").toString() : "",
                                                                  overAllTotal.toString(),
                                                                  context.read<SettingsCubit>().getSettings().branchId,
                                                                  context)
                                                              .whenComplete(() async {
                                                            await getOffLineCart(widget.productVariantId!).then((value) {
                                                              context.read<OfflineCartCubit>().updateQuantity(widget.productDetailsModel,
                                                                  widget.qtyData[widget.productVariantId!].toString(), widget.productVariantId);
                                                              Navigator.pop(context);
                                                            });
                                                          });
                                                        } else {
                                                          print(context.read<SettingsCubit>().state.settingsModel!.cartCount.toString());
                                                          Navigator.pop(context);
                                                          UiUtils.setSnackBar(StringsRes.singleRestaurantAddMessage, context, false, type: "2");
                                                        }
                                                      } else {
                                                        int qty = 0;
                                                        //if (widget.from == "cart") {
                                                          qty = int.parse(widget.qtyData[widget.productVariantId!].toString());
                                                        /* } else {
                                                          qty = (int.parse(widget.productDetailsModel.variants![widget.currentIndex!].cartCount!) +
                                                              int.parse(widget.qtyData[widget.productVariantId!].toString()));
                                                        } */
                                                        print(
                                                            "cart--${widget.productDetailsModel.minimumOrderQuantity!}-${widget.productDetailsModel.totalAllowedQuantity!}--");
                                                        if (qty < int.parse(widget.productDetailsModel.minimumOrderQuantity!)) {
                                                          Navigator.pop(context);
                                                          UiUtils.setSnackBar(
                                                              "${StringsRes.minimumQuantityAllowed} ${widget.productDetailsModel.minimumOrderQuantity!}",
                                                              context,
                                                              false,
                                                              type: "2");
                                                        } else if (widget.productDetailsModel.totalAllowedQuantity != "" &&
                                                            qty > int.parse(widget.productDetailsModel.totalAllowedQuantity!)) {
                                                          Navigator.pop(context);
                                                          UiUtils.setSnackBar(
                                                              "${StringsRes.maximumQuantityAllowed} ${widget.productDetailsModel.totalAllowedQuantity!}",
                                                              context,
                                                              false,
                                                              type: "2");
                                                        } else {
                                                          setState(() {
                                                            
                                                            status = true;
                                                          });
                                                          context.read<ManageCartCubit>().manageCartUser(
                                                              userId: context.read<AuthCubit>().getId(),
                                                              productVariantId: widget.productVariantId,
                                                              isSavedForLater: "0",
                                                              qty: widget.qtyData[widget.productVariantId!].toString(),
                                                              addOnId: widget.addOnIds.isNotEmpty ? widget.addOnIds.join(",").toString() : "",
                                                              addOnQty: widget.addOnQty.isNotEmpty ? widget.addOnQty.join(",").toString() : "",
                                                              branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                        }
                                                      }
                                                      db.getCart();
                                                    }
                                                    setState(() {
                                                      
                                                    });
                                                  },
                                                );
                                              });
                                        });
                                  })
                                : ButtonContainer(
                                    color: Theme.of(context).colorScheme.background,
                                    height: widget.height,
                                    width: widget.width,
                                    text: UiUtils.getTranslatedLabel(context, outOfStockLabel),
                                    top: widget.height! / 55.0,
                                    bottom: widget.height! / 55.0,
                                    start: widget.width! / 99.0,
                                    end: widget.width! / 99.0,
                                    status: false,
                                    borderColor: commentBoxBorderColor,
                                    textColor: commentBoxBorderColor,
                                    onPressed: () {}),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }
          );
        }),
      );
    });
  }
}
