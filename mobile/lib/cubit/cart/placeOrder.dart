import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

// State
abstract class PlaceOrderState {}

class PlaceOrderInitial extends PlaceOrderState {}

class PlaceOrder extends PlaceOrderState {
  // To PlaceOrder
  String? userId, productVariantId;

  PlaceOrder({this.userId, this.productVariantId});
}

class PlaceOrderProgress extends PlaceOrderState {
  PlaceOrderProgress();
}

class PlaceOrderSuccess extends PlaceOrderState {
  final String? userId,
      mobile,
      productVariantId,
      quantity,
      total,
      deliveryCharge,
      taxAmount,
      taxPercentage,
      finalTotal,
      latitude,
      longitude,
      promoCode,
      paymentMethod,
      addressId,
      isWalletUsed,
      walletBalanceUsed,
      activeStatus,
      orderNote,
      deliveryTip;
  PlaceOrderSuccess(
      this.userId,
      this.mobile,
      this.productVariantId,
      this.quantity,
      this.total,
      this.deliveryCharge,
      this.taxAmount,
      this.taxPercentage,
      this.finalTotal,
      this.latitude,
      this.longitude,
      this.promoCode,
      this.paymentMethod,
      this.addressId,
      this.isWalletUsed,
      this.walletBalanceUsed,
      this.activeStatus,
      this.orderNote,
      this.deliveryTip);
}

class PlaceOrderFailure extends PlaceOrderState {
  final String errorMessage, errorStatusCode;
  PlaceOrderFailure(this.errorMessage, this.errorStatusCode);
}

class PlaceOrderCubit extends Cubit<PlaceOrderState> {
  final CartRepository _cartRepository;
  PlaceOrderCubit(this._cartRepository) : super(PlaceOrderInitial());

  // To PlaceOrder user
  void placeOrderUser(
      {String? userId,
      String? mobile,
      String? productVariantId,
      String? quantity,
      String? total,
      String? deliveryCharge,
      String? taxAmount,
      String? taxPercentage,
      String? finalTotal,
      String? latitude,
      String? longitude,
      String? promoCode,
      String? paymentMethod,
      String? addressId,
      String? isWalletUsed,
      String? walletBalanceUsed,
      String? activeStatus,
      String? orderNote,
      String? deliveryTip}) {
    // Emitting PlaceOrderProgress state
    emit(PlaceOrderProgress());
    // PlaceOrder
    _cartRepository
        .placeOrderData(
            userId: userId,
            mobile: mobile,
            productVariantId: productVariantId,
            quantity: quantity,
            total: total,
            deliveryCharge: deliveryCharge,
            taxAmount: taxAmount,
            taxPercentage: taxPercentage,
            finalTotal: finalTotal,
            latitude: latitude,
            longitude: longitude,
            promoCode: promoCode,
            paymentMethod: paymentMethod,
            addressId: addressId,
            isWalletUsed: isWalletUsed,
            walletBalanceUsed: walletBalanceUsed,
            activeStatus: activeStatus,
            orderNote: orderNote,
            deliveryTip: deliveryTip)
        .then((result) {
      // Success
      emit(PlaceOrderSuccess(userId, mobile, productVariantId, quantity, total, deliveryCharge, taxAmount, taxPercentage, finalTotal, latitude,
          longitude, promoCode, paymentMethod, addressId, isWalletUsed, walletBalanceUsed, activeStatus, orderNote, deliveryTip));
    }).catchError((e) {
      // Failure
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(PlaceOrderFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
