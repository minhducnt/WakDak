import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/simmer/productSimmer.dart';

class MenuDetailSimmer extends StatelessWidget {
  final double? width, height;
  const MenuDetailSimmer({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Container(
                padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 99.0),
                height: height!,
                width: width!,
                margin: EdgeInsetsDirectional.only(top: height! / 15.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                        child: Row(
                          children: [
                            Container(
                              width: width! / 20,
                              height: height! / 40.0,
                              margin: EdgeInsetsDirectional.only(end: width! / 20.0),
                              decoration: DesignConfig.boxDecorationContainer(white, 0),
                            ),
                            Container(
                              width: width! / 6,
                              height: height! / 40.0,
                              decoration: DesignConfig.boxDecorationContainer(white, 0),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: width! / 40.0, top: height! / 80.0, bottom: height! / 50.0),
                      ),
                      ProductSimmer(length: 5, width: width!, height: height!),
                    ],
                  ),
                ))));
  }
}
