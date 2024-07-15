import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/withdrawModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

@immutable
abstract class GetWithdrawRequestState {}

class GetWithdrawRequestInitial extends GetWithdrawRequestState {}

class GetWithdrawRequestProgress extends GetWithdrawRequestState {}

class GetWithdrawRequestSuccess extends GetWithdrawRequestState {
  final List<WithdrawModel> withdrawRequestList;
  final int totalData;
  final bool hasMore;
  GetWithdrawRequestSuccess(this.withdrawRequestList, this.totalData, this.hasMore);
}

class GetWithdrawRequestFailure extends GetWithdrawRequestState {
  final String errorMessage, errorStatusCode;
  GetWithdrawRequestFailure(this.errorMessage, this.errorStatusCode);
}

String? totalHasMore;

class GetWithdrawRequestCubit extends Cubit<GetWithdrawRequestState> {
  GetWithdrawRequestCubit() : super(GetWithdrawRequestInitial());
  Future<List<WithdrawModel>> _fetchData({required String limit, String? offset, String? userId}) async {
    try {
      // Body of post request
      final body = {limitKey: limit, offsetKey: offset ?? "", userIdKey: userId ?? ""};
      if (offset == null) {
        body.remove(offset);
      }
      final result = await Api.post(body: body, url: Api.getWithdrawRequestUrl, token: true, errorCode: true);
      totalHasMore = result[totalKey].toString();
      return (result[dataKey] as List).map((e) => WithdrawModel.fromJson(e)).toList();
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString(), errorStatusCode: '');
    }
  }

  void fetchGetWithdrawRequest(String limit, String? userId) {
    emit(GetWithdrawRequestProgress());
    _fetchData(limit: limit, userId: userId).then((value) {
      final List<WithdrawModel> usersDetails = value;
      final total = int.parse(totalHasMore!);
      emit(GetWithdrawRequestSuccess(
        usersDetails,
        total,
        total > usersDetails.length,
      ));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(GetWithdrawRequestFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  void fetchMoreGetWithdrawRequestData(String limit, String? userId) {
    _fetchData(limit: limit, offset: (state as GetWithdrawRequestSuccess).withdrawRequestList.length.toString(), userId: userId).then((value) {
      final oldState = (state as GetWithdrawRequestSuccess);
      final List<WithdrawModel> usersDetails = value;
      final List<WithdrawModel> updatedUserDetails = List.from(oldState.withdrawRequestList);
      updatedUserDetails.addAll(usersDetails);
      emit(GetWithdrawRequestSuccess(updatedUserDetails, oldState.totalData, oldState.totalData > updatedUserDetails.length));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(GetWithdrawRequestFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  bool hasMoreData() {
    if (state is GetWithdrawRequestSuccess) {
      return (state as GetWithdrawRequestSuccess).hasMore;
    } else {
      return false;
    }
  }

  void addWithdrawRequest(WithdrawModel withdrawModel) {
    if (state is GetWithdrawRequestSuccess) {
      List<WithdrawModel> currentGetWithdrawRequest = (state as GetWithdrawRequestSuccess).withdrawRequestList;
      int offset = (state as GetWithdrawRequestSuccess).totalData;
      bool limit = (state as GetWithdrawRequestSuccess).hasMore;
      currentGetWithdrawRequest.insert(0, withdrawModel);
      emit(GetWithdrawRequestSuccess(List<WithdrawModel>.from(currentGetWithdrawRequest), offset, limit));
    }
  }

  List<WithdrawModel> getGetWithdrawRequestList() {
    if (state is GetWithdrawRequestSuccess) {
      final withdrawRequestList = (state as GetWithdrawRequestSuccess).withdrawRequestList;
      return withdrawRequestList;
    }
    return [];
  }
}
