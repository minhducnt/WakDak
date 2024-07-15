import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/favourite/favouriteProductsCubit.dart';
import 'package:wakDak/cubit/favourite/updateFavouriteProduct.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/bottomSheetContainer.dart';
import 'package:wakDak/ui/widgets/brachCloseDialog.dart';
import 'package:wakDak/ui/widgets/productUnavailableDialog.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/string.dart';

class TopBrandContainer extends StatefulWidget {
  final List<ProductDetails> topProductList;
  final double? width, height, price, off;
  final int index;
  final String? from;
  const TopBrandContainer(
      {Key? key, required this.topProductList, this.width, this.height, required this.index, required this.from, this.price, this.off})
      : super(key: key);

  @override
  State<TopBrandContainer> createState() => _TopBrandContainerState();
}

class _TopBrandContainerState extends State<TopBrandContainer> {
  var db = DatabaseHelper();
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
        qty = int.parse(productDetailsModel.variants![currentIndex].cartCount!); //qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      } else {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      }
    }
    qtyData[productVariantId!] = qty;
    bool descTextShowFlag = false;

    showModalBottomSheet(
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
        });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UpdateProductFavoriteStatusCubit>(
      create: (context) => UpdateProductFavoriteStatusCubit(),
      child: Builder(builder: (context) {
        return GestureDetector(
          onTap: () {
            if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
              bool check = getStoreOpenStatus(widget.topProductList[widget.index].startTime!, widget.topProductList[widget.index].endTime!);
              if (widget.topProductList[widget.index].availableTime == "1") {
                if (check == true) {
                  addToCartBottomModelSheet(context
                      .read<GetCartCubit>()
                      .getProductDetailsData(widget.topProductList[widget.index].id!, widget.topProductList[widget.index])[0]);
                } else {
                  showDialog(
                      context: context,
                      builder: (_) => ProductUnavailableDialog(
                          startTime: widget.topProductList[widget.index].startTime,
                          endTime: widget.topProductList[widget.index].endTime,
                          width: widget.width,
                          height: widget.height));
                }
              } else {
                addToCartBottomModelSheet(context
                    .read<GetCartCubit>()
                    .getProductDetailsData(widget.topProductList[widget.index].id!, widget.topProductList[widget.index])[0]);
              }
            } else {
              showDialog(
                  context: context,
                  builder: (_) => BranchCloseDialog(hours: "", minute: "", status: false, width: widget.width!, height: widget.height!));
            }
          },
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsetsDirectional.only(start: widget.width! / 20.0, top: widget.height! / 99.0, bottom: widget.height! / 99.0),
            padding: EdgeInsetsDirectional.only(start: 8.0, top: 8.0, bottom: 8.0, end: 8.0),
            width: widget.from == "home" ? widget.width! / 2.4 : widget.width,
            height: widget.from == "home" ? widget.height! / 2.78 : widget.height!,
            decoration: DesignConfig.boxDecorationContainerCardShadow(
                Theme.of(context).colorScheme.onBackground, Theme.of(context).colorScheme.onPrimary.withOpacity(0.1), 8.0, 0, 0, 8, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  fit: StackFit.loose,
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
                            child: DesignConfig.imageWidgets(widget.topProductList[widget.index].image!, widget.height! / 5.5,
                                widget.from == "home" ? widget.width! / 2.4 : widget.width, "2")),
                      ),
                    ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      start: 10.0,
                      bottom: 10.0,
                      child: widget.off!.toStringAsFixed(2) == "0.00"
                          ? const SizedBox()
                          : Text("${widget.off!.toStringAsFixed(2)}${StringsRes.percentSymbol} ${StringsRes.off}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onBackground,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal)),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    widget.topProductList[widget.index].indicator == "1"
                        ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 15, height: 15)
                        : widget.topProductList[widget.index].indicator == "2"
                            ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"), width: 15, height: 15)
                            : Row(
                                children: [
                                  SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 15, height: 15),
                                  const SizedBox(width: 2.0),
                                  SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"), width: 15, height: 15),
                                ],
                              ),
                    widget.topProductList[widget.index].rating == "0"
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(Routes.productRatingDetail, arguments: {'productId': widget.topProductList[widget.index].id!});
                              },
                              child: Row(
                                children: [
                                  SvgPicture.asset(DesignConfig.setSvgPath("rating"), fit: BoxFit.scaleDown, width: 7.0, height: 12.3),
                                  const SizedBox(width: 3.4),
                                  Text(
                                    double.parse(widget.topProductList[widget.index].rating!).toStringAsFixed(1),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
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
                                  context.read<FavoriteProductsCubit>().isProductFavorite(widget.topProductList[widget.index].id!);
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
                                      child: ClipOval(
                                          child: Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(4.0),
                                              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.error))),
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
                                              product: widget.topProductList[widget.index],
                                              branchId: context.read<SettingsCubit>().getSettings().branchId);
                                        } else {
                                          context.read<UpdateProductFavoriteStatusCubit>().favoriteProduct(
                                              userId: context.read<AuthCubit>().getId(),
                                              type: productsKey,
                                              product: widget.topProductList[widget.index],
                                              branchId: context.read<SettingsCubit>().getSettings().branchId);
                                        }
                                      },
                                      child: ClipOval(
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
                                                    height: 18)),
                                      ));
                                },
                              );
                            }
                            //if some how failed to fetch favorite products or still fetching the products
                            return InkWell(
                                onTap: () {
                                  if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                    Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'product'}).then((value) {
                                      appDataRefresh(context);
                                    });
                                    return;
                                  }
                                },
                                child: Container(
                                    alignment: Alignment.center,
                                    child: SvgPicture.asset(DesignConfig.setSvgPath("wishlist1"),
                                        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                        width: 20.0,
                                        height: 20)));
                          });
                    })
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(widget.topProductList[widget.index].categoryName!,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6.0),
                Expanded(
                  child: Text(widget.topProductList[widget.index].name!,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 6.0),
                Row(
                  children: [
                    Text(context.read<SystemConfigCubit>().getCurrency() + widget.price.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(width: widget.width! / 99.0),
                    widget.off!.toStringAsFixed(2) == "0.00"
                        ? const SizedBox()
                        : Text(
                            "${context.read<SystemConfigCubit>().getCurrency()}${widget.topProductList[widget.index].variants![0].price!}",
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                letterSpacing: 0,
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis),
                            maxLines: 1,
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
