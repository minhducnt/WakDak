import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/authModel.dart';
import 'package:wakDak/data/repositories/profileManagement/profileManagementRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

@immutable
abstract class UpdateUserDetailState {}

class UpdateUserDetailInitial extends UpdateUserDetailState {}

class UpdateUserDetailInProgress extends UpdateUserDetailState {}

class UpdateUserDetailSuccess extends UpdateUserDetailState {
  final AuthModel authModel;
  UpdateUserDetailSuccess(this.authModel);
}

class UpdateUserDetailFailure extends UpdateUserDetailState {
  final String errorMessage, errorStatusCode;
  UpdateUserDetailFailure(this.errorMessage, this.errorStatusCode);
}

class UpdateUserDetailCubit extends Cubit<UpdateUserDetailState> {
  final ProfileManagementRepository _profileManagementRepository;

  UpdateUserDetailCubit(this._profileManagementRepository) : super(UpdateUserDetailInitial());

  void updateProfile({String? userId, String? email, String? name, String? mobile, String? referralCode}) async {
    emit(UpdateUserDetailInProgress());
    _profileManagementRepository
        .updateProfile(
      userId: userId,
      name: name,
      email: email,
      mobile: mobile,
      referralCode: referralCode,
    )
        .then((value) {
      emit(UpdateUserDetailSuccess(AuthModel(id: userId, email: email, username: name, mobile: mobile, referralCode: referralCode)));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(UpdateUserDetailFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
