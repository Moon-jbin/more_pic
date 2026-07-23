// FILE: lib/provider/system_config_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 1. 배송비 설정 상태 제공자
final shippingConfigProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('system_settings')
      .doc('shipping_config')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return snapshot.data()!;
    }
    // 기본값 폴백
    return {'fee': 3000, 'message': '', 'isEvent': false};
  });
});

// 2. 홈 팝업 설정 상태 제공자 (텍스트 기반으로 변경!)
final popupConfigProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('system_settings')
      .doc('popup_config')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return snapshot.data()!;
    }
    // 기본값 폴백
    return {'isActive': false, 'title': '', 'content': ''};
  });
});