import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/deliveryBoyRatingModel.dart';
import 'package:wakDak/data/repositories/rating/ratingRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class DeleteRatingState {}

class DeleteRatingInitial extends DeleteRatingState {}

class DeleteRatingProgress extends DeleteRatingState {}

class DeleteRatingSuccess extends DeleteRatingState {
  final RiderRatingModel riderRatingModel;

  DeleteRatingSuccess(this.riderRatingModel);
}

class DeleteRatingFailure extends DeleteRatingState {
  final String errorCode, errorStatusCode;
  DeleteRatingFailure(this.errorCode, this.errorStatusCode);
}

class DeleteRatingCubit extends Cubit<DeleteRatingState> {
  final RatingRepository _ratingRepository;

  DeleteRatingCubit(this._ratingRepository) : super(DeleteRatingInitial());

  void deleteOrderRating(String? ratingId) {
    emit(DeleteRatingProgress());
    _ratingRepository.deleteOrderRating(ratingId).then((value) => emit(DeleteRatingSuccess(RiderRatingModel()))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(DeleteRatingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  void deleteProductRating(String? ratingId) {
    emit(DeleteRatingProgress());
    _ratingRepository.deleteProductRating(ratingId).then((value) => emit(DeleteRatingSuccess(RiderRatingModel()))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(DeleteRatingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  void deleteRiderRating(String? ratingId) {
    emit(DeleteRatingProgress());
    _ratingRepository.deleteRiderRating(ratingId).then((value) => emit(DeleteRatingSuccess(RiderRatingModel()))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(DeleteRatingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
