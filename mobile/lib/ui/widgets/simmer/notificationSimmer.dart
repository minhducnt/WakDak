import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';

class NotificationSimmer extends StatelessWidget {
  final double? width, height;
  const NotificationSimmer({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height! / 1.28,
      child: Center(
          child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: ListView.builder(
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: Container(
                margin: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 50.0),
                width: width,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: width! / 32.0, bottom: width! / 32.0, start: width! / 32.0, end: width! / 32.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 10.0, width: double.maxFinite, color: shimmerContentColor),
                            const SizedBox(height: 7),
                            Container(height: 10.0, width: double.maxFinite, color: shimmerContentColor),
                            const SizedBox(height: 7),
                            Container(height: 10.0, width: double.maxFinite, color: shimmerContentColor),
                          ],
                        ),
                      ),
                      Container(
                          height: 81.0,
                          width: 81.0,
                          decoration: DesignConfig.boxDecorationContainer(shimmerContentColor, 4.0),
                          margin: EdgeInsetsDirectional.only(start: width! / 32.0)),
                    ],
                  ),
                )),
          ),
          itemCount: 6,
        ),
      )),
    );
  }
}
