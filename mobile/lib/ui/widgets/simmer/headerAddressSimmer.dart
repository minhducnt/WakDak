import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wakDak/ui/styles/color.dart';

class HeaderAddressSimmer extends StatelessWidget {
  final double? width, height;
  const HeaderAddressSimmer({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: SizedBox(
          height: height! / 20.0,
          child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: width! / 10.0,
              height: 8.0,
              color: shimmerContentColor,
            ),
            SizedBox(height: height! / 99.0),
            Container(
              width: width! / 2.0,
              height: 8.0,
              color: shimmerContentColor,
            ),
          ]),
        ),
      ),
    );
  }
}
