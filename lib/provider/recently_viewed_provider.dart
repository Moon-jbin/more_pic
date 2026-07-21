import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedNotifier extends StateNotifier<List<ProductModel>> {
  static const _storageKey = 'recently_viewed_products';

  RecentlyViewedNotifier() : super([]) {
    _loadFromStorage(); // 앱/웹 시작 시 기존 데이터 불러오기
  }

  // 1. 기기 저장소에서 불러오기
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        state = jsonList.map((item) => ProductModel.fromJson(item)).toList();
      } catch (e) {
        // 데이터 파싱 에러 예외 처리
        state = [];
      }
    }
  }

  // 2. 기기 저장소에 저장하기
  Future<void> _saveToStorage(List<ProductModel> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // 3. 상품 추가 (최대 5개 유지 및 저장)
  void addProduct(ProductModel product) {
    final filteredList = state.where((p) => p.id != product.id).toList();
    final updatedList = [product, ...filteredList].take(5).toList();

    state = updatedList;
    _saveToStorage(updatedList); // 저장소 반영
  }

  // 4. 개별 삭제
  void removeProduct(int productId) {
    final updatedList = state.where((p) => p.id != productId).toList();
    state = updatedList;
    _saveToStorage(updatedList);
  }

  // 5. 전체 비우기
  void clearAll() {
    state = [];
    _saveToStorage([]);
  }
}

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<ProductModel>>((ref) {
  return RecentlyViewedNotifier();
});