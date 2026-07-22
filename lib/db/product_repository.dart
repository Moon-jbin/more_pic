import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// 🚀 [레거시 완전 제거] 상품 업로드 최종 스펙
  Future<void> uploadFullProduct({
    required String name,
    required int price,
    required List<String> categories, // 🌟 오직 이 배열 하나만 취급!
    required String size,
    required String productDetail,
    required String color,
    required String shippingType,
    required String shippingMethod,
    required List<XFile> imageFiles,
    required Function(double, String) onProgress,
  }) async {
    onProgress(0.1, "이미지 분석 및 스토리지 업로드 중...");

    // 🌟 [수정]: 기존에 프로젝트에서 사용하시던 스토리지 업로드 로직을 수행합니다.
    List<String> imageUrls = [];

    try {
      if (imageFiles.isNotEmpty) {
        for (int i = 0; i < imageFiles.length; i++) {
          final file = imageFiles[i];
          final progressRatio =
              0.1 + ((i / imageFiles.length) * 0.5); // 10% ~ 60% 구간 진행률 표시
          onProgress(
              progressRatio, "이미지 (${i + 1}/${imageFiles.length}) 업로드 중...");

          // 💡 유저님의 Firebase Storage 업로드 로직 적용 구역
          // 예: 스토리지 내 저장될 고유 파일명 정의 (시간초 기반)
          final ref = FirebaseStorage.instance
              .ref()
              .child('products')
              .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');

          // 파일 업로드 (웹 환경과 모바일 환경 범용성을 위해 bytes 또는 file 형태로 업로드)
          final uploadTask = ref.putData(await file.readAsBytes());
          final snapshot = await uploadTask;

          // 업로드 완료된 이미지의 진짜 다운로드 URL 획득 🔑
          final downloadUrl = await snapshot.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        }
      }
    } catch (e) {
      // 업로드 실패 시 에러 핸들링
      onProgress(0.0, "이미지 업로드 중 에러 발생: $e");
      rethrow;
    }

    onProgress(0.7, "파이어베이스 매대 등록 데이터 조립 중...");

    // 데이터베이스에 딱 1개의 문서만 진짜 다운로드 완료된 imageUrls를 들고 깔끔하게 생성!
    await _db.collection('products').add({
      'name': name,
      'price': price,
      'categories': categories, // 🌟 파이어스토어 문서 내부에 배열 주입
      'images': imageUrls, // 🌟 진짜 업로드된 이미지 리스트 주입!
      'size': size,
      'productDetail': productDetail,
      'color': color,
      'shippingType': shippingType,
      'shippingMethod': shippingMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });

    onProgress(1.0, "진열 완수!");
  }

  // 🌟 [새 기능 도킹]: 사진을 제외한 상품의 순수 텍스트 정보들만 Firestore에 업데이트합니다.
  Future<void> updateProductTextInfo(
      {required String productId,
      required String name,
      required int price,
      required String size,
      required String color}) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'name': name,
        'price': price,
        'size': size,
        'color': color,
        'updatedAt': FieldValue.serverTimestamp(), // 수정 시간 기록
      });
      // print("🎉 [Firestore 수정 완치] 제품 ID: $productId 장부 변경 성공!");
    } catch (e) {
      print("❌ [Firestore 수정 에러] 원인: $e");
      throw Exception('상품 정보 수정 중 서버 통신 실패: $e');
    }
  }

  // 📌 [신규 추가]: 텍스트 + 이미지 혼합 수정 (순서 변경, 삭제, 신규 추가 완벽 반영)
  Future<void> updateProductWithImages({
    required String productId,
    required String name,
    required int price,
    required String size,
    required String color,
    required List<dynamic> mixedImages, // String(기존 URL)과 XFile(새 이미지) 혼합 배열
    required Function(double, String) onProgress,
  }) async {
    List<String> finalImageUrls = [];
    onProgress(0.1, "데이터 분석 및 업로드 준비 중...");

    try {
      for (int i = 0; i < mixedImages.length; i++) {
        final item = mixedImages[i];
        final progressRatio = 0.1 + ((i / mixedImages.length) * 0.7);
        onProgress(progressRatio, "이미지 처리 중 (${i + 1}/${mixedImages.length})...");

        if (item is String) {
          // 기존에 있던 이미지 URL은 새로 업로드할 필요 없이 그대로 유지
          finalImageUrls.add(item);
        } else if (item is XFile) {
          // 새로 추가된 파일은 Storage에 업로드 후 URL 추출
          final ref = FirebaseStorage.instance
              .ref()
              .child('products')
              .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          final uploadTask = ref.putData(await item.readAsBytes());
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          finalImageUrls.add(downloadUrl);
        }
      }

      onProgress(0.9, "데이터베이스 최종 업데이트 중...");

      // 텍스트 정보와 재정렬된 이미지 배열을 한 번에 업데이트!
      await _db.collection('products').doc(productId).update({
        'name': name,
        'price': price,
        'size': size,
        'color': color,
        'images': finalImageUrls, 
        'updatedAt': FieldValue.serverTimestamp(),
      });

      onProgress(1.0, "수정 완료!");
    } catch (e) {
      onProgress(0.0, "이미지 처리 중 에러 발생: $e");
      rethrow;
    }
  }
}

// 리버팟 프로바이더 도킹 (기존 변수명과 일치)
final productRepositoryProvider = Provider((ref) => ProductRepository());
