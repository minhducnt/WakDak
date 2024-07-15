import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

// State
@immutable
abstract class RemoveFromCartState {}

class RemoveFromCartInitial extends RemoveFromCartState {}

class RemoveFromCart extends RemoveFromCartState {
  // To removeFromCart
  final String? userId, productVariantId;

  RemoveFromCart({this.userId, this.productVariantId});
}

class RemoveFromCartProgress extends RemoveFromCartState {
  RemoveFromCartProgress();
}

class RemoveFromCartSuccess extends RemoveFromCartState {
  RemoveFromCartSuccess();
}

class RemoveFromCartFailure extends RemoveFromCartState {
  final String errorMessage, errorStatusCode;
  RemoveFromCartFailure(this.errorMessage, this.errorStatusCode);
}

class RemoveFromCartCubit extends Cubit<RemoveFromCartState> {
  final CartRepository _cartRepository;
  RemoveFromCartCubit(this._cartRepository) : super(RemoveFromCartInitial());

  // To RemoveFromCart user
  void removeFromCart({String? userId, String? productVariantId, String? branchId}) {
    // Emitting removeFromCartProgress state
    emit(RemoveFromCartProgress());
    // RemoveFromCart user in api
    _cartRepository.removeFromCart(userId: userId, productVariantId: productVariantId, branchId: branchId).then((result) {
      // Success
      emit(RemoveFromCartSuccess());
    }).catchError((e) {
      // Failure
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(RemoveFromCartFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
