import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/authModel.dart';
import 'package:wakDak/data/repositories/auth/authRepository.dart';

// State
@immutable
abstract class SignInState {}

class SignInInitial extends SignInState {}

class SignIn extends SignInState {
  //to store authDetails
  final AuthModel authModel;

  SignIn({required this.authModel});
}

class SignInProgress extends SignInState {
  SignInProgress();
}

class SignInSuccess extends SignInState {
  final AuthModel authModel;
  SignInSuccess(this.authModel);
}

class SignInFailure extends SignInState {
  final String errorMessage;
  SignInFailure(this.errorMessage);
}

class SignInCubit extends Cubit<SignInState> {
  final AuthRepository _authRepository;
  SignInCubit(this._authRepository) : super(SignInInitial());

  //to signIn user
  void signInUser({
    String? mobile,
  }) {
    //emitting signInProgress state
    emit(SignInProgress());
    //signIn user with given provider and also add user details in api
    _authRepository
        .login(
      mobile: mobile,
    )
        .then((result) {
      //success
      emit(SignInSuccess(AuthModel.fromJson(result)));
    }).catchError((e) {
      //failure
      emit(SignInFailure(e.toString()));
    });
  }
}
