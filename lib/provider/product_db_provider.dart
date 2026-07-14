// // import 'dart:async';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:hooks_riverpod/hooks_riverpod.dart';
// // import 'package:image_picker/image_picker.dart'; // 💡 File 대신 XFile 규격을 쓰기 위해 추가
// // import 'package:more_pic/db/product_repository.dart';
// // import 'package:more_pic/model/product_item.dart';

// // // 💡 Family 패턴을 사용해 카테고리 문자열('inner', 'sale' 등)별로 각각 독자적인 비동기 상자를 관리합니다.
// // class ProductDatabaseNotifier
// //     extends AutoDisposeFamilyAsyncNotifier<List<ProductItem>, String> {
// //   @override
// //   FutureOr<List<ProductItem>> build(String arg) {
// //     // 이 카테고리 창고가 열리면 자동으로 파이어베이스 DB를 호출해서 데이터를 수신합니다.
// //     return ref.read(productRepositoryProvider).fetchProductsByCategory(arg);
// //   }

// //   /// ✨ [최종 진화형] 서버 전송 시 진행률 피드백(Progress)을 UI에 중계해주는 액션
// //   Future<void> uploadProduct({
// //     required String name,
// //     required int price,
// //     required String size,
// //     required String productDetail,
// //     required String color,
// //     required String sh,
// //     required String shippingType,
// //     required String shippingMethod,
// //     required List<XFile> imageFiles,
// //     required Function(double, String) onProgress, // 👈 UI로부터 진행률 콜백을 넘겨받습니다!
// //   }) async {
// //     state = const AsyncValue.loading(); // UI에 먼저 로딩 스피너 돌리기
// //     state = await AsyncValue.guard(() async {
// //       // 💡 고도화된 리포지토리의 함수를 호출하며, 넘겨받은 콜백을 그대로 배달(토스)합니다.
// //       await ref.read(productRepositoryProvider).uploadFullProduct(
// //             name: name,
// //             price: price,
// //             category: arg, // 현재 패밀리 카테고리 문자열('inner' 등)이 자동으로 들어갑니다.
// //             size: size,
// //             productDetail: productDetail,
// //             color: color,
// //             shippingMethod: shippingMethod,
// //             shippingType: shippingType,
// //             imageFiles: imageFiles,
// //             onProgress: onProgress, // 👈 리포지토리로 완벽하게 토스! 🎯
// //           );

// //       ref.invalidateSelf(); // 상자를 새로고침하여 파이어베이스 최신 목록으로 화면 갱신!
// //       return future;
// //     });
// //   }

// //   /// 🗑️ 상품 삭제 액션
// //   Future<void> deleteProduct(String productId) async {
// //     state = const AsyncValue.loading();
// //     state = await AsyncValue.guard(() async {
// //       await ref.read(productRepositoryProvider).deleteProductFromDB(productId);
// //       ref.invalidateSelf(); // 삭제 반영 후 상자 새로고침!
// //       return future;
// //     });
// //   }
// // }

// // // 🌐 동적 패밀리 비동기 프로바이더 오픈
// // final productDBProvider = AsyncNotifierProvider.family
// //     .autoDispose<ProductDatabaseNotifier, List<ProductItem>, String>(() {
// //   return ProductDatabaseNotifier();
// // });

// // class ProductModel {
// //   final String id;
// //   final String name;
// //   final int price;
// //   final List<String> categoryNames;
// //   final List<String> images;
// //   final String size; // 🌟 새롭게 추가
// //   final String color; // 🌟 새롭게 추가

// //   ProductModel({
// //     required this.id,
// //     required this.name,
// //     required this.price,
// //     required this.categoryNames,
// //     required this.images,
// //     required this.size, // 🌟 추가
// //     required this.color, // 🌟 추가
// //   });

// //   factory ProductModel.fromDocument(DocumentSnapshot doc) {
// //     final data = doc.data() as Map<String, dynamic>;
// //     // 🌟 [하이브리드 호환성 방어막]
// //     // 1. 서버에 categories 배열이 존재하면 정상적으로 파싱
// //     // 2. 만약 옛날 데이터라 categories가 없고 categoryName(String)만 있다면,
// //     //    이를 원소 1개짜리 리스트로 알아서 말아서 리턴해 줍니다.
// //     List<String> parsedCategories = [];
// //     if (data['categories'] != null) {
// //       parsedCategories = List<String>.from(data['categories']);
// //     } else if (data['categoryName'] != null) {
// //       parsedCategories = [data['categoryName'].toString()];
// //     }
// //     return ProductModel(
// //       id: doc.id,
// //       name: data['name'] ?? '',
// //       price: data['price'] ?? 0,
// //       categoryNames: parsedCategories,
// //             images: List<String>.from(data['images'] ?? []),
// //       size: data['size'] ?? '', // 🌟 Firestore 데이터 매핑 안전 처리
// //       color: data['color'] ?? '', // 🌟 Firestore 데이터 매핑 안전 처리
// //     );
// //   }
// // }

// // // 📦 페이지네이션 상태를 담을 가방
// // class PaginationState {
// //   final List<ProductModel> items;
// //   final bool hasMore; // 더 가져올 데이터가 남아있는지 여부
// //   final DocumentSnapshot? lastDoc; // 다음 10개를 긁어오기 위한 기준점 좌표

// //   PaginationState({required this.items, required this.hasMore, this.lastDoc});
// // }

// // // 🎯 [10개씩 끊어 읽는 파이어베이스 페이지네이션 엔진]
// // class PaginatedProductNotifier
// //     extends FamilyAsyncNotifier<PaginationState, String> {
// //   final int _limit = 10; // 🌟 유저님 요청: 딱 10개씩 스캔

// //   @override
// //   FutureOr<PaginationState> build(String arg) async {
// //     // 1️⃣ 구글 파이어베이스에서 최신순으로 첫 10개(또는 정해둔 _limit만큼) 조각을 긁어옵니다.
// //     Query query = FirebaseFirestore.instance
// //         .collection('products')
// //         .orderBy('createdAt', descending: true);

// //     if (arg != 'all') {
// //       query = query.where('categoryName', isEqualTo: arg);
// //     }

// //     final snapshot = await query.limit(_limit).get();
// //     final fetchedItems =
// //         snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
// //     final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
// //     final hasMore = snapshot.docs.length == _limit;

// //     print('\n==================================================');
// //     print('🚨 [최초 화면 로드 엔진 가동] 카테고리: "$arg"');
// //     print('📊 파이어베이스에서 최초로 긁어온 생짜 데이터 개수: ${fetchedItems.length}개');
// //     print('==================================================');

// //     // 2️⃣ 🛡️ [최초 로드 전용 쌍둥이 박멸 레이더]
// //     final Map<String, ProductModel> uniqueMap = {};

// //     for (var item in fetchedItems) {
// //       // 이름 양옆 공백 자르고 가격과 묶어 고유의 상품 열쇠 생성
// //       final String uniqueKey = "${item.name.trim()}_${item.price}";

// //       if (arg == 'all') {
// //         if (!uniqueMap.containsKey(uniqueKey)) {
// //           uniqueMap[uniqueKey] = item;
// //         } else {
// //           // 최초 빌드 때 쌍둥이가 걸러지면 즉시 콘솔에 제보!
// //           print('   ❌ [초기 로드 중복 차단!] '
// //               '이미 장부에 있는 상품명 복사 감지 ➔ 키: "$uniqueKey" | '
// //               '차단된 ID: ${item.id} | 카테고리: ${item.categoryName}');
// //         }
// //       } else {
// //         // 일반 개별 카테고리 코너에서는 중복 없이 도큐먼트 ID 기준으로 정상 노출
// //         uniqueMap[item.id.toString()] = item;
// //       }
// //     }

// //     // 3️⃣ 🧼 중복 세척이 완벽하게 끝난 청정 리스트 정제
// //     final List<ProductModel> cleanedInitialItems = uniqueMap.values.toList();

// //     print('--------------------------------------------------');
// //     print(
// //         '📦 [초기화 완료] 🧼 중복 청소 후 화면에 최종 뿌려줄 개수: ${cleanedInitialItems.length}개');
// //     print('==================================================\n');

// //     return PaginationState(
// //       items: cleanedInitialItems, // 🌟 처음 화면이 켜질 때부터 중복 없는 청정 데이터 주입!
// //       hasMore: hasMore,
// //       lastDoc: lastDoc,
// //     );
// //   }

// // // 🚀 [바닥 쳤을 때 다음 10개 낚아채는 함수 - 전정밀 디버깅 로그 탑재]
// //   Future<void> fetchNextPage() async {
// //     final currentState = state.value;
// //     if (currentState == null || !currentState.hasMore || state.isLoading) {
// //       return;
// //     }

// //     state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);

// //     await AsyncValue.guard(() async {
// //       Query query = FirebaseFirestore.instance.collection('products');

// //       if (arg != 'all') {
// //         query = query.where('categoryName', isEqualTo: arg);
// //       }

// //       query = query
// //           .orderBy('createdAt', descending: true)
// //           .startAfterDocument(currentState.lastDoc!)
// //           .limit(_limit);

// //       final snapshot = await query.get();
// //       final newItems =
// //           snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();

// //       final lastDoc =
// //           snapshot.docs.isNotEmpty ? snapshot.docs.last : currentState.lastDoc;
// //       final hasMore = snapshot.docs.length == _limit;

// //       print('\n==================================================');
// //       print(
// //           '🔍 [디버깅 레이더] Firebase에서 방금 막 긁어온 원본 생짜 데이터 스캔 개수: ${newItems.length}개');
// //       print('==================================================');

// //       for (int i = 0; i < newItems.length; i++) {
// //         final item = newItems[i];
// //         // 로그 가독성을 위해 글자수 고정 가드 처리
// //         final String debugName = item.name.length > 15
// //             ? '${item.name.substring(0, 13)}...'
// //             : item.name;
// //         print('  📍 [새 데이터 $i] '
// //             'ID: ${item.id} | '
// //             '이름(글자수:${item.name.length}): "$debugName" | '
// //             '카테고리: ${item.categoryName} | '
// //             '가격: ${item.price}원');
// //       }
// //       print('--------------------------------------------------');

// //       // 1️⃣ 기존 가방 아이템과 새로 긁어온 따끈한 아이템을 한 바구니에 합체
// //       final List<ProductModel> totalList = [...currentState.items, ...newItems];

// //       // 2️⃣ 🛡️ [쌍둥이 상품명 저격 방어막 가동 및 필터링 로그 스캔]
// //       final Map<String, ProductModel> uniqueMap = {};

// //       print('🧼 [디버깅 레이더] 현재 중복 세척(Filter) 진행 과정 실시간 추적 시작:');

// //       for (var item in totalList) {
// //         // 공백 에러 박멸을 위해 완전히 공백을 압축한 고유 키 생성
// //         final String trimmedName = item.name.trim();
// //         final String uniqueKey = "${trimmedName}_${item.price}";

// //         if (arg == 'all') {
// //           if (!uniqueMap.containsKey(uniqueKey)) {
// //             // 최초 등록 성공 로그
// //             uniqueMap[uniqueKey] = item;
// //           } else {
// //             // 🔥 중복으로 판정되어 튕겨 나갈 때 콘솔에 실시간 제보!
// //             print('     ❌ [중복 튕김 차단 성공!] '
// //                 '이미 가방에 동일 키 존재함 ➔ 키: "$uniqueKey" | '
// //                 '방금 튕겨낸 아이템 ID: ${item.id} | 카테고리: ${item.categoryName}');
// //           }
// //         } else {
// //           uniqueMap[item.id.toString()] = item;
// //         }
// //       }

// //       // 3️⃣ 중복 유전자가 완벽히 세척된 청정 리스트 정제 추출
// //       final List<ProductModel> cleanedItems = uniqueMap.values.toList();

// //       print('--------------------------------------------------');
// //       print('📦 [결과 리포트] 가방 병합 연산 종료');
// //       print('   • 기존 가방에 있던 개수: ${currentState.items.length}개');
// //       print('   • 서버에서 긁어온 개수: ${newItems.length}개');
// //       print('   • 🧼 중복 세척 후 최종 진열 개수: ${cleanedItems.length}개');
// //       print('   • 다음 페이지 또 있냐?(hasMore): $hasMore');
// //       print('==================================================\n');

// //       state = AsyncValue.data(
// //         PaginationState(
// //           items: cleanedItems,
// //           hasMore: hasMore,
// //           lastDoc: lastDoc,
// //         ),
// //       );
// //     });
// //   }
// // }

// // // 💡 전역 프로바이더 도킹 완료
// // final paginatedProductProvider = AsyncNotifierProviderFamily<
// //     PaginatedProductNotifier, PaginationState, String>(() {
// //   return PaginatedProductNotifier();
// // });

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:more_pic/db/product_repository.dart';

// // ====================================================================
// // 1. 단일 조회용 구식 레거시 프로바이더 (배열 스펙에 맞춰 단순 동기화)
// // ====================================================================
// class ProductDatabaseNotifier
//     extends AutoDisposeFamilyAsyncNotifier<List<ProductModel>, String> {
//   @override
//   FutureOr<List<ProductModel>> build(String arg) async {
//     // 하이브리드 대응을 위해 리포지토리에서 가져온 원본 데이터를 새 모델로 파싱 처리
//     Query query = FirebaseFirestore.instance
//         .collection('products')
//         .orderBy('createdAt', descending: true);
//     if (arg != 'all') {
//       query = query.where('categories', arrayContains: arg);
//     }
//     final snapshot = await query.get();
//     return snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
//   }

//   /// 🚀 상품 업로드 및 멀티 카테고리 배열 전송 액션
//   Future<void> uploadProduct({
//     required String name,
//     required int price,
//     required String size,
//     required String productDetail,
//     required String color,
//     required String sh,
//     required String shippingType,
//     required String shippingMethod,
//     required List<XFile> imageFiles,
//     required List<String>
//         selectedCategories, // 🌟 [대수술]: 단일 arg 대신 선택된 카테고리 '배열'을 직접 수용!
//     required Function(double, String) onProgress,
//   }) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       // 리포지토리에 배열 데이터를 한 번에 밀어 넣습니다.
//       await ref.read(productRepositoryProvider).uploadFullProduct(
//             name: name,
//             price: price,
//             categories: selectedCategories, // 🌟 파이어스토어 실문서에 주입될 핵심 배열!
//             size: size,
//             productDetail: productDetail,
//             color: color,
//             shippingMethod: shippingMethod,
//             shippingType: shippingType,
//             imageFiles: imageFiles,
//             onProgress: onProgress,
//           );

//       ref.invalidateSelf();
//       return future;
//     });
//   }

// // 🗑️ [전역 삭제 저격 트리거 - 타입 버그 완치 버전]
//   Future<void> deleteProduct(String productId) async {
//     // 🌟 [핵심 교체]: loading 뒤에 <PaginationState> 제너릭 타입을 정확히 명시해 줍니다!
//     state =
//         const AsyncValue<List<ProductModel>>.loading().copyWithPrevious(state);

//     await AsyncValue.guard(() async {
//       await FirebaseFirestore.instance
//           .collection('products')
//           .doc(productId)
//           .delete();

//       // 🔄 내 창고 캐시를 완벽하게 초기화(새로고침)
//       ref.invalidateSelf();

//       // 💡 만약 삭제된 빈자리를 채우기 위해 무조건 'all' 피드도 같이 새로고침 해야 한다면 아래 주석을 풀어주세요.
//       // ref.invalidate(paginatedProductProvider('all'));

//       return future;
//     });
//   }
// }

// final productDBProvider = AsyncNotifierProvider.family
//     .autoDispose<ProductDatabaseNotifier, List<ProductModel>, String>(() {
//   return ProductDatabaseNotifier();
// });

// // ====================================================================
// // 2. [최종 진화] 청정 신구조 ProductModel 사양 정의
// // ====================================================================
// class ProductModel {
//   final String id;
//   final String name;
//   final int price;
//   final List<String> categoryNames; // 🌟 완벽한 배열로 정착
//   final List<String> images;
//   final String size;
//   final String color;

//   ProductModel({
//     required this.id,
//     required this.name,
//     required this.price,
//     required this.categoryNames,
//     required this.images,
//     required this.size,
//     required this.color,
//   });

//   factory ProductModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     // 🛡️ [과거 데이터 구출용 하이브리드 방어막]
//     List<String> parsedCategories = [];
//     if (data['categories'] != null) {
//       parsedCategories = List<String>.from(data['categories']);
//     } else if (data['categoryName'] != null) {
//       final String oldCat = data['categoryName'].toString();
//       parsedCategories = oldCat == 'all' ? [] : [oldCat];
//     }

//     return ProductModel(
//       id: doc.id,
//       name: data['name'] ?? '',
//       price: data['price'] ?? 0,
//       categoryNames: parsedCategories, // 🧼 언제나 중복 없는 청정 배열 리턴
//       images: List<String>.from(data['images'] ?? []),
//       size: data['size'] ?? '',
//       color: data['color'] ?? '',
//     );
//   }
// }

// // ====================================================================
// // 3. 10개씩 끊어 읽는 무한스크롤 페이지네이션 가방 및 엔진
// // ====================================================================
// class PaginationState {
//   final List<ProductModel> items;
//   final bool hasMore;
//   final DocumentSnapshot? lastDoc;

//   PaginationState({required this.items, required this.hasMore, this.lastDoc});
// }

// class PaginatedProductNotifier
//     extends FamilyAsyncNotifier<PaginationState, String> {
//   final int _limit = 10;

//   @override
//   FutureOr<PaginationState> build(String arg) async {
//     Query query = FirebaseFirestore.instance
//         .collection('products')
//         .orderBy('createdAt', descending: true);

//     // 🌟 [배열 포함 검색식 작동]: 'all'이 아니면 categories 배열 안에 arg가 들었는지 서칭!
//     if (arg != 'all') {
//       query = query.where('categories', arrayContains: arg);
//     }

//     final snapshot = await query.limit(_limit).get();
//     final fetchedItems =
//         snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
//     final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
//     final hasMore = snapshot.docs.length == _limit;

//     // 🧼 [중복 박멸 완료]: 애초에 DB에 복사본 쌍둥이가 없으므로, uniqueMap 거름망 코드는 완전히 삭제되었습니다!
//     return PaginationState(
//       items: fetchedItems,
//       hasMore: hasMore,
//       lastDoc: lastDoc,
//     );
//   }

//   // 🚀 [바닥 쳤을 때 다음 10개 이어 붙이는 무한 스크롤 파이프라인]
//   Future<void> fetchNextPage() async {
//     final currentState = state.value;
//     if (currentState == null || !currentState.hasMore || state.isLoading) {
//       return;
//     }

//     state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);

//     await AsyncValue.guard(() async {
//       Query query = FirebaseFirestore.instance.collection('products');

//       if (arg != 'all') {
//         query = query.where('categories', arrayContains: arg);
//       }

//       // 🌟 복합 쿼리 가이드 순서 일치 (인덱스 생성용)
//       query = query
//           .orderBy('createdAt', descending: true)
//           .startAfterDocument(currentState.lastDoc!)
//           .limit(_limit);

//       final snapshot = await query.get();
//       final newItems =
//           snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();

//       final lastDoc =
//           snapshot.docs.isNotEmpty ? snapshot.docs.last : currentState.lastDoc;
//       final hasMore = snapshot.docs.length == _limit;

//       // 🧼 가방 결합도 군더더기 없이 일렬로 찰떡 병합 완료!
//       state = AsyncValue.data(
//         PaginationState(
//           items: [...currentState.items, ...newItems],
//           hasMore: hasMore,
//           lastDoc: lastDoc,
//         ),
//       );
//     });
//   }

//   // 🗑️ [전역 삭제 저격 트리거]: 메인이든 카테고리방이든 버튼 누르면 파이어베이스 원본 기둥을 바로 뽑아버립니다.
//   Future<void> deleteProduct(String productId) async {
//     state = const AsyncValue<PaginationState>.loading().copyWithPrevious(state);
//     await AsyncValue.guard(() async {
//       await FirebaseFirestore.instance
//           .collection('products')
//           .doc(productId)
//           .delete();

//       // 🔄 내 창고 및 전체보기('all') 창고 캐시까지 세트로 광속 무효화(새로고침)
//       ref.invalidateSelf();
//     });
//   }
// }

// // 🌐 3열 격자가 실시간 구독할 동적 페이지네이션 프로바이더 센터
// final paginatedProductProvider = AsyncNotifierProviderFamily<
//     PaginatedProductNotifier, PaginationState, String>(() {
//   return PaginatedProductNotifier();
// });

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/db/product_repository.dart';

// 📦 1. 상품 모델 정의 (하이브리드 과거 데이터 방어망 장착)
class ProductModel {
  final String id;
  final String name;
  final int price;
  final List<String> categoryNames;
  final List<String> images;
  final String size;
  final String color;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryNames,
    required this.images,
    required this.size,
    required this.color,
  });

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> parsedCategories = [];
    if (data['categories'] != null) {
      parsedCategories = List<String>.from(data['categories']);
    } else if (data['categoryName'] != null) {
      final String oldCat = data['categoryName'].toString();
      parsedCategories = oldCat == 'all' ? [] : [oldCat];
    }

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      categoryNames: parsedCategories,
      images: List<String>.from(data['images'] ?? []),
      size: data['size'] ?? '',
      color: data['color'] ?? '',
    );
  }
}

// 📦 2. 페이지네이션 스태이트 가방
class PaginationState {
  final List<ProductModel> items;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  PaginationState({required this.items, required this.hasMore, this.lastDoc});
}

// 🎯 3. 무한스크롤 페이징 엔진
class PaginatedProductNotifier
    extends FamilyAsyncNotifier<PaginationState, String> {
  final int _limit = 10;

  @override
  FutureOr<PaginationState> build(String arg) async {
    Query query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true);

    if (arg != 'all') {
      query = query.where('categories', arrayContains: arg);
    }

    final snapshot = await query.limit(_limit).get();
    final fetchedItems =
        snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length == _limit;

    return PaginationState(
        items: fetchedItems, hasMore: hasMore, lastDoc: lastDoc);
  }

  Future<void> fetchNextPage() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading)
      return;

    state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);

    await AsyncValue.guard(() async {
      Query query = FirebaseFirestore.instance.collection('products');
      if (arg != 'all') {
        query = query.where('categories', arrayContains: arg);
      }
      query = query
          .orderBy('createdAt', descending: true)
          .startAfterDocument(currentState.lastDoc!)
          .limit(_limit);

      final snapshot = await query.get();
      final newItems =
          snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
      final lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : currentState.lastDoc;
      final hasMore = snapshot.docs.length == _limit;

      state = AsyncValue.data(PaginationState(
        items: [...currentState.items, ...newItems],
        hasMore: hasMore,
        lastDoc: lastDoc,
      ));
    });
  }

  // // 🗑️ 단일 ID 완전 폭파 딜리트 엔진 (타입 에러 완치)
  // Future<void> deleteProduct(String productId) async {
  //   state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);
  //   await AsyncValue.guard(() async {
  //     await FirebaseFirestore.instance
  //         .collection('products')
  //         .doc(productId)
  //         .delete();
  //     ref.invalidateSelf();
  //     return future;
  //   });
  // }

  // 🗑️ [스마트 매대 철수 및 전역 삭제 결합 엔진]
  Future<void> deleteProduct({
    required String productId,
    required String targetCategory,
    required List<String> productCategories,
  }) async {
    state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);
    await AsyncValue.guard(() async {
      final docRef =
          FirebaseFirestore.instance.collection('products').doc(productId);

      if (targetCategory == 'all') {
        // 1️⃣ 메인('all')에서 삭제를 누르면 자비 없이 전역 영구 삭제!
        await docRef.delete();
      } else {
        // 2️⃣ 개별 카테고리 매대에서 삭제를 누르면 "현재 코너만 배열에서 쏙 제거(Pull)"
        await docRef.update({
          'categories': FieldValue.arrayRemove([targetCategory]),
        });

        // 3️⃣ [안전 가드]: 지우고 나서 남은 매대가 아무 데도 없다면 유령 방지를 위해 영구 삭제
        final updatedDoc = await docRef.get();
        if (updatedDoc.exists) {
          final updatedData = updatedDoc.data() as Map<String, dynamic>;
          final List remainingCategories = updatedData['categories'] ?? [];
          if (remainingCategories.isEmpty) {
            await docRef.delete();
          }
        }
      }

      // 🔄 4️⃣ [실시간 연쇄 동기화 무효화 뿜뿜]
      // 메인('all') 피드 즉시 리프레시
      ref.invalidate(paginatedProductProvider('all'));

      // 이 상품이 엮여있던 다른 코너들도 싹 새로고침 처리
      for (var cat in productCategories) {
        print("cat => ${cat}");
        ref.invalidate(paginatedProductProvider(cat));
      }

      // 현재 내가 보고 있는 매대 가방 최종 무효화
      ref.invalidateSelf();

      return future;
    });
  }
}

final paginatedProductProvider = AsyncNotifierProviderFamily<
    PaginatedProductNotifier, PaginationState, String>(() {
  return PaginatedProductNotifier();
});
