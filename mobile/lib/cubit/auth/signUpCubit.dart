import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/authModel.dart';
import 'package:wakDak/data/repositories/auth/authRepository.dart';

// State
@immutable
abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUp extends SignUpState {
  // To store authDetails
  final AuthModel authModel;

  SignUp({required this.authModel});
}

class SignUpProgress extends SignUpState {
  SignUpProgress();
}

class SignUpSuccess extends SignUpState {
  final AuthModel authModel;
  final String? message;
  SignUpSuccess({required this.authModel, this.message});
}

class SignUpFailure extends SignUpState {
  final String errorMessage;
  SignUpFailure(this.errorMessage);
}

class SignUpCubit extends Cubit<SignUpState> {
  final AuthRepository _authRepository;
  SignUpCubit(this._authRepository) : super(SignUpInitial());

  // To signUp user
  void signUpUser({
    String? name,
    String? email,
    String? mobile,
    String? countryCode,
    String? fcmId,
    String? friendCode,
    String? referCode,
  }) {
    // signUp user with given provider and also add user details in api
    _authRepository
        .addUserData(
      name: name,
      email: email,
      mobile: mobile,
      countryCode: countryCode ?? "",
      fcmId: fcmId ?? "",
      friendCode: friendCode ?? "",
      referCode: referCode ?? "",
    )
        .then((result) {
      // Success
      emit(SignUpSuccess(authModel: AuthModel.fromJson(result)));
    }).catchError((e) {
      // Failure
      emit(SignUpFailure(e.toString()));
    });
  }
}
