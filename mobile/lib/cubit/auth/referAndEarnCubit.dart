import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/repositories/auth/authRepository.dart';

abstract class ReferAndEarnState {}

class ReferAndEarnInitial extends ReferAndEarnState {}

class ReferAndEarnProgress extends ReferAndEarnState {}

class ReferAndEarnSuccess extends ReferAndEarnState {
  final String? referCode;

  ReferAndEarnSuccess(this.referCode);
}

class ReferAndEarnFailure extends ReferAndEarnState {
  final String errorCode;

  ReferAndEarnFailure(this.errorCode);
}

class ReferAndEarnCubit extends Cubit<ReferAndEarnState> {
  final AuthRepository _authRepository;

  ReferAndEarnCubit(this._authRepository) : super(ReferAndEarnInitial());

  fetchReferAndEarn(String? referCode) {
    emit(ReferAndEarnProgress());
    _authRepository.geReferAndEarn(referCode).then((value) => emit(ReferAndEarnSuccess(value))).catchError((e) {
      emit(ReferAndEarnFailure(e.toString()));
    });
  }

  String getReferAndEarn() {
    if (state is ReferAndEarnSuccess) {
      return (state as ReferAndEarnSuccess).referCode!;
    }
    return "";
  }
}
