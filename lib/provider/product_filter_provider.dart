import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ProductSortOption {
  newest('신상품순'),
  priceLow('낮은 가격순'),
  priceHigh('높은 가격순'),
  name('상품명순');

  final String label;
  const ProductSortOption(this.label);
}

class ProductFilterState {
  final ProductSortOption sortOption;
  final bool onlyInStock;

  ProductFilterState({
    this.sortOption = ProductSortOption.newest,
    this.onlyInStock = false,
  });

  ProductFilterState copyWith({
    ProductSortOption? sortOption,
    bool? onlyInStock,
  }) {
    return ProductFilterState(
      sortOption: sortOption ?? this.sortOption,
      onlyInStock: onlyInStock ?? this.onlyInStock,
    );
  }
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilterState>(ProductFilterNotifier.new);

class ProductFilterNotifier extends Notifier<ProductFilterState> {
  @override
  ProductFilterState build() {
    return ProductFilterState();
  }

  void setSortOption(ProductSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void toggleOnlyInStock() {
    state = state.copyWith(onlyInStock: !state.onlyInStock);
  }

  void resetFilters() {
    state = ProductFilterState();
  }
}