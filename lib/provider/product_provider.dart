import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/model/product_item.dart';

// 📦 모든 상품 데이터를 쥐고 흔들 마스터 전역 상자
class ProductManagementNotifier extends StateNotifier<List<ProductItem>> {
  ProductManagementNotifier() : super([]); // 초기값으로 기존 데이터 복사

  /// ✨ [1. 상품 업로드 (추가)]
  void uploadProduct(ProductItem newProduct) {
    // 기존 리스트에 새 상품을 더해서 상태를 갱신 (UI 자동 리빌드 트리거)
    state = [newProduct, ...state]; 
  }

  /// 🗑️ [2. 상품 삭제]
  void deleteProduct(String productId) {
    // 해당 ID를 제외한 아이템들로만 리스트를 필터링하여 갱신
    state = state.where((product) => product.id != productId).toList();
  }
  
  /// ✏️ [추가 - 3. 상품 수정 (필요시)]
  void updateProduct(ProductItem updatedProduct) {
    state = state.map((item) => item.id == updatedProduct.id ? updatedProduct : item).toList();
  }
}

// 🌐 외부 위젯들이 구독할 프로바이더 선언
final productManagementProvider = StateNotifierProvider<ProductManagementNotifier, List<ProductItem>>((ref) {
  return ProductManagementNotifier();
});