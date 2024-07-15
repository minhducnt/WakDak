import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/product/productRepository.dart';
import 'package:wakDak/utils/SqliteData.dart';

// State
@immutable
abstract class OfflineCartState {}

class OfflineCartInitial extends OfflineCartState {}

class OfflineCart extends OfflineCartState {
  final List<ProductDetails> offlineCartList;
  OfflineCart({required this.offlineCartList});
}

class OfflineCartProgress extends OfflineCartState {}

class OfflineCartSuccess extends OfflineCartState {
  final List<ProductDetails> productModel;
  OfflineCartSuccess(this.productModel);
}

class OfflineCartFailure extends OfflineCartState {
  final String errorMessage;
  OfflineCartFailure(this.errorMessage);
}

class OfflineCartCubit extends Cubit<OfflineCartState> {
  final ProductRepository _productRepository;
  OfflineCartCubit(this._productRepository) : super(OfflineCartInitial());

  // To getOfflineCartProduct
  getOfflineCart(
      {/* 
    String? latitude,
    String? longitude,
    String? cityId, */
      String? productVariantIds,
      String? branchId}) {
    //emitting OfflineCartProgress state
    emit(OfflineCartProgress());
    //GetOfflineCart Product
    _productRepository
        .getOfflineCartData(productVariantIds, branchId)
        .then((value) => emit(OfflineCartSuccess(
            value)))
        .catchError((e) {
      emit(OfflineCartFailure(e.toString()));
    });
  }

  List<ProductDetails> getOfflineCartModel() {
    if (state is OfflineCartSuccess) {
      return (state as OfflineCartSuccess).productModel;
    }
    return [];
  }

  void updateOfflineCartList(List<ProductDetails> productModel) {
    emit(OfflineCartSuccess(productModel));
  }

  void updateQuantity(ProductDetails productDetails, String? qty, String? varianceId) {
    if (state is OfflineCartSuccess) {
      List<ProductDetails> currentProduct = (state as OfflineCartSuccess).productModel;
      int i = currentProduct.indexWhere((element) => (element.id == productDetails.id));
      int j;
      if (i == -1) {
        currentProduct.insert(0, productDetails);
        int k = currentProduct.indexWhere((element) => (element.id == productDetails.id));
        j = currentProduct[k].variants!.indexWhere((element) => (element.id == varianceId));
        currentProduct[k].variants![j].cartCount = qty;
      } else {
        j = currentProduct[i].variants!.indexWhere((element) => (element.id == varianceId));
        currentProduct[i].variants![j].cartCount = qty;
      }
      emit(OfflineCartSuccess(currentProduct));
    }
  }

  Future<List<String>> AddOnsList(String id, ProductDetails productDetails, BuildContext context) async {
    if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
      var db = DatabaseHelper();
      List<String> addOnsList = [];
      Map? productVariants;
      List<String>? productVariantIds = [];
      productVariants = (await db.getCart());
      productVariantIds = productVariants['VID'];
      for (int j = 0; j < productDetails.variants!.length; j++) {
        if (productVariantIds!.contains(productDetails.variants![j].id)) {
          List<String> addOnsListIds = (await db.getVariantItemData(productDetails.id!, productDetails.variants![j].id!))!;
          addOnsList.addAll(addOnsListIds);
        }
      }
      return addOnsList;
    }
    return [];
  }

  void clearOfflineCartModel() {
    if (state is OfflineCartSuccess) {
      emit(OfflineCartInitial());
    }
  }
}
