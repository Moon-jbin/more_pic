import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/product_db_provider.dart';

final searchBarOpenProvider =
    NotifierProvider<SearchBarOpenNotifier, bool>(SearchBarOpenNotifier.new);
final searchListenerProvider =
    NotifierProvider<SearchListenerProvider, int>(SearchListenerProvider.new);
final globalSearchProvider =
    NotifierProvider<GlobalSearchNotifier, List<ProductModel>>(
        GlobalSearchNotifier.new);
final searchContentProvider =
    NotifierProvider<SearchContentProvider, SearchContent>(
        SearchContentProvider.new);

// 검색창이 열려있는지 여부만 관리하는 간단한 Notifier
class SearchBarOpenNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // 초기 상태는 닫힘
  }

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

// class GlobalSearchNotifier extends Notifier<List<ProductItem>> {
//   @override
//   List<ProductItem> build() {
//     return []; // 검색어 입력 전에는 빈 결과 리스트
//   }

//   void filterProducts(String query) {
//     if (query.trim().isEmpty) {
//       state = [];
//       return;
//     }

//     // 💡 [전역 확장]: 특정 카테고리가 아닌, 쇼핑몰 전체 상품(allProducts)에서 검색합니다.
//     state = allProducts.where((product) {
//       return product.name.toLowerCase().contains(query.toLowerCase());
//     }).toList();
//   }

//   void clearSearch() => state = [];
// }

// // 🌍 언제 어디서나 호출 가능한 전역 검색 프로바이더
// final globalSearchProvider = NotifierProvider<GlobalSearchNotifier, List<ProductItem>>(GlobalSearchNotifier.new);

class GlobalSearchNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() {
    return [];
  }

  // 💡 핵심 수정: 검색어(query)와 함께 현재 페이지의 원본 데이터 리스트(targetList)를 받습니다.
  void filterProducts(
      {required String query, required List<ProductModel> targetList}) {
    if (query.trim().isEmpty) {
      state = [];
      return;
    }

    // 주입받은 특정 페이지 데이터 안에서만 핥아서 필터링합니다. (타 페이지 간섭 0%)
    state = targetList.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  ///```
  /// 전체 데이터 받아오기
  ///```
  void allProductsFn(List<ProductModel> targetList) {
    state = targetList;
  }

  void clearSearch() => state = [];
}

class SearchListenerProvider extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  ///```
  /// 검색창 -> 페이지네이션 hide (1)
  ///```
  void workListener(int value) {
    state = value;
  }

  void stopListener() => state = 0;
}

class SearchContentProvider extends Notifier<SearchContent> {
  @override
  SearchContent build() {
    return const SearchContent(searchContent: '', page: 1);
  }

  void setState(SearchContent searchContent) {
    state = searchContent;
  }

  void initState() {
    state = const SearchContent(searchContent: '', page: 1);
  }
}
