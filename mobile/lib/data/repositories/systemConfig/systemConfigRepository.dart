import 'package:wakDak/data/model/settingModel.dart';
import 'package:wakDak/data/repositories/systemConfig/systemConfigRemoteDataSource.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class SystemConfigRepository {
  static final SystemConfigRepository _systemConfigRepository = SystemConfigRepository._internal();
  late SystemConfigRemoteDataSource _systemConfigRemoteDataSource;

  factory SystemConfigRepository() {
    _systemConfigRepository._systemConfigRemoteDataSource = SystemConfigRemoteDataSource();
    return _systemConfigRepository;
  }

  SystemConfigRepository._internal();

  Future<SettingModel> getSystemConfig(String? userId) async {
    try {
      SettingModel result = await _systemConfigRemoteDataSource.getSystemConfig(userId);
      print(result);
      return result;
    } catch (e) {
      print("error: ${e.toString()}");
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  Future<String> getAppSettings(String type) async {
    try {
      final result = await _systemConfigRemoteDataSource.getAppSettings(type);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
