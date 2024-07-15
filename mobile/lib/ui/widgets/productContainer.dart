import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/cart/getQuantityCubit.dart';
import 'package:wakDak/cubit/cart/manageCartCubit.dart';
import 'package:wakDak/cubit/cart/removeFromCartCubit.dart';
import 'package:wakDak/cubit/favourite/favouriteProductsCubit.dart';
import 'package:wakDak/cubit/favourite/updateFavouriteProduct.dart';
import 'package:wakDak/cubit/promoCode/validatePromoCodeCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/productAddOnsModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/ui/screen/cart/cart_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/bottomSheetContainer.dart';
import 'package:wakDak/ui/widgets/brachCloseDialog.dart';
import 'package:wakDak/ui/widgets/productUnavailableDialog.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

// ignore: must_be_immutable
class ProductContainer extends StatefulWidget {
  final ProductDetails productDetails;
  final double? width, height, price, off;
  final List<ProductDetails> productList;
  final int? index;
  final String? from;
  ProductContainer(
      {Key? key, required this.productDetails, this.width, this.height, this.price, this.off, required this.productList, this.index, this.from})
      : super(key: key);

  @override
  State<ProductContainer> createState() => _ProductContainerState();
}

class _ProductContainerState extends State<ProductContainer> {
  var db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<GetQuantityCubit>().getQuantity(widget.productDetails.id!, widget.productDetails, context);
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
              height: widget.height!,
              width: widget.width!,
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
        }).then((value) {
          if(mounted)
      Future.delayed(const Duration(seconds: 1), () {
        context.read<GetQuantityCubit>().getQuantity(productList.id!, productList, context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    RegExp regex = RegExp(r'([^\d]00)(?=[^\d]|$)');
    return BlocProvider<UpdateProductFavoriteStatusCubit>(
      create: (context) => UpdateProductFavoriteStatusCubit(),
      child: BlocBuilder<GetQuantityCubit, GetQuantityState>(
        builder: (context, state) {
          return Builder(builder: (context) {
            return InkWell(
              onTap: () {
                if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
                  bool check = getStoreOpenStatus(widget.productDetails.startTime!, widget.productDetails.endTime!);
                  if (widget.productDetails.availableTime == "1") {
                    if (check == true) {
                      addToCartBottomModelSheet(
                          context.read<GetCartCubit>().getProductDetailsData(widget.productDetails.id!, widget.productDetails)[0]);
                    } else {
                      showDialog(
                          context: context,
                          builder: (_) => ProductUnavailableDialog(
                              startTime: widget.productDetails.startTime,
                              endTime: widget.productDetails.endTime,
                              width: widget.width,
                              height: widget.height));
                    }
                  } else {
                    addToCartBottomModelSheet(
                        context.read<GetCartCubit>().getProductDetailsData(widget.productDetails.id!, widget.productDetails)[0]);
                  }
                } else {
                  showDialog(
                      context: context,
                      builder: (_) => BranchCloseDialog(hours: "", minute: "", status: false, width: widget.width!, height: widget.height!));
                }
              },
              child: Container(
                  padding: EdgeInsetsDirectional.only(
                      top: widget.height! / 99.0, end: widget.width! / 40.0, start: widget.width! / 40.0, bottom: widget.height! / 80.0),
                  width: widget.width!,
                  margin: EdgeInsetsDirectional.only(top: widget.height! / 80.0, start: widget.width! / 24.0, end: widget.width! / 24.0),
                  decoration: DesignConfig.boxDecorationContainerCardShadow(
                      Theme.of(context).colorScheme.onBackground, Theme.of(context).colorScheme.onPrimary.withOpacity(0.1), 8.0, 0, 0, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
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
                                  child: ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [shaderColor, widget.off!.toStringAsFixed(2) == "0.00" ? shaderColor : black],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.darken,
                                      child: DesignConfig.imageWidgets(widget.productDetails.image!, widget.height! / 6.5, widget.width!, "2")),
                                )),
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              start: 10.0,
                              bottom: 10.0,
                              child: widget.off!.toStringAsFixed(2) == "0.00"
                                  ? const SizedBox()
                                  : Text("${widget.off!.toStringAsFixed(2).replaceAll(regex, '')}${StringsRes.percentSymbol} ${StringsRes.off}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onBackground,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.normal)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: widget.width! / 30.0,
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(
                              children: [
                                widget.productDetails.indicator == "1"
                                    ? Container(child: SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 15, height: 15))
                                    : widget.productDetails.indicator == "2"
                                        ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"), width: 15, height: 15)
                                        : const SizedBox(),
                                (widget.productDetails.rating == "0" ||
                                        widget.productDetails.rating == "0.0" ||
                                        widget.productDetails.rating == "0.00")
                                    ? const SizedBox()
                                    : Padding(
                                        padding: EdgeInsetsDirectional.only(start: 8.0),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(DesignConfig.setSvgPath("rating"), fit: BoxFit.scaleDown, width: 7.0, height: 12.3),
                                            const SizedBox(width: 3.4),
                                            Text(
                                              double.parse(widget.productDetails.rating!).toStringAsFixed(1),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                const Spacer(),
                                BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                                  return BlocBuilder<FavoriteProductsCubit, FavoriteProductsState>(
                                      bloc: context.read<FavoriteProductsCubit>(),
                                      builder: (context, favoriteProductState) {
                                        if (favoriteProductState is FavoriteProductsFetchSuccess) {
                                          //check if restaurant is favorite or not
                                          bool isProductFavorite = context.read<FavoriteProductsCubit>().isProductFavorite(widget.productDetails.id!);
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
                                                return SizedBox(
                                                  width: 30.0,
                                                  height: 30,
                                                  child: Container(
                                                      alignment: Alignment.center,
                                                      padding: const EdgeInsets.all(4.0),
                                                      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.error)),
                                                );
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
                                                          product: widget.productDetails,
                                                          branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                    } else {
                                                      context.read<UpdateProductFavoriteStatusCubit>().favoriteProduct(
                                                          userId: context.read<AuthCubit>().getId(),
                                                          type: productsKey,
                                                          product: widget.productDetails,
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
                                                              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
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
                            widget.from == "home" ? SizedBox(height: 8.0) : const SizedBox.shrink(),
                            widget.from == "home"
                                ? Text(widget.productDetails.categoryName!,
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis)
                                : const SizedBox.shrink(),
                            widget.from == "home" ? SizedBox(height: 8.0) : const SizedBox.shrink(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(widget.productDetails.name!,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                overflow: TextOverflow.ellipsis),
                                            maxLines: 2),
                                      ),
                                      SizedBox(width: widget.width! / 50.0),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.read<SystemConfigCubit>().getCurrency() + widget.price.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.w700)),
                                    SizedBox(width: widget.width! / 99.0),
                                    widget.off!.toStringAsFixed(2) == "0.00"
                                        ? const SizedBox()
                                        : Text(
                                            "${context.read<SystemConfigCubit>().getCurrency()}${widget.productDetails.variants![0].price!}",
                                            style: TextStyle(
                                                decoration: TextDecoration.lineThrough,
                                                letterSpacing: 0,
                                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                overflow: TextOverflow.ellipsis),
                                            maxLines: 1,
                                          ),
                                  ],
                                ),
                                const Spacer(),
                                widget.from == "home"
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: EdgeInsetsDirectional.only(top: widget.height! / 60.0),
                                        child: /* context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                ?  */
                                            InkWell(
                                                onTap: () {
                                                  if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
                                                    bool check = getStoreOpenStatus(widget.productDetails.startTime!, widget.productDetails.endTime!);
                                                    if (widget.productDetails.availableTime == "1") {
                                                      if (check == true) {
                                                        addToCartBottomModelSheet(context
                                                            .read<GetCartCubit>()
                                                            .getProductDetailsData(widget.productDetails.id!, widget.productDetails)[0]);
                                                      } else {
                                                        showDialog(
                                                            context: context,
                                                            builder: (_) => ProductUnavailableDialog(
                                                                startTime: widget.productDetails.startTime,
                                                                endTime: widget.productDetails.endTime,
                                                                width: widget.width,
                                                                height: widget.height));
                                                      }
                                                    } else {
                                                      addToCartBottomModelSheet(context
                                                          .read<GetCartCubit>()
                                                          .getProductDetailsData(widget.productDetails.id!, widget.productDetails)[0]);
                                                    }
                                                  } else {
                                                    showDialog(
                                                        context: context,
                                                        builder: (_) => BranchCloseDialog(
                                                            hours: "", minute: "", status: false, width: widget.width!, height: widget.height!));
                                                  }
                                                },
                                                child: (context.read<GetQuantityCubit>().fetchQty() == "0" ||
                                                        context.read<GetQuantityCubit>().fetchQty() == "")
                                                    ? Container(
                                                        alignment: Alignment.center,
                                                        width: widget.width! / 3.8,
                                                        height: widget.height! / 20,
                                                        decoration: DesignConfig.boxDecorationContainerBorder(
                                                            context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                                ? Theme.of(context).colorScheme.primary
                                                                : textFieldBorder,
                                                            context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                                                : textFieldBackground,
                                                            5.0),
                                                        child: Text(UiUtils.getTranslatedLabel(context, addLabel).toUpperCase(),
                                                            style: TextStyle(
                                                                color: context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                                    ? Theme.of(context).colorScheme.primary
                                                                    : textFieldBorder,
                                                                fontWeight: FontWeight.w700,
                                                                fontStyle: FontStyle.normal,
                                                                fontSize: 16.0),
                                                            textAlign: TextAlign.left))
                                                    : BlocConsumer<ManageCartCubit, ManageCartState>(
                                                        bloc: context.read<ManageCartCubit>(),
                                                        listener: (context, state) {
                                                          print(state.toString());

                                                          if (state is ManageCartSuccess) {
                                                            if (context.read<AuthCubit>().state is AuthInitial ||
                                                                context.read<AuthCubit>().state is Unauthenticated) {
                                                              return;
                                                            } else {
                                                              final currentCartModel = context.read<GetCartCubit>().getCartModel();
                                                              context.read<GetCartCubit>().updateCartList(currentCartModel.updateCart(
                                                                  state.data,
                                                                  (/* int.parse(currentCartModel.totalQuantity ?? '0') +  */int.parse(state.totalQuantity!))
                                                                      .toString(),
                                                                  state.subTotal,
                                                                  state.taxPercentage,
                                                                  state.taxAmount,
                                                                  state.overallAmount,
                                                                  List.from(state.variantId ?? [])..addAll(currentCartModel.variantId ?? [])));
                                                              print(currentCartModel.variantId);
                                                              if (context.read<AuthCubit>().getId().isEmpty ||
                                                                  context.read<AuthCubit>().getId() == "") {
                                                              } else {
                                                                if (promoCode != "") {
                                                                  context.read<ValidatePromoCodeCubit>().getValidatePromoCode(
                                                                      promoCode,
                                                                      context.read<AuthCubit>().getId(),
                                                                      state.overallAmount!.toStringAsFixed(2),
                                                                      context.read<SettingsCubit>().getSettings().branchId);
                                                                }
                                                              }
                                                              Future.delayed(const Duration(seconds: 1), () {
                                                                context
                                                                    .read<GetQuantityCubit>()
                                                                    .getQuantity(widget.productDetails.id!, widget.productDetails, context);
                                                              });
                                                            }
                                                          } else if (state is ManageCartFailure) {
                                                            if (context.read<AuthCubit>().state is AuthInitial ||
                                                                context.read<AuthCubit>().state is Unauthenticated) {
                                                              return;
                                                            } else {
                                                              UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                                            }
                                                          }
                                                        },
                                                        builder: (context, state) {
                                                          return Container(
                                                            padding: EdgeInsetsDirectional.all(8.0),
                                                            alignment: Alignment.center,
                                                            width: widget.width! / 3.8,
                                                            height: widget.height! / 20,
                                                            decoration:
                                                                DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 5.0),
                                                            child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  BlocConsumer<RemoveFromCartCubit, RemoveFromCartState>(
                                                                      bloc: context.read<RemoveFromCartCubit>(),
                                                                      listener: (context, state) {
                                                                        if (state is RemoveFromCartSuccess) {
                                                                          context.read<GetCartCubit>().getCartUser(
                                                                              userId: context.read<AuthCubit>().getId(),
                                                                              branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                        }
                                                                      },
                                                                      builder: (context, state) {
                                                                        return InkWell(
                                                                          onTap: () async {
                                                                            List<String> addOnIds = [];
                                                                            List<String> addOnQty = [];
                                                                            List<double> addOnPrice = [];
                                                                            List<String> productAddOnIds = [];
                                                                            List<String> productAddOnId = [];
                                                                            if (context.read<AuthCubit>().getId().isEmpty ||
                                                                                context.read<AuthCubit>().getId() == "") {
                                                                              productAddOnId = (await db.getVariantItemData(widget.productDetails.id!,
                                                                                  widget.productDetails.variants![0].id!))!;
                                                                              productAddOnIds = productAddOnId
                                                                                  .toString()
                                                                                  .replaceAll("[", "")
                                                                                  .replaceAll("]", "")
                                                                                  .split(",");
                                                                            } else {
                                                                              if (widget.productDetails.variants![0].addOnsData!.isEmpty) {
                                                                                for (int i = 0;
                                                                                    i < widget.productDetails.variants![0].addOnsData!.length;
                                                                                    i++) {
                                                                                  productAddOnIds
                                                                                      .add(widget.productDetails.variants![0].addOnsData![i].id!);
                                                                                }
                                                                              }
                                                                            }
                                                                            if (widget.productDetails.productAddOns!.isNotEmpty) {
                                                                              for (int j = 0; j < widget.productDetails.productAddOns!.length; j++) {
                                                                                ProductAddOnsModel data = widget.productDetails.productAddOns![j];
                                                                                if (productAddOnIds.contains(data.id)) {
                                                                                  if (!addOnIds.contains(data.id!)) {
                                                                                    addOnIds.add(data.id!);
                                                                                    addOnQty.add(
                                                                                        (int.parse(context.read<GetQuantityCubit>().fetchQty()) - 1)
                                                                                            .toString());
                                                                                    addOnPrice.add(double.parse(data.price!));
                                                                                  }
                                                                                } else {}
                                                                              }
                                                                            }
                                                                            var sum = 0.0;
                                                                            for (var i = 0; i < addOnPrice.length; i++) {
                                                                              sum += (addOnPrice[i] *
                                                                                  int.parse(context.read<GetQuantityCubit>().fetchQty()));
                                                                            }
                                                                            double priceCurrent =
                                                                                double.parse(widget.productDetails.variants![0].specialPrice!);
                                                                            if (priceCurrent == 0) {
                                                                              priceCurrent = double.parse(widget.productDetails.variants![0].price!);
                                                                            }
                                                                            double overAllTotal = (priceCurrent *
                                                                                    int.parse(context.read<GetQuantityCubit>().fetchQty()!) +
                                                                                sum);
                                                                            if (int.parse(context.read<GetQuantityCubit>().fetchQty()) == 1) {
                                                                              context.read<RemoveFromCartCubit>().removeFromCart(
                                                                                  userId: context.read<AuthCubit>().getId(),
                                                                                  productVariantId: widget.productDetails.variants![0].id,
                                                                                  branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                            } else {
                                                                              if (context.read<AuthCubit>().getId().isEmpty ||
                                                                                  context.read<AuthCubit>().getId() == "") {
                                                                                db
                                                                                    .insertCart(
                                                                                        widget.productDetails.id!,
                                                                                        widget.productDetails.variants![0].id!,
                                                                                        (int.parse(context.read<GetQuantityCubit>().fetchQty()) - 1)
                                                                                            .toString(),
                                                                                        addOnIds.isNotEmpty ? addOnIds.join(",").toString() : "",
                                                                                        addOnQty.isNotEmpty ? addOnQty.join(",").toString() : "",
                                                                                        overAllTotal.toString(),
                                                                                        context.read<SettingsCubit>().getSettings().branchId,
                                                                                        context)
                                                                                    .then((value) {
                                                                                  Future.delayed(const Duration(seconds: 1), () {
                                                                                    context.read<GetQuantityCubit>().getQuantity(
                                                                                        widget.productDetails.id!, widget.productDetails, context);
                                                                                  });
                                                                                });
                                                                              } else {
                                                                                context.read<ManageCartCubit>().manageCartUser(
                                                                                    userId: context.read<AuthCubit>().getId(),
                                                                                    productVariantId: widget.productDetails.variants![0].id,
                                                                                    isSavedForLater: "0",
                                                                                    qty: (int.parse(context.read<GetQuantityCubit>().fetchQty()) - 1)
                                                                                        .toString(),
                                                                                    addOnId: addOnIds.isNotEmpty ? addOnIds.join(",").toString() : "",
                                                                                    addOnQty:
                                                                                        addOnQty.isNotEmpty ? addOnQty.join(",").toString() : "",
                                                                                    branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                              }
                                                                            }
                                                                            Future.delayed(const Duration(seconds: 1), () {
                                                                              context.read<GetQuantityCubit>().getQuantity(
                                                                                  widget.productDetails.id!, widget.productDetails, context);
                                                                            });
                                                                            if (context.read<AuthCubit>().getId().isEmpty ||
                                                                                context.read<AuthCubit>().getId() == "") {
                                                                            } else {
                                                                              if (promoCode != "") {
                                                                                context.read<ValidatePromoCodeCubit>().getValidatePromoCode(
                                                                                    promoCode,
                                                                                    context.read<AuthCubit>().getId(),
                                                                                    overAllAmount.toStringAsFixed(2),
                                                                                    context.read<SettingsCubit>().getSettings().branchId);
                                                                              }
                                                                            }
                                                                          },
                                                                          child: Container(
                                                                              decoration: DesignConfig.boxDecorationContainer(
                                                                                  Theme.of(context).colorScheme.onBackground, 2.0),
                                                                              child: Icon(Icons.remove,
                                                                                  color: Theme.of(context).colorScheme.onSecondary)),
                                                                        );
                                                                      }),
                                                                  const Spacer(),
                                                                  Text(context.read<GetQuantityCubit>().fetchQty(),
                                                                      /* context.read<GetCartCubit>().AllVariantQty(widget.dataItem.id!, widget.dataItem) */
                                                                      textAlign: TextAlign.center,
                                                                      style: TextStyle(
                                                                          color: Theme.of(context).colorScheme.onPrimary,
                                                                          fontWeight: FontWeight.w700,
                                                                          fontStyle: FontStyle.normal,
                                                                          fontSize: 16.0)),
                                                                  const Spacer(),
                                                                  InkWell(
                                                                      onTap: () async {
                                                                        List<String> addOnIds = [];
                                                                        List<String> addOnQty = [];
                                                                        List<double> addOnPrice = [];
                                                                        List<String> productAddOnIds = [];
                                                                        List<String> productAddOnId = [];
                                                                        if (context.read<AuthCubit>().getId().isEmpty ||
                                                                            context.read<AuthCubit>().getId() == "") {
                                                                          productAddOnId = (await db.getVariantItemData(
                                                                              widget.productDetails.id!, widget.productDetails.variants![0].id!))!;
                                                                          productAddOnIds = productAddOnId
                                                                              .toString()
                                                                              .replaceAll("[", "")
                                                                              .replaceAll("]", "")
                                                                              .split(",");
                                                                        } else {
                                                                          if (widget.productDetails.variants![0].addOnsData!.isEmpty) {
                                                                            for (int i = 0;
                                                                                i < widget.productDetails.variants![0].addOnsData!.length;
                                                                                i++) {
                                                                              productAddOnIds
                                                                                  .add(widget.productDetails.variants![0].addOnsData![i].id!);
                                                                            }
                                                                          }
                                                                        }
                                                                        if (widget.productDetails.productAddOns!.isNotEmpty) {
                                                                          for (int j = 0; j < widget.productDetails.productAddOns!.length; j++) {
                                                                            ProductAddOnsModel data = widget.productDetails.productAddOns![j];
                                                                            if (productAddOnIds.contains(data.id)) {
                                                                              if (!addOnIds.contains(data.id!)) {
                                                                                addOnIds.add(data.id!);
                                                                                addOnQty.add(
                                                                                    (int.parse(context.read<GetQuantityCubit>().fetchQty()) - 1)
                                                                                        .toString());
                                                                                addOnPrice.add(double.parse(data.price!));
                                                                              }
                                                                            } else {}
                                                                          }
                                                                        }
                                                                        var sum = 0.0;
                                                                        for (var i = 0; i < addOnPrice.length; i++) {
                                                                          sum += (addOnPrice[i] *
                                                                              int.parse(context.read<GetQuantityCubit>().fetchQty()));
                                                                        }
                                                                        double priceCurrent =
                                                                            double.parse(widget.productDetails.variants![0].specialPrice!);
                                                                        if (priceCurrent == 0) {
                                                                          priceCurrent = double.parse(widget.productDetails.variants![0].price!);
                                                                        }
                                                                        double overAllTotal =
                                                                            (priceCurrent * int.parse(context.read<GetQuantityCubit>().fetchQty()!) +
                                                                                sum);
                                                                        setState(() {
                                                                          if (int.parse(context.read<GetQuantityCubit>().fetchQty()) <
                                                                              int.parse(widget.productDetails.minimumOrderQuantity!)) {
                                                                            Navigator.pop(context);
                                                                            UiUtils.setSnackBar(
                                                                                "${StringsRes.minimumQuantityAllowed} ${widget.productDetails.minimumOrderQuantity!}",
                                                                                context,
                                                                                false,
                                                                                type: "2");
                                                                          } else if (widget.productDetails.totalAllowedQuantity != "" &&
                                                                              int.parse(context.read<GetQuantityCubit>().fetchQty()) >=
                                                                                  int.parse(widget.productDetails.totalAllowedQuantity!)) {
                                                                            UiUtils.setSnackBar(
                                                                                "${StringsRes.minimumQuantityAllowed} ${widget.productDetails.totalAllowedQuantity!}",
                                                                                context,
                                                                                false,
                                                                                type: "2");
                                                                          } else {
                                                                            if (context.read<AuthCubit>().getId().isEmpty ||
                                                                                context.read<AuthCubit>().getId() == "") {
                                                                              db
                                                                                  .insertCart(
                                                                                      widget.productDetails.id!,
                                                                                      widget.productDetails.variants![0].id!,
                                                                                      (int.parse(context.read<GetQuantityCubit>().fetchQty()) + 1)
                                                                                          .toString(),
                                                                                      addOnIds.isNotEmpty ? addOnIds.join(",").toString() : "",
                                                                                      addOnQty.isNotEmpty ? addOnQty.join(",").toString() : "",
                                                                                      overAllTotal.toString(),
                                                                                      context.read<SettingsCubit>().getSettings().branchId,
                                                                                      context)
                                                                                  .then((value) {
                                                                                Future.delayed(const Duration(seconds: 1), () {
                                                                                  context.read<GetQuantityCubit>().getQuantity(
                                                                                      widget.productDetails.id!, widget.productDetails, context);
                                                                                });
                                                                              });
                                                                            } else {
                                                                              context.read<ManageCartCubit>().manageCartUser(
                                                                                  userId: context.read<AuthCubit>().getId(),
                                                                                  productVariantId: widget.productDetails.variants![0].id,
                                                                                  isSavedForLater: "0",
                                                                                  qty: (int.parse(context.read<GetQuantityCubit>().fetchQty()) + 1)
                                                                                      .toString(),
                                                                                  addOnId: addOnIds.isNotEmpty ? addOnIds.join(",").toString() : "",
                                                                                  addOnQty: addOnQty.isNotEmpty ? addOnQty.join(",").toString() : "",
                                                                                  branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                            }
                                                                            Future.delayed(const Duration(seconds: 1), () {
                                                                              context.read<GetQuantityCubit>().getQuantity(
                                                                                  widget.productDetails.id!, widget.productDetails, context);
                                                                            });
                                                                            if (context.read<AuthCubit>().getId().isEmpty ||
                                                                                context.read<AuthCubit>().getId() == "") {
                                                                            } else {
                                                                              if (promoCode != "") {
                                                                                context.read<ValidatePromoCodeCubit>().getValidatePromoCode(
                                                                                    promoCode,
                                                                                    context.read<AuthCubit>().getId(),
                                                                                    overAllAmount.toStringAsFixed(2),
                                                                                    context.read<SettingsCubit>().getSettings().branchId);
                                                                              }
                                                                            }
                                                                          }
                                                                        });
                                                                      },
                                                                      child: Container(
                                                                          decoration: DesignConfig.boxDecorationContainer(
                                                                              Theme.of(context).colorScheme.onBackground, 2.0),
                                                                          child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSecondary))),
                                                                ]),
                                                          );
                                                        }))),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ],
                  )),
            );
          });
        },
      ),
    );
  }
}
