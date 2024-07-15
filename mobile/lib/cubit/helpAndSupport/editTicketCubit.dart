import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/ticketModel.dart';
import 'package:wakDak/data/repositories/helpAndSupport/helpAndSupportRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class EditTicketState {}

class EditTicketInitial extends EditTicketState {}

class EditTicketProgress extends EditTicketState {}

class EditTicketSuccess extends EditTicketState {
  final TicketModel ticketModel;

  EditTicketSuccess(this.ticketModel);
}

class EditTicketFailure extends EditTicketState {
  final String errorCode, errorStatusCode;
  EditTicketFailure(this.errorCode, this.errorStatusCode);
}

class EditTicketCubit extends Cubit<EditTicketState> {
  final HelpAndSupportRepository _helpAndSupportRepository;

  EditTicketCubit(this._helpAndSupportRepository) : super(EditTicketInitial());

  void fetchEditTicket(String? ticketId, String? ticketTypeId, String? subject, String? email, String? description, String? userId, String? status) {
    emit(EditTicketProgress());
    _helpAndSupportRepository
        .getEditTicket(ticketId, ticketTypeId, subject, email, description, userId, status)
        .then((value) => emit(EditTicketSuccess(TicketModel.fromJson(value[0]))))
        .catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(EditTicketFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
