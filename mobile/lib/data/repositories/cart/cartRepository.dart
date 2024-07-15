import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/data/model/cartModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/cart/cartRemoteDataSource.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class CartRepository {
  static final CartRepository _cartRepository = CartRepository._internal();
  late CartRemoteDataSource _cartRemoteDataSource;

  factory CartRepository() {
    _cartRepository._cartRemoteDataSource = CartRemoteDataSource();
    return _cartRepository;
  }
  CartRepository._internal();

  // To manageCart
  Future<Map<String, dynamic>> manageCartData(
      {String? userId, String? productVariantId, String? isSavedForLater, String? qty, String? addOnId, String? addOnQty, String? branchId}) async {
    try {
      final result = await _cartRemoteDataSource.manageCart(
          userId: userId,
          productVariantId: productVariantId,
          isSavedForLater: isSavedForLater,
          qty: qty,
          addOnId: addOnId,
          addOnQty: addOnQty,
          branchId: branchId);
      return Map.from(result); //
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  // To placeOrder
  Future<Map<String, dynamic>> placeOrderData(
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
      String? deliveryTip}) async {
    final result = await _cartRemoteDataSource.placeOrder(
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
        deliveryTip: deliveryTip);
    return Map.from(result); //
  }

  // To removeFromCart
  Future<Map<String, dynamic>> removeFromCart({String? userId, String? productVariantId, String? branchId}) async {
    final result = await _cartRemoteDataSource.removeCart(userId: userId, productVariantId: productVariantId, branchId: branchId);
    return Map.from(result); //
  }

  // To clearCart
  Future<Map<String, dynamic>> clearCart({String? userId, String? branchId}) async {
    final result = await _cartRemoteDataSource.clearCart(userId: userId, branchId: branchId);
    return Map.from(result); //
  }

  // To getCart
  Future<CartModel> getCartData(String? userId, String? branchId) async {
    try {
      CartModel result = await _cartRemoteDataSource.getCart(userId: userId, branchId: branchId);
      return result;
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<String> AllVariantQty(String id, ProductDetails productDetails, BuildContext context) async {
    if (context.read<GetCartCubit>().state is GetCartSuccess) {
      int qtyTotal = 0;
      List<ProductDetails>? productDetailsData = (context.read<GetCartCubit>().state as GetCartSuccess)
          .cartModel
          .data!
          .firstWhere((element) => element.id == id, orElse: () => Data(productDetails: [productDetails]))
          .productDetails;
      for (int j = 0; j < productDetailsData![0].variants!.length; j++) {
        if (productDetails.variants![0].id == productDetailsData[0].variants![j].id) {
          qtyTotal = int.parse(productDetailsData[0].variants![j].cartCount!);
        }
      }
      return qtyTotal.toString();
    } else {
      if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
        var db = DatabaseHelper();
        int qtyTotal = 0;
        Map? productVariants;
        List<String>? productVariantIds = [];
        productVariants = (await db.getCart());
        productVariantIds = productVariants['VID'];
        for (int j = 0; j < productDetails.variants!.length; j++) {
          if (productVariantIds!.contains(productDetails.variants![0].id)) {
            String qty = (await db.checkCartItemExists(productDetails.id!, productDetails.variants![j].id!))!;
            productDetails.variants![j].cartCount = qty;
            qtyTotal = int.parse(qty);
          }
        }
        return qtyTotal.toString();
      } else {
        return "0";
      }
    }
  }
}
