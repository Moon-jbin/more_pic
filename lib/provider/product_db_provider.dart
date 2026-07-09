import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // 💡 File 대신 XFile 규격을 쓰기 위해 추가
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/model/product_item.dart';

// 💡 Family 패턴을 사용해 카테고리 문자열('inner', 'sale' 등)별로 각각 독자적인 비동기 상자를 관리합니다.
class ProductDatabaseNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ProductItem>, String> {
  @override
  FutureOr<List<ProductItem>> build(String arg) {
    // 이 카테고리 창고가 열리면 자동으로 파이어베이스 DB를 호출해서 데이터를 수신합니다.
    return ref.read(productRepositoryProvider).fetchProductsByCategory(arg);
  }

  /// ✨ [최종 진화형] 서버 전송 시 진행률 피드백(Progress)을 UI에 중계해주는 액션
  Future<void> uploadProduct({
    required String name,
    required int price,
    required String size,
    required String productDetail,
    required String color,
    required String sh,
    required String shippingType,
    required String shippingMethod,
    required List<XFile> imageFiles,
    required Function(double, String) onProgress, // 👈 UI로부터 진행률 콜백을 넘겨받습니다!
  }) async {
    state = const AsyncValue.loading(); // UI에 먼저 로딩 스피너 돌리기
    state = await AsyncValue.guard(() async {
      // 💡 고도화된 리포지토리의 함수를 호출하며, 넘겨받은 콜백을 그대로 배달(토스)합니다.
      await ref.read(productRepositoryProvider).uploadFullProduct(
            name: name,
            price: price,
            category: arg, // 현재 패밀리 카테고리 문자열('inner' 등)이 자동으로 들어갑니다.
            size: size,
            productDetail: productDetail,
            color : color,
            shippingMethod: shippingMethod,
            shippingType: shippingType,
            imageFiles: imageFiles,
            onProgress: onProgress, // 👈 리포지토리로 완벽하게 토스! 🎯
          );

      ref.invalidateSelf(); // 상자를 새로고침하여 파이어베이스 최신 목록으로 화면 갱신!
      return future;
    });
  }

  /// 🗑️ 상품 삭제 액션
  Future<void> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).deleteProductFromDB(productId);
      ref.invalidateSelf(); // 삭제 반영 후 상자 새로고침!
      return future;
    });
  }
}

// 🌐 동적 패밀리 비동기 프로바이더 오픈
final productDBProvider = AsyncNotifierProvider.family
    .autoDispose<ProductDatabaseNotifier, List<ProductItem>, String>(() {
  return ProductDatabaseNotifier();
});
