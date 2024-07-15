//State
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/withdrawModel.dart';
import 'package:wakDak/data/repositories/payment/paymentRepository.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class SendWithdrawRequestState {}

class SendWithdrawRequestInitial extends SendWithdrawRequestState {}

class SendWithdrawRequestFetchInProgress extends SendWithdrawRequestState {}

class SendWithdrawRequestFetchSuccess extends SendWithdrawRequestState {
  final String? userId, amount, paymentAddress, walletAmount;
  final WithdrawModel? withdrawModel;
  SendWithdrawRequestFetchSuccess({this.userId, this.amount, this.paymentAddress, this.walletAmount, this.withdrawModel});
}

class SendWithdrawRequestFetchFailure extends SendWithdrawRequestState {
  final String errorCode, errorStatusCode;
  SendWithdrawRequestFetchFailure(this.errorCode, this.errorStatusCode);
}

class SendWithdrawRequestCubit extends Cubit<SendWithdrawRequestState> {
  final PaymentRepository _paymentRepository;
  SendWithdrawRequestCubit(this._paymentRepository) : super(SendWithdrawRequestInitial());

  // To sendWithdrawRequest user
  void sendWithdrawRequest(String? userId, String? amount, String? paymentAddress) {
    // Emitting SendWithdrawRequestProgress state
    emit(SendWithdrawRequestFetchInProgress());
    // SendWithdrawRequest in api
    _paymentRepository
        .sendWalletRequest(userId, amount, paymentAddress)
        .then((value) => emit(SendWithdrawRequestFetchSuccess(
            userId: userId,
            amount: amount,
            paymentAddress: paymentAddress,
            walletAmount: value['new_balance'],
            withdrawModel: WithdrawModel.fromJson(value[dataKey][0]))))
        .catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(
          SendWithdrawRequestFetchFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
