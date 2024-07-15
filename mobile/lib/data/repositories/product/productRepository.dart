import 'package:wakDak/data/model/productModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/product/productRemoteDataSource.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class ProductRepository {
  static final ProductRepository _productRepository = ProductRepository._internal();
  late ProductRemoteDataSource _productRemoteDataSource;

  factory ProductRepository() {
    _productRepository._productRemoteDataSource = ProductRemoteDataSource();
    return _productRepository;
  }
  ProductRepository._internal();

  // To getProduct
  Future<ProductModel> getProductData(
      String? partnerId, String? latitude, String? longitude, String? userId, String? cityId, String? vegetarian) async {
    try {
      ProductModel result = await _productRemoteDataSource.getProduct(
          partnerId: partnerId, latitude: latitude ?? "", longitude: longitude ?? "", userId: userId, cityId: cityId, vegetarian: vegetarian);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To getOfflineCartData
  Future <List<ProductDetails>> getOfflineCartData(
      String? productVariantIds, String? branchId) async {
    try {
      List<ProductDetails> result = await _productRemoteDataSource.getOfflineCart(
          productVariantIds: productVariantIds, branchId: branchId);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To manageOfflineCartData
  Future<ProductModel> manageOfflineCartData(String? latitude, String? longitude, String? cityId, String? productVariantIds) async {
    try {
      ProductModel result = await _productRemoteDataSource.manageOfflineCart(
          latitude: latitude ?? "", longitude: longitude ?? "", cityId: cityId, productVariantIds: productVariantIds);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
