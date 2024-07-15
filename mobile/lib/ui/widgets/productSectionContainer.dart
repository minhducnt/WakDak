import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/favourite/updateFavouriteProduct.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class ProductSectionContainer extends StatelessWidget {
  final ProductDetails productDetails;
  final List<ProductDetails>? productDetailsList;
  final double? width, height, price, off;
  final String? from, axis;
  const ProductSectionContainer(
      {Key? key, required this.productDetails, this.width, this.height, this.price, this.off, this.productDetailsList, this.from, this.axis})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    RegExp regex = RegExp(r'([^\d]00)(?=[^\d]|$)');
    return BlocProvider<UpdateProductFavoriteStatusCubit>(
      create: (context) => UpdateProductFavoriteStatusCubit(),
      child: Builder(builder: (context) {
        return Container(
          alignment: Alignment.topLeft,
          margin: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0, end: axis == "horizontal" ? 0.0 : width!/ 20.0),
          child: Stack(
            textDirection: Directionality.of(context),
            children: [
              Container(
                alignment: Alignment.center,
                width: productDetailsList!.length != 1 && axis == "horizontal" ? width! / 1.5 : width! / 1.1,
                height: height! / 3.5,
                margin: EdgeInsetsDirectional.only(top: height! / 80.0),
                child: Stack(
                  fit: StackFit.loose,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
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
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [shaderColor, black],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.darken,
                            child: DesignConfig.imageWidgets(productDetails.image!, height! / 3.5,
                                productDetailsList!.length != 1 && axis == "horizontal" ? width! / 1.5 : width! / 1.1, "2")),
                      ),
                    ),
                    double.parse(productDetails.rating!).toStringAsFixed(1).toString() == "0.0"
                        ? const SizedBox()
                        : Positioned.directional(
                            textDirection: Directionality.of(context),
                            start: 10.0,
                            top: 10.0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(Routes.productRatingDetail, arguments: {'productId': productDetails.id!});
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2.0),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    padding: const EdgeInsets.all(5.0),
                                    decoration: DesignConfig.boxDecorationContainer(black, 2),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(DesignConfig.setSvgPath("rating"), fit: BoxFit.scaleDown, width: 7.0, height: 12.3),
                                        const SizedBox(width: 3.4),
                                        Text(
                                          double.parse(productDetails.rating!).toStringAsFixed(1),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      start: 10.0,
                      bottom: 10.0,
                      end: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: axis == "horizontal" ? width!/2.2: width!/ 1.5,
                                child: Text(
                                  productDetails.name!,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onBackground,
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      overflow: TextOverflow.ellipsis),
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(height: 5.0),
                              off!.toStringAsFixed(2) == "0.00"
                                  ? const SizedBox()
                                  : Text(
                                      "${off!.toStringAsFixed(2).replaceAll(regex, '')}${StringsRes.percentSymbol} ${UiUtils.getTranslatedLabel(context, offLabel)}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${UiUtils.getTranslatedLabel(context, priceLabel)}",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onBackground,
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    overflow: TextOverflow.ellipsis),
                                maxLines: 2,
                              ),
                              SizedBox(height: 5.0),
                              Text(
                                "${context.read<SystemConfigCubit>().getCurrency()}${price!.toString()}",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
