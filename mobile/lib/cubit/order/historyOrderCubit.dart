import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/orderModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

@immutable
abstract class HistoryOrderState {}

class HistoryOrderInitial extends HistoryOrderState {}

class HistoryOrderProgress extends HistoryOrderState {}

class HistoryOrderSuccess extends HistoryOrderState {
  final List<OrderModel> historyOrderList;
  final int totalData;
  final bool hasMore;
  HistoryOrderSuccess(this.historyOrderList, this.totalData, this.hasMore);
}

class HistoryOrderFailure extends HistoryOrderState {
  final String errorMessage, errorStatusCode;
  HistoryOrderFailure(this.errorMessage, this.errorStatusCode);
}

String? totalHasMore;

class HistoryOrderCubit extends Cubit<HistoryOrderState> {
  HistoryOrderCubit() : super(HistoryOrderInitial());
  Future<List<OrderModel>> _fetchData(
      {required String limit, String? offset, required String? userId, String? id, String? activeStatus, String? isSelfPickup}) async {
    try {
      // Body of post request
      final body = {limitKey: limit, offsetKey: offset ?? "", userIdKey: userId, idKey: id ?? "", isSelfPickUpKey: isSelfPickup ?? ""};

      if (offset == null) {
        body.remove(offset);
      }
      if (activeStatus != null) {
        body[activeStatusKey] = activeStatus;
      }
      final result = await Api.post(body: body, url: Api.getOrdersUrl, token: true, errorCode: true);
      totalHasMore = result[totalKey].toString();
      return (result[dataKey] as List).map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  void fetchHistoryOrder(String limit, String userId, String id, String activeStatus, String isSelfPickup) {
    emit(HistoryOrderProgress());
    _fetchData(limit: limit, userId: userId, id: id, activeStatus: activeStatus, isSelfPickup: isSelfPickup).then((value) {
      final List<OrderModel> usersDetails = value;
      final total = int.parse(totalHasMore!);
      emit(HistoryOrderSuccess(
        usersDetails,
        total,
        total > usersDetails.length,
      ));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(HistoryOrderFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  void fetchMoreHistoryOrderData(String limit, String? userId, String? id, String? activeStatus, String? isSelfPickup) {
    _fetchData(
            limit: limit,
            offset: (state as HistoryOrderSuccess).historyOrderList.length.toString(),
            userId: userId,
            id: id,
            activeStatus: activeStatus,
            isSelfPickup: isSelfPickup)
        .then((value) {
      final oldState = (state as HistoryOrderSuccess);
      final List<OrderModel> usersDetails = value;
      final List<OrderModel> updatedUserDetails = List.from(oldState.historyOrderList);
      updatedUserDetails.addAll(usersDetails);
      emit(HistoryOrderSuccess(updatedUserDetails, oldState.totalData, oldState.totalData > updatedUserDetails.length));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(HistoryOrderFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  bool hasMoreData() {
    if (state is HistoryOrderSuccess) {
      return (state as HistoryOrderSuccess).hasMore;
    } else {
      return false;
    }
  }
}
