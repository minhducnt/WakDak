import 'dart:async';

import 'package:flutter/material.dart';

import 'package:wakDak/ui/screen/auth/otp_verify_screen.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class ResendOtpTimerContainer extends StatefulWidget {
  final Function enableResendOtpButton;
  const ResendOtpTimerContainer({Key? key, required this.enableResendOtpButton}) : super(key: key);

  @override
  ResendOtpTimerContainerState createState() => ResendOtpTimerContainerState();
}

class ResendOtpTimerContainerState extends State<ResendOtpTimerContainer> {
  Timer? resendOtpTimer;
  int resendOtpTimeInSeconds = otpTimeOutSeconds - 1;

  void setResendOtpTimer() {
    print("Start resend otp timer");
    print("------------------------------------");
    setState(() {
      resendOtpTimeInSeconds = otpTimeOutSeconds - 1;
    });
    resendOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendOtpTimeInSeconds == 0) {
        timer.cancel();
        widget.enableResendOtpButton();
      } else {
        resendOtpTimeInSeconds--;
        setState(() {});
        print("------------------------------------$resendOtpTimeInSeconds");
      }
    });
  }

  void cancelOtpTimer() {
    resendOtpTimer?.cancel();
  }

  @override
  void dispose() {
    cancelOtpTimer();
    super.dispose();
  }

//to get time to display in text widget
  String getTime() {
    String secondsAsString = resendOtpTimeInSeconds < 10 ? " 0$resendOtpTimeInSeconds" : resendOtpTimeInSeconds.toString();
    return " $secondsAsString";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "${UiUtils.getTranslatedLabel(context, resetCodeInLabel)} 00 :${getTime()} ",
      style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500),
      textAlign: TextAlign.center,
    );
  }
}
