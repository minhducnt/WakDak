import 'package:flutter/material.dart';

import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';

class SearchBarContainer extends StatelessWidget {
  final double? width, height;
  final String? title;
  const SearchBarContainer({Key? key, this.width, this.height, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height! / 16.0,
        alignment: Alignment.centerLeft,
        decoration: DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
        padding: EdgeInsetsDirectional.only(start: width! / 20.0),
        child: Text(title!,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 16.0, fontWeight: FontWeight.w500)));
  }
}
