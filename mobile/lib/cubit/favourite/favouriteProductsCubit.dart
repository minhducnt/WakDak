import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/repositories/favourite/favouriteRepository.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';

abstract class FavoriteProductsState {}

class FavoriteProductsInitial extends FavoriteProductsState {}

class FavoriteProductsFetchInProgress extends FavoriteProductsState {}

class FavoriteProductsFetchSuccess extends FavoriteProductsState {
  final List<ProductDetails> favoriteProducts;

  FavoriteProductsFetchSuccess(this.favoriteProducts);
}

class FavoriteProductsFetchFailure extends FavoriteProductsState {
  final String errorMessage, errorStatusCode;
  FavoriteProductsFetchFailure(this.errorMessage, this.errorStatusCode);
}

class FavoriteProductsCubit extends Cubit<FavoriteProductsState> {
  late FavouriteRepository favoriteRepository;
  FavoriteProductsCubit() : super(FavoriteProductsInitial()) {
    favoriteRepository = FavouriteRepository();
  }

  getFavoriteProducts(String? userId, String? type, String? branchId) {
    emit(FavoriteProductsFetchInProgress());

    favoriteRepository.getFavoriteProducts(userId, type, branchId).then((value) {
      emit(FavoriteProductsFetchSuccess(value));
    }).catchError((e) {
      ApiMessageAndCodeException favouriteException = e;
      if (e.toString() == "No Favourite(s) Product Added.") {
        emit(FavoriteProductsFetchSuccess([]));
      } else {
        emit(FavoriteProductsFetchFailure(favouriteException.errorMessage.toString(), favouriteException.errorStatusCode.toString()));
      }
    });
  }

  void addFavoriteProduct(ProductDetails productDetails) {
    if (state is FavoriteProductsFetchSuccess) {
      final favoriteProducts = (state as FavoriteProductsFetchSuccess).favoriteProducts;
      favoriteProducts.insert(0, productDetails);
      emit(FavoriteProductsFetchSuccess(List.from(favoriteProducts)));
    }
  }

  // Can pass only product id here
  void removeFavoriteProduct(ProductDetails productDetails) {
    if (state is FavoriteProductsFetchSuccess) {
      final favoriteProducts = (state as FavoriteProductsFetchSuccess).favoriteProducts;
      favoriteProducts.removeWhere(((element) => element.id == productDetails.id));
      emit(FavoriteProductsFetchSuccess(List.from(favoriteProducts)));
    }
  }

  bool isProductFavorite(String productId) {
    if (state is FavoriteProductsFetchSuccess) {
      final favoriteProducts = (state as FavoriteProductsFetchSuccess).favoriteProducts;
      return favoriteProducts.indexWhere((element) => element.id == productId) != -1;
    }
    return false;
  }
}
