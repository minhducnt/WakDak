import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:paytm/paytm.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/payment/GetWithdrawRequestCubit.dart';
import 'package:wakDak/cubit/payment/sendWithdrawRequestCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/cubit/transaction/transactionCubit.dart';
import 'package:wakDak/data/model/transactionModel.dart';
import 'package:wakDak/ui/screen/payment/Stripe_Service.dart';
import 'package:wakDak/ui/screen/payment/midTransWebView.dart';
import 'package:wakDak/ui/screen/payment/payment_radio.dart';
import 'package:wakDak/ui/screen/payment/paypal_webview_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/noDataContainer.dart';
import 'package:wakDak/ui/widgets/simmer/myOrderSimmer.dart';
import 'package:wakDak/ui/widgets/smallButtonContainer.dart';
import 'package:wakDak/ui/widgets/transactionContainer.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

import '../cart/cart_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  WalletScreenState createState() => WalletScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(providers: [
              BlocProvider<GetWithdrawRequestCubit>(
                create: (_) => GetWithdrawRequestCubit(),
              )
            ], child: const WalletScreen()));
  }
}

class WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  double? width, height;
  ScrollController controller = ScrollController();
  ScrollController withdrawWalletController = ScrollController();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  TextEditingController? amountController, messageController, withdrawAmountController, paymentAddressController;
  List<String?> paymentMethodList = [];
  List<String> paymentIconList = ['paypal', 'rozerpay', 'paystack', 'flutterwave', 'stripe', 'paytm', 'midtrans'];
  List<RadioModel> payModel = [];
  bool? paypal, razorpay, paumoney, paystack, flutterwave, stripe, paytm, midtrans;
  String? razorpayId, payStackId, stripeId, stripeSecret, stripeMode = "test", stripeCurCode, paytmMerId, paytmMerKey;

  int? selectedMethod;
  String? payMethod;
  StateSetter? dialogState;
  bool isProgress = false;
  late Razorpay _razorpay;
  int offset = 0;
  int total = 0;
  bool isLoading = true, payTesting = true;
  final payStackPlugin = PaystackPlugin();
  final DateFormat formatter = DateFormat('dd-MM-yyyy');
  String? walletAmount, filter = "0";
  bool enableList = false;
  int? _selectedIndex = 0;
  TabController? tabController;
  List<String> transactionType = [StringsRes.walletTransaction, StringsRes.walletWithdrawTransaction];

  @override
  void initState() {
    super.initState();
    walletAmount = context.read<SystemConfigCubit>().getWallet();
    selectedMethod = null;
    payMethod = null;
    Future.delayed(Duration.zero, () {
      paymentMethodList = [
        UiUtils.getTranslatedLabel(context, payPalLblLabel),
        UiUtils.getTranslatedLabel(context, razorpayLblLabel),
        UiUtils.getTranslatedLabel(context, payStackLblLabel),
        UiUtils.getTranslatedLabel(context, flutterWaveLblLabel),
        UiUtils.getTranslatedLabel(context, stripeLblLabel),
        UiUtils.getTranslatedLabel(context, paytmLblLabel),
        UiUtils.getTranslatedLabel(context, midtransLable),
      ];
      getPaymentMethod();
    });
    amountController = TextEditingController();
    messageController = TextEditingController();
    withdrawAmountController = TextEditingController();
    paymentAddressController = TextEditingController();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    controller.addListener(scrollListener);
    Future.delayed(Duration.zero, () {
      context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
    });
    withdrawWalletController.addListener(scrollGetWithdrawListener);
    Future.delayed(Duration.zero, () {
      context.read<GetWithdrawRequestCubit>().fetchGetWithdrawRequest(perPage, context.read<AuthCubit>().getId());
    });
    tabController = TabController(length: 2, vsync: this);
    context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.initState();
  }

  scrollListener() {
    if (controller.position.maxScrollExtent == controller.offset) {
      if (context.read<TransactionCubit>().hasMoreData()) {
        context.read<TransactionCubit>().fetchMoreTransactionData(perPage, context.read<AuthCubit>().getId(), walletKey);
      }
    }
  }

  scrollGetWithdrawListener() {
    if (withdrawWalletController.position.maxScrollExtent == withdrawWalletController.offset) {
      if (context.read<GetWithdrawRequestCubit>().hasMoreData()) {
        context.read<GetWithdrawRequestCubit>().fetchMoreGetWithdrawRequestData(perPage, context.read<AuthCubit>().getId());
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    amountController!.dispose();
    messageController!.dispose();
    withdrawAmountController!.dispose();
    paymentAddressController!.dispose();
    controller.dispose();
    withdrawWalletController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  onChanged(int position) {
    setState(() {
      _selectedIndex = position;
      enableList = !enableList;
    });
  }

  onTap() {
    setState(() {
      enableList = !enableList;
    });
  }

  Widget selectTransactionType() {
    return Container(
      decoration: DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
      margin: EdgeInsetsDirectional.only(top: height! / 99.0, start: width! / 30.0, end: width! / 30.0),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              decoration: DesignConfig.boxDecorationContainer(textFieldBackground, 4.0),
              padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 80.0, top: height! / 80.0, bottom: height! / 99.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                      child: Text(
                    transactionType[_selectedIndex!],
                    style: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontWeight: FontWeight.w500),
                  )),
                  Icon(enableList ? Icons.expand_less : Icons.expand_more,
                      size: 24.0, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76)),
                ],
              ),
            ),
          ),
          enableList
              ? ListView.builder(
                  padding: EdgeInsetsDirectional.only(top: height! / 99.9, bottom: height! / 99.0),
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: transactionType.length,
                  itemBuilder: (context, position) {
                    return InkWell(
                      onTap: () {
                        onChanged(position);
                        filter = transactionType[position];
                        if (position == 0) {
                          context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
                        } else {
                          context.read<GetWithdrawRequestCubit>().fetchGetWithdrawRequest(perPage, context.read<AuthCubit>().getId());
                        }
                      },
                      child: Container(
                          padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, top: height! / 99.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transactionType[position],
                                style: TextStyle(fontSize: 12.0, color: Theme.of(context).colorScheme.onSecondary),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(top: height! / 99.0),
                                child: DesignConfig.dividerSolid(),
                              ),
                            ],
                          )),
                    );
                  })
              : Container(),
        ],
      ),
    );
  }

  Future<void> getPaymentMethod() async {
    try {
      var parameter = {
        typeKey: paymentMethodKey,
      };
      Response response = await post(Uri.parse(Api.getSettingsUrl), body: parameter, headers: Api.getHeaders()).timeout(const Duration(seconds: 50));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata[errorKey];

        if (!error) {
          var data = getdata[dataKey];

          var payment = data["payment_method"];

          paypal = payment["paypal_payment_method"] == "1" ? true : false;
          paumoney = payment["payumoney_payment_method"] == "1" ? true : false;
          flutterwave = payment["flutterwave_payment_method"] == "1" ? true : false;
          razorpay = payment["razorpay_payment_method"] == "1" ? true : false;
          paystack = payment["paystack_payment_method"] == "1" ? true : false;
          stripe = payment["stripe_payment_method"] == "1" ? true : false;
          paytm = payment["paytm_payment_method"] == "1" ? true : false;
          midtrans = payment["midtrans_payment_method"] == "1" ? true : false;

          if (razorpay!) razorpayId = payment["razorpay_key_id"];
          if (paystack!) {
            payStackId = payment["paystack_key_id"];

            await payStackPlugin.initialize(publicKey: payStackId!);
          }
          if (stripe!) {
            stripeId = payment['stripe_publishable_key'];
            stripeSecret = payment['stripe_secret_key'];
            stripeCurCode = payment['stripe_currency_code'];

            stripeMode = payment['stripe_mode'] ?? 'test';
            StripeService.secret = stripeSecret;
            StripeService.init(stripeId, stripeMode);
          }
          if (paytm!) {
            paytmMerId = payment['paytm_merchant_id'];
            paytmMerKey = payment['paytm_merchant_key'];
            payTesting = payment['paytm_payment_mode'] == 'sandbox' ? true : false;
          }
          if (midtrans!) {
            midTranshMerchandId = payment['midtrans_merchant_id'];
            midtransPaymentMethod = payment['midtrans_payment_method'];
            midtransPaymentMode = payment['midtrans_payment_mode'];
            midtransServerKey = payment['midtrans_server_key'];
            midtrasClientKey = payment['midtrans_client_key'];
          }

          for (int i = 0; i < paymentMethodList.length; i++) {
            payModel.add(RadioModel(isSelected: i == selectedMethod ? true : false, name: paymentMethodList[i], img: paymentIconList[i]));
          }
        }
      }
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      if (dialogState != null) dialogState!(() {});
    } on TimeoutException catch (_) {
      UiUtils.setSnackBar(StringsRes.somethingMsg, context, false, type: "2");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    sendRequest(response.paymentId!, "RazorPay");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    var getdata = json.decode(response.message!);
    String errorMsg = getdata[errorKey]["description"];

    UiUtils.setSnackBar(errorMsg, context, false, type: "2");

    if (mounted) {
      isProgress = true;
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> sendRequest(String txnId, String payMethod) async {
    String orderId =
        "wallet-refill-user-${context.read<AuthCubit>().getId()}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";
    try {
      var body = {
        userIdKey: context.read<AuthCubit>().getId(),
        amountKey: amountController!.text.toString(),
        transactionTypeKey: 'wallet',
        typeKey: 'credit',
        messageKey: (messageController!.text == '' || messageController!.text.isEmpty) ? "Added through wallet" : messageController!.text,
        txnIdKey: txnId,
        orderIdKey: orderId,
        statusKey: "success",
        paymentMethodKey: payMethod.toLowerCase(),
      };

      if (payMethod.toLowerCase() == "stripe" || payMethod.toLowerCase() == "paypal") {
        body[skipVerifyTransactionKey] = (payMethod.toLowerCase() == "stripe" || payMethod.toLowerCase() == "paypal") ? "true" : "false";
      }

      final result = await Api.post(body: body, url: Api.addTransactionUrl, token: true, errorCode: true);

      if ((payMethod.toLowerCase() == "stripe" || payMethod.toLowerCase() == "paypal")) {
        setState(() {
          walletAmount = context.read<SystemConfigCubit>().setWallet(result['new_balance']);
        });
      } else {
        setState(() {
          walletAmount = context.read<SystemConfigCubit>().setWallet(result['new_balance']);
        });
      }

      bool error = result[errorKey];
      String msg = result[messageKey];

      if (!error) {
        if (mounted) {
          setState(() {
            context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
            if (context.read<TransactionCubit>().getTransactionList().isEmpty) {
              context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
            } else {
              context.read<TransactionCubit>().addTransaction(TransactionModel.fromJson(result[dataKey][0]));
            }
          });
        }

        UiUtils.setSnackBar(msg, context, false, type: "1");
      }
      if (mounted) {
        setState(() {
          isProgress = false;
        });
      }
    } on TimeoutException catch (_) {
      UiUtils.setSnackBar(StringsRes.somethingMsg, context, false, type: "2");

      setState(() {
        isProgress = false;
      });
    }
    return;
  }

  List<Widget> getPayList() {
    return paymentMethodList
        .asMap()
        .map(
          (index, element) => MapEntry(index, paymentItem(index)),
        )
        .values
        .toList();
  }

  Widget paymentItem(int index) {
    if (index == 0 && paypal! ||
        index == 1 && razorpay! ||
        index == 2 && paystack! ||
        index == 3 && flutterwave! ||
        index == 4 && stripe! ||
        index == 5 && paytm! ||
        index == 6 && midtrans!) {
      return InkWell(
        onTap: () {
          if (mounted) {
            dialogState!(() {
              selectedMethod = index;
              payMethod = paymentMethodList[selectedMethod!];
              for (var element in payModel) {
                element.isSelected = false;
              }
              payModel[index].isSelected = true;
            });
          }
        },
        child: RadioItem(payModel[index], height: height, width: width),
      );
    } else {
      return Container();
    }
  }

  Future<void> paypalPayment(String amt) async {
    String orderId =
        "wallet-refill-user-${context.read<AuthCubit>().getId()}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";

    try {
      var body = {userIdKey: context.read<AuthCubit>().getId(), orderIdKey: orderId, amountKey: amt};
      final result = await Api.post(body: body, url: Api.getPaypalLinkUrl, token: true, errorCode: true);

      bool error = result[errorKey];
      String? msg = result[messageKey];
      if (!error) {
        String? data = result[dataKey];

        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (BuildContext context) => PaypalWebView(
                      url: data,
                      from: "wallet",
                      amt: amountController!.text.toString(),
                      msg: messageController!.text,
                      addNote: "",
                    ))).then((value) {
          if (value != null) {
            setState(() {
              walletAmount = context.read<SystemConfigCubit>().setWallet(value['walletBalance']);
            });
          }
          context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
          if (context.read<TransactionCubit>().getTransactionList().isEmpty) {
            context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
          } else {}
        });
      } else {
        UiUtils.setSnackBar(msg!, context, false, type: "2");
      }
    } on TimeoutException catch (_) {
      UiUtils.setSnackBar(StringsRes.somethingMsg, context, false, type: "2");
    }
  }

  Future<void> flutterWavePayment(String price) async {
    try {
      if (mounted) {
        setState(() {
          isProgress = true;
        });
      }

      var body = {
        amountKey: price,
        userIdKey: context.read<AuthCubit>().getId(),
      };
        final result = await Api.post(body: body, url: Api.flutterwaveWebviewUrl, token: true, errorCode: true);

        bool error = result[errorKey];
        String? msg = result[messageKey];
        if (!error) {
          var data = result["link"];
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (BuildContext context) => PaypalWebView(
                        url: data,
                        from: "wallet",
                        amt: amountController!.text.toString(),
                        msg: messageController!.text,
                        addNote: "",
                      ))).then((value) {
            if (value != null) {
              setState(() {
                walletAmount = context.read<SystemConfigCubit>().setWallet(value['walletBalance']);
              });
            }
            context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
          });
        } else {
          UiUtils.setSnackBar(msg!, context, false, type: "2");
        }
        setState(() {
          isProgress = false;
        });
    } on TimeoutException catch (_) {
      setState(() {
        isProgress = false;
      });

      UiUtils.setSnackBar(StringsRes.somethingMsg, context, false, type: "2");
    }
  }

  razorpayPayment(double price) async {
    String? contact = context.read<AuthCubit>().getMobile();
    String? email = context.read<AuthCubit>().getEmail();
    String? name = context.read<AuthCubit>().getName();
    double amt = price * 100;

    if (mounted) {
      setState(() {
        isProgress = true;
      });
    }

    var options = {
      key: razorpayId,
      amountKey: amt,
      nameKey: name,
      'prefill': {contactKey: contact, emailKey: email},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void paytmPayment(double price) async {
    String? paymentResponse;
    setState(() {
      isProgress = true;
    });
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl = '${payTesting ? 'https://securegw-stage.paytm.in' : 'https://securegw.paytm.in'}/theia/paytmCallback?ORDER_ID=$orderId';

    var parameter = {amountKey: price.toString(), userIdKey: context.read<AuthCubit>().getId(), orderIdKey: orderId};

    try {
      final response = await post(
        Uri.parse(Api.generatePaytmTxnTokenUrl),
        body: parameter,
        headers: Api.getHeaders(),
      );
      var getdata = json.decode(response.body);
      String? txnToken;
      setState(() {
        txnToken = getdata["txn_token"];
      });

      var paytmResponse = Paytm.payWithPaytm(
          callBackUrl: callBackUrl, mId: paytmMerId!, orderId: orderId, txnToken: txnToken!, txnAmount: price.toString(), staging: payTesting);

      paytmResponse.then((value) {
        setState(() {
          isProgress = false;

          if (value[errorKey]) {
            paymentResponse = value['errorMessage'];
          } else {
            if (value['response'] != null) {
              paymentResponse = value['response']['STATUS'];
              if (paymentResponse == "TXN_SUCCESS") {
                sendRequest(orderId, "Paytm");
              }
            }
          }

          UiUtils.setSnackBar(paymentResponse!, context, false, type: "1");
        });
      });
    } catch (e) {
      print(e);
      UiUtils.setSnackBar(e.toString(), context, false, type: "2");
    }
  }

  stripePayment(int price) async {
    if (mounted) {
      setState(() {
        isProgress = true;
      });
    }

    var response =
        await StripeService.payWithPaymentSheet(amount: (price * 100).toString(), currency: stripeCurCode, from: "wallet", context: context);

    if (mounted) {
      setState(() {
        isProgress = false;
      });
    }

    if (!mounted) return;
    if (response.status == 'succeeded') {
      sendRequest(stripePayId!, "Stripe");
      UiUtils.setSnackBar(response.message!, context, false, type: "1");
    } else {
      UiUtils.setSnackBar(response.message!, context, false, type: "2");
    }
  }

  payStackPayment(BuildContext context, int price) async {
    if (mounted) {
      setState(() {
        isProgress = true;
      });
    }
    await payStackPlugin.initialize(publicKey: payStackId!);
    if (!mounted) return;
    String? email = context.read<AuthCubit>().getEmail();

    Charge charge = Charge()
      ..amount = int.parse("${(price * 100)}").toInt()
      ..reference = _getReference()
      ..email = email;

    try {
      if (!mounted) return;
      CheckoutResponse response = await payStackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );

      if (response.status) {
        sendRequest(response.reference!, "Paystack");
      } else {
        if (!mounted) return;
        UiUtils.setSnackBar(response.message, context, false, type: "2");
        if (mounted) {
          setState(() {
            isProgress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isProgress = false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> midtransPayment({
    required String price,
  }) async {
    try {
      String orderID =
          'wallet-refill-user-${context.read<AuthCubit>().getId()}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';

      try {
        var body = {
          amountKey: price,
          userIdKey: context.read<AuthCubit>().getId(),
          orderIdKey: orderID,
        };
        await Api.post(body: body, url: Api.createMidtransTransactionUrl, token: true, errorCode: true).then(
          (result) {
            var getdata = json.decode(result.body);
            bool error = getdata[errorKey];
            String? msg = getdata[messageKey];
            if (!error) {
              var data = getdata[dataKey];

              String redirectUrl = data['redirect_url'];
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (BuildContext context) => MidTrashWebview(
                    url: redirectUrl,
                    from: 'wallet',
                    orderId: orderID,
                  ),
                ),
              ).then(
                (value) async {
                  if (mounted) {
                    setState(() {
                      context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
                      context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
                    });
                  }
                },
              );
            } else {
              UiUtils.setSnackBar(msg.toString(), context, false, type: "2");
            }
          },
          onError: (error) {
            UiUtils.setSnackBar(error.toString(), context, false, type: "2");
          },
        );
      } on TimeoutException catch (_) {
        UiUtils.setSnackBar(StringsRes.somethingMsg, context, false, type: "2");
      }
      return {errorKey: false, messageKey: 'Transaction Successful', 'status': true};
    } catch (e) {
      return {errorKey: true, messageKey: e.toString(), 'status': false};
    }
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Widget walletWithdraw() {
    return BlocConsumer<GetWithdrawRequestCubit, GetWithdrawRequestState>(
        bloc: context.read<GetWithdrawRequestCubit>(),
        listener: (context, state) {
        },
        builder: (context, state) {
          if (state is GetWithdrawRequestProgress || state is GetWithdrawRequestInitial) {
            return MyOrderSimmer(length: 5, width: width, height: height);
          }
          if (state is GetWithdrawRequestFailure) {
            return SizedBox(height: height! / 1.5, child: onData());
          }
          final withdrawRequestList = (state as GetWithdrawRequestSuccess).withdrawRequestList;
          final hasMore = state.hasMore;
          return withdrawRequestList.isEmpty
              ? onData()
              : ListView.builder(
                  controller: withdrawWalletController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: withdrawRequestList.length,
                  itemBuilder: (BuildContext context, index) {
                    return hasMore && index == (withdrawRequestList.length - 1)
                        ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                        : Container(
                            padding:
                                EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 80.0, end: width! / 20.0, bottom: height! / 80.0),
                            width: width!,
                            margin: EdgeInsetsDirectional.only(top: index == 0 ? 0.0 : height! / 52.0),
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: width! / 60.0),
                              child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(UiUtils.getTranslatedLabel(context, idLabel).toUpperCase(),
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700, fontSize: 14.0)),
                                        Text(" #${withdrawRequestList[index].id!}",
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700, fontSize: 14.0)),
                                      ],
                                    ),
                                    const Spacer(),
                                    withdrawRequestList[index].status == ""
                                        ? const SizedBox()
                                        : Align(
                                            alignment: Alignment.topRight,
                                            child: Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsetsDirectional.only(top: 5.0, bottom: 5.0, start: 5.0, end: 5.0),
                                              margin: const EdgeInsetsDirectional.only(start: 4.5),
                                              decoration: DesignConfig.boxDecorationContainerBorder(
                                                  DesignConfig.walletWithdrawStatusCartColor(withdrawRequestList[index].status!),
                                                  DesignConfig.walletWithdrawStatusCartColor(withdrawRequestList[index].status!).withOpacity(0.10),
                                                  4.0),
                                              child: Text(
                                                DesignConfig.walletWithdrawStatusCartTitle(withdrawRequestList[index].status!),
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.normal,
                                                    color: DesignConfig.walletWithdrawStatusCartColor(withdrawRequestList[index].status!)),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                                  child: DesignConfig.divider(),
                                ),
                                Text("${UiUtils.getTranslatedLabel(context, dateLabel)} :",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 14.0)),
                                Text(formatter.format(DateTime.parse(withdrawRequestList[index].dateCreated!)),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.0)),
                                SizedBox(height: height! / 60.0),
                                Text("${UiUtils.getTranslatedLabel(context, typeLabel)} : ",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 14.0)),
                                Text(
                                  withdrawRequestList[index].paymentType!,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontWeight: FontWeight.w600, fontSize: 14.0),
                                  maxLines: 2,
                                ),
                                SizedBox(height: height! / 60.0),
                                withdrawRequestList[index].paymentAddress!.isEmpty
                                    ? const SizedBox()
                                    : Text("${UiUtils.getTranslatedLabel(context, messageLabel)} :",
                                        textAlign: TextAlign.start,
                                        style:
                                            TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 14.0)),
                                withdrawRequestList[index].paymentAddress!.isEmpty
                                    ? const SizedBox()
                                    : SizedBox(
                                        width: width! / 1.1,
                                        child: Text(withdrawRequestList[index].paymentAddress!,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.0),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis)),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                                  child: DesignConfig.divider(),
                                ),
                                Row(children: [
                                  SvgPicture.asset(DesignConfig.setSvgPath("amout_icon"),
                                      fit: BoxFit.scaleDown,
                                      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                      width: 7.0,
                                      height: 12.3),
                                  SizedBox(width: width! / 80.0),
                                  Text("${UiUtils.getTranslatedLabel(context, amountLabel)}",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 14.0)),
                                  const Spacer(),
                                  Text(
                                      "${context.read<SystemConfigCubit>().getCurrency()}${double.parse(withdrawRequestList[index].amountRequested!).toStringAsFixed(2)}",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 14.0)),
                                ]),
                              ]),
                            ),
                          );
                  });
        });
  }

  Widget onData() {
    return NoDataContainer(
        image: "wallet",
        title: UiUtils.getTranslatedLabel(context, noWalletFoundLabel),
        subTitle: UiUtils.getTranslatedLabel(context, noWalletFoundSubTitleLabel),
        width: width!,
        height: height!);
  }

  Widget wallet() {
    return BlocConsumer<TransactionCubit, TransactionState>(
        bloc: context.read<TransactionCubit>(),
        listener: (context, state) {
        },
        builder: (context, state) {
          if (state is TransactionProgress || state is TransactionInitial) {
            return MyOrderSimmer(length: 5, width: width, height: height);
          }
          if (state is TransactionFailure) {
            return SizedBox(height: height! / 1.5, child: onData());
          }
          final transactionList = (state as TransactionSuccess).transactionList;
          final hasMore = state.hasMore;
          return transactionList.isEmpty
              ? onData()
              : ListView.builder(
                  shrinkWrap: true,
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: transactionList.length,
                  itemBuilder: (BuildContext context, index) {
                    return hasMore && index == (transactionList.length - 1)
                        ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                        : TransactionContainer(transactionModel: transactionList[index], height: height, width: width, index: index);
                  });
        });
  }

  addMoneyBottomSheet() {
    bool payWarn = false;
    showModalBottomSheet(
        isDismissible: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setStater) {
            dialogState = setStater;
            return Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                margin: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Form(
                      key: _formkey,
                      child: Flexible(
                        child: ListView(children: <Widget>[
                          Container(
                              margin: EdgeInsetsDirectional.only(top: height! / 60.0),
                              child: TextFormField(
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) => validateField(val!, UiUtils.getTranslatedLabel(context, requirdFieldLabel)),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                textInputAction: TextInputAction.done,
                                decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, amountLabel),
                                    UiUtils.getTranslatedLabel(context, enterAmountLabel), width!, context),
                                cursorColor: lightFont,
                                controller: amountController,
                              )),
                          Container(
                              margin: EdgeInsetsDirectional.only(top: height! / 60.0),
                              child: TextFormField(
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                  fontSize: 16.0,
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, messageLabel),
                                    UiUtils.getTranslatedLabel(context, enterMessageLabel), width!, context),
                                cursorColor: lightFont,
                                controller: messageController,
                              )),
                          Padding(
                            padding: EdgeInsetsDirectional.only(top: height! / 40.0, bottom: height! / 80.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 2),
                                    height: height! / 40.0,
                                    width: width! / 80.0),
                                SizedBox(width: width! / 80.0),
                                Expanded(
                                  child: Text(
                                    UiUtils.getTranslatedLabel(context, paymentLabel),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 16.0),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DesignConfig.divider(),
                          payWarn
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Text(UiUtils.getTranslatedLabel(context, payWarningLabel),
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 14.0)),
                                )
                              : Container(),
                          SizedBox(height: height! / 80.0),
                          paypal == null
                              ? Center(
                                  child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ))
                              : Column(mainAxisAlignment: MainAxisAlignment.start, children: getPayList()),
                        ]),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: SmallButtonContainer(
                            color: Theme.of(context).colorScheme.onBackground,
                            height: height,
                            width: width,
                            text: UiUtils.getTranslatedLabel(context, cancelLabel),
                            start: 0,
                            end: width! / 40.0,
                            bottom: height! / 60.0,
                            top: height! / 99.0,
                            radius: 5.0,
                            status: false,
                            borderColor: Theme.of(context).colorScheme.onPrimary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Expanded(
                          child: SmallButtonContainer(
                            color: Theme.of(context).colorScheme.primary,
                            height: height,
                            width: width,
                            text: UiUtils.getTranslatedLabel(context, addMoneyLabel),
                            start: 0,
                            end: 0,
                            bottom: height! / 60.0,
                            top: height! / 99.0,
                            radius: 5.0,
                            status: false,
                            borderColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            onTap: () {
                              final form = _formkey.currentState!;
                              if (form.validate() && amountController!.text != '0') {
                                form.save();
                                if (payMethod == null) {
                                  dialogState!(() {
                                    payWarn = true;
                                  });
                                } else {
                                  if (payMethod!.trim() == UiUtils.getTranslatedLabel(context, stripeLblLabel)) {
                                    stripePayment(int.parse(amountController!.text));
                                  } else if (payMethod!.trim() == UiUtils.getTranslatedLabel(context, razorpayLblLabel)) {
                                    razorpayPayment(double.parse(amountController!.text));
                                  } else if (payMethod!.trim() == UiUtils.getTranslatedLabel(context, payStackLblLabel)) {
                                    payStackPayment(context, int.parse(amountController!.text));
                                  } else if (payMethod == UiUtils.getTranslatedLabel(context, paytmLblLabel)) {
                                    paytmPayment(double.parse(amountController!.text));
                                  } else if (payMethod == UiUtils.getTranslatedLabel(context, payPalLblLabel)) {
                                    paypalPayment((amountController!.text).toString());
                                  } else if (payMethod == UiUtils.getTranslatedLabel(context, flutterWaveLblLabel)) {
                                    flutterWavePayment(amountController!.text);
                                  } else if (payMethod == UiUtils.getTranslatedLabel(context, midtransLable)) {
                                    midtransPayment(price: amountController!.text);
                                  }
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ));
          });
        });
  }

  withDrawMoneyBottomSheet(GetWithdrawRequestCubit getWithdrawRequestCubit) {
    showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
            dialogState = setStater;
            return Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Form(
                        key: _formkey,
                        child: Flexible(
                          child: SingleChildScrollView(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
                            Container(
                                margin: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 60.0, end: width! / 20.0),
                                child: TextFormField(
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 16.0, fontWeight: FontWeight.w500),
                                  keyboardType: TextInputType.number,
                                  validator: (val) => validateField(val!, UiUtils.getTranslatedLabel(context, requirdFieldLabel)),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  textInputAction: TextInputAction.done,
                                  decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, amountLabel),
                                      UiUtils.getTranslatedLabel(context, enterWithdrawAmountLabel), width!, context),
                                  cursorColor: lightFont,
                                  controller: withdrawAmountController,
                                )),
                            Container(
                                margin: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 60.0, end: width! / 20.0),
                                child: TextFormField(
                                  maxLines: 7,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 16.0, fontWeight: FontWeight.w500),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, bankDetailLabel),
                                      UiUtils.getTranslatedLabel(context, enterBankDetailLabel), width!, context),
                                  cursorColor: lightFont,
                                  controller: paymentAddressController,
                                )),
                          ])),
                        ),
                      ),
                      SizedBox(
                        height: height! / 40.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SmallButtonContainer(
                              color: Theme.of(context).colorScheme.onBackground,
                              height: height,
                              width: width,
                              text: UiUtils.getTranslatedLabel(context, cancelLabel),
                              start: width! / 20.0,
                              end: width! / 40.0,
                              bottom: height! / 60.0,
                              top: height! / 99.0,
                              radius: 5.0,
                              status: false,
                              borderColor: Theme.of(context).colorScheme.onPrimary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Expanded(
                            child: BlocConsumer<SendWithdrawRequestCubit, SendWithdrawRequestState>(
                                bloc: context.read<SendWithdrawRequestCubit>(),
                                listener: (context, state) {
                                  if (state is SendWithdrawRequestFetchSuccess) {
                                    print(state.walletAmount);
                                    walletAmount = state.walletAmount.toString();
                                    context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
                                    if (context.read<GetWithdrawRequestCubit>().getGetWithdrawRequestList().isEmpty) {
                                      getWithdrawRequestCubit.fetchGetWithdrawRequest(perPage, context.read<AuthCubit>().getId());
                                    } else {
                                      getWithdrawRequestCubit.addWithdrawRequest(state.withdrawModel!);
                                    }
                                    Navigator.of(context, rootNavigator: true).pop(true);
                                  }
                                },
                                builder: (context, state) {
                                  print(state.toString());
                                  if (state is SendWithdrawRequestFetchFailure) {
                                    print(state.errorCode);
                                    return SmallButtonContainer(
                                      color: Theme.of(context).colorScheme.primary,
                                      height: height,
                                      width: width,
                                      text: UiUtils.getTranslatedLabel(context, sendLabel),
                                      start: 0,
                                      end: 0,
                                      bottom: height! / 60.0,
                                      top: height! / 99.0,
                                      radius: 5.0,
                                      status: false,
                                      borderColor: Theme.of(context).colorScheme.primary,
                                      textColor: Theme.of(context).colorScheme.onPrimary,
                                      onTap: () {
                                        final form = _formkey.currentState!;
                                        if (form.validate() && withdrawAmountController!.text != '0') {
                                          form.save();
                                          context.read<SendWithdrawRequestCubit>().sendWithdrawRequest(
                                              context.read<AuthCubit>().getId(), withdrawAmountController!.text, paymentAddressController!.text);
                                        }
                                      },
                                    );
                                  } else {
                                    return SmallButtonContainer(
                                      color: Theme.of(context).colorScheme.primary,
                                      height: height,
                                      width: width,
                                      text: UiUtils.getTranslatedLabel(context, sendLabel),
                                      start: 0,
                                      end: width! / 20.0,
                                      bottom: height! / 60.0,
                                      top: height! / 99.0,
                                      radius: 5.0,
                                      status: false,
                                      borderColor: Theme.of(context).colorScheme.primary,
                                      textColor: Theme.of(context).colorScheme.onPrimary,
                                      onTap: () {
                                        final form = _formkey.currentState!;
                                        if (form.validate() && withdrawAmountController!.text != '0') {
                                          form.save();

                                          context.read<SendWithdrawRequestCubit>().sendWithdrawRequest(
                                              context.read<AuthCubit>().getId(), withdrawAmountController!.text, paymentAddressController!.text);
                                        }
                                      },
                                    );
                                  }
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ));
          });
        });
  }

  Future<void> refreshList() async {
    context.read<TransactionCubit>().fetchTransaction(perPage, context.read<AuthCubit>().getId(), walletKey);
    context.read<GetWithdrawRequestCubit>().fetchGetWithdrawRequest(perPage, context.read<AuthCubit>().getId());
    context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.background,
                appBar: DesignConfig.appBar(context, width!, UiUtils.getTranslatedLabel(context, walletLabel),
                    PreferredSize(preferredSize: Size(width!, height! / 12.0), child: SizedBox())),
                body: BlocListener<SystemConfigCubit, SystemConfigState>(
                  bloc: context.read<SystemConfigCubit>(),
                  listener: (context, state) {
                    if (state is SystemConfigFetchSuccess) {
                      walletAmount = state.systemConfigModel.data!.userData![0].balance;
                    }
                    if (state is SystemConfigFetchFailure) {
                      print(state.errorCode);
                    }
                  },
                  child: Container(
                    margin: EdgeInsetsDirectional.only(top: height! / 90.0),
                    width: width,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsetsDirectional.only(start: width! / 30.0, end: width! / 30.0, top: height! / 80.0),
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 4.0),
                            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Stack(
                                children: [
                                  Container(
                                      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 10.0),
                                      margin: EdgeInsetsDirectional.only(start: width! / 30.0, end: width! / 30.0),
                                      padding: EdgeInsetsDirectional.only(
                                          top: height! / 40.0, bottom: height! / 40.0, start: width! / 20.0, end: width! / 20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            " ${UiUtils.getTranslatedLabel(context, currentBalanceLabel)}",
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal, fontSize: 14.0),
                                          ),
                                          const SizedBox(height: 5.0),
                                          BlocBuilder<SystemConfigCubit, SystemConfigState>(
                                              bloc: context.read<SystemConfigCubit>(),
                                              builder: (context, state) {
                                                if (state is SystemConfigFetchSuccess) {
                                                  return Text(
                                                    "${context.read<SystemConfigCubit>().getCurrency()}${double.parse(state.systemConfigModel.data!.userData![0].balance!).toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.normal,
                                                        fontSize: 20.0),
                                                  );
                                                } else {
                                                  return Text(
                                                    "${context.read<SystemConfigCubit>().getCurrency()}${double.parse(walletAmount!).toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.normal,
                                                        fontSize: 20.0),
                                                  );
                                                }
                                              }),
                                          SizedBox(height: height! / 40.0),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SmallButtonContainer(
                                                  color: Theme.of(context).colorScheme.onBackground,
                                                  height: height,
                                                  width: width,
                                                  text: UiUtils.getTranslatedLabel(context, addMoneyLabel),
                                                  start: width! / 99.0,
                                                  end: width! / 40.0,
                                                  bottom: 0,
                                                  top: 0,
                                                  status: false,
                                                  radius: 5.0,
                                                  borderColor: Theme.of(context).colorScheme.onBackground,
                                                  textColor: Theme.of(context).colorScheme.onSecondary,
                                                  onTap: () {
                                                    addMoneyBottomSheet();
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                child: SmallButtonContainer(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  height: height,
                                                  width: width,
                                                  text: UiUtils.getTranslatedLabel(context, withdrawMoneyLabel),
                                                  start: width! / 40.0,
                                                  end: width! / 99.0,
                                                  bottom: 0,
                                                  top: 0,
                                                  status: false,
                                                  radius: 5.0,
                                                  borderColor: Theme.of(context).colorScheme.onBackground,
                                                  textColor: white,
                                                  onTap: () {
                                                    withDrawMoneyBottomSheet(context.read<GetWithdrawRequestCubit>());
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      )),
                                  Positioned.directional(
                                    end: width! / 30.0,
                                    textDirection: Directionality.of(context),
                                    child: Container(
                                      alignment: Alignment.bottomLeft,
                                      width: width! / 5.4,
                                      height: height! / 12.0,
                                      decoration: Directionality.of(context) == ui.TextDirection.rtl
                                          ? DesignConfig.boxDecorationContainerRoundHalf(
                                              Theme.of(context).colorScheme.onBackground.withOpacity(0.10), 0, 0, 10, 62)
                                          : DesignConfig.boxDecorationContainerRoundHalf(
                                              Theme.of(context).colorScheme.onBackground.withOpacity(0.10), 0, 62, 10, 0),
                                    ),
                                  ),
                                  Positioned.directional(
                                    start: width! / 30.0,
                                    textDirection: Directionality.of(context),
                                    bottom: 0.0,
                                    child: Container(
                                      width: width! / 5.4,
                                      height: height! / 12.0,
                                      decoration: Directionality.of(context) == ui.TextDirection.rtl
                                          ? DesignConfig.boxDecorationContainerRoundHalf(
                                              Theme.of(context).colorScheme.onBackground.withOpacity(0.10), 62, 10, 0, 0)
                                          : DesignConfig.boxDecorationContainerRoundHalf(
                                              Theme.of(context).colorScheme.onBackground.withOpacity(0.10), 0, 0, 62, 0),
                                    ),
                                  ),
                                ],
                              ),
                              PreferredSize(
                                  preferredSize: Size.fromHeight(height! / 8.0),
                                  child: TabBar(
                                    labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary),
                                    controller: tabController,
                                    padding: EdgeInsetsDirectional.only(top: height! / 80.0),
                                    unselectedLabelStyle:
                                        TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.secondary),
                                    tabs: [
                                      Tab(text: UiUtils.getTranslatedLabel(context, walletTransactionLabel)),
                                      Tab(text: UiUtils.getTranslatedLabel(context, walletWithdrawLabel)),
                                    ],
                                    unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
                                    labelColor: Theme.of(context).colorScheme.secondary,
                                  )),
                            ]),
                          ),
                          Container(
                              height: height! / 1.62,
                              margin: EdgeInsetsDirectional.only(top: height! / 60.0),
                              child: TabBarView(
                                controller: tabController,
                                children: [
                                  RefreshIndicator(onRefresh: refreshList, color: Theme.of(context).colorScheme.primary, child: wallet()),
                                  RefreshIndicator(onRefresh: refreshList, color: Theme.of(context).colorScheme.primary, child: walletWithdraw())
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

String? validateField(String value, String? msg) {
  if (value.isEmpty) {
    return msg;
  } else {
    return null;
  }
}
