// import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:more_pic/global/custom_widget/custom_widget.dart';
// import 'package:more_pic/provider/admin_settings_provider.dart';
// import 'package:more_pic/provider/global_provider.dart';

// class PasswordCheckDlg extends HookConsumerWidget {
//   const PasswordCheckDlg({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final passwordController = useTextEditingController();
//     final globalProviderFnRead = ref.read(globalProviderFunction.notifier);
//     final adminSettingsRead = ref.read(adminSettingsProvider.notifier);

//     // 🌟 [반응형 가로폭 계산]
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 360.0;

//     Future<void> handleVerification() async {
//       final String inputPassword = passwordController.text.trim();

//       if (inputPassword.isEmpty) {
//         ScaffoldMessenger.of(context).clearSnackBars();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('🔑 패스워드를 입력해 주세요.'),
//             duration: Duration(milliseconds: 1500),
//           ),
//         );
//         return;
//       }

//       final bool isCorrect =
//           await globalProviderFnRead.checkAdminPassword(inputPassword);

//       if (isCorrect) {
//         adminSettingsRead.adminModeFn();
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).clearSnackBars();
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('🎉 관리자 편집 모드가 활성화되었습니다.')),
//           );
//         }
//       } else {
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).clearSnackBars();
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('❌ 비밀번호가 올바르지 않습니다!'),
//               duration: Duration(milliseconds: 1500),
//             ),
//           );
//         }
//       }
//     }

//     return CustomWidget.dialogCustomForm(
//       width: dialogWidth,
//       height: 220,
//       isScrollable: false, // 🌟 가로 스크롤을 꺼서 무한대 팽창 크래시를 원천 박멸합니다!
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CustomWidget.customDialogTitle(
//             context,
//             ref,
//             title: '관리자 인증',
//             isShowCloseBtn: true,
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: passwordController,
//                   decoration: const InputDecoration(
//                     labelText: '관리자 패스워드 입력',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.lock_outline),
//                     contentPadding:
//                         EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//                   ),
//                   onSubmitted: (_) => handleVerification(),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4A6FA5),
//                     minimumSize: const Size(double.infinity,
//                         48), // 💡 이제 무한대 너비(infinity)를 줘도 터지지 않고 부모 폭에 안착합니다!
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     elevation: 0,
//                   ),
//                   onPressed: handleVerification,
//                   child: const Text(
//                     '인증하기',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
