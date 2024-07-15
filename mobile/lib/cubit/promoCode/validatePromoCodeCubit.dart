import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/promoCodeValidateModel.dart';
import 'package:wakDak/data/repositories/promoCode/promoCodeRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class ValidatePromoCodeState {}

class ValidatePromoCodeIntial extends ValidatePromoCodeState {}

class ValidatePromoCodeFetchInProgress extends ValidatePromoCodeState {}

class ValidatePromoCodeFetchSuccess extends ValidatePromoCodeState {
  final PromoCodeValidateModel? promoCodeValidateModel;

  ValidatePromoCodeFetchSuccess({this.promoCodeValidateModel});
}

class ValidatePromoCodeFetchFailure extends ValidatePromoCodeState {
  final String errorMessage, errorStatusCode;
  ValidatePromoCodeFetchFailure(this.errorMessage, this.errorStatusCode);
}

class ValidatePromoCodeCubit extends Cubit<ValidatePromoCodeState> {
  final PromoCodeRepository _validatePromoCodeRepository;
  ValidatePromoCodeCubit(this._validatePromoCodeRepository) : super(ValidatePromoCodeIntial());

  //to ValidatePromoCode
  void getValidatePromoCode(String? promoCode, String? userId, String? finalTotal, String? branchId) {
    //ValidatePromoCode
    _validatePromoCodeRepository
        .validatePromoCodeData(promoCode: promoCode, userId: userId, finalTotal: finalTotal, branchId: branchId)
        .then((value) => emit(ValidatePromoCodeFetchSuccess(promoCodeValidateModel: value)))
        .catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(ValidatePromoCodeFetchFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
