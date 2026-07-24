// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:more_pic/provider/product_db_provider.dart';

// class ProductRepository {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // 📌 1. [일회성 동기화]: 기존 DB의 모든 상품을 미니 사전에 일괄 등록
//   Future<int> syncExistingProductsToIndex() async {
//     try {
//       final snapshot = await _db.collection('products').get();
//       List<Map<String, dynamic>> miniIndex = snapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'id': doc.id,
//           'name': data['name'] ?? '',
//         };
//       }).toList();

//       await _db.collection('system').doc('search_index').set({
//         'items': miniIndex,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });

//       return miniIndex.length;
//     } catch (e) {
//       print("❌ 미니 사전 동기화 에러: $e");
//       rethrow;
//     }
//   }

//   // 📌 2. [미니 사전 기반 전체 검색]: DB 전체를 대상으로 중간 단어까지 검색
//   Future<List<ProductModel>> searchProductsFromIndex(String keyword) async {
//     if (keyword.trim().isEmpty) return [];

//     try {
//       // 1) 미니 사전 문서 딱 1개만 다운로드 (읽기 비용 1회)
//       final indexDoc = await _db.collection('system').doc('search_index').get();
//       if (!indexDoc.exists || indexDoc.data() == null) return [];

//       final List<dynamic> rawItems = indexDoc.data()!['items'] ?? [];
//       final String cleanKeyword = keyword.trim().toLowerCase();

//       // 2) 앱 메모리 상에서 중간 단어 포함 여부 검사 (.contains)
//       final matchedIds = rawItems
//           .where((item) {
//             final String name = (item['name'] ?? '').toString().toLowerCase();
//             return name.contains(cleanKeyword);
//           })
//           .map((item) => item['id'].toString())
//           .toList();

//       if (matchedIds.isEmpty) return [];

//       // 3) 일치하는 상품 ID 리스트로 products 상세 데이터 한번에 조회
//       // (Firestore FieldPath.documentId in 쿼리 활용 - 최대 30개 단위 분할 조회)
//       List<ProductModel> results = [];
//       for (var i = 0; i < matchedIds.length; i += 30) {
//         final end = (i + 30 < matchedIds.length) ? i + 30 : matchedIds.length;
//         final chunk = matchedIds.sublist(i, end);

//         final productSnapshots = await _db
//             .collection('products')
//             .where(FieldPath.documentId, whereIn: chunk)
//             .get();

//         results.addAll(
//             productSnapshots.docs.map((doc) => ProductModel.fromDocument(doc)));
//       }

//       return results;
//     } catch (e) {
//       print("❌ 검색 처리 실패: $e");
//       return [];
//     }
//   }

//   // 📌 3. 상품 업로드 (업로드 시 미니 사전에도 자동 추가)
//   Future<void> uploadFullProduct({
//     required String name,
//     required int price,
//     required List<String> categories,
//     required String size,
//     required String productDetail,
//     required String color,
//     required String shippingType,
//     required String shippingMethod,
//     required List<XFile> imageFiles,
//     required Function(double, String) onProgress,
//   }) async {
//     onProgress(0.1, "이미지 분석 및 스토리지 업로드 준비 중..");

//     List<String> imageUrls = List.filled(imageFiles.length, '');
//     try {
//       if (imageFiles.isNotEmpty) {
//         int completedCount = 0;

//         // ⚡ 핵심: 모든 이미지를 동시에 동시(병렬) 업로드 처리!
//         await Future.wait(
//           imageFiles.asMap().entries.map((entry) async {
//             int index = entry.key;
//             XFile file = entry.value;

//             final ref = FirebaseStorage.instance
//                 .ref()
//                 .child('products')
//                 .child('${DateTime.now().millisecondsSinceEpoch}_${index}.jpg');

//             final metadata = SettableMetadata(
//               contentType: 'image/jpg',
//               cacheControl: 'public, max-age=31536000',
//             );

//             final bytes = await file.readAsBytes();
//             final uploadTask = ref.putData(bytes, metadata);
//             final snapshot = await uploadTask;
//             final downloadUrl = await snapshot.ref.getDownloadURL();

//             imageUrls[index] = downloadUrl; // 순서 보장

//             completedCount++;
//             double ratio = 0.1 + ((completedCount / imageFiles.length) * 0.6);
//             onProgress(
//                 ratio, "이미지 초속업로드 중 ($completedCount/${imageFiles.length})...");
//           }),
//         );
//       }
//     } catch (e) {
//       onProgress(0.0, "이미지 업로드 중 에러 발생: $e");
//       rethrow;
//     }

//     onProgress(0.7, "파이어베이스 매물 등록 데이터 조립 중..");

//     // ① 본 문서 저장
//     final docRef = await _db.collection('products').add({
//       'name': name,
//       'price': price,
//       'categories': categories,
//       'images': imageUrls,
//       'size': size,
//       'productDetail': productDetail,
//       'color': color,
//       'shippingType': shippingType,
//       'shippingMethod': shippingMethod,
//       'createdAt': FieldValue.serverTimestamp(),
//     });

//     // ② 검색 미니 사전에 신규 상품 등록 (arrayUnion)
//     await _db.collection('system').doc('search_index').set({
//       'items': FieldValue.arrayUnion([
//         {'id': docRef.id, 'name': name}
//       ]),
//       'lastUpdated': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true));

//     onProgress(1.0, "진열 완료!");
//   }

//   // 📌 4. 텍스트 정보만 수정 (상품명이 바뀐 경우 미니 사전도 동기화)
//   Future<void> updateProductTextInfo({
//     required String productId,
//     required String name,
//     required int price,
//     required String size,
//     required String color,
//   }) async {
//     try {
//       // 기존 상품 문서 참조
//       final docRef = _db.collection('products').doc(productId);
//       final oldSnapshot = await docRef.get();
//       final String oldName = oldSnapshot.data()?['name'] ?? '';

//       // 본 데이터 수정
//       await docRef.update({
//         'name': name,
//         'price': price,
//         'size': size,
//         'color': color,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // 미니 사전 갱신 (이름이 변경되었을 때)
//       if (oldName != name) {
//         await _db.collection('system').doc('search_index').update({
//           'items': FieldValue.arrayRemove([
//             {'id': productId, 'name': oldName}
//           ])
//         });
//         await _db.collection('system').doc('search_index').update({
//           'items': FieldValue.arrayUnion([
//             {'id': productId, 'name': name}
//           ])
//         });
//       }
//     } catch (e) {
//       throw Exception('상품 정보 수정 중 서버 통신 실패: $e');
//     }
//   }

//   // 📌 5. 텍스트 + 이미지 수정 (미니 사전 갱신)
//   Future<void> updateProductWithImages({
//     required String productId,
//     required String name,
//     required int price,
//     required String size,
//     required String color,
//     required List<dynamic> mixedImages,
//     required Function(double, String) onProgress,
//   }) async {
//     List<String> finalImageUrls = [];
//     onProgress(0.1, "데이터 분석 및 업로드 준비 중...");

//     try {
//       final docRef = _db.collection('products').doc(productId);
//       final oldSnapshot = await docRef.get();
//       final String oldName = oldSnapshot.data()?['name'] ?? '';

//       for (int i = 0; i < mixedImages.length; i++) {
//         final item = mixedImages[i];
//         final progressRatio = 0.1 + ((i / mixedImages.length) * 0.7);
//         onProgress(
//             progressRatio, "이미지 처리 중 (${i + 1}/${mixedImages.length})...");

//         if (item is String) {
//           finalImageUrls.add(item);
//         } else if (item is XFile) {
//           final ref = FirebaseStorage.instance
//               .ref()
//               .child('products')
//               .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
//           final metadata = SettableMetadata(
//             contentType: 'image/jpg',
//             cacheControl:
//                 'public, max-age=31536000', // 🚀 핵심: 1년(31,536,000초) 동안 브라우저에 캐시 저장!
//           );
//           final uploadTask = ref.putData(await item.readAsBytes(), metadata);
//           final snapshot = await uploadTask;
//           final downloadUrl = await snapshot.ref.getDownloadURL();
//           finalImageUrls.add(downloadUrl);
//         }
//       }

//       await docRef.update({
//         'name': name,
//         'price': price,
//         'size': size,
//         'color': color,
//         'images': finalImageUrls,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // 미니 사전 갱신
//       if (oldName != name) {
//         await _db.collection('system').doc('search_index').update({
//           'items': FieldValue.arrayRemove([
//             {'id': productId, 'name': oldName}
//           ])
//         });
//         await _db.collection('system').doc('search_index').update({
//           'items': FieldValue.arrayUnion([
//             {'id': productId, 'name': name}
//           ])
//         });
//       }

//       onProgress(1.0, "수정 완료!");
//     } catch (e) {
//       onProgress(0.0, "이미지 처리 중 에러 발생: $e");
//       rethrow;
//     }
//   }

//   // 📌 6. 상품 삭제 시 미니 사전에서도 제거
//   Future<void> removeProductFromSearchIndex(
//       String productId, String productName) async {
//     try {
//       await _db.collection('system').doc('search_index').update({
//         'items': FieldValue.arrayRemove([
//           {'id': productId, 'name': productName}
//         ])
//       });
//     } catch (e) {
//       print("미니 사전 삭제 실패 (무시 가능): $e");
//     }
//   }
// }

// final productRepositoryProvider = Provider((ref) => ProductRepository());


import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/provider/product_db_provider.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // ⭐️ [핵심] 샤딩 한계치 설정 (안전하게 1문서당 8,000개)
  static const int maxItemsPerShard = 8000;
  static const String indexCollection = 'system_search_shards';

  // [추가] 무한 스크롤 패키지를 위한 전용 데이터 로더
  Future<Map<String, dynamic>> fetchPaginatedProducts({
    required String category,
    required List<Map<String, dynamic>> menuTree,
    required String sortOptionLabel,
    DocumentSnapshot? lastDoc,
    int limit = 12,
  }) async {
    Query query = _db.collection('products');
    
    if (category != 'all') {
      final targetCategories = _expandCategoryWithChildren(category, menuTree);
      if (targetCategories.length == 1) {
        query = query.where('categories', arrayContains: category);
      } else {
        query = query.where('categories', arrayContainsAny: targetCategories);
      }
    }
    
    if (sortOptionLabel == '낮은 가격순') {
      query = query.orderBy('price', descending: false);
    } else if (sortOptionLabel == '높은 가격순') {
      query = query.orderBy('price', descending: true);
    } else if (sortOptionLabel == '상품명순') {
      query = query.orderBy('name', descending: false);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }
    
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    
    final snapshot = await query.limit(limit).get();
    final items = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
    final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    
    return {'items': items, 'lastDoc': newLastDoc};
  }

  // [추가] 하위 카테고리 추출 유틸
  List<String> _expandCategoryWithChildren(String targetCategory, List<Map<String, dynamic>> menuTree) {
    Set<String> categorySet = {targetCategory};
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

    void searchAndCollect(List menuList, bool isMatchingTarget) {
      for (var item in menuList) {
        final mapItem = Map<String, dynamic>.from(item);
        final String path = mapItem['path'] ?? '';
        final String catKey = pathToCat(path);
        bool isCurrentMatch = isMatchingTarget || (catKey == targetCategory);
        if (isCurrentMatch) categorySet.add(catKey);
        final List? children = mapItem['children'];
        if (children != null && children.isNotEmpty) {
          searchAndCollect(children, isCurrentMatch);
        }
      }
    }
    searchAndCollect(menuTree, false);
    return categorySet.toList();
  }

  // [기능 1. 사전 동기화 (전체 재생성)]
  Future<int> syncExistingProductsToIndex() async {
    try {
      final snapshot = await _db.collection('products').get();
      List<Map<String, dynamic>> allMiniItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).toList();

      // 기존 샤드 싹 지우기 (초기화)
      final oldShards = await _db.collection(indexCollection).get();
      for (var doc in oldShards.docs) {
        await doc.reference.delete();
      }

      // 8000개씩 쪼개서(Sharding) 저장하기
      int shardCount = 0;
      for (var i = 0; i < allMiniItems.length; i += maxItemsPerShard) {
        final end = (i + maxItemsPerShard < allMiniItems.length)
            ? i + maxItemsPerShard
            : allMiniItems.length;
        final chunk = allMiniItems.sublist(i, end);

        await _db.collection(indexCollection).doc('shard_$shardCount').set({
          'items': chunk,
          'lastUpdated': FieldValue.serverTimestamp(),
          'shardIndex': shardCount,
        });
        shardCount++;
      }
      
      // 샤드 개수 기록해두기 (검색할 때 몇 권을 읽어야 하는지 알기 위해)
      await _db.collection('system').doc('search_meta').set({
        'totalShards': shardCount,
        'totalItems': allMiniItems.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return allMiniItems.length;
    } catch (e) {
      print("미니 사전 동기화 에러: $e");
      rethrow;
    }
  }

  // [기능 2. 샤딩된 사전 기반 전체 검색]
  Future<List<ProductModel>> searchProductsFromIndex(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    try {
      // 1) 몇 권으로 쪼개져 있는지 확인 (메타데이터 읽기 - 1회 읽기)
      final metaDoc = await _db.collection('system').doc('search_meta').get();
      final int totalShards = metaDoc.exists ? (metaDoc.data()!['totalShards'] ?? 1) : 1;

      final String cleanKeyword = keyword.trim().toLowerCase();
      List<String> matchedIds = [];

      // 2) 쪼개진 사전들(샤드)을 모두 병렬로 다운로드해서 찾기
      // 샤드가 3개면 읽기 3회 발생. (여전히 3만개 상품 전체 조회하는 30,000회보다 압도적으로 저렴)
      List<Future<void>> searchTasks = [];
      for (int i = 0; i < totalShards; i++) {
        searchTasks.add(
          _db.collection(indexCollection).doc('shard_$i').get().then((shardDoc) {
            if (shardDoc.exists && shardDoc.data() != null) {
              final List<dynamic> rawItems = shardDoc.data()!['items'] ?? [];
              final foundInShard = rawItems
                  .where((item) {
                    final String name = (item['name'] ?? '').toString().toLowerCase();
                    return name.contains(cleanKeyword);
                  })
                  .map((item) => item['id'].toString());
              matchedIds.addAll(foundInShard);
            }
          })
        );
      }
      await Future.wait(searchTasks); // 병렬 처리로 속도 극대화

      if (matchedIds.isEmpty) return [];

      // 3) 일치하는 상품 ID 리스트로 products 상세 데이터 한번에 조회
      List<ProductModel> results = [];
      for (var i = 0; i < matchedIds.length; i += 30) {
        final end = (i + 30 < matchedIds.length) ? i + 30 : matchedIds.length;
        final chunk = matchedIds.sublist(i, end);

        final productSnapshots = await _db
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        results.addAll(
            productSnapshots.docs.map((doc) => ProductModel.fromDocument(doc)));
      }

      return results;
    } catch (e) {
      print("검색 처리 실패: $e");
      return [];
    }
  }

  // [기능 3. 상품 업로드 시 사전 업데이트 (마지막 샤드에 추가)]
  Future<void> _addIndexToShard(String docId, String name) async {
    final metaDoc = await _db.collection('system').doc('search_meta').get();
    int totalShards = metaDoc.exists ? (metaDoc.data()!['totalShards'] ?? 1) : 1;
    
    // 가장 마지막 샤드(권) 확인
    int lastShardIndex = totalShards > 0 ? totalShards - 1 : 0;
    final lastShardRef = _db.collection(indexCollection).doc('shard_$lastShardIndex');
    
    final lastShardDoc = await lastShardRef.get();
    List<dynamic> currentItems = [];
    if (lastShardDoc.exists) {
      currentItems = lastShardDoc.data()?['items'] ?? [];
    }

    // 만약 마지막 권이 8000개가 넘었다면 새로운 권(새 샤드) 발행
    if (currentItems.length >= maxItemsPerShard) {
      lastShardIndex++;
      await _db.collection(indexCollection).doc('shard_$lastShardIndex').set({
        'items': [{'id': docId, 'name': name}],
        'lastUpdated': FieldValue.serverTimestamp(),
        'shardIndex': lastShardIndex,
      });
      
      // 메타데이터(총 권수) 업데이트
      await _db.collection('system').doc('search_meta').set({
        'totalShards': lastShardIndex + 1,
      }, SetOptions(merge: true));
      
    } else {
      // 아직 여유가 있다면 기존 권에 추가
      await lastShardRef.set({
        'items': FieldValue.arrayUnion([
          {'id': docId, 'name': name}
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // 전체 상품 업로드 로직 (기능 3 연동)
  Future<void> uploadFullProduct({
    required String name,
    required int price,
    required List<String> categories,
    required String size,
    required String productDetail,
    required String color,
    required String shippingType,
    required String shippingMethod,
    required List<XFile> imageFiles,
    required Function(double, String) onProgress,
  }) async {
    onProgress(0.1, "이미지 분석 및 스토리지 업로드 준비중.");

    List<String> imageUrls = List.filled(imageFiles.length, '');
    try {
      if (imageFiles.isNotEmpty) {
        int completedCount = 0;
        await Future.wait(
          imageFiles.asMap().entries.map((entry) async {
            int index = entry.key;
            XFile file = entry.value;

            final ref = FirebaseStorage.instance
                .ref()
                .child('products')
                .child('${DateTime.now().millisecondsSinceEpoch}_${index}.jpg');

            final metadata = SettableMetadata(
              contentType: 'image/jpg',
              cacheControl: 'public, max-age=31536000',
            );

            final bytes = await file.readAsBytes();
            final uploadTask = ref.putData(bytes, metadata);
            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();

            imageUrls[index] = downloadUrl;

            completedCount++;
            double ratio = 0.1 + ((completedCount / imageFiles.length) * 0.6);
            onProgress(
                ratio, "이미지 초속업로드중($completedCount/${imageFiles.length})...");
          }),
        );
      }
    } catch (e) {
      onProgress(0.0, "이미지 업로드중 에러 발생: $e");
      rethrow;
    }

    onProgress(0.7, "데이터베이스 매물 등록 데이터 조립 중.");

    // 원본 문서 생성
    final docRef = await _db.collection('products').add({
      'name': name,
      'price': price,
      'categories': categories,
      'images': imageUrls,
      'size': size,
      'productDetail': productDetail,
      'color': color,
      'shippingType': shippingType,
      'shippingMethod': shippingMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ⭐️ 샤딩된 사전에 아이템 추가
    await _addIndexToShard(docRef.id, name);

    onProgress(1.0, "진열 완료!");
  }
// FILE: lib/db/product_repository.dart

// [수정 1] 텍스트 정보 수정 시 categories 업데이트 추가
Future<void> updateProductTextInfo({
  required String productId,
  required String name,
  required int price,
  required List<String> categories, // ⭐️ 카테고리 리스트 받아오기
  required String size,
  required String color,
}) async {
  try {
    final docRef = _db.collection('products').doc(productId);
    final oldSnapshot = await docRef.get();
    final String oldName = oldSnapshot.data()?['name'] ?? '';

    await docRef.update({
      'name': name,
      'price': price,
      'categories': categories, // ⭐️ Firestore에 업데이트!
      'size': size,
      'color': color,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (oldName != name) {
      await _updateIndexInShard(productId, oldName, name);
    }
  } catch (e) {
    throw Exception('상품 정보 수정 중 서버 통신 실패: $e');
  }
}

// [수정 2] 텍스트 + 이미지 수정 시 categories 업데이트 추가
Future<void> updateProductWithImages({
  required String productId,
  required String name,
  required int price,
  required List<String> categories, // ⭐️ 카테고리 리스트 받아오기
  required String size,
  required String color,
  required List<dynamic> mixedImages,
  required Function(double, String) onProgress,
}) async {
  List<String> finalImageUrls = [];
  onProgress(0.1, "데이터 분석 및 업로드 준비중..");

  try {
    final docRef = _db.collection('products').doc(productId);
    final oldSnapshot = await docRef.get();
    final String oldName = oldSnapshot.data()?['name'] ?? '';

    for (int i = 0; i < mixedImages.length; i++) {
      final item = mixedImages[i];
      final progressRatio = 0.1 + ((i / mixedImages.length) * 0.7);
      onProgress(progressRatio, "이미지 처리 중(${i + 1}/${mixedImages.length})...");

      if (item is String) {
        finalImageUrls.add(item);
      } else if (item is XFile) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('products')
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final metadata = SettableMetadata(
          contentType: 'image/jpg',
          cacheControl: 'public, max-age=31536000',
        );
        final uploadTask = ref.putData(await item.readAsBytes(), metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        finalImageUrls.add(downloadUrl);
      }
    }

    await docRef.update({
      'name': name,
      'price': price,
      'categories': categories, // ⭐️ Firestore에 업데이트!
      'size': size,
      'color': color,
      'images': finalImageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (oldName != name) {
      await _updateIndexInShard(productId, oldName, name);
    }

    onProgress(1.0, "수정 완료!");
  } catch (e) {
    onProgress(0.0, "이미지 처리 중 에러 발생: $e");
    rethrow;
  }
}
  // [기능 6. 상품 삭제 시 사전에서 제거]
  Future<void> removeProductFromSearchIndex(
      String productId, String productName) async {
    try {
      final metaDoc = await _db.collection('system').doc('search_meta').get();
      final int totalShards = metaDoc.exists ? (metaDoc.data()!['totalShards'] ?? 1) : 1;

      // 삭제는 모든 샤드에 날려서 걸리는 곳에서 지워지게끔 (병렬 전송)
      List<Future> removeTasks = [];
      for (int i = 0; i < totalShards; i++) {
        removeTasks.add(
          _db.collection(indexCollection).doc('shard_$i').update({
            'items': FieldValue.arrayRemove([
              {'id': productId, 'name': productName}
            ])
          }).catchError((_) => null) // 해당 샤드에 없어서 나는 에러는 무시
        );
      }
      await Future.wait(removeTasks);
    } catch (e) {
      print("미니 사전 삭제 실패 (무시 가능): $e");
    }
  }

  // [내부 유틸] 이름 변경 시 사전 업데이트 로직
  Future<void> _updateIndexInShard(String docId, String oldName, String newName) async {
     final metaDoc = await _db.collection('system').doc('search_meta').get();
     final int totalShards = metaDoc.exists ? (metaDoc.data()!['totalShards'] ?? 1) : 1;

     // 삭제 명령 병렬 전송
     List<Future> removeTasks = [];
     for (int i = 0; i < totalShards; i++) {
        removeTasks.add(
          _db.collection(indexCollection).doc('shard_$i').update({
            'items': FieldValue.arrayRemove([
              {'id': docId, 'name': oldName}
            ])
          }).catchError((_) => null)
        );
     }
     await Future.wait(removeTasks);
     
     // 새로운 이름으로 다시 추가 (가장 마지막 권에 편하게 추가)
     await _addIndexToShard(docId, newName);
  }
}

final productRepositoryProvider = Provider((ref) => ProductRepository());