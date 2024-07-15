import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class PaymentRemoteDataSource {
  Future<dynamic> getPayment(String? userId, String? orderId, String? amount) async {
    try {
      final body = {userIdKey: userId, orderIdKey: orderId, amountKey: amount};
      final result = await Api.post(body: body, url: Api.getPaypalLinkUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> sendWalletRequest(String? userId, String? amount, String? paymentAddress) async {
    try {
      final body = {userIdKey: userId, amountKey: amount, paymentAddressKey: paymentAddress};
      final result = await Api.post(body: body, url: Api.sendWithdrawRequestUrl, token: true, errorCode: true);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

}
