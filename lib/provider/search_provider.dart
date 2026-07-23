import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// 검색 로딩 상태
final isSearchingProvider = StateProvider<bool>((ref) => false);

final globalMenuProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('system_settings')
      .doc('menu_config')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return [];
    final List<dynamic> rawMenus = snapshot.data()!['menus'] ?? [];
    return rawMenus.map((item) => Map<String, dynamic>.from(item)).toList();
  });
});

class SearchBarOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

class GlobalSearchNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() => [];

  // 📌 DB 전체 미니 사전 기반 실시간 검색 트리거
  Future<void> performDbSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      state = [];
      return;
    }

    ref.read(isSearchingProvider.notifier).state = true;
    try {
      final repo = ref.read(productRepositoryProvider);
      final results = await repo.searchProductsFromIndex(cleanQuery);
      state = results;
    } catch (e) {
      print("검색 에러: $e");
      state = [];
    } finally {
      ref.read(isSearchingProvider.notifier).state = false;
    }
  }

  void clearSearch() => state = [];
}

class SearchListenerProvider extends Notifier<int> {
  @override
  int build() => 0;
  void workListener(int value) => state = value;
  void stopListener() => state = 0;
}

class SearchContentProvider extends Notifier<SearchContent> {
  @override
  SearchContent build() => const SearchContent(searchContent: '', page: 1);
  void setState(SearchContent searchContent) => state = searchContent;
  void initState() => state = const SearchContent(searchContent: '', page: 1);
}

Future<void> updateRemoteMenuTree(
    List<Map<String, dynamic>> newMenuTree) async {
  await FirebaseFirestore.instance
      .collection('system_settings')
      .doc('menu_config')
      .set({'menus': newMenuTree});
}