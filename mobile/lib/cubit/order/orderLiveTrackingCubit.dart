import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/orderLiveTrackingModel.dart';
import 'package:wakDak/data/repositories/order/orderRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

// State
@immutable
abstract class OrderLiveTrackingState {}

class OrderLiveTrackingInitial extends OrderLiveTrackingState {}

class OrderLiveTracking extends OrderLiveTrackingState {
  final OrderLiveTrackingModel orderLiveTrackingList;

  OrderLiveTracking({required this.orderLiveTrackingList});
}

class OrderLiveTrackingProgress extends OrderLiveTrackingState {
  OrderLiveTrackingProgress();
}

class OrderLiveTrackingSuccess extends OrderLiveTrackingState {
  final OrderLiveTrackingModel orderLiveTracking;
  OrderLiveTrackingSuccess(this.orderLiveTracking);
}

class OrderLiveTrackingFailure extends OrderLiveTrackingState {
  final String errorMessage, errorStatusCode;
  OrderLiveTrackingFailure(this.errorMessage, this.errorStatusCode);
}

class OrderLiveTrackingCubit extends Cubit<OrderLiveTrackingState> {
  final OrderRepository _orderRepository;
  OrderLiveTrackingCubit(this._orderRepository) : super(OrderLiveTrackingInitial());

  // to getOrderLiveTracking rider
  void getOrderLiveTracking({
    String? orderId,
  }) {
    if (state is! OrderLiveTrackingSuccess) {
      // Emitting OrderLiveTrackingProgress state
      emit(OrderLiveTrackingProgress());
    }
    // getOrderLiveTracking rider details in api
    _orderRepository.getOrderLiveTrackingData(orderId).then((value) => emit(OrderLiveTrackingSuccess(value))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(OrderLiveTrackingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
