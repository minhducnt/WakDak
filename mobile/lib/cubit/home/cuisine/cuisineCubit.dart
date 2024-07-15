import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/cuisineModel.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageException.dart';

@immutable
abstract class CuisineState {}

class CuisineInitial extends CuisineState {}

class CuisineProgress extends CuisineState {}

class CuisineSuccess extends CuisineState {
  final List<CuisineModel> cuisineList;
  final int totalData;
  final bool hasMore;
  CuisineSuccess(this.cuisineList, this.totalData, this.hasMore);
}

class CuisineFailure extends CuisineState {
  final String errorMessage;
  CuisineFailure(this.errorMessage);
}

String? totalHasMore;

class CuisineCubit extends Cubit<CuisineState> {
  CuisineCubit() : super(CuisineInitial());
  Future<List<CuisineModel>> _fetchData({
    required String limit,
    String? offset,
    required String? type,
    String? branchId,
  }) async {
    try {
      // Body of post request
      final body = {
        limitKey: limit,
        offsetKey: offset ?? "",
      };
      if (offset == null) {
        body.remove(offset);
      }
      if (branchId != null) {
        body[branchIdKey] = branchId;
      }
      final result = await Api.post(body: body, url: Api.getCategoriesUrl, token: true, errorCode: false);
      totalHasMore = result[totalKey].toString();
      if (type == popularCategoriesKey) {
        return (result['popular_categories'] as List).map((e) => CuisineModel.fromJson(e)).toList();
      } else {
        return (result[dataKey] as List).map((e) => CuisineModel.fromJson(e)).toList();
      }
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  void fetchCuisine(String limit, String type, String branchId) {
    emit(CuisineProgress());
    _fetchData(limit: limit, type: type, branchId: branchId).then((value) {
      final List<CuisineModel> usersDetails = value;
      final total = int.parse(totalHasMore!);
      emit(CuisineSuccess(
        usersDetails,
        total,
        total > usersDetails.length,
      ));
    }).catchError((e) {
      emit(CuisineFailure(e.toString()));
    });
  }

  void fetchMoreCuisineData(String limit, String type, String branchId) {
    _fetchData(limit: limit, offset: (state as CuisineSuccess).cuisineList.length.toString(), type: type, branchId: branchId).then((value) {
      final oldState = (state as CuisineSuccess);
      final List<CuisineModel> usersDetails = value;
      final List<CuisineModel> updatedUserDetails = List.from(oldState.cuisineList);
      updatedUserDetails.addAll(usersDetails);
      emit(CuisineSuccess(updatedUserDetails, oldState.totalData, oldState.totalData > updatedUserDetails.length));
    }).catchError((e) {
      emit(CuisineFailure(e.toString()));
    });
  }

  bool hasMoreData() {
    if (state is CuisineSuccess) {
      return (state as CuisineSuccess).hasMore;
    } else {
      return false;
    }
  }

  List<CuisineModel> cuisineList() {
    if (state is CuisineSuccess) {
      return (state as CuisineSuccess).cuisineList;
    } else {
      return [];
    }
  }
}
