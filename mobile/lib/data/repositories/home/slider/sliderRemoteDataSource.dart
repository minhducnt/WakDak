import 'package:wakDak/data/model/sliderModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class SliderRemoteDataSource {
  Future<List<SliderModel>> getSlider(String? branchId) async {
    try {
      final body = {branchIdKey: branchId};
      final result = await Api.post(body: body, url: Api.getSliderImagesUrl, token: true, errorCode: false);
      return (result[dataKey] as List).map((e) => SliderModel.fromJson(Map.from(e))).toList();
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
