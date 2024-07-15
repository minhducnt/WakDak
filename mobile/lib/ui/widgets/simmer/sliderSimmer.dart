import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wakDak/ui/styles/color.dart';

class SliderSimmer extends StatelessWidget {
  final double? width, height;
  const SliderSimmer({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: SizedBox(
              height: height! / 4.6,
              child: Container(
                margin: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 40.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  child: Container(
                    width: width,
                    height: height! / 5.0,
                    color: shimmerContentColor,
                  ),
                ),
              ),
            )));
  }
}
