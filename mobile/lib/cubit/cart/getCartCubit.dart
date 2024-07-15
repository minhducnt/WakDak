import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/cartModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

// State
@immutable
abstract class GetCartState {}

class GetCartInitial extends GetCartState {}

class GetCart extends GetCartState {
  // To store cartDetails
  final List<CartModel> cartList;

  GetCart({required this.cartList});
}

class GetCartProgress extends GetCartState {
  GetCartProgress();
}

class GetCartSuccess extends GetCartState {
  final CartModel cartModel;
  GetCartSuccess(this.cartModel);
}

class GetCartFailure extends GetCartState {
  final String errorMessage, errorStatusCode;
  GetCartFailure(this.errorMessage, this.errorStatusCode);
}

class GetCartCubit extends Cubit<GetCartState> {
  final CartRepository _cartRepository;
  GetCartCubit(this._cartRepository) : super(GetCartInitial());

  // To getCart user
  getCartUser({String? userId, String? branchId}) {
    // Emitting GetCartProgress state
    emit(GetCartProgress());
    // GetCart user with given user id details in api
    _cartRepository.getCartData(userId, branchId).then((value) => emit(GetCartSuccess(value))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(GetCartFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  CartModel getCartModel() {
    if (state is GetCartSuccess) {
      return (state as GetCartSuccess).cartModel;
    } else {
      return CartModel();
    }
  }

  void clearCartModel() {
    if (state is GetCartSuccess) {
      emit(GetCartInitial());
    }
  }

  void updateCartList(CartModel cartModel) {
    emit(GetCartSuccess(cartModel));
  }

  getProductDetailsData(String id, ProductDetails productDetails) {
    if (state is GetCartSuccess) {
      return (state as GetCartSuccess)
          .cartModel
          .data!
          .firstWhere((element) => element.id == id, orElse: () => Data(productDetails: [productDetails]))
          .productDetails;
    } else {
      return [productDetails];
    }
  }

  String AllVariantQty(String id, ProductDetails productDetails) {
    if (state is GetCartSuccess) {
      int qtyTotal = 0;
      List<ProductDetails>? productDetailsData = (state as GetCartSuccess)
          .cartModel
          .data!
          .firstWhere((element) => element.id == id, orElse: () => Data(productDetails: [productDetails]))
          .productDetails;
      for (int j = 0; j < productDetailsData![0].variants!.length; j++) {
        qtyTotal = qtyTotal + int.parse(productDetailsData[0].variants![j].cartCount!);
      }
      return qtyTotal.toString();
    }
    return "";
  }

  void updateQuantity(Data productDetails, String? qty, String? varianceId) {
    if (state is GetCartSuccess) {
      CartModel currentProduct = (state as GetCartSuccess).cartModel;
      int i = currentProduct.data!.indexWhere((element) => (element.id == productDetails.id));
      int j;
      if (i == -1) {
        currentProduct.data!.insert(0, productDetails);
        int k = currentProduct.data!.indexWhere((element) => (element.id == productDetails.id));
        j = currentProduct.data![k].productDetails![0].variants!.indexWhere((element) => (element.id == varianceId));
        currentProduct.data![k].productDetails![0].variants![j].cartCount = qty;
      } else {
        j = currentProduct.data![i].productDetails![0].variants!.indexWhere((element) => (element.id == varianceId));
        currentProduct.data![i].productDetails![0].variants![j].cartCount = qty;
      }
      emit(GetCartSuccess(currentProduct));
    }
  }

  getCartItemQty(Data productDetails, String? varianceId) {
    if (state is GetCartSuccess) {
      CartModel currentProduct = (state as GetCartSuccess).cartModel;
      int i = currentProduct.data!.indexWhere((element) => (element.id == productDetails.id));
      int j = currentProduct.data![i].productDetails![0].variants!.indexWhere((element) => (element.id == varianceId));
      return currentProduct.data![i].productDetails![0].variants![j].cartCount;
    }
    return "0";
  }
}
