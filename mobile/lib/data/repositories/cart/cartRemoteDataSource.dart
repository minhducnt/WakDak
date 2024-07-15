import 'package:wakDak/data/model/cartModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class CartRemoteDataSource {
// to manageCart
  Future<dynamic> manageCart(
      {String? userId, String? productVariantId, String? isSavedForLater, String? qty, String? addOnId, String? addOnQty, String? branchId}) async {
    try {
      // Body of post request
      final body = {
        userIdKey: userId,
        productVariantIdKey: productVariantId,
        isSavedForLaterKey: isSavedForLater,
        qtyKey: qty,
        addOnIdKey: addOnId ?? "",
        addOnQtyKey: addOnQty ?? "",
        branchIdKey: branchId ?? ""
      };
      final result = await Api.post(body: body, url: Api.manageCartUrl, token: true, errorCode: true);
      return result;
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  // To placeOrder
  Future<dynamic> placeOrder(
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
      String? deliveryTip,
      String? branchId}) async {
    try {
      // Body of post request
      final body = {
        userIdKey: userId,
        mobileKey: mobile,
        productVariantIdKey: productVariantId,
        quantityKey: quantity,
        totalKey: total,
        deliveryChargeKey: deliveryCharge,
        taxAmountKey: taxAmount,
        taxPercentageKey: taxPercentage,
        finalTotalKey: finalTotal,
        latitudeKey: latitude,
        longitudeKey: longitude,
        promoCodeKey: promoCode,
        paymentMethodKey: paymentMethod,
        addressIdKey: addressId,
        isWalletUsedKey: isWalletUsed,
        walletBalanceUsedKey: walletBalanceUsed,
        activeStatusKey: activeStatus,
        orderNoteKey: orderNote,
        deliveryTipKey: deliveryTip,
        branchIdKey: branchId
      };
      final result = await Api.post(body: body, url: Api.placeOrderUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  // To removeCart
  Future<dynamic> removeCart({String? userId, String? productVariantId, String? branchId}) async {
    try {
      // Body of post request
      final body = {userIdKey: userId, productVariantIdKey: productVariantId, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.removeFromCartUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  // To clearCart
  Future<dynamic> clearCart({String? userId, String? branchId}) async {
    try {
      // Body of post request
      final body = {userIdKey: userId, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.removeFromCartUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  // To getUserCart
  Future<CartModel> getCart({String? userId, String? branchId}) async {
    try {
      // Body of post request
      final body = {userIdKey: userId, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.getUserCartUrl, token: true, errorCode: true);
      return CartModel.fromJson(result);
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }
}
