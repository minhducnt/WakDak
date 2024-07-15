import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/addressModel.dart';
import 'package:wakDak/data/repositories/rating/ratingRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class SetProductRatingState {}

class SetProductRatingInitial extends SetProductRatingState {}

class SetProductRatingProgress extends SetProductRatingState {}

class SetProductRatingSuccess extends SetProductRatingState {
  final AddressModel addressModel;

  SetProductRatingSuccess(this.addressModel);
}

class SetProductRatingFailure extends SetProductRatingState {
  final String errorCode, errorStatusCode;
  SetProductRatingFailure(this.errorCode, this.errorStatusCode);
}

class SetProductRatingCubit extends Cubit<SetProductRatingState> {
  final RatingRepository _ratingRepository;

  SetProductRatingCubit(this._ratingRepository) : super(SetProductRatingInitial());

  void setProductRating(String? userId, List? productRatingDataString) {
    emit(SetProductRatingProgress());
    _ratingRepository
        .setProductRating(userId, productRatingDataString)
        .then((value) =>
            emit(SetProductRatingSuccess(AddressModel())))
        .catchError((e) {
      print(e.toString());
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(SetProductRatingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
