import 'package:flutter/material.dart';

class SmallButtonContainer extends StatefulWidget {
  final double? width, height, start, end, top, bottom, radius;
  final String? text;
  final VoidCallback? onTap;
  final Color? color, borderColor, textColor;
  final bool? status;
  const SmallButtonContainer(
      {Key? key,
      this.width,
      this.height,
      this.text,
      this.onTap,
      this.color,
      this.start,
      this.end,
      this.top,
      this.bottom,
      this.status,
      this.borderColor,
      this.textColor,
      this.radius})
      : super(key: key);

  @override
  State<SmallButtonContainer> createState() => _SmallButtonContainerState();
}

class _SmallButtonContainerState extends State<SmallButtonContainer> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: widget.start!, end: widget.end!, top: widget.top!, bottom: widget.bottom!),
      child: SizedBox(
        height: widget.height! / 25,
        width: widget.width! / 3.6,
        child: TextButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(widget.textColor!.withOpacity(0.10)),
            backgroundColor: MaterialStateProperty.all(widget.color),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: BorderSide(color: widget.borderColor!)),
            ),
          ),
          onPressed: widget.onTap,
          child: widget.status == true
              ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onBackground)
              : Text(widget.text!,
                  textAlign: TextAlign.center, maxLines: 1, style: TextStyle(color: widget.textColor!, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
