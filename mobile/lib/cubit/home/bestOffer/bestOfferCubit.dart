import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/bestOfferModel.dart';
import 'package:wakDak/data/repositories/home/bestOffer/bestOfferRepository.dart';

abstract class BestOfferState {}

class BestOfferInitial extends BestOfferState {}

class BestOfferProgress extends BestOfferState {}

class BestOfferSuccess extends BestOfferState {
  final List<BestOfferModel> bestOfferList;

  BestOfferSuccess(this.bestOfferList);
}

class BestOfferFailure extends BestOfferState {
  final String errorCode;

  BestOfferFailure(this.errorCode);
}

class BestOfferCubit extends Cubit<BestOfferState> {
  final BestOfferRepository _bestOfferRepository;

  BestOfferCubit(this._bestOfferRepository) : super(BestOfferInitial());

  void fetchBestOffer(String? branchId) {
    emit(BestOfferProgress());
    _bestOfferRepository.getBestOffer(branchId).then((value) => emit(BestOfferSuccess(value))).catchError((e) {
      emit(BestOfferFailure(e.toString()));
    });
  }
}
