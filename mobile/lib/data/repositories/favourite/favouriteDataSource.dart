import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class FavouriteRemoteDataSource {
  Future<List<ProductDetails>> getFavouriteProducts({String? userId, String? type, String? branchId}) async {
    try {
      final body = {userIdKey: userId, typeKey: type, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.getFavoritesUrl, token: true, errorCode: true);
      return (result[dataKey] as List).map((e) => ProductDetails.fromJson(e)).toList();
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  Future favouriteAdd(String? userId, String? type, String? typeId, String? branchId) async {
    try {
      final body = {userIdKey: userId, typeKey: type, typeIdKey: typeId, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.addToFavoritesUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future favouriteRemove(String? userId, String? type, String? typeId, String? branchId) async {
    try {
      final body = {userIdKey: userId, typeKey: type, typeIdKey: typeId, branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.removeFromFavoritesUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
