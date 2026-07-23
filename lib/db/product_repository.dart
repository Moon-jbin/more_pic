import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:more_pic/provider/product_db_provider.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📌 1. [일회성 동기화]: 기존 DB의 모든 상품을 미니 사전에 일괄 등록
  Future<int> syncExistingProductsToIndex() async {
    try {
      final snapshot = await _db.collection('products').get();
      List<Map<String, dynamic>> miniIndex = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).toList();

      await _db.collection('system').doc('search_index').set({
        'items': miniIndex,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return miniIndex.length;
    } catch (e) {
      print("❌ 미니 사전 동기화 에러: $e");
      rethrow;
    }
  }

  // 📌 2. [미니 사전 기반 전체 검색]: DB 전체를 대상으로 중간 단어까지 검색
  Future<List<ProductModel>> searchProductsFromIndex(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    try {
      // 1) 미니 사전 문서 딱 1개만 다운로드 (읽기 비용 1회)
      final indexDoc = await _db.collection('system').doc('search_index').get();
      if (!indexDoc.exists || indexDoc.data() == null) return [];

      final List<dynamic> rawItems = indexDoc.data()!['items'] ?? [];
      final String cleanKeyword = keyword.trim().toLowerCase();

      // 2) 앱 메모리 상에서 중간 단어 포함 여부 검사 (.contains)
      final matchedIds = rawItems
          .where((item) {
            final String name = (item['name'] ?? '').toString().toLowerCase();
            return name.contains(cleanKeyword);
          })
          .map((item) => item['id'].toString())
          .toList();

      if (matchedIds.isEmpty) return [];

      // 3) 일치하는 상품 ID 리스트로 products 상세 데이터 한번에 조회
      // (Firestore FieldPath.documentId in 쿼리 활용 - 최대 30개 단위 분할 조회)
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
      print("❌ 검색 처리 실패: $e");
      return [];
    }
  }

  // 📌 3. 상품 업로드 (업로드 시 미니 사전에도 자동 추가)
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
    onProgress(0.1, "이미지 분석 및 스토리지 업로드 중..");

    List<String> imageUrls = [];
    try {
      if (imageFiles.isNotEmpty) {
        for (int i = 0; i < imageFiles.length; i++) {
          final file = imageFiles[i];
          final progressRatio = 0.1 + ((i / imageFiles.length) * 0.5);
          onProgress(
              progressRatio, "이미지 (${i + 1}/${imageFiles.length}) 업로드 중..");

          final ref = FirebaseStorage.instance
              .ref()
              .child('products')
              .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          final metadata = SettableMetadata(
            contentType: 'image/jpg', // WebP로 압축하셨으니 webp로 명시
            cacheControl:
                'public, max-age=31536000', // 🚀 핵심: 1년(31,536,000초) 동안 브라우저에 캐시 저장!
          );
          final uploadTask = ref.putData(await file.readAsBytes(), metadata);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        }
      }
    } catch (e) {
      onProgress(0.0, "이미지 업로드 중 에러 발생: $e");
      rethrow;
    }

    onProgress(0.7, "파이어베이스 매대 등록 데이터 조립 중..");

    // ① 본 문서 저장
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

    // ② 검색 미니 사전에 신규 상품 등록 (arrayUnion)
    await _db.collection('system').doc('search_index').set({
      'items': FieldValue.arrayUnion([
        {'id': docRef.id, 'name': name}
      ]),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    onProgress(1.0, "진열 완료!");
  }

  // 📌 4. 텍스트 정보만 수정 (상품명이 바뀐 경우 미니 사전도 동기화)
  Future<void> updateProductTextInfo({
    required String productId,
    required String name,
    required int price,
    required String size,
    required String color,
  }) async {
    try {
      // 기존 상품 문서 참조
      final docRef = _db.collection('products').doc(productId);
      final oldSnapshot = await docRef.get();
      final String oldName = oldSnapshot.data()?['name'] ?? '';

      // 본 데이터 수정
      await docRef.update({
        'name': name,
        'price': price,
        'size': size,
        'color': color,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 미니 사전 갱신 (이름이 변경되었을 때)
      if (oldName != name) {
        await _db.collection('system').doc('search_index').update({
          'items': FieldValue.arrayRemove([
            {'id': productId, 'name': oldName}
          ])
        });
        await _db.collection('system').doc('search_index').update({
          'items': FieldValue.arrayUnion([
            {'id': productId, 'name': name}
          ])
        });
      }
    } catch (e) {
      throw Exception('상품 정보 수정 중 서버 통신 실패: $e');
    }
  }

  // 📌 5. 텍스트 + 이미지 수정 (미니 사전 갱신)
  Future<void> updateProductWithImages({
    required String productId,
    required String name,
    required int price,
    required String size,
    required String color,
    required List<dynamic> mixedImages,
    required Function(double, String) onProgress,
  }) async {
    List<String> finalImageUrls = [];
    onProgress(0.1, "데이터 분석 및 업로드 준비 중...");

    try {
      final docRef = _db.collection('products').doc(productId);
      final oldSnapshot = await docRef.get();
      final String oldName = oldSnapshot.data()?['name'] ?? '';

      for (int i = 0; i < mixedImages.length; i++) {
        final item = mixedImages[i];
        final progressRatio = 0.1 + ((i / mixedImages.length) * 0.7);
        onProgress(
            progressRatio, "이미지 처리 중 (${i + 1}/${mixedImages.length})...");

        if (item is String) {
          finalImageUrls.add(item);
        } else if (item is XFile) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('products')
              .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          final metadata = SettableMetadata(
            contentType: 'image/jpg',
            cacheControl:
                'public, max-age=31536000', // 🚀 핵심: 1년(31,536,000초) 동안 브라우저에 캐시 저장!
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
        'size': size,
        'color': color,
        'images': finalImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 미니 사전 갱신
      if (oldName != name) {
        await _db.collection('system').doc('search_index').update({
          'items': FieldValue.arrayRemove([
            {'id': productId, 'name': oldName}
          ])
        });
        await _db.collection('system').doc('search_index').update({
          'items': FieldValue.arrayUnion([
            {'id': productId, 'name': name}
          ])
        });
      }

      onProgress(1.0, "수정 완료!");
    } catch (e) {
      onProgress(0.0, "이미지 처리 중 에러 발생: $e");
      rethrow;
    }
  }

  // 📌 6. 상품 삭제 시 미니 사전에서도 제거
  Future<void> removeProductFromSearchIndex(
      String productId, String productName) async {
    try {
      await _db.collection('system').doc('search_index').update({
        'items': FieldValue.arrayRemove([
          {'id': productId, 'name': productName}
        ])
      });
    } catch (e) {
      print("미니 사전 삭제 실패 (무시 가능): $e");
    }
  }
}

final productRepositoryProvider = Provider((ref) => ProductRepository());
