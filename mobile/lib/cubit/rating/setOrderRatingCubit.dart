import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/deliveryBoyRatingModel.dart';
import 'package:wakDak/data/repositories/rating/ratingRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class SetOrderRatingState {}

class SetOrderRatingInitial extends SetOrderRatingState {}

class SetOrderRatingProgress extends SetOrderRatingState {}

class SetOrderRatingSuccess extends SetOrderRatingState {
  final RiderRatingModel riderRatingModel;

  SetOrderRatingSuccess(this.riderRatingModel);
}

class SetOrderRatingFailure extends SetOrderRatingState {
  final String errorCode, errorStatusCode;
  SetOrderRatingFailure(this.errorCode, this.errorStatusCode);
}

class SetOrderRatingCubit extends Cubit<SetOrderRatingState> {
  final RatingRepository _ratingRepository;

  SetOrderRatingCubit(this._ratingRepository) : super(SetOrderRatingInitial());

  void setOrderRating(String? userId, String? orderId, String? rating, String? comment, List<File> images) {
    emit(SetOrderRatingProgress());
    _ratingRepository
        .setOrderRating(userId, orderId, rating, comment, images)
        .then((value) => emit(SetOrderRatingSuccess(RiderRatingModel())))
        .catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(SetOrderRatingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
