// import 'dart:async';
// import 'dart:typed_data';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:image_picker/image_picker.dart'; // 💡 File 대신 XFile 사용을 위해 필요
// import 'package:more_pic/model/product_item.dart';
// import 'dart:typed_data';
// import 'package:image/image.dart' as img; // 👈 상단 임포트 필수!
// import 'dart:html' as html;

// class ProductRepository {
//   final CollectionReference _productsCollection =
//       FirebaseFirestore.instance.collection('products');
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   Future<List<ProductItem>> fetchProductsByCategory(String category) async {
//     try {
//       Query query = _productsCollection;

//       if (category != 'all') {
//         query = query.where('categoryName', isEqualTo: category);
//       }

//       // 🚀 [문서 ID 기준 최신순 정렬]: p_1783578587184 처럼 숫자가 큰 최신 문서가 0번 인덱스로 오도록 역순(descending) 정렬합니다!
//       query = query.orderBy(FieldPath.documentId, descending: true);

//       final querySnapshot = await query.get();

//       return querySnapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return ProductItem.fromJson({'id': doc.id, ...data});
//       }).toList();
//     } catch (e) {
//       throw Exception('Firebase DB 로드 실패: $e');
//     }
//   }
//   // Future<List<ProductItem>> fetchProductsByCategory(String category) async {
//   //   try {
//   //     Query query = _productsCollection;

//   //     // 카테고리가 'all'이 아닐 때만 필터링
//   //     if (category != 'all') {
//   //       query = query.where('categoryName', isEqualTo: category);
//   //     }

//   //     // ❌ 에러를 뿜던 서버 정렬(orderBy) 코드는 과감히 지우거나 주석 처리합니다!
//   //     // query = query.orderBy(FieldPath.documentId, descending: true);

//   //     final querySnapshot = await query.get();

//   //     // 파이어베이스에서 일단 데이터를 다 긁어옵니다.
//   //     final products = querySnapshot.docs.map((doc) {
//   //       final data = doc.data() as Map<String, dynamic>;
//   //       return ProductItem.fromJson({'id': doc.id, ...data});
//   //     }).toList();

//   //     // ⭕ [Dart 쾌속 정렬]: 받아온 상품 리스트를 앱 내부에서 문서 ID(id) 역순으로 정렬해 버립니다!
//   //     products.sort((a, b) => b.id.compareTo(a.id));

//   //     return products;
//   //   } catch (e) {
//   //     throw Exception('Firebase DB 로드 실패: $e');
//   //   }
//   // }

// // ⭕ [아래 코드로 완전히 교체해 주세요!]
//   Future<String> _uploadImageToStorage(
//       Uint8List fileBytes, String productId, String fileName) async {
//     try {
//       // 1. 파이어베이스 스토리지 저장 경로 설정
//       final storageRef =
//           FirebaseStorage.instance.ref().child('products/$productId/$fileName');

//       // 2. ⚡ 웹/태블릿 환경에서 Blob 에러를 원천 차단하는 putData 엔진 가동!
//       final uploadTask = await storageRef.putData(
//         fileBytes,
//         SettableMetadata(contentType: 'image/jpeg'), // JPG 포맷 메타데이터 설정
//       );

//       // 3. 구글 서버에 안착된 최종 이미지 다운로드 URL 확보 후 반환
//       return await uploadTask.ref.getDownloadURL();
//     } catch (e) {
//       print("💥 하위 스토리지 전송 단독 실패: $e");
//       rethrow;
//     }
//   }

//   // /// ✨ [수정]: 통합 업로드 함수의 매개변수 타입을 XFile 규격으로 변경
//   // Future<void> uploadFullProduct({
//   //   required String name,
//   //   required int price,
//   //   required String category,
//   //   required String size,
//   //   required XFile mainImageFile,          // 💡 XFile로 변경
//   //   required List<XFile> detailImageFiles, // 💡 List<XFile>로 변경
//   // }) async {
//   //   try {
//   //     final String productId = 'p_${DateTime.now().millisecondsSinceEpoch}';

//   //     String mainImageUrl = await _uploadImageToStorage(mainImageFile, productId, 'main.jpg');

//   //     List<String> detailUrls = [];
//   //     for (int i = 0; i < detailImageFiles.length; i++) {
//   //       String url = await _uploadImageToStorage(detailImageFiles[i], productId, 'detail_$i.jpg');
//   //       detailUrls.add(url);
//   //     }

//   //     await _productsCollection.doc(productId).set({
//   //       'name': name,
//   //       'price': price,
//   //       'size': size,
//   //       'image': mainImageUrl,
//   //       'detailImages': detailUrls,
//   //       'categoryName': category,
//   //     });
//   //   } catch (e) {
//   //     throw Exception('상품 등록 전체 프로세스 실패: $e');
//   //   }
//   // }
//   // /// ✨ [디버깅 버전] 통합 업로드 함수: 터미널로 실시간 중계를 돌립니다.
//   // /// 💡 [튜닝 완료] 세로 4,000px 한계선 리사이징 및 고효율 압축 파이프라인
//   // Future<void> uploadFullProduct({
//   //   required String name,
//   //   required int price,
//   //   required String category,
//   //   required String size,
//   //   required XFile mainImageFile,
//   //   required List<XFile> detailImageFiles,
//   // }) async {
//   //   try {
//   //     print("===== 🚀 [디버그 시작] 구글 서버 전송 파이프라인 가동 =====");
//   //     print(
//   //         "📦 전달된 데이터 -> 상품명: $name, 가격: $price, 카테고리: $category, 사이즈: $size");

//   //     final String productId = 'p_${DateTime.now().millisecondsSinceEpoch}';
//   //     print("🔑 생성된 상품 ID: $productId");

//   //     // 🛠️ [핵심 압축 장치 내부 도킹 함수]
//   //     Future<Uint8List> _processAndCompressImage(XFile file) async {
//   //       // 1. 태블릿 보안 가드를 파괴하기 위해 날것의 바이트 데이터로 먼저 읽어옵니다.
//   //       final Uint8List originalBytes = await file.readAsBytes();

//   //       print(
//   //           "📐 [압축 엔진] 원본 파일 바이트 크기: ${(originalBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB");

//   //       // 2. flutter_image_compress 엔진 가동
//   //       final Uint8List compressedBytes =
//   //           await FlutterImageCompress.compressWithList(
//   //         originalBytes,
//   //         minHeight: 4000, // ⚡ 유저님이 찾아내신 완벽한 갤탭 마법의 안전선 스펙!
//   //         minWidth: 1000, // 가로 해상도 한계선
//   //         quality: 75, // 용량은 1/10, 화질은 고화질 유지하는 황금 마진율
//   //         format: CompressFormat.jpeg, // 무조건 가벼운 JPEG 포맷으로 강제 컨버팅
//   //       );

//   //       print(
//   //           "⚡ [압축 엔진] 다이어트 완료 바이트 크기: ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB");
//   //       return compressedBytes;
//   //     }

//   //     // 1️⃣ 대표 이미지 업로드 시도 (압축 바이너리 주입)
//   //     print("⏳ 1. 대표 이미지 앱 내부 자동 다이어트 및 스토리지 전송 시작...");
//   //     final Uint8List compressedMainBytes =
//   //         await _processAndCompressImage(mainImageFile);

//   //     // 💡 주의: 아래 기존 _uploadImageToStorage 함수가 XFile이 아니라 'Uint8List(Bytes)'를 받도록
//   //     // 혹은 함수 내부에서 putData를 쓰도록 수정해야 태블릿 Blob 에러가 안 납니다!
//   //     String mainImageUrl = await _uploadImageToStorage(
//   //         compressedMainBytes, // 👈 주소 대신 압축된 알맹이(Bytes) 데이터 전송!
//   //         productId,
//   //         'main.jpg');
//   //     print("✅ 1. 대표 이미지 전송 완료! 주소 확보: $mainImageUrl");

//   //     // 2️⃣ 상세 이미지 업로드 시도 (루프 돌며 순차 압축)
//   //     List<String> detailUrls = [];
//   //     print("⏳ 2. 상세 이미지 루프 전송 시작...");
//   //     for (int i = 0; i < detailImageFiles.length; i++) {
//   //       print(
//   //           "   -> [${i + 1}/${detailImageFiles.length}] 상세 이미지 압축 및 전송 중...");

//   //       final Uint8List compressedDetailBytes =
//   //           await _processAndCompressImage(detailImageFiles[i]);

//   //       String url = await _uploadImageToStorage(
//   //           compressedDetailBytes, productId, 'detail_$i.jpg');
//   //       detailUrls.add(url);
//   //     }
//   //     print("✅ 2. 상세 이미지 루프 완료! 확보된 주소 리스트: $detailUrls");

//   //     // 3️⃣ 최종 Firestore DB 바인딩 시도
//   //     print("⏳ 3. Firestore Database 문서 등록 시도 중...");
//   //     await _productsCollection.doc(productId).set({
//   //       'name': name,
//   //       'price': price,
//   //       'size': size,
//   //       'image': mainImageUrl,
//   //       'detailImages': detailUrls,
//   //       'categoryName': category,
//   //     });
//   //     print("🎉 3. Firestore DB 최종 안착 성공!!! 데이터가 무조건 들어갔습니다.");
//   //     print("=======================================================");
//   //   } catch (e) {
//   //     print("❌ [디버그 에러 발견] 서버 전송 도중 폭발함 -> 원인: $e");
//   //     throw Exception('상품 등록 전체 프로세스 실패: $e');
//   //   }
//   // }

//   // /// 🚀 [진화형] 대표/상세 구분 없이 하나의 이미지 리스트만 순서대로 받아 업로드
//   // /// 🚀 [최종 진화형] 구글 스토리지 업로드 진행률 콜백이 탑재된 서버 전송 함수
//   // Future<void> uploadFullProduct({
//   //   required String name,
//   //   required int price,
//   //   required String category,
//   //   required String size,
//   //   required String productDetail,
//   //   required String color,
//   //   required String shippingType,
//   //   required String shippingMethod,
//   //   required List<XFile> imageFiles,
//   //   required Function(double, String) onProgress, // 👈 실시간 프로그레스 콜백 함수 추가!
//   // }) async {
//   //   try {
//   //     print("===== 🚀 [디버그 시작] 통합 이미지 전송 파이프라인 가동 =====");
//   //     final String productId = 'p_${DateTime.now().millisecondsSinceEpoch}';

//   //     List<String> uploadedUrls = [];

//   //     // 1️⃣ 조각난 이미지들을 순서대로 구글 서버에 업로드
//   //     for (int i = 0; i < imageFiles.length; i++) {
//   //       // 📊 UI단 팝업창에 진행률 배달 (예: 14장 중 3장 완료 시 21% 완료 마크)
//   //       double percent = (i / imageFiles.length).clamp(0.0, 0.95);
//   //       onProgress(
//   //           percent, "구글 스토리지로 [${i + 1}/${imageFiles.length}] 이미지 전송 중... 🚀");

//   //       final Uint8List bytes = await imageFiles[i].readAsBytes();
//   //       String url =
//   //           await _uploadImageToStorage(bytes, productId, 'img_$i.jpg');
//   //       uploadedUrls.add(url);
//   //     }

//   //     // 2️⃣ 스토리지 업로드가 다 끝나면 DB 바인딩 단계 진행률 전송
//   //     onProgress(0.98, "Firestore Database에 상품 정보 최종 진열 중... 🏷️");

//   //     // 최종 Firestore 셋팅
//   //     await _productsCollection.doc(productId).set({
//   //       'name': name,
//   //       'price': price,
//   //       'size': size,
//   //       'categoryName': category,
//   //       'images': uploadedUrls,
//   //       'productDetail': productDetail,
//   //       'color': color,
//   //       'shippingType': shippingType,
//   //       'shippingMethod': shippingMethod
//   //     });

//   //     // 3️⃣ 100% 완전 임무 완료 통보
//   //     onProgress(1.0, "상품 진열 완료! 🎉");
//   //     print("🎉 Firestore DB 최종 안착 성공!!!");
//   //   } catch (e) {
//   //     print("❌ 서버 전송 실패 -> 원인: $e");
//   //     throw Exception('상품 등록 프로세스 실패: $e');
//   //   }
//   // }
//   /// 🚀 [최종 초가속 진화형] 병렬 동시 업로드 및 실시간 프로그레스 연동 함수
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
//     required Function(double, String) onProgress, // 실시간 프로그레스 콜백
//   }) async {
//     try {
//       print("===== 🚀 [디버그 시작] 통합 초가속 병렬 전송 파이프라인 가동 =====");
//       final String productId = 'p_${DateTime.now().millisecondsSinceEpoch}';

//       if (imageFiles.isEmpty) return;

//       onProgress(0.05, "조각 이미지 병렬 전송 준비 중... 🚀");

//       // 🌟 [최적화 핵심]: 순차 await를 깨부수고, 모든 업로드 비동기 작업을 리스트로 묶습니다.
//       int completedCount = 0; // 동시 업로드 중 완료된 파일 개수 카운팅용

//       // List<Future<String>> uploadTasks = List.generate(imageFiles.length, (i) async {
//       //   final Uint8List bytes = await imageFiles[i].readAsBytes();

//       //   // 각각의 독립된 Future 스레드가 스토리지 업로드를 개별 수행합니다.
//       //   String url = await _uploadImageToStorage(bytes, productId, 'img_$i.jpg');

//       //   // 📊 [병렬 프로그레스 가드]: 먼저 끝나는 조각들이 생길 때마다 진행률 카운트를 올립니다.
//       //   completedCount++;
//       //   double percent = (completedCount / imageFiles.length) * 0.90; // 업로드는 최대 90%까지 배정
//       //   onProgress(
//       //     percent.clamp(0.1, 0.90),
//       //     "구글 스토리지 동시 전송 중... [$completedCount/${imageFiles.length}] 완료 ⚡"
//       //   );

//       //   return url;
//       // });
// List<Future<String>> uploadTasks = List.generate(imageFiles.length, (i) async {
//         final Uint8List bytes = await imageFiles[i].readAsBytes();

//         // 1️⃣ [파일 용량 계산] bytes 길이 기반 (KB 단위 변환)
//         final double fileSizeKB = bytes.lengthInBytes / 1024;

//         // 2️⃣ [가로/세로 해상도 계산] 브라우저 ImageElement 표준 활용 (비동기 0초 컷)
//         final html.ImageElement decodeImg = html.ImageElement();
//         final imgCompleter = Completer<void>();
//         decodeImg.onLoad.listen((_) => imgCompleter.complete());

//         final tempBlob = html.Blob([bytes]);
//         final tempUrl = html.Url.createObjectUrlFromBlob(tempBlob);
//         decodeImg.src = tempUrl;

//         await imgCompleter.future; // 브라우저가 사이즈 읽을 때까지 잠깐 대기
//         int imgWidth = decodeImg.naturalWidth;
//         int imgHeight = decodeImg.naturalHeight;
//         html.Url.revokeObjectUrl(tempUrl); // 메모리 해제

//         // 📊 [초정밀 사이즈 로그 출력]
//         print('📸 [조각 $i 사이즈 확인] 해상도: ${imgWidth}x${imgHeight}px | 용량: ${fileSizeKB.toStringAsFixed(1)} KB');

//         // 구글 스토리지 전송
//         String url = await _uploadImageToStorage(bytes, productId, 'img_$i.jpg');

//         completedCount++;
//         double percent = (completedCount / imageFiles.length) * 0.90;

//         // UI 모달창에 용량과 해상도까지 실시간으로 꽂아줄 수 있습니다.
//         onProgress(
//           percent.clamp(0.1, 0.90),
//           "[${completedCount}/${imageFiles.length}] 전송 중 (${imgWidth}x${imgHeight}px, ${fileSizeKB.toStringAsFixed(0)}KB) ⚡"
//         );

//         return url;
//       });
//       // 🚀 [동시 타격]: 15개 조각을 브라우저 파이프라인에 한 방에 태워 동시 업로드 시킵니다!
//       List<String> uploadedUrls = await Future.wait(uploadTasks);

//       // 2️⃣ 스토리지 업로드가 다 끝나면 DB 바인딩 단계 진행률 전송
//       onProgress(0.95, "Firestore Database에 상품 정보 최종 진열 중... 🏷️");

//       // 최종 Firestore 셋팅
//       await _productsCollection.doc(productId).set({
//         'name': name,
//         'price': price,
//         'size': size,
//         'categoryNames': categorys,
//         'images': uploadedUrls, // 순서대로 완벽히 정렬된 URL 리스트 바인딩
//         'productDetail': productDetail,
//         'color': color,
//         'shippingType': shippingType,
//         'shippingMethod': shippingMethod,
//         'createdAt': FieldValue.serverTimestamp(), // 서버 타임스탬프 권장
//       });

//       // 3️⃣ 100% 완전 임무 완료 통보
//       onProgress(1.0, "상품 진열 완료! 🎉");
//       print("🎉 Firestore DB 최종 안착 성공!!!");
//     } catch (e) {
//       print("❌ 서버 전송 실패 -> 원인: $e");
//       throw Exception('상품 등록 프로세스 실패: $e');
//     }
//   }
//   Future<void> deleteProductFromDB(String productId) async {
//     try {
//       await _productsCollection.doc(productId).delete();
//     } catch (e) {
//       throw Exception('Firebase 데이터 삭제 실패: $e');
//     }
//   }
// }

// final productRepositoryProvider = Provider((ref) => ProductRepository());

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
}

// 리버팟 프로바이더 도킹 (기존 변수명과 일치)
final productRepositoryProvider = Provider((ref) => ProductRepository());
