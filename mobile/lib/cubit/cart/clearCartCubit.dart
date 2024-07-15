import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

// State
@immutable
abstract class ClearCartState {}

class ClearCartInitial extends ClearCartState {}

class ClearCart extends ClearCartState {
  // to clearCart
  final String? userId, productVariantId;

  ClearCart({this.userId, this.productVariantId});
}

class ClearCartProgress extends ClearCartState {
  ClearCartProgress();
}

class ClearCartSuccess extends ClearCartState {
  ClearCartSuccess();
}

class ClearCartFailure extends ClearCartState {
  final String errorMessage, errorStatusCode;
  ClearCartFailure(this.errorMessage, this.errorStatusCode);
}

class ClearCartCubit extends Cubit<ClearCartState> {
  final CartRepository _cartRepository;
  ClearCartCubit(this._cartRepository) : super(ClearCartInitial());

  // To clearCart user
  void clearCart({
    String? userId,
    String? branchId,
  }) {
    // Emitting clearCartProgress state
    emit(ClearCartProgress());
    // ClearCart user in api
    _cartRepository
        .clearCart(
      userId: userId,
      branchId: branchId,
    )
        .then((result) {
      // Success
      emit(ClearCartSuccess());
    }).catchError((e) {
      // Failure
      ApiMessageAndCodeException cartException = e;
      emit(ClearCartFailure(cartException.errorMessage.toString(), cartException.errorStatusCode.toString()));
    });
  }
}
