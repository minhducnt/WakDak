import 'dart:async';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/manageCartCubit.dart';
import 'package:wakDak/cubit/order/historyOrderCubit.dart';
import 'package:wakDak/cubit/order/orderCubit.dart';
import 'package:wakDak/cubit/order/orderDetailCubit.dart';
import 'package:wakDak/cubit/order/reOrderCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/addOnsDataModel.dart';
import 'package:wakDak/data/model/orderModel.dart';
import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/data/repositories/order/orderRepository.dart';
import 'package:wakDak/ui/screen/cart/cart_screen.dart';
import 'package:wakDak/ui/screen/home/home_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/dashLine.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/ui/widgets/noDataContainer.dart';
import 'package:wakDak/ui/widgets/simmer/myOrderSimmer.dart';
import 'package:wakDak/ui/widgets/smallButtonContainer.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class MyOrderScreen extends StatefulWidget {
  const MyOrderScreen({Key? key}) : super(key: key);

  @override
  MyOrderScreenState createState() => MyOrderScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (_) => BlocProvider<OrderCubit>(
              create: (_) => OrderCubit(),
              child: const MyOrderScreen(),
            ));
  }
}

class MyOrderScreenState extends State<MyOrderScreen> with TickerProviderStateMixin {
  double? width, height;
  ScrollController orderController = ScrollController();
  ScrollController orderHistoryController = ScrollController();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  RegExp regex = RegExp(r'([^\d]00)(?=[^\d]|$)');
  bool enableList = false;
  int? _selectedIndex = 0;
  String? reason = reasonList[0];
  var inputFormat = DateFormat('yyyy-MM-dd hh:mm:ss');
  TabController? tabController;
  var outputFormat = DateFormat('dd,MMMM yyyy hh:mm a');
  StateSetter? dialogState;

  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    tabController = TabController(length: 2, vsync: this);
    orderController.addListener(orderScrollListener);
    orderHistoryController.addListener(orderHistoryScrollListener);
    Future.delayed(Duration.zero, () {
      context.read<OrderCubit>().fetchOrder(perPage, context.read<AuthCubit>().getId(), "",
          "$preparingKey,$waitingKey,$pendingKey,$readyForPickupKey,$outForDeliveryKey,$confirmedKey");
      context.read<HistoryOrderCubit>().fetchHistoryOrder(perPage, context.read<AuthCubit>().getId(), "", "$deliveredKey,$cancelledKey", "");
    });
    setStreamConfig();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  setStreamConfig() {
    streamController = StreamController<String>.broadcast();
    streamController!.stream.listen((data) {
      print("streamNotification recive::::::$data");
      if (data == "1") {
        context.read<OrderCubit>().fetchOrder(perPage, context.read<AuthCubit>().getId(), "",
            "$preparingKey,$waitingKey,$pendingKey,$readyForPickupKey,$outForDeliveryKey,$confirmedKey");
        context.read<HistoryOrderCubit>().fetchHistoryOrder(perPage, context.read<AuthCubit>().getId(), "", "$deliveredKey,$cancelledKey", "");
      }
    });
  }

  orderScrollListener() {
    if (orderController.position.maxScrollExtent == orderController.offset) {
      if (context.read<OrderCubit>().hasMoreData()) {
        context.read<OrderCubit>().fetchMoreOrderData(perPage, context.read<AuthCubit>().getId(), "",
            "$preparingKey,$waitingKey,$pendingKey,$readyForPickupKey,$outForDeliveryKey,$confirmedKey");
      }
    }
  }

  orderHistoryScrollListener() {
    if (orderHistoryController.position.maxScrollExtent == orderHistoryController.offset) {
      if (context.read<HistoryOrderCubit>().hasMoreData()) {
        context
            .read<HistoryOrderCubit>()
            .fetchMoreHistoryOrderData(perPage, context.read<AuthCubit>().getId(), "", "$deliveredKey,$cancelledKey", "");
      }
    }
  }

  onChanged(int position, StateSetter setStates) {
    setStates(() {
      _selectedIndex = position;
      enableList = !enableList;
    });
  }

  Widget selectType(StateSetter setStates) {
    return Container(
      decoration: DesignConfig.boxDecorationContainerCardShadow(Theme.of(context).colorScheme.onBackground, shadow, 10.0, 0.0, 0.0, 10.0, 0.0),
      margin: EdgeInsetsDirectional.only(top: height! / 99.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setStates(() {
                enableList = !enableList;
              });
            },
            child: Container(
              decoration: DesignConfig.boxDecorationContainer(textFieldBackground, 10.0),
              padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 99.0, top: height! / 99.0, bottom: height! / 99.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                      child: Text(
                    _selectedIndex != null ? reasonList[_selectedIndex!] : UiUtils.getTranslatedLabel(context, selectReasonLabel),
                    style: TextStyle(fontSize: 12.0, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                  )),
                  Icon(enableList ? Icons.expand_less : Icons.expand_more, size: 24.0, color: Theme.of(context).colorScheme.onSecondary),
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
                  itemCount: reasonList.length,
                  itemBuilder: (context, position) {
                    return InkWell(
                      onTap: () {
                        onChanged(position, setStates);
                        reason = reasonList[position];
                      },
                      child: Container(
                          padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, top: height! / 99.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reasonList[position],
                                style: TextStyle(fontSize: 12.0, color: Theme.of(context).colorScheme.onSecondary),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(top: height! / 99.0),
                                child: Divider(
                                  color: lightFont.withOpacity(0.10),
                                  height: 1.0,
                                ),
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

  cancel(BuildContext context, String? status, String? orderId) {
    int? _selectedIndex = 0;
    showModalBottomSheet(
        isDismissible: true,
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
                padding: EdgeInsetsDirectional.only(bottom: MediaQuery.of(context).viewInsets.bottom, start: width! / 20.0, end: width! / 20.0),
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${UiUtils.getTranslatedLabel(context, orderIdLabel)}: #${orderId}",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.w700)),
                      Padding(
                        padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0),
                        child: DesignConfig.divider(),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(top: width! / 99.0, bottom: width! / 80.0),
                        child: Text(UiUtils.getTranslatedLabel(context, cancelDialogSubTitleLabel),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(reasonList.length, (index) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: Theme.of(context).colorScheme.secondary,
                                  disabledColor: Theme.of(context).colorScheme.secondary),
                              child: RadioListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                activeColor: Theme.of(context).colorScheme.primary,
                                controlAffinity: ListTileControlAffinity.trailing,
                                value: index,
                                groupValue: _selectedIndex,
                                title: Text(reasonList[index],
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal)),
                                onChanged: (int? value) {
                                  dialogState!(() {
                                    _selectedIndex = value;
                                    reason = reasonList[value!];
                                  });
                                },
                              ),
                            );
                          })),
                      (reason == "" || reason!.isEmpty)
                          ? Padding(
                              padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
                              child: Text(UiUtils.getTranslatedLabel(context, pleaseSelectReasonLabel),
                                  textAlign: TextAlign.left,
                                  maxLines: 2,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12, fontWeight: FontWeight.w500)),
                            )
                          : const SizedBox(),
                      BlocConsumer<OrderDetailCubit, OrderDetailState>(
                          bloc: context.read<OrderDetailCubit>(),
                          listener: (context, state) {
                            if (state is OrderDetailSuccess) {
                              Navigator.of(context, rootNavigator: true).pop(true);
                            }
                          },
                          builder: (context, state) {
                            print(state.toString());
                            if (state is OrderDetailFailure) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(state.errorMessage,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12, fontWeight: FontWeight.w500)),
                                  SizedBox(
                                    width: width!,
                                    child: ButtonContainer(
                                      color: Theme.of(context).colorScheme.primary,
                                      height: height,
                                      width: width,
                                      text: UiUtils.getTranslatedLabel(context, cancelOrderLabel),
                                      start: 0,
                                      end: 0,
                                      bottom: height! / 60.0,
                                      top: height! / 99.0,
                                      status: false,
                                      borderColor: Theme.of(context).colorScheme.primary,
                                      textColor: Theme.of(context).colorScheme.onPrimary,
                                      onPressed: () {
                                        if (reason == "" || reason!.isEmpty) {
                                        } else {
                                          context.read<OrderDetailCubit>().getOrderDetail(status: status, orderId: orderId, reason: reason);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return SizedBox(
                                width: width,
                                child: ButtonContainer(
                                  color: Theme.of(context).colorScheme.primary,
                                  height: height,
                                  width: width,
                                  text: UiUtils.getTranslatedLabel(context, cancelOrderLabel),
                                  start: 0,
                                  end: 0,
                                  bottom: height! / 60.0,
                                  top: height! / 99.0,
                                  status: false,
                                  borderColor: Theme.of(context).colorScheme.primary,
                                  textColor: Theme.of(context).colorScheme.onPrimary,
                                  onPressed: () {
                                    if (reason == "" || reason!.isEmpty) {
                                    } else {
                                      context.read<OrderDetailCubit>().getOrderDetail(status: status, orderId: orderId, reason: reason);
                                    }
                                  },
                                ),
                              );
                            }
                          })
                    ],
                  ),
                ));
          });
        });
  }

  Widget noOrder() {
    return NoDataContainer(
        image: "empty_order",
        title: UiUtils.getTranslatedLabel(context, noOrderYetLabel),
        subTitle: UiUtils.getTranslatedLabel(context, noOrderYetSubTitleLabel),
        width: width!,
        height: height!);
  }

  Widget myOrder() {
    return BlocConsumer<OrderCubit, OrderState>(
        bloc: context.read<OrderCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is OrderProgress || state is OrderInitial) {
            return MyOrderSimmer(length: 5, width: width!, height: height!);
          }
          if (state is OrderFailure) {
            return (state.errorMessage.toString() == "No Order(s) Found !" || state.errorStatusCode.toString() == tokenExpireCode)
                ? noOrder()
                : Center(
                    child: Text(
                    state.errorMessage.toString(),
                    textAlign: TextAlign.center,
                  ));
          }
          final orderList = (state as OrderSuccess).orderList;
          final hasMore = state.hasMore;
          return orderList.isEmpty
              ? noOrder()
              : SizedBox(
                  height: height! / 1.1,
                  child: ListView.builder(
                      shrinkWrap: true,
                      controller: orderController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: orderList.length,
                      itemBuilder: (BuildContext context, index) {
                        List<bool> cancelStatus = [];
                        int k = 0;
                        for (int j = 0; j < orderList[index].orderItems!.length; j++) {
                          if (orderList[index].orderItems![j].isCancelable == "1") {
                            cancelStatus.add(true);
                          } else {
                            cancelStatus.add(false);
                          }
                        }
                        var status = "";
                        if (orderList[index].activeStatus == deliveredKey) {
                          status = UiUtils.getTranslatedLabel(context, deliveredLabel);
                        } else if (orderList[index].activeStatus == pendingKey) {
                          status = UiUtils.getTranslatedLabel(context, pendingLbLabel);
                        } else if (orderList[index].activeStatus == waitingKey) {
                          status = UiUtils.getTranslatedLabel(context, awaitingLbLabel);
                        } else if (orderList[index].activeStatus == outForDeliveryKey) {
                          status = UiUtils.getTranslatedLabel(context, outForDeliveryLbLabel);
                        } else if (orderList[index].activeStatus == confirmedKey) {
                          status = UiUtils.getTranslatedLabel(context, confirmedLbLabel);
                        } else if (orderList[index].activeStatus == cancelledKey) {
                          status = UiUtils.getTranslatedLabel(context, cancelledsLabel);
                        } else if (orderList[index].activeStatus == preparingKey) {
                          status = UiUtils.getTranslatedLabel(context, preparingLbLabel);
                        } else if (orderList[index].activeStatus == readyForPickupKey) {
                          status = UiUtils.getTranslatedLabel(context, readyForPickupLbLabel);
                        } else {
                          status = "";
                        }
                        var inputDate = inputFormat.parse(orderList[index].dateAdded!); // <-- dd/MM 24H format
                        var outputDate = outputFormat.format(inputDate);
                        return hasMore && index == (orderList.length - 1)
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                            : BlocProvider(
                                create: (context) => ManageCartCubit(CartRepository()),
                                child: Builder(builder: (context) {
                                  return GestureDetector(
                                    onTap: () {
                                      print(orderList[index].activeStatus);
                                      Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
                                        'id': orderList[index].id!,
                                        'riderId': orderList[index].riderId!,
                                        'riderName': orderList[index].riderName!,
                                        'riderRating': orderList[index].riderRating!,
                                        'riderImage': orderList[index].riderImage!,
                                        'riderMobile': orderList[index].riderMobile!,
                                        'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                        'isSelfPickup': orderList[index].isSelfPickUp!,
                                        'from': orderList[index].activeStatus == "delivered" ? 'orderDeliverd' : 'orderDetail'
                                      });
                                    },
                                    child: Container(
                                        padding: EdgeInsetsDirectional.only(
                                            start: width! / 20.0, top: height! / 80.0, end: width! / 20.0, bottom: height! / 80.0),
                                        width: width!,
                                        margin: EdgeInsetsDirectional.only(
                                          top: index == 0 ? 0.0 : height! / 70.0,
                                        ),
                                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(start: width! / 60.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "${UiUtils.getTranslatedLabel(context, orderIdLabel)}: #${orderList[index].id!}",
                                                        textAlign: TextAlign.start,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                            color: Theme.of(context).colorScheme.secondary,
                                                            fontSize: 14,
                                                            overflow: TextOverflow.ellipsis,
                                                            fontWeight: FontWeight.w700),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(outputDate.toString(),
                                                          textAlign: TextAlign.start,
                                                          style: TextStyle(
                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                          )),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  orderList[index].activeStatus == readyForPickupKey ||
                                                          orderList[index].activeStatus == outForDeliveryKey
                                                      ? FittedBox(
                                                          fit: BoxFit.fitWidth,
                                                          child: Container(
                                                            width: width! / 5.0,
                                                            alignment: Alignment.center,
                                                            padding: const EdgeInsetsDirectional.only(top: 4.5, bottom: 4.5, start: 4.5, end: 4.5),
                                                            decoration: DesignConfig.boxDecorationContainerBorder(
                                                                DesignConfig.orderStatusCartColor(orderList[index].activeStatus!),
                                                                DesignConfig.orderStatusCartColor(orderList[index].activeStatus!).withOpacity(0.10),
                                                                4.0),
                                                            child: Text(
                                                              status,
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: DesignConfig.orderStatusCartColor(orderList[index].activeStatus!),
                                                                  overflow: TextOverflow.ellipsis),
                                                              maxLines: 2,
                                                            ),
                                                          ),
                                                        )
                                                      : FittedBox(
                                                          fit: BoxFit.fitWidth,
                                                          child: Container(
                                                            alignment: Alignment.topLeft,
                                                            padding: const EdgeInsetsDirectional.only(top: 4.5, bottom: 4.5, start: 4.5, end: 4.5),
                                                            decoration: DesignConfig.boxDecorationContainerBorder(
                                                                DesignConfig.orderStatusCartColor(orderList[index].activeStatus!),
                                                                DesignConfig.orderStatusCartColor(orderList[index].activeStatus!).withOpacity(0.10),
                                                                4.0),
                                                            child: Text(
                                                              status,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: DesignConfig.orderStatusCartColor(orderList[index].activeStatus!),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(
                                                  top: height! / 80.0, bottom: height! / 80.0, start: width! / 40.0, end: width! / 99.0),
                                              child: const DashLineView(
                                                fillRate: 0.5,
                                                direction: Axis.horizontal,
                                              ),
                                            ),
                                            Column(
                                                children: List.generate(
                                                    orderList[index].orderItems!.length > 2 ? 2 : orderList[index].orderItems!.length, (i) {
                                              k = i;
                                              OrderItems data = orderList[index].orderItems![i];
                                              return Container(
                                                padding: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                                                width: width!,
                                                margin: EdgeInsetsDirectional.only(top: height! / 99.0, start: width! / 40.0, end: width! / 60.0),
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          data.indicator == "1"
                                                              ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 15, height: 15)
                                                              : data.indicator == "2"
                                                                  ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"), width: 15, height: 15)
                                                                  : const SizedBox(height: 15, width: 15.0),
                                                          const SizedBox(width: 5.0),
                                                          Text(
                                                            "${data.quantity!} x ",
                                                            textAlign:
                                                                Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                                            style: TextStyle(
                                                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                overflow: TextOverflow.ellipsis),
                                                            maxLines: 1,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              data.name!,
                                                              textAlign: Directionality.of(context) == ui.TextDirection.rtl
                                                                  ? TextAlign.right
                                                                  : TextAlign.start,
                                                              style: TextStyle(
                                                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                  overflow: TextOverflow.ellipsis),
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                          i == 0
                                                              ? InkWell(
                                                                  onTap: () {
                                                                    Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
                                                                      'id': orderList[index].id!,
                                                                      'riderId': orderList[index].riderId!,
                                                                      'riderName': orderList[index].riderName!,
                                                                      'riderRating': orderList[index].riderRating!,
                                                                      'riderImage': orderList[index].riderImage!,
                                                                      'riderMobile': orderList[index].riderMobile!,
                                                                      'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                                                      'isSelfPickup': orderList[index].isSelfPickUp!,
                                                                      'from': orderList[index].activeStatus == "delivered"
                                                                          ? 'orderDeliverd'
                                                                          : 'orderDetail'
                                                                    });
                                                                  },
                                                                  child: Icon(Icons.arrow_circle_right_rounded,
                                                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76)))
                                                              : const SizedBox.shrink()
                                                        ],
                                                      ),
                                                      orderList[index].orderItems![i].attrName != ""
                                                          ? Padding(
                                                              padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text("${orderList[index].orderItems![i].attrName!} : ",
                                                                      textAlign: TextAlign.left,
                                                                      style: const TextStyle(
                                                                          color: lightFont, fontSize: 10, fontWeight: FontWeight.w500)),
                                                                  Text(orderList[index].orderItems![i].variantValues!,
                                                                      textAlign: TextAlign.left,
                                                                      style: const TextStyle(
                                                                        color: lightFont,
                                                                        fontSize: 10,
                                                                      )),
                                                                ],
                                                              ),
                                                            )
                                                          : Container(),
                                                      Padding(
                                                        padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 99.0),
                                                        child: Wrap(
                                                            spacing: 5.0,
                                                            runSpacing: 2.0,
                                                            direction: Axis.horizontal,
                                                            children: List.generate(orderList[index].orderItems![i].addOns!.length, (j) {
                                                              AddOnsDataModel addOnData = orderList[index].orderItems![i].addOns![j];
                                                              return Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text("${addOnData.qty!} x ",
                                                                        textAlign: TextAlign.start,
                                                                        style: TextStyle(
                                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 10,
                                                                            overflow: TextOverflow.ellipsis),
                                                                        maxLines: 2),
                                                                    Text("${addOnData.title!} ",
                                                                        textAlign: TextAlign.start,
                                                                        style: TextStyle(
                                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 10,
                                                                            overflow: TextOverflow.ellipsis),
                                                                        maxLines: 2),
                                                                    Text("${context.read<SystemConfigCubit>().getCurrency()}${addOnData.price!}, ",
                                                                        textAlign: TextAlign.start,
                                                                        style: TextStyle(
                                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 10,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            fontWeight: FontWeight.w600)),
                                                                  ]);
                                                            })),
                                                      ),
                                                    ]),
                                              );
                                            })),
                                            orderList[index].orderItems!.length > 2
                                                ? Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Padding(
                                                      padding: EdgeInsetsDirectional.only(
                                                          start: width! / 13.0, bottom: height! / 80.0, top: height! / 99.0),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                              "${orderList[index].orderItems!.length - 2} ${StringsRes.plusSymbol} ${UiUtils.getTranslatedLabel(context, moreLabel)}",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Theme.of(context).colorScheme.secondary)),
                                                          SizedBox(width: width! / 80.0),
                                                        ],
                                                      ),
                                                    ))
                                                : SizedBox.shrink(),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(
                                                  top: height! / 99.0, bottom: height! / 80.0, start: width! / 40.0, end: width! / 99.0),
                                              child: const DashLineView(
                                                fillRate: 0.5,
                                                direction: Axis.horizontal,
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0),
                                              child: Row(children: [
                                                Text(UiUtils.getTranslatedLabel(context, totalPayLabel),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                                const Spacer(),
                                                Text(context.read<SystemConfigCubit>().getCurrency() + orderList[index].finalTotal!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.secondary,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.96)),
                                              ]),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(
                                                  top: height! / 99.0, bottom: height! / 70.0, start: width! / 40.0, end: width! / 99.0),
                                              child: const DashLineView(
                                                fillRate: 0.5,
                                                direction: Axis.horizontal,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                cancelStatus[k] == true
                                                    ? Expanded(
                                                        child: orderList[index].activeStatus == preparingKey
                                                            ? const SizedBox.shrink()
                                                            : SmallButtonContainer(
                                                                color: Theme.of(context).colorScheme.onBackground,
                                                                height: height,
                                                                width: width,
                                                                text: orderList[index].activeStatus == deliveredKey
                                                                    ? UiUtils.getTranslatedLabel(context, rateLabel)
                                                                    : cancelStatus[k] == true
                                                                        ? UiUtils.getTranslatedLabel(context, cancelLabel)
                                                                        : "",
                                                                start: width! / 40.0,
                                                                end: width! / 99.0,
                                                                bottom: 0,
                                                                top: 0,
                                                                radius: 5.0,
                                                                status: false,
                                                                borderColor: orderList[index].activeStatus == deliveredKey || cancelStatus[k] == true
                                                                    ? Theme.of(context).colorScheme.onPrimary
                                                                    : Theme.of(context).colorScheme.onBackground,
                                                                textColor: Theme.of(context).colorScheme.onPrimary,
                                                                onTap: () {
                                                                  if (mounted) {
                                                                    print(orderList[index].activeStatus);
                                                                    if (orderList[index].activeStatus == deliveredKey) {
                                                                      Navigator.of(context).pushNamed(Routes.productRating,
                                                                          arguments: {'orderId': orderList[index].id!});
                                                                    } else if (cancelStatus[k] == true) {
                                                                      print(cancelStatus[k]);
                                                                      if (orderList[index].activeStatus == cancelledKey) {
                                                                        UiUtils.setSnackBar(StringsRes.orderCantCancel, context, false, type: "2");
                                                                      } else {
                                                                        cancel(context, cancelledKey, orderList[index].id!);
                                                                      }
                                                                    } else {}
                                                                  }
                                                                },
                                                              ),
                                                      )
                                                    : const SizedBox.shrink(),
                                                BlocConsumer<ManageCartCubit, ManageCartState>(
                                                    bloc: context.read<ManageCartCubit>(),
                                                    listener: (context, state) {
                                                      if (state is ManageCartSuccess) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => const CartScreen(),
                                                          ),
                                                        );
                                                      } else if (state is ManageCartFailure) {
                                                        UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                                      }
                                                    },
                                                    builder: (context, state) {
                                                      return orderList[index].isSelfPickUp! == "0"
                                                          ? Expanded(
                                                              child: SmallButtonContainer(
                                                                color: Theme.of(context).colorScheme.secondary,
                                                                height: height,
                                                                width: width,
                                                                text: UiUtils.getTranslatedLabel(context, trackOrderLabel),
                                                                start: width! / 80.0,
                                                                end: 0,
                                                                bottom: 0,
                                                                top: 0,
                                                                radius: 5.0,
                                                                status: false,
                                                                borderColor: Theme.of(context).colorScheme.secondary,
                                                                textColor: white,
                                                                onTap: () {
                                                                  Navigator.of(context).pushNamed(Routes.orderTracking, arguments: {
                                                                    'id': orderList[index].id!,
                                                                    'riderId': orderList[index].riderId!,
                                                                    'riderName': orderList[index].riderName!,
                                                                    'riderRating': orderList[index].riderRating!,
                                                                    'riderImage': orderList[index].riderImage!,
                                                                    'riderMobile': orderList[index].riderMobile!,
                                                                    'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                                                    'latitude': double.parse(orderList[index].latitude!),
                                                                    'longitude': double.parse(orderList[index].longitude!),
                                                                    'latitudeRes': double.parse(orderList[index].branchModel!.latitude!),
                                                                    'longitudeRes': double.parse(orderList[index].branchModel!.longitude!),
                                                                    'orderAddress': orderList[index].address,
                                                                    'partnerAddress': context.read<SettingsCubit>().getSettings().branchAddress,
                                                                    'isTracking': orderList[index].activeStatus == outForDeliveryKey ? true : false
                                                                  });
                                                                },
                                                              ),
                                                            )
                                                          : const SizedBox.shrink();
                                                    })
                                              ],
                                            ),
                                          ],
                                        )),
                                  );
                                }),
                              );
                      }),
                );
        });
  }

  Widget myOrderHistory() {
    return BlocConsumer<HistoryOrderCubit, HistoryOrderState>(
        bloc: context.read<HistoryOrderCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is HistoryOrderProgress || state is HistoryOrderInitial) {
            return MyOrderSimmer(length: 5, width: width!, height: height!);
          }
          if (state is HistoryOrderFailure) {
            return (state.errorMessage.toString() == "No Order(s) Found !" || state.errorStatusCode.toString() == tokenExpireCode)
                ? noOrder()
                : Center(
                    child: Text(
                    state.errorMessage.toString(),
                    textAlign: TextAlign.center,
                  ));
          }
          final orderList = (state as HistoryOrderSuccess).historyOrderList;
          final hasMore = state.hasMore;
          return orderList.isEmpty
              ? noOrder()
              : SizedBox(
                  height: height! / 1.1,
                  child: ListView.builder(
                      shrinkWrap: true,
                      controller: orderHistoryController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: orderList.length,
                      itemBuilder: (BuildContext context, index) {
                        List<bool> cancelStatus = [];

                        for (int j = 0; j < orderList[index].orderItems!.length; j++) {
                          if (orderList[index].orderItems![j].isCancelable == "1") {
                            cancelStatus.add(true);
                          } else {
                            cancelStatus.add(false);
                          }
                        }
                        var status = "";
                        if (orderList[index].activeStatus == deliveredKey) {
                          status = UiUtils.getTranslatedLabel(context, deliveredLabel);
                        } else if (orderList[index].activeStatus == pendingKey) {
                          status = UiUtils.getTranslatedLabel(context, pendingLbLabel);
                        } else if (orderList[index].activeStatus == waitingKey) {
                          status = UiUtils.getTranslatedLabel(context, pendingLbLabel);
                        } else if (orderList[index].activeStatus == receivedKey) {
                          status = UiUtils.getTranslatedLabel(context, pendingLbLabel);
                        } else if (orderList[index].activeStatus == outForDeliveryKey) {
                          status = UiUtils.getTranslatedLabel(context, outForDeliveryLbLabel);
                        } else if (orderList[index].activeStatus == confirmedKey) {
                          status = UiUtils.getTranslatedLabel(context, confirmedLbLabel);
                        } else if (orderList[index].activeStatus == cancelledKey) {
                          status = UiUtils.getTranslatedLabel(context, cancelledsLabel);
                        } else if (orderList[index].activeStatus == preparingKey) {
                          status = UiUtils.getTranslatedLabel(context, preparingLbLabel);
                        } else if (orderList[index].activeStatus == readyForPickupKey) {
                          status = UiUtils.getTranslatedLabel(context, pickupLabel);
                        } else {
                          status = "";
                        }
                        var inputDate = inputFormat.parse(orderList[index].dateAdded!); // <-- dd/MM 24H format
                        var outputDate = outputFormat.format(inputDate);
                        return hasMore && index == (orderList.length - 1)
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                            : BlocProvider(
                                create: (context) => ReOrderCubit(OrderRepository()),
                                child: Builder(builder: (context) {
                                  return GestureDetector(
                                    onTap: () {
                                      print(orderList[index].activeStatus);
                                      Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
                                        'id': orderList[index].id!,
                                        'riderId': orderList[index].riderId!,
                                        'riderName': orderList[index].riderName!,
                                        'riderRating': orderList[index].riderRating!,
                                        'riderImage': orderList[index].riderImage!,
                                        'riderMobile': orderList[index].riderMobile!,
                                        'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                        'isSelfPickup': orderList[index].isSelfPickUp!,
                                        'from': orderList[index].activeStatus == "delivered" ? 'orderDeliverd' : 'orderDetail'
                                      });
                                    },
                                    child: Container(
                                        padding: EdgeInsetsDirectional.only(
                                            start: width! / 20.0, top: height! / 80.0, end: width! / 20.0, bottom: height! / 80.0),
                                        width: width!,
                                        margin: EdgeInsetsDirectional.only(
                                          top: index == 0 ? 0.0 : height! / 70.0,
                                        ),
                                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(start: width! / 60.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "${UiUtils.getTranslatedLabel(context, orderIdLabel)}: #${orderList[index].id!}",
                                                        textAlign: TextAlign.start,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                            color: Theme.of(context).colorScheme.secondary,
                                                            fontSize: 14,
                                                            overflow: TextOverflow.ellipsis,
                                                            fontWeight: FontWeight.w700),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(outputDate.toString(),
                                                          textAlign: TextAlign.start,
                                                          style: TextStyle(
                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                          )),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  FittedBox(
                                                    fit: BoxFit.fitWidth,
                                                    child: Container(
                                                      alignment: Alignment.topLeft,
                                                      padding: const EdgeInsetsDirectional.only(top: 4.5, bottom: 4.5, start: 4.5, end: 4.5),
                                                      decoration: DesignConfig.boxDecorationContainerBorder(
                                                          DesignConfig.orderStatusCartColor(orderList[index].activeStatus!),
                                                          DesignConfig.orderStatusCartColor(orderList[index].activeStatus!).withOpacity(0.10),
                                                          4.0),
                                                      child: Text(
                                                        status,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: DesignConfig.orderStatusCartColor(orderList[index].activeStatus!),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(
                                                  top: height! / 80.0, bottom: height! / 80.0, start: width! / 40.0, end: width! / 99.0),
                                              child: const DashLineView(
                                                fillRate: 0.5,
                                                direction: Axis.horizontal,
                                              ),
                                            ),
                                            Column(
                                                children: List.generate(
                                                    orderList[index].orderItems!.length > 2 ? 2 : orderList[index].orderItems!.length, (i) {
                                              OrderItems data = orderList[index].orderItems![i];
                                              return InkWell(
                                                  onTap: () {},
                                                  child: Container(
                                                    padding: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                                                    width: width!,
                                                    margin: EdgeInsetsDirectional.only(top: height! / 99.0, start: width! / 40.0, end: width! / 60.0),
                                                    child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              data.indicator == "1"
                                                                  ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"), width: 15, height: 15)
                                                                  : data.indicator == "2"
                                                                      ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"),
                                                                          width: 15, height: 15)
                                                                      : const SizedBox(height: 15, width: 15.0),
                                                              const SizedBox(width: 5.0),
                                                              Text(
                                                                "${data.quantity!} x ",
                                                                textAlign: Directionality.of(context) == ui.TextDirection.rtl
                                                                    ? TextAlign.right
                                                                    : TextAlign.left,
                                                                style: TextStyle(
                                                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.bold,
                                                                    overflow: TextOverflow.ellipsis),
                                                                maxLines: 1,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  data.name!,
                                                                  textAlign: Directionality.of(context) == ui.TextDirection.rtl
                                                                      ? TextAlign.right
                                                                      : TextAlign.left,
                                                                  style: TextStyle(
                                                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.bold,
                                                                      overflow: TextOverflow.ellipsis),
                                                                  maxLines: 1,
                                                                ),
                                                              ),
                                                              i == 0
                                                                  ? InkWell(
                                                                      onTap: () {
                                                                        Navigator.of(context).pushNamed(Routes.orderDetail, arguments: {
                                                                          'id': orderList[index].id!,
                                                                          'riderId': orderList[index].riderId!,
                                                                          'riderName': orderList[index].riderName!,
                                                                          'riderRating': orderList[index].riderRating!,
                                                                          'riderImage': orderList[index].riderImage!,
                                                                          'riderMobile': orderList[index].riderMobile!,
                                                                          'riderNoOfRating': orderList[index].riderNoOfRatings!,
                                                                          'isSelfPickup': orderList[index].isSelfPickUp!,
                                                                          'from': orderList[index].activeStatus == "delivered"
                                                                              ? 'orderDeliverd'
                                                                              : 'orderDetail'
                                                                        });
                                                                      },
                                                                      child: Icon(Icons.arrow_circle_right_rounded,
                                                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76)))
                                                                  : const SizedBox.shrink()
                                                            ],
                                                          ),
                                                          orderList[index].orderItems![i].attrName != ""
                                                              ? Padding(
                                                                  padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text("${orderList[index].orderItems![i].attrName!} : ",
                                                                          textAlign: TextAlign.start,
                                                                          style: const TextStyle(
                                                                              color: lightFont, fontSize: 10, fontWeight: FontWeight.w500)),
                                                                      Text(orderList[index].orderItems![i].variantValues!,
                                                                          textAlign: TextAlign.start,
                                                                          style: TextStyle(
                                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 10,
                                                                          )),
                                                                    ],
                                                                  ),
                                                                )
                                                              : Container(),
                                                          Padding(
                                                            padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 99.0),
                                                            child: Wrap(
                                                                spacing: 5.0,
                                                                runSpacing: 2.0,
                                                                direction: Axis.horizontal,
                                                                children: List.generate(orderList[index].orderItems![i].addOns!.length, (j) {
                                                                  AddOnsDataModel addOnData = orderList[index].orderItems![i].addOns![j];
                                                                  return Text(
                                                                    "${addOnData.qty!} x ${addOnData.title!}, ",
                                                                    textAlign: TextAlign.center,
                                                                    style: TextStyle(
                                                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                        fontSize: 10,
                                                                        overflow: TextOverflow.ellipsis),
                                                                    maxLines: 2,
                                                                  );
                                                                })),
                                                          ),
                                                        ]),
                                                  ));
                                            })),
                                            orderList[index].orderItems!.length > 2
                                                ? Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Padding(
                                                      padding: EdgeInsetsDirectional.only(
                                                          start: width! / 13.0, bottom: height! / 80.0, top: height! / 99.0),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                              "${orderList[index].orderItems!.length - 2} ${StringsRes.plusSymbol} ${UiUtils.getTranslatedLabel(context, moreLabel)}",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Theme.of(context).colorScheme.secondary)),
                                                          SizedBox(width: width! / 80.0),
                                                        ],
                                                      ),
                                                    ))
                                                : SizedBox.shrink(),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(
                                                  top: height! / 99.0, bottom: height! / 80.0, start: width! / 40.0, end: width! / 99.0),
                                              child: const DashLineView(
                                                fillRate: 0.5,
                                                direction: Axis.horizontal,
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0),
                                              child: Row(children: [
                                                Text(UiUtils.getTranslatedLabel(context, totalPayLabel),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                                const Spacer(),
                                                Text(context.read<SystemConfigCubit>().getCurrency() + orderList[index].finalTotal!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.secondary,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.96)),
                                              ]),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(
                                                  top: height! / 99.0, bottom: height! / 70.0, start: width! / 40.0, end: width! / 99.0),
                                              child: const DashLineView(
                                                fillRate: 0.5,
                                                direction: Axis.horizontal,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                    child: BlocListener<ReOrderCubit, ReOrderState>(
                                                  listener: (context, state) {
                                                    if (state is ReOrderSuccess) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => const CartScreen(
                                                            from: 'order',
                                                          ),
                                                        ),
                                                      );
                                                    } else if (state is ReOrderFailure) {
                                                      UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                                    }
                                                  },
                                                  child: SmallButtonContainer(
                                                    color: context.read<SettingsCubit>().getSettings().branchId == orderList[index].branchId
                                                        ? Theme.of(context).colorScheme.secondary
                                                        : Theme.of(context).colorScheme.background,
                                                    height: height,
                                                    width: width,
                                                    text: UiUtils.getTranslatedLabel(context, reOrderLabel),
                                                    start: width! / 40.0,
                                                    end: width! / 99.0,
                                                    bottom: 0,
                                                    top: 0,
                                                    radius: 5.0,
                                                    status: false,
                                                    borderColor: context.read<SettingsCubit>().getSettings().branchId == orderList[index].branchId
                                                        ? Theme.of(context).colorScheme.secondary
                                                        : commentBoxBorderColor,
                                                    textColor: context.read<SettingsCubit>().getSettings().branchId == orderList[index].branchId
                                                        ? Theme.of(context).colorScheme.onBackground
                                                        : commentBoxBorderColor,
                                                    onTap: () {
                                                      if (context.read<SettingsCubit>().getSettings().branchId == orderList[index].branchId) {
                                                        context.read<ReOrderCubit>().reOrder(orderId: orderList[index].id);
                                                      } else {
                                                        UiUtils.setSnackBar(
                                                            "Your branch is different from branch of this order, please change branch..!!",
                                                            context,
                                                            false,
                                                            type: "1");
                                                      }
                                                    },
                                                  ),
                                                )),
                                                Expanded(
                                                  child: orderList[index].activeStatus == deliveredKey
                                                      ? SmallButtonContainer(
                                                          color: Theme.of(context).colorScheme.onBackground,
                                                          height: height,
                                                          width: width,
                                                          text: UiUtils.getTranslatedLabel(context, rateLabel),
                                                          start: width! / 40.0,
                                                          end: width! / 99.0,
                                                          bottom: 0,
                                                          top: 0,
                                                          radius: 5.0,
                                                          status: false,
                                                          borderColor: Theme.of(context).colorScheme.onPrimary,
                                                          textColor: Theme.of(context).colorScheme.onPrimary,
                                                          onTap: () {
                                                            if (mounted) {
                                                              Navigator.of(context)
                                                                  .pushNamed(Routes.productRating, arguments: {'orderId': orderList[index].id!});
                                                            }
                                                          },
                                                        )
                                                      : const SizedBox(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )),
                                  );
                                }),
                              );
                      }),
                );
        });
  }

  Future<void> refreshList() async {
    context.read<OrderCubit>().fetchOrder(
        perPage, context.read<AuthCubit>().getId(), "", "$preparingKey,$waitingKey,$pendingKey,$readyForPickupKey,$outForDeliveryKey,$confirmedKey");
  }

  Future<void> refreshHistoryList() async {
    context.read<HistoryOrderCubit>().fetchHistoryOrder(perPage, context.read<AuthCubit>().getId(), "", "$deliveredKey,$cancelledKey", "");
  }

  @override
  void dispose() {
    orderController.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
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
                appBar: DesignConfig.appBar(
                    context,
                    width!,
                    UiUtils.getTranslatedLabel(context, myOrderLabel),
                    PreferredSize(
                        preferredSize: Size.fromHeight(kToolbarHeight),
                        child: TabBar(
                          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary),
                          controller: tabController,
                          unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.secondary),
                          tabs: [
                            Tab(text: UiUtils.getTranslatedLabel(context, ongoingLabel)),
                            Tab(text: UiUtils.getTranslatedLabel(context, historyLabel)),
                          ],
                          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
                          labelColor: Theme.of(context).colorScheme.secondary,
                        )),
                    preferSize: height! / 8.0),
                body: TabBarView(
                  controller: tabController,
                  children: [
                    RefreshIndicator(onRefresh: refreshList, color: Theme.of(context).colorScheme.primary, child: myOrder()),
                    RefreshIndicator(onRefresh: refreshHistoryList, color: Theme.of(context).colorScheme.primary, child: myOrderHistory())
                  ],
                ),
              ),
            ),
    );
  }
}
