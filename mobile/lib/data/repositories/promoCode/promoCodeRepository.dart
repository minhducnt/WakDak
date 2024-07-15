import 'package:wakDak/data/model/promoCodeValidateModel.dart';
import 'package:wakDak/data/repositories/promoCode/promoCodeRemoteDataSource.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class PromoCodeRepository {
  static final PromoCodeRepository _promoCodeRepository = PromoCodeRepository._internal();
  late PromoCodeRemoteDataSource _promoCodeRemoteDataSource;

  factory PromoCodeRepository() {
    _promoCodeRepository._promoCodeRemoteDataSource = PromoCodeRemoteDataSource();
    return _promoCodeRepository;
  }
  PromoCodeRepository._internal();

  // To add user's data to database. This will be in use when authenticating using phoneNumber
  Future<PromoCodeValidateModel> validatePromoCodeData({String? promoCode, String? userId, String? finalTotal, String? branchId}) async {
    try {
      final result =
          await _promoCodeRemoteDataSource.validatePromoCode(promoCode: promoCode, userId: userId, finalTotal: finalTotal, branchId: branchId);
      return result;
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
