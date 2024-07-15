import 'package:wakDak/data/model/bestOfferModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class BestOfferRemoteDataSource {
  Future<List<BestOfferModel>> getBestOffer(String? branchId) async {
    try {
      final body = {branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.getOfferImagesUrl, token: true, errorCode: false);
      return (result[dataKey] as List).map((e) => BestOfferModel.fromJson(Map.from(e))).toList();
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
