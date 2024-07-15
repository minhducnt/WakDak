import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/repositories/address/addressRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class DeliveryChargeState {}

class DeliveryChargeInitial extends DeliveryChargeState {}

class DeliveryChargeProgress extends DeliveryChargeState {}

class DeliveryChargeSuccess extends DeliveryChargeState {
  final String? userId, addressId, deliveryCharge;

  DeliveryChargeSuccess(this.userId, this.addressId, this.deliveryCharge);
}

class DeliveryChargeFailure extends DeliveryChargeState {
  final String errorStatusCode, errorMessage;
  DeliveryChargeFailure(this.errorMessage, this.errorStatusCode);
}

class DeliveryChargeCubit extends Cubit<DeliveryChargeState> {
  final AddressRepository _addressRepository;

  DeliveryChargeCubit(this._addressRepository) : super(DeliveryChargeInitial());

  fetchDeliveryCharge(String? userId, String? addressId) {
    emit(DeliveryChargeProgress());
    _addressRepository.getDeliveryCharge(userId, addressId).then((value) => emit(DeliveryChargeSuccess(userId, addressId, value))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(DeliveryChargeFailure(apiMessageAndCodeException.errorMessage, apiMessageAndCodeException.errorStatusCode!));
    });
  }

  String getDeliveryCharge() {
    if (state is DeliveryChargeSuccess) {
      return (state as DeliveryChargeSuccess).deliveryCharge!;
    }
    return "";
  }
}
