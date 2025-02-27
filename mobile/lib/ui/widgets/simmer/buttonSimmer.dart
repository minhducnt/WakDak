import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';

class ButtonSimmer extends StatelessWidget {
  final int? length;
  final double? width, height;
  const ButtonSimmer({Key? key, this.length, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height! / 9.0,
      width: width,
      padding: EdgeInsetsDirectional.only(top: height! / 55.0, start: width! / 40.0, end: width! / 40.0),
      child: Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {},
              child: Container(
                  height: height! / 12.0,
                  margin: EdgeInsetsDirectional.only(bottom: height! / 80.0),
                  width: width,
                  padding: EdgeInsetsDirectional.only(top: height! / 55.0, bottom: height! / 55.0, start: width! / 40.0, end: width! / 40.0),
                  decoration: DesignConfig.boxDecorationContainer(shimmerContentColor, 10.0)))),
    );
  }
}
