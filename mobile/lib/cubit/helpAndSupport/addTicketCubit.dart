import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/ticketModel.dart';
import 'package:wakDak/data/repositories/helpAndSupport/helpAndSupportRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class AddTicketState {}

class AddTicketInitial extends AddTicketState {}

class AddTicketProgress extends AddTicketState {}

class AddTicketSuccess extends AddTicketState {
  final TicketModel ticketModel;

  AddTicketSuccess(this.ticketModel);
}

class AddTicketFailure extends AddTicketState {
  final String errorCode, errorStatusCode;
  AddTicketFailure(this.errorCode, this.errorStatusCode);
}

class AddTicketCubit extends Cubit<AddTicketState> {
  final HelpAndSupportRepository _helpAndSupportRepository;

  AddTicketCubit(this._helpAndSupportRepository) : super(AddTicketInitial());

  void fetchAddTicket(String? ticketTypeId, String? subject, String? email, String? description, String? userId) {
    emit(AddTicketProgress());
    _helpAndSupportRepository.getAddTicket(ticketTypeId, subject, email, description, userId).then((value) {
      emit(AddTicketSuccess(TicketModel.fromJson(value[0])));
    }).catchError((e) {
      print(e.toString());
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(AddTicketFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
