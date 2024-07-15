import 'package:wakDak/data/model/promoCodeValidateModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class PromoCodeRemoteDataSource {
// To promoCode
  Future<PromoCodeValidateModel> validatePromoCode({String? promoCode, String? userId, String? finalTotal, String? branchId}) async {
    try {
      // Body of post request
      final body = {promoCodeKey: promoCode, userIdKey: userId, finalTotalKey: finalTotal, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.validatePromoCodeUrl, token: true, errorCode: true);
      return PromoCodeValidateModel.fromJson(result[dataKey][0]);
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }
}
