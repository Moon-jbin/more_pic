import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/product_filter_provider.dart';

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

  // 🌟 공통 쿼리 생성 함수 (필터/정렬 적용)
  Query _buildQuery(String arg, ProductFilterState filter) {
    Query query = FirebaseFirestore.instance.collection('products');

    // 1. 카테고리 필터
    if (arg != 'all') {
      query = query.where('categories', arrayContains: arg);
    }
    // 3. 정렬 옵션
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
