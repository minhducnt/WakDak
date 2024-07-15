import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wakDak/ui/styles/color.dart';

class SectionSimmer extends StatelessWidget {
  final int? length;
  final double? width, height;
  const SectionSimmer({Key? key, this.length, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            // scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (BuildContext buildContext, index) {
              return Column(
                children: [
                  length == 10
                      ? const SizedBox.shrink()
                      : Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 60.0),
                            child: Container(color: shimmerContentColor, height: 10.0, width: width! / 1.5),
                          ),
                          const Spacer(),
                        ]),
                  SizedBox(
                    height: height! / 4.0,
                    child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: 3,
                        itemBuilder: (BuildContext buildContext, i) {
                          return Container(
                            margin: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 80.0),
                            child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                child: Container(
                                  color: shimmerContentColor,
                                  width: width! / 2.32,
                                  height: height! / 5.0,
                                )),
                          );
                        }),
                  ),
                ],
              );
            }));
  }
}
