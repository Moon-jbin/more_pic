import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            color: color,
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

class ProductModel {
  final String id;
  final String name;
  final int price;
  final String categoryName;
  final List<String> images;
  final String size; // 🌟 새롭게 추가
  final String color; // 🌟 새롭게 추가

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryName,
    required this.images,
    required this.size, // 🌟 추가
    required this.color, // 🌟 추가
  });

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      categoryName: data['categoryName'] ?? 'all',
      images: List<String>.from(data['images'] ?? []),
      size: data['size'] ?? '', // 🌟 Firestore 데이터 매핑 안전 처리
      color: data['color'] ?? '', // 🌟 Firestore 데이터 매핑 안전 처리
    );
  }
}

// 📦 페이지네이션 상태를 담을 가방
class PaginationState {
  final List<ProductModel> items;
  final bool hasMore; // 더 가져올 데이터가 남아있는지 여부
  final DocumentSnapshot? lastDoc; // 다음 10개를 긁어오기 위한 기준점 좌표

  PaginationState({required this.items, required this.hasMore, this.lastDoc});
}

// 🎯 [10개씩 끊어 읽는 파이어베이스 페이지네이션 엔진]
class PaginatedProductNotifier
    extends FamilyAsyncNotifier<PaginationState, String> {
  final int _limit = 10; // 🌟 유저님 요청: 딱 10개씩 스캔

  @override
  Future<PaginationState> build(String arg) async {
    print('==================================================');
    print('🔄 [무한스크롤 엔진] 1페이지 최초 구동! (카테고리: $arg)');
    print('==================================================');
    // 최초 1단계: 첫 10개 데이터 탑재
    Query query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(_limit);

    if (arg != 'all') {
      query = query.where('categoryName', isEqualTo: arg);
    }

    final snapshot = await query.get();

    final items =
        snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length == _limit;

    print('📥 [1페이지 로드 완료] 가져온 아이템 개수: ${items.length}개');
    if (items.isNotEmpty) {
      print('📌 첫 번째 아이템: ${items.first.name} | 마지막 아이템: ${items.last.name}');
    }
    print('➕ 다음 페이지 존재 여부(hasMore): $hasMore');
    print('--------------------------------------------------\n');

    return PaginationState(items: items, hasMore: hasMore, lastDoc: lastDoc);
  }

  // 🚀 [바닥 쳤을 때 다음 10개 낚아채는 함수]
  Future<void> fetchNextPage() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading)
      return;

    // 추가 로드 중임을 알림
    // state = const AsyncLoading();
    // 🌟 [핵심 가드]: 기존 데이터를 가방에 그대로 둔 채로, 백그라운드 로딩 상태로만 전환합니다!
    state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);

    await AsyncValue.guard(() async {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(currentState.lastDoc!)
          .limit(_limit);

      if (arg != 'all') {
        query = query.where('categoryName', isEqualTo: arg);
      }

      final snapshot = await query.get();
      final newItems =
          snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == _limit;

      // 📊 추가 로드 검증 로그
      print('✨ [추가 페이지 로드 완료] 이번에 새로 긁어온 개수: ${newItems.length}개');
      if (newItems.isNotEmpty) {
        print(
            '📌 새 조각 첫 아이템: ${newItems.first.name} | 새 조각 마지막 아이템: ${newItems.last.name}');
      }

      final totalCount = currentState.items.length + newItems.length;
      print('📦 가방에 합체된 총 아이템 개수: $totalCount개');
      print('➕ 다음 페이지 또 있냐?(hasMore): $hasMore');
      print('--------------------------------------------------\n');

      state = AsyncValue.data(PaginationState(
        items: [...currentState.items, ...newItems], // 기존 템 + 새 조각 10개 합체
        hasMore: hasMore,
        lastDoc: lastDoc,
      ));
    });
  }
}

// 💡 전역 프로바이더 도킹 완료
final paginatedProductProvider = AsyncNotifierProviderFamily<
    PaginatedProductNotifier, PaginationState, String>(() {
  return PaginatedProductNotifier();
});
