//State
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/repositories/payment/paymentRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionFetchInProgress extends TransactionState {}

class TransactionFetchSuccess extends TransactionState {
  final String? userId, orderId, amount;

  TransactionFetchSuccess({this.userId, this.orderId, this.amount});
}

class TransactionFetchFailure extends TransactionState {
  final String errorCode, errorStatusCode;
  TransactionFetchFailure(this.errorCode, this.errorStatusCode);
}

class TransactionCubit extends Cubit<TransactionState> {
  final PaymentRepository _paymentRepository;
  TransactionCubit(this._paymentRepository) : super(TransactionInitial());

  //to getTransaction user
  void getTransaction(String? userId, String? orderId, String? amount) {
    //emitting GetTransactionProgress state
    emit(TransactionFetchInProgress());
    //GetTransaction details in api
    _paymentRepository
        .getPayment(userId, orderId, amount)
        .then((value) => emit(TransactionFetchSuccess(userId: userId, orderId: orderId, amount: amount)))
        .catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(TransactionFetchFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
