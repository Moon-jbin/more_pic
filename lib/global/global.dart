import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/model/product_item.dart';

Future<void> migrateProductImageUrlsParallel() async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  
  // 병렬 처리를 위해 각 문서 수정 작업을 Future 리스트로 생성
  final List<Future<void>> updateTasks = [];
  int updatedCount = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    if (data.containsKey('images') && data['images'] is List) {
      List<dynamic> oldImages = data['images'];
      List<String> newImages = [];
      bool needUpdate = false;

      for (var item in oldImages) {
        String url = item.toString();

        if (url.contains('more-pic.firebasestorage.app')) {
          needUpdate = true;

          // %2F 뒤의 파일명 추출
          final uri = Uri.parse(url);
          final pathAndQuery = uri.path;
          final fileName = pathAndQuery.split('%2F').last;

          // 서울 버킷 Direct URL
          final newUrl = 'https://storage.googleapis.com/more_pick/products/$fileName';
          newImages.add(newUrl);
        } else {
          newImages.add(url);
        }
      }

      // 변환이 필요한 문서들의 update() 비동기 작업(Future)을 배열에 수집
      if (needUpdate) {
        updatedCount++;
        updateTasks.add(doc.reference.update({'images': newImages}));
      }
    }
  }

  // 모든 비동기 개별 update 요청을 동시(병렬)에 실행하고 완료 대기
  if (updateTasks.isNotEmpty) {
    await Future.wait(updateTasks);
    print('🚀 총 $updatedCount개 문서의 URL 병렬 마이그레이션 완료!');
  } else {
    print('ℹ️ 변경할 URL이 없습니다.');
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
