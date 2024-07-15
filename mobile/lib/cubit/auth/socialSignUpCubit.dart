import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/data/model/authModel.dart';
import 'package:wakDak/data/repositories/auth/authRepository.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';

// State
@immutable
abstract class SocialSignUpState {}

class SocialSignUpInitial extends SocialSignUpState {}

class SocialSignUp extends SocialSignUpState {
  //to store authDetails
  final AuthModel authModel;

  SocialSignUp({required this.authModel});
}

class SocialSignUpProgress extends SocialSignUpState {
  SocialSignUpProgress();
}

class SocialSignUpSuccess extends SocialSignUpState {
  final AuthModel authModel;
  final String? message;
  SocialSignUpSuccess({required this.authModel, this.message});
}

class SocialSignUpFailure extends SocialSignUpState {
  final String errorMessage;
  SocialSignUpFailure(this.errorMessage);
}

class SocialSignUpCubit extends Cubit<SocialSignUpState> {
  final AuthRepository _authRepository;
  SocialSignUpCubit(this._authRepository) : super(SocialSignUpInitial());

  // To socialSocialSignUp user
  void socialSocialSignUpUser({
    AuthProviders? authProvider,
    String? friendCode,
    String? referCode,
  }) {
    // socialSocialSignUp user details in api
    _authRepository.signInUser(authProvider!, referCode, friendCode).then((result) {
      print(result);
      // Success
      emit(SocialSignUpSuccess(authModel: AuthModel.fromJson(result[dataKey]), message: result[messageKey]));
    }).catchError((e) {
      // Failure
      emit(SocialSignUpFailure(e.toString()));
    });
  }
}
