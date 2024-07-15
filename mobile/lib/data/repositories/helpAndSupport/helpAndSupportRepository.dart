import 'package:wakDak/data/model/helpAndSupportModel.dart';
import 'package:wakDak/data/repositories/helpAndSupport/helpAndSupportRemoteDataSource.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class HelpAndSupportRepository {
  static final HelpAndSupportRepository _helpAndSupportRepository = HelpAndSupportRepository._internal();
  late HelpAndSupportRemoteDataSource _helpAndSupportRemoteDataSource;

  factory HelpAndSupportRepository() {
    _helpAndSupportRepository._helpAndSupportRemoteDataSource = HelpAndSupportRemoteDataSource();
    return _helpAndSupportRepository;
  }

  HelpAndSupportRepository._internal();

  Future<List<HelpAndSupportModel>> getHelpAndSupport() async {
    try {
      List<HelpAndSupportModel> result = await _helpAndSupportRemoteDataSource.getHelpAndSupport();
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  Future getAddTicket(String? ticketTypeId, String? subject, String? email, String? description, String? userId) async {
    try {
      final result = await _helpAndSupportRemoteDataSource.getAddTicket(ticketTypeId, subject, email, description, userId);
      return result;
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future getEditTicket(
      String? ticketId, String? ticketTypeId, String? subject, String? email, String? description, String? userId, String? status) async {
    try {
      final result = await _helpAndSupportRemoteDataSource.getEditTicket(ticketId, ticketTypeId, subject, email, description, userId, status);
      return result;
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
