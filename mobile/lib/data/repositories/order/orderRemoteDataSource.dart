import 'package:wakDak/data/model/orderLiveTrackingModel.dart';
import 'package:wakDak/data/model/orderModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

class OrderRemoteDataSource {
  // To getUserOrder
  Future<OrderModel> getOrder({String? status, String? orderId, String? reason}) async {
    try {
      //body of post request
      final body = {statusKey: status, orderIdKey: orderId, reasonKey: reason ?? ""};
      final result = await Api.post(body: body, url: Api.updateOrderStatusUrl, token: true, errorCode: true);
      return OrderModel.fromJson(result);
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  // To getUserOrderLiveTracking
  Future<OrderLiveTrackingModel> getOrderLiveTracing({String? orderId}) async {
    try {
      //body of post request
      final body = {orderIdKey: orderId};
      final result = await Api.post(body: body, url: Api.getLiveTrackingDetailsUrl, token: true, errorCode: true);
      return OrderLiveTrackingModel.fromJson(result[dataKey][0]);
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }

  // To reOrder
  Future<dynamic> reOrder({String? orderId}) async {
    try {
      // Body of post request
      final body = {orderIdKey: orderId};
      final result = await Api.post(body: body, url: Api.reOrderUrl, token: true, errorCode: true);
      return result;
    } catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e as ApiMessageAndCodeException;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage, errorStatusCode: apiMessageAndCodeException.errorStatusCode);
    }
  }
}
