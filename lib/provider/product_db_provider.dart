import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/product_filter_provider.dart';
import 'package:more_pic/provider/search_provider.dart';

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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      categoryNames: List<String>.from(json['categoryNames'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      size: json['size'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'categoryNames': categoryNames,
      'images': images,
      'size': size,
      'color': color,
    };
  }
}

class PaginationState {
  final List<ProductModel> items;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  PaginationState({required this.items, required this.hasMore, this.lastDoc});
}

class PaginatedProductNotifier
    extends FamilyAsyncNotifier<PaginationState, String> {
  final int _limit = 10;

  // 🔥 [새로 추가] 상위 카테고리 코드가 들어왔을 때, 해당 카테고리와 자식 카테고리들을 모두 모아주는 함수
  List<String> _expandCategoryWithChildren(
      String targetCategory, List<Map<String, dynamic>> menuTree) {
    Set<String> categorySet = {targetCategory};

    // 경로(path) 문자열을 카테고리 키값으로 변환하는 동일 로직
    String pathToCat(String path) {
      if (path == '/') return 'newProduct';
      if (path.isEmpty) return 'unknown';
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) return 'unknown';
      String result = parts[0];
      for (int i = 1; i < parts.length; i++) {
        String word = parts[i];
        final subParts = word.split('_');
        for (var sub in subParts) {
          if (sub.isNotEmpty) result += sub[0].toUpperCase() + sub.substring(1);
        }
      }
      return result;
    }

    // 트리 구조 재귀 탐색
    void searchAndCollect(List menuList, bool isMatchingTarget) {
      for (var item in menuList) {
        final Map<String, dynamic> mapItem = Map<String, dynamic>.from(item);
        final String path = mapItem['path'] ?? '';
        final String catKey = pathToCat(path);

        bool isCurrentMatch = isMatchingTarget || (catKey == targetCategory);

        if (isCurrentMatch) {
          categorySet.add(catKey);
        }

        final List? children = mapItem['children'];
        if (children != null && children.isNotEmpty) {
          searchAndCollect(children, isCurrentMatch);
        }
      }
    }

    searchAndCollect(menuTree, false);
    return categorySet.toList();
  }

  // 🛠️ [기존 _buildQuery 함수 수정]
  Query _buildQuery(String arg, ProductFilterState filter) {
    Query query = FirebaseFirestore.instance.collection('products');

    // 1. 카테고리 필터
    if (arg != 'all') {
      final menuTree = ref.read(globalMenuProvider).value ?? [];
      // 선택된 카테고리 및 그 아래의 자식 카테고리 키값 목록을 확보 (예: ['babyOuter', 'babyOuterJumperJacket', ...])
      final List<String> targetCategories =
          _expandCategoryWithChildren(arg, menuTree);

      if (targetCategories.length == 1) {
        // 단일 카테고리인 경우 (최하위)
        query = query.where('categories', arrayContains: arg);
      } else {
        // 🔥 하위 그룹을 포함하는 상위 카테고리인 경우!
        // Firestore의 arrayContainsAny를 사용하여 자식 카테고리 중 하나라도 포함된 상품을 전부 끌어옴
        query = query.where('categories', arrayContainsAny: targetCategories);
      }
    }

    // 2. 정렬 옵션
    switch (filter.sortOption) {
      case ProductSortOption.priceLow:
        query = query.orderBy('price', descending: false);
        break;
      case ProductSortOption.priceHigh:
        query = query.orderBy('price', descending: true);
        break;
      case ProductSortOption.name:
        query = query.orderBy('name', descending: false);
        break;
      case ProductSortOption.newest:
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }
    return query;
  }

  @override
  FutureOr<PaginationState> build(String arg) async {
    // 💡 필터 상태를 watch (필터가 변경되면 build가 다시 호출되어 1페이지부터 다시 불러옴!)
    final filter = ref.watch(productFilterProvider);

    Query query = _buildQuery(arg, filter);
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
      // 💡 다음 페이지 로드 시에는 read로 현재 필터 상태만 가져옴
      final filter = ref.read(productFilterProvider);
      Query query = _buildQuery(arg, filter);

      query = query.startAfterDocument(currentState.lastDoc!).limit(_limit);

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

  // FILE: lib/provider/product_db_provider.dart

  // FILE: lib/provider/product_db_provider.dart

  Future<void> deleteProduct({
    required String productId,
    required String targetCategory,
    required List<String> productCategories,
  }) async {
    state = AsyncValue<PaginationState>.loading().copyWithPrevious(state);
    await AsyncValue.guard(() async {
      final docRef =
          FirebaseFirestore.instance.collection('products').doc(productId);

      // 삭제 전 스토리지 이미지 URL 추출
      final docSnapshot = await docRef.get();
      List<String> imageUrlsToDelete = [];
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        imageUrlsToDelete = List<String>.from(data['images'] ?? []);
      }

      if (targetCategory == 'all') {
        // 1. Firestore 문서 삭제
        await docRef.delete();

        // 🚀 2. Future.wait로 스토리지 이미지들을 '동시 병렬 삭제' (속도 대폭 향상!)
        if (imageUrlsToDelete.isNotEmpty) {
          await Future.wait(
            imageUrlsToDelete.map((url) async {
              try {
                await FirebaseStorage.instance.refFromURL(url).delete();
              } catch (e) {
                print("스토리지 이미지 삭제 중 에러 (무시 가능): $e");
              }
            }),
          );
        }
      } else {
        // 특정 카테고리에서만 제거 시도
        await docRef.update({
          'categories': FieldValue.arrayRemove([targetCategory]),
        });
        final updatedDoc = await docRef.get();
        if (updatedDoc.exists) {
          final updatedData = updatedDoc.data() as Map<String, dynamic>;
          final List remainingCategories = updatedData['categories'] ?? [];

          if (remainingCategories.isEmpty) {
            await docRef.delete();
            if (imageUrlsToDelete.isNotEmpty) {
              await Future.wait(
                imageUrlsToDelete.map((url) async {
                  try {
                    await FirebaseStorage.instance.refFromURL(url).delete();
                  } catch (e) {
                    print("스토리지 이미지 삭제 중 에러: $e");
                  }
                }),
              );
            }
          }
        }
      }

      ref.invalidate(paginatedProductProvider('all'));
      for (var cat in productCategories) {
        ref.invalidate(paginatedProductProvider(cat));
      }
      ref.invalidateSelf();
      return future;
    });
  }

  
}

final paginatedProductProvider = AsyncNotifierProviderFamily<
    PaginatedProductNotifier, PaginationState, String>(() {
  return PaginatedProductNotifier();
});



// 📌 [신규 추가]: 카테고리별 전체 상품 개수(Count) 전용 Provider
final categoryItemCountProvider = FutureProvider.family<int, String>((ref, category) async {
  Query query = FirebaseFirestore.instance.collection('products');

  if (category != 'all') {
    final menuTree = ref.watch(globalMenuProvider).value ?? [];
    
    // 기존에 만드셨던 하위 카테고리 확장 메서드 활용
    final notifier = PaginatedProductNotifier();
    final List<String> targetCategories = notifier._expandCategoryWithChildren(category, menuTree);

    if (targetCategories.length == 1) {
      query = query.where('categories', arrayContains: category);
    } else {
      query = query.where('categories', arrayContainsAny: targetCategories);
    }
  }

  // Firestore의 count() API를 사용하여 읽기 비용 1회만 소모하고 빠르게 개수 산출
  final AggregateQuerySnapshot snapshot = await query.count().get();
  return snapshot.count ?? 0;
});