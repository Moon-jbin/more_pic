import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/model/product_item.dart';
import 'package:http/http.dart' as http;
// FILE: lib/global/global.dart 최하단

import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

Future<void> compressExistingStorageImages({
  required Function(double progress, String message) onProgress,
}) async {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  final snapshot = await firestore.collection('products').get();
  final docs = snapshot.docs;
  int totalDocs = docs.length;
  if (totalDocs == 0) return;

  int completedDocs = 0;

  if (kDebugMode) {
    print("🚀 [초고속 병렬 일괄 압축 시작] 총 $totalDocs개 상품 병렬 처리진행");
  }

  // 한 번에 동시에 처리할 상품 청크 단위 (3개씩 동시 처리)
  const int chunkSize = 3;

  for (int i = 0; i < docs.length; i += chunkSize) {
    final chunk = docs.sublist(
        i, (i + chunkSize > docs.length) ? docs.length : i + chunkSize);

    // ⚡️ 청크 내 상품들을 동시에 병렬 처리
    await Future.wait(chunk.map((doc) async {
      final data = doc.data();
      final List<dynamic> oldImages = data['images'] ?? [];
      if (oldImages.isEmpty) {
        completedDocs++;
        return;
      }

      List<String> newImages = List.filled(oldImages.length, '');
      bool isDocUpdated = false;

      // ⚡️ 한 상품 내의 여러 이미지들도 동시 병렬 다운로드 & 압축 & 업로드
      await Future.wait(
        oldImages.asMap().entries.map((entry) async {
          int imgIndex = entry.key;
          String imageUrl = entry.value.toString();

          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode != 200) {
              newImages[imgIndex] = imageUrl;
              return;
            }

            final Uint8List originalBytes = response.bodyBytes;
            final int originalKb = originalBytes.lengthInBytes ~/ 1024;

            // 이미 120KB 미만으로 작다면 기존 URL 유지
            if (originalKb < 120) {
              newImages[imgIndex] = imageUrl;
              return;
            }

            // flutter_image_compress 75% 퀄리티 재압축
            final Uint8List compressedBytes =
                await FlutterImageCompress.compressWithList(
              originalBytes,
              minWidth: 1080,
              minHeight: 1080,
              quality: 75,
              format: CompressFormat.jpeg,
            );

            final int compressedKb = compressedBytes.lengthInBytes ~/ 1024;

            final ref = storage.ref().child('products').child(
                '${DateTime.now().millisecondsSinceEpoch}_p_${doc.id}_$imgIndex.jpg');

            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              cacheControl: 'public, max-age=31536000',
            );

            // Storage 병렬 업로드
            final uploadTask = await ref.putData(compressedBytes, metadata);
            final newDownloadUrl = await uploadTask.ref.getDownloadURL();

            newImages[imgIndex] = newDownloadUrl;
            isDocUpdated = true;

            if (kDebugMode) {
              print(
                  "   ⚡️ [병렬 압축/업로드 완료] '${data['name'] ?? ''}' (#$imgIndex): $originalKb KB ➡️ $compressedKb KB");
            }
          } catch (e) {
            if (kDebugMode) print("   ⚠️ 이미지 처리 실패 (기존 유지): $e");
            newImages[imgIndex] = imageUrl;
          }
        }),
      );

      // Firestore 이미지 URL 배열 동시 업데이트
      if (isDocUpdated) {
        // 비어있는 방어용 필터링
        final cleanNewImages =
            newImages.where((url) => url.isNotEmpty).toList();
        await doc.reference.update({'images': cleanNewImages});
      }

      completedDocs++;
      double ratio = (completedDocs / totalDocs).clamp(0.0, 1.0);
      onProgress(
        ratio,
        "[$completedDocs/$totalDocs] '${data['name'] ?? ''}' 등 병렬 처리 중...",
      );
    }));
  }

  if (kDebugMode) {
    print("✅ [전체 이미지 초고속 병렬 압축 완료]");
  }
}

String getCdnImageUrl(String originalUrl) {
  // if (kDebugMode) return originalUrl;

  // try {
  //   Uri uri = Uri.parse(originalUrl);
  //   if (uri.host.contains("firebasestorage.googleapis.com")) {
  //     final pathPart = originalUrl.split('/o/')[1].split('?')[0];
  //     final decodedPath = Uri.decodeComponent(pathPart);

  //     // 상대 경로로 돌려주어 Hosting CDN을 타게 합니다.
  //     return "/storage-api/$decodedPath";
  //   }
  // } catch (e) {
  //   print("URL 변환 에러: $e");
  //   return originalUrl;
  // }
  return originalUrl;
}

bool isMobile(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  bool isMobile = screenWidth < 960;

  return isMobile;
}

// 예시: global.dart 파일 내부 혹은 하단
// 💡 각 카테고리 페이지의 리스트들을 스프레드 연산자(...)로 전부 합쳐버립니다.
final List<ProductItem> allProducts = [
  ...newBornClothesProducts,
  // ...babyProducts,    <-- 다른 카테고리 데이터 리스트가 생길 때마다
  // ...kidsProducts,    <-- 여기에 쉼표 찍고 차곡차곡 추가해 주시면 됩니다!
];

String numberFormat(int number) {
  String format = NumberFormat('#,###').format(number);

  return format;
}

const String kakaoUrl = 'https://pf.kakao.com/_xbyxdwX';
const String accountNumber = '3333-37-7919709';

final bool isDesktopOrWeb = defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;
