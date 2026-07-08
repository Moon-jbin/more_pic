import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // 💡 File 대신 XFile 사용을 위해 필요
import 'package:more_pic/model/product_item.dart';

class ProductRepository {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<ProductItem>> fetchProductsByCategory(String category) async {
    try {
      final querySnapshot = await _productsCollection
          .where('categoryName', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductItem.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      throw Exception('Firebase DB 로드 실패: $e');
    }
  }

  /// 📥 [수정]: File 대신 XFile을 받고, 웹 호환을 위해 바이트 데이터(readAsBytes)로 업로드합니다.
  Future<String> _uploadImageToStorage(
      XFile xFile, String productId, String fileName) async {
    try {
      final Reference ref =
          _storage.ref().child('products/$productId/$fileName');

      // 💡 웹 브라우저에서도 안전하게 바이너리가 추출되도록 readAsBytes()를 활용합니다.
      final byteData = await xFile.readAsBytes();

      // putFile 대신 putData로 쏘아 올립니다. (웹/모바일 공용 최고 안전 규격)
      final UploadTask uploadTask =
          ref.putData(byteData, SettableMetadata(contentType: 'image/jpeg'));
      final TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('구글 스토리지 이미지 업로드 실패: $e');
    }
  }

  // /// ✨ [수정]: 통합 업로드 함수의 매개변수 타입을 XFile 규격으로 변경
  // Future<void> uploadFullProduct({
  //   required String name,
  //   required int price,
  //   required String category,
  //   required String size,
  //   required XFile mainImageFile,          // 💡 XFile로 변경
  //   required List<XFile> detailImageFiles, // 💡 List<XFile>로 변경
  // }) async {
  //   try {
  //     final String productId = 'p_${DateTime.now().millisecondsSinceEpoch}';

  //     String mainImageUrl = await _uploadImageToStorage(mainImageFile, productId, 'main.jpg');

  //     List<String> detailUrls = [];
  //     for (int i = 0; i < detailImageFiles.length; i++) {
  //       String url = await _uploadImageToStorage(detailImageFiles[i], productId, 'detail_$i.jpg');
  //       detailUrls.add(url);
  //     }

  //     await _productsCollection.doc(productId).set({
  //       'name': name,
  //       'price': price,
  //       'size': size,
  //       'image': mainImageUrl,
  //       'detailImages': detailUrls,
  //       'categoryName': category,
  //     });
  //   } catch (e) {
  //     throw Exception('상품 등록 전체 프로세스 실패: $e');
  //   }
  // }
  /// ✨ [디버깅 버전] 통합 업로드 함수: 터미널로 실시간 중계를 돌립니다.
  Future<void> uploadFullProduct({
    required String name,
    required int price,
    required String category,
    required String size,
    required XFile mainImageFile,
    required List<XFile> detailImageFiles,
  }) async {
    try {
      print("===== 🚀 [디버그 시작] 구글 서버 전송 파이프라인 가동 =====");
      print(
          "📦 전달된 데이터 -> 상품명: $name, 가격: $price, 카테고리: $category, 사이즈: $size");
      print("🖼️ 대표 이미지 파일 경로: ${mainImageFile.path}");
      print("📸 상세 이미지 개수: ${detailImageFiles.length}개");

      final String productId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      print("🔑 생성된 상품 ID: $productId");

      // 1. 대표 이미지 업로드 시도
      print("⏳ 1. 대표 이미지 구글 스토리지 전송 시작...");
      String mainImageUrl =
          await _uploadImageToStorage(mainImageFile, productId, 'main.jpg');
      print("✅ 1. 대표 이미지 전송 완료! 주소 확보: $mainImageUrl");

      // 2. 상세 이미지 업로드 시도
      List<String> detailUrls = [];
      print("⏳ 2. 상세 이미지 루프 전송 시작...");
      for (int i = 0; i < detailImageFiles.length; i++) {
        print("   -> [${i + 1}/${detailImageFiles.length}] 상세 이미지 전송 중...");
        String url = await _uploadImageToStorage(
            detailImageFiles[i], productId, 'detail_$i.jpg');
        detailUrls.add(url);
      }
      print("✅ 2. 상세 이미지 루프 완료! 확보된 주소 리스트: $detailUrls");

      // 3. 최종 Firestore DB 바인딩 시도
      print("⏳ 3. Firestore Database 문서 등록 시도 중...");
      await _productsCollection.doc(productId).set({
        'name': name,
        'price': price,
        'size': size,
        'image': mainImageUrl,
        'detailImages': detailUrls,
        'categoryName': category,
      });
      print("🎉 3. Firestore DB 최종 안착 성공!!! 데이터가 무조건 들어갔습니다.");
      print("=======================================================");
    } catch (e) {
      print("❌ [디버그 에러 발견] 서버 전송 도중 폭발함 -> 원인: $e");
      throw Exception('상품 등록 전체 프로세스 실패: $e');
    }
  }

  Future<void> deleteProductFromDB(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      throw Exception('Firebase 데이터 삭제 실패: $e');
    }
  }
}

final productRepositoryProvider = Provider((ref) => ProductRepository());
