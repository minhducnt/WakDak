import 'package:wakDak/data/model/productModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class ProductRemoteDataSource {
  // To getProduct
  Future<ProductModel> getProduct(
      {String? partnerId, String? latitude, String? longitude, String? userId, String? cityId, String? vegetarian}) async {
    try {
      // Body of post request
      final body = {
        filterByKey: filterByProductKey,
        latitudeKey: latitude ?? "",
        longitudeKey: longitude ?? "",
        userIdKey: userId,
        cityIdKey: cityId ?? "",
        vegetarianKey: vegetarian ?? ""
      };
      final result = await Api.post(body: body, url: Api.getProductsUrl, token: true, errorCode: false);
      return ProductModel.fromJson(result);
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To getOfflineCart
  Future <List<ProductDetails>> getOfflineCart(
      {String? productVariantIds, String? branchId}) async {
    try {
      // Body of post request
      final body = {
        filterByKey: filterByProductKey,
        productVariantIdsKey: productVariantIds ?? "",
        branchIdKey: branchId
      };
      final result = await Api.post(body: body, url: Api.getProductsUrl, token: true, errorCode: false);
      return (result[dataKey] as List).map((e) => ProductDetails.fromJson(e)).toList(); 
    } catch (e) {
      print(e.toString());
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To ManageOfflineCart
  Future<ProductModel> manageOfflineCart({String? latitude, String? longitude, String? cityId, String? productVariantIds}) async {
    try {
      // Body of post request
      final body = {
        filterByKey: filterByProductKey,
        latitudeKey: latitude ?? "",
        longitudeKey: longitude ?? "",
        cityIdKey: cityId ?? "",
        productVariantIdsKey: productVariantIds ?? ""
      };
      final result = await Api.post(body: body, url: Api.getProductsUrl, token: true, errorCode: false);
      return ProductModel.fromJson(result);
    } catch (e) {
      print(e.toString());
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
