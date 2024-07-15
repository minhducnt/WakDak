import 'dart:convert';
import 'dart:io';

import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';
import 'package:wakDak/utils/string.dart';

class RatingRemoteDataSource {
  Future setProductRating(String? userId, List? productRatingData) async {
    try {
      Map<String, String> body = {userIdKey: userId!};
      Map<dynamic, File> fileList = {};
      for (int i = 0; i < productRatingData!.length; i++) {
        body["$productRatingDataKey[$i][$productIdKey]"] = productRatingData[i]["$productIdKey"];
        body["$productRatingDataKey[$i][$ratingKey]"] = productRatingData[i]["$ratingKey"];
        body["$productRatingDataKey[$i][$commentKey]"] = productRatingData[i]["$commentKey"];
        for (int j = 0; j < productRatingData[i]["$imagesKey"].length; j++) {
          fileList.addAll({'$productRatingDataKey[$i][$imagesKey][$j]': productRatingData[i]["$imagesKey"][j]});
        }
      }
      final response = await Api.postApiFileProductRating(Uri.parse(Api.setProductRatingUrl), body, userId, fileList);
      final responseJson = json.decode(response);

      if (responseJson[errorKey]) {
        throw ApiMessageAndCodeException(errorMessage: responseJson[messageKey], errorStatusCode: responseJson[statusCodeKey].toString());
      }

      return responseJson[dataKey];
    } on SocketException catch (_) {
      throw ApiMessageAndCodeException(errorMessage: StringsRes.noInternet);
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future setRiderRating(String? userId, String? riderId, String? rating, String? comment) async {
    try {
      final body = {userIdKey: userId, riderIdKey: riderId, ratingKey: rating, commentKey: comment};
      final result = await Api.post(body: body, url: Api.setRiderRatingUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future deleteProductRating(String? ratingId) async {
    try {
      final body = {ratingIdKey: ratingId};
      final result = await Api.post(body: body, url: Api.deleteProductRatingUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future deleteRiderRating(String? ratingId) async {
    try {
      final body = {ratingIdKey: ratingId};
      final result = await Api.post(body: body, url: Api.deleteRiderRatingUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future setOrderRating(String? userId, String? orderId, String? rating, String? comment, List<File> images) async {
    try {
      Map<String, String?> body = {userIdKey: userId, orderIdKey: orderId, ratingKey: rating, commentKey: comment};
      List<File> imagesList = images;
      final response = await Api.postApiFile(Uri.parse(Api.setOrderRatingUrl), imagesList, body, userId, orderId, rating, comment);
      final responseJson = json.decode(response);
      if (responseJson[errorKey]) {
        throw ApiMessageAndCodeException(errorMessage: responseJson[messageKey], errorStatusCode: responseJson[statusCodeKey].toString());
      }

      return responseJson[dataKey];
    } on SocketException catch (_) {
      throw ApiMessageAndCodeException(errorMessage: StringsRes.noInternet);
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future deleteOrderRating(String? orderId) async {
    try {
      final body = {ratingIdKey: orderId};
      final result = await Api.post(body: body, url: Api.deleteOrderRatingUrl, token: true, errorCode: true);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
