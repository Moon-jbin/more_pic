// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:more_pic/secret.dart';

// final adminSettingsProvider =
//     NotifierProvider<AdminSettingsNotifier, bool>(AdminSettingsNotifier.new);

// class AdminSettingsNotifier extends Notifier<bool> {
//   final String _masterAdminEmail = SecretConfig.masterAdminEmail;

//   bool _isLoggedInInternal = false;

//   @override
//   bool build() {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     _isLoggedInInternal = currentUser != null;

//     FirebaseAuth.instance.authStateChanges().listen((User? user) {
//       if (user == null) {
//         _isLoggedInInternal = false;
//         state = false; // 🔔 로그아웃 시 state가 false로 변하면서 화면이 리빌드됩니다!
//       } else {
//         _isLoggedInInternal = true;
//         if (user.email == _masterAdminEmail) {
//           state = true;
//         } else {
//           state = false;
//         }
//       }
//     });

//     return currentUser != null && currentUser.email == _masterAdminEmail;
//   }

//   bool get isLoggedIn => _isLoggedInInternal;

//   bool get isMasterAdmin {
//     final user = FirebaseAuth.instance.currentUser;
//     return user != null && user.email == _masterAdminEmail;
//   }

//   void toggleEditMode() {
//     if (isMasterAdmin) {
//       state = !state;
//     } else {
//       state = false;
//     }
//   }

//   Future<bool> login(
//     String email,
//     String password, {
//     bool rememberId = false,
//     bool autoLogin = false,
//   }) async {
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       _isLoggedInInternal = true;

//       if (email == _masterAdminEmail) {
//         state = true;
//       } else {
//         // 🌟 [중요] 일반 회원 로그인 시에도 state를 강제로 갱신(Rebuild 트리거)
//         state = false;
//       }
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<void> register(String email, String password) async {
//     await FirebaseAuth.instance.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     _isLoggedInInternal = true;

//     // 🌟 [중요] 회원가입 시에도 state를 강제로 흔들어 화면을 새로 그리게 만듭니다.
//     state = false;
//   }

//   Future<void> logout() async {
//     await FirebaseAuth.instance.signOut();
//     _isLoggedInInternal = false;

//     // 🌟 [중요] 로그아웃 시 state를 false로 밀어서 감시 중인 화면들을 즉시 리빌드 시킵니다.
//     state = false;
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/secret.dart';

// 🌟 [추가]: 파이어베이스의 인증 세션을 실시간으로 완벽하게 감시하는 스트림 프로바이더
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, bool>(AdminSettingsNotifier.new);

class AdminSettingsNotifier extends Notifier<bool> {
  final String _masterAdminEmail = SecretConfig.masterAdminEmail;

  @override
  bool build() {
    // 앱 시작 시 사장님 계정인지 여부로 초기 편집 모드(state) 결정
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.email == _masterAdminEmail;
  }

  // 동기적 체크를 위한 게터들 (직접 파이어베이스를 조회하여 100% 신뢰성 보장)
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  bool get isMasterAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == _masterAdminEmail;
  }

  void toggleEditMode() {
    if (isMasterAdmin) {
      state = !state;
    } else {
      state = false;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberId = false,
    bool autoLogin = false,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 로그인 성공 시 어드민 계정이면 편집 모드 ON, 아니면 OFF
      state = (email == _masterAdminEmail);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> register(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    state = false; // 일반 회원은 편집 모드 무조건 OFF
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = false; // 로그아웃 시 편집 모드 OFF
  }
}
