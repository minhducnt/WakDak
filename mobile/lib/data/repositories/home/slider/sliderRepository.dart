import 'package:wakDak/data/model/sliderModel.dart';
import 'package:wakDak/data/repositories/home/slider/sliderRemoteDataSource.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class SliderRepository {
  static final SliderRepository _sliderRepository = SliderRepository._internal();
  late SliderRemoteDataSource _sliderRemoteDataSource;

  factory SliderRepository() {
    _sliderRepository._sliderRemoteDataSource = SliderRemoteDataSource();
    return _sliderRepository;
  }

  SliderRepository._internal();

  Future<List<SliderModel>> getSlider(String? branchId) async {
    try {
      List<SliderModel> result = await _sliderRemoteDataSource.getSlider(branchId);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
