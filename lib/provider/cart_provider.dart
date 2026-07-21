import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:more_pic/model/cart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _loadCart();
  }

  static const _cartKey = 'saved_cart_items';

  // 1. 저장된 장바구니 불러오기
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartStrings = prefs.getStringList(_cartKey) ?? [];
    
    state = cartStrings.map((item) => CartItem.fromJson(item)).toList();
  }

  // 2. 장바구니 로컬에 저장하기
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartStrings = state.map((item) => item.toJson()).toList();
    await prefs.setStringList(_cartKey, cartStrings);
  }

  // 3. 상품 추가 (이미 있으면 수량만 증가)
  void addItem(CartItem item) {
    final existingIndex = state.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity + item.quantity),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, item];
    }
    _saveCart();
  }

  // 4. 수량 업데이트
  void updateQuantity(String id, int newQuantity) {
    if (newQuantity < 1) return;
    state = state.map((item) => item.id == id ? item.copyWith(quantity: newQuantity) : item).toList();
    _saveCart();
  }

  // 5. 상품 삭제
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveCart();
  }

  // 6. 장바구니 비우기 (주문 완료 후 호출)
  void clearCart() {
    state = [];
    _saveCart();
  }

  // 💡 총 상품 금액 계산기
  int get totalItemPrice {
    return state.fold(0, (total, item) => total + (item.price * item.quantity));
  }
}