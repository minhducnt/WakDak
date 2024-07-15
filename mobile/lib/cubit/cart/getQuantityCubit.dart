import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/cart/cartRepository.dart';

// State
@immutable
abstract class GetQuantityState {}

class GetQuantityInitial extends GetQuantityState {}

class GetQuantity extends GetQuantityState {
  // To GetQuantity
  final String? userId, productVariantId;

  GetQuantity({this.userId, this.productVariantId});
}

class GetQuantityProgress extends GetQuantityState {
  GetQuantityProgress();
}

// ignore: must_be_immutable
class GetQuantitySuccess extends GetQuantityState {
  String qty;
  GetQuantitySuccess(this.qty);
}

class GetQuantityFailure extends GetQuantityState {
  final String errorMessage;
  GetQuantityFailure(this.errorMessage);
}

class GetQuantityCubit extends Cubit<GetQuantityState> {
  final CartRepository _cartRepository = CartRepository();
  GetQuantityCubit() : super(GetQuantityInitial());

  // To GetQuantity user
  getQuantity(String id, ProductDetails productDetails, BuildContext context) {
    // Emitting GetQuantityProgress state
    emit(GetQuantityProgress());
    // GetQuantity user in api
    _cartRepository.AllVariantQty(id, productDetails, context).then((result) {
      // Success
      emit(GetQuantitySuccess(result));
    }).catchError((e) {
      // Failure
      emit(GetQuantityFailure(e.toString()));
    });
  }

  fetchQty() {
    if (state is GetQuantitySuccess) {
      return (state as GetQuantitySuccess).qty.toString();
    }
    return '';
  }
}
