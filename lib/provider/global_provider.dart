import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final globalProviderFunction =
    StateNotifierProvider<GlobalProviderFunction, Function>(
        (ref) => GlobalProviderFunction());

class GlobalProviderFunction extends StateNotifier<Function> {
  GlobalProviderFunction() : super(() {});

  ///```
  /// Dialog pop Function
  ///```
  void dialogCloseFn(BuildContext context) {
    Navigator.pop(context);
  }


  /// 🔐 [추가] 파이어베이스에 저장된 관리자 비밀번호와 일치하는지 검증하는 함수
  Future<bool> checkAdminPassword(String inputPassword) async {
    try {
      // admin_settings 컬렉션의 security 문서를 읽어옵니다.
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('security')
          .get();

      if (doc.exists && doc.data() != null) {
        final String? serverPassword = doc.data()!['adminPassword'];
        // 입력한 비번과 서버 비번이 완벽히 일치하면 true 반환
        return serverPassword == inputPassword;
      }
      return false;
    } catch (e) {
      print("❌ 비밀번호 검증 오류: $e");
      return false;
    }
  }
}
