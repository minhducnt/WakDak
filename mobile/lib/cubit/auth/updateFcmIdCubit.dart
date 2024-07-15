import 'package:flutter/material.dart';
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:wakDak/data/repositories/auth/authRepository.dart';

// State
@immutable
abstract class UpdateFcmIdState {}

class UpdateFcmIdInitial extends UpdateFcmIdState {}

class UpdateFcmId extends UpdateFcmIdState {
  // To update fcmId
  final String? userId, fcmId;

  UpdateFcmId({this.userId, this.fcmId});
}

class UpdateFcmIdProgress extends UpdateFcmIdState {
  UpdateFcmIdProgress();
}

class UpdateFcmIdSuccess extends UpdateFcmIdState {
  UpdateFcmIdSuccess();
}

class UpdateFcmIdFailure extends UpdateFcmIdState {
  final String errorMessage;
  UpdateFcmIdFailure(this.errorMessage);
}

class UpdateFcmIdCubit extends Cubit<UpdateFcmIdState> {
  final AuthRepository _authRepository;
  UpdateFcmIdCubit(this._authRepository) : super(UpdateFcmIdInitial());

  // To update fcmId
  void updateFcmId({
    String? userId,
    String? fcmId,
  }) {
    // Emitting updateFcmIdProgress state
    emit(UpdateFcmIdProgress());
    // Update fcmId of user with given provider and also update user fcmId in api
    _authRepository
        .updateFcmId(
      userId: userId,
      fcmId: fcmId,
    )
        .then((result) {
      // Success
      emit(UpdateFcmIdSuccess());
    }).catchError((e) {
      // Failure
      emit(UpdateFcmIdFailure(e.toString()));
    });
  }
}
