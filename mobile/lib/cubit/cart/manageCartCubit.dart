import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/cartModel.dart';
import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

// State
@immutable
abstract class ManageCartState {}

class ManageCartInitial extends ManageCartState {}

class ManageCart extends ManageCartState {
  // To manageCart
  final String? userId, productVariantId;

  ManageCart({this.userId, this.productVariantId});
}

class ManageCartProgress extends ManageCartState {
  ManageCartProgress();
}

class ManageCartSuccess extends ManageCartState {
  final List<Data> data;
  final String? totalQuantity, subTotal, taxPercentage, taxAmount;
  final double? overallAmount;
  final List<String>? variantId;
  ManageCartSuccess(this.data, this.totalQuantity, this.subTotal, this.taxPercentage, this.taxAmount, this.overallAmount, this.variantId);
}

class ManageCartFailure extends ManageCartState {
  final String errorMessage, errorStatusCode;
  ManageCartFailure(this.errorMessage, this.errorStatusCode);
}

class ManageCartCubit extends Cubit<ManageCartState> {
  final CartRepository _cartRepository;
  ManageCartCubit(this._cartRepository) : super(ManageCartInitial());

  // To manageCart user
  void manageCartUser(
      {String? userId, String? productVariantId, String? isSavedForLater, String? qty, String? addOnId, String? addOnQty, String? branchId}) {
    // Emitting manageCartProgress state
    emit(ManageCartProgress());
    // manageCart
    _cartRepository
        .manageCartData(
            userId: userId,
            productVariantId: productVariantId,
            isSavedForLater: isSavedForLater,
            qty: qty,
            addOnId: addOnId,
            addOnQty: addOnQty,
            branchId: branchId)
        .then((result) {
      // Success
      emit(ManageCartSuccess(
          (result['cart'] as List).map((e) => Data.fromJson(e)).toList(),
          result[dataKey]['total_quantity'],
          result[dataKey]['sub_total'],
          result[dataKey]['tax_percentage'],
          result[dataKey]['tax_amount'],
          double.parse(result[dataKey]['overall_amount']),
          result[dataKey]['variant_id']));
    }).catchError((e) {
      // Failure
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(ManageCartFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
