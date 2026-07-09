import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/global_provider.dart';

class PasswordCheckDlg extends HookConsumerWidget {
  const PasswordCheckDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();
    final globalProviderFnRead = ref.read(globalProviderFunction.notifier);
    final adminSettingsRead = ref.read(adminSettingsProvider.notifier);

    // 🎯 [중복 제거] 엔터키와 마우스 클릭 액션을 하나로 관통하는 통합 인증 함수
    Future<void> handleVerification() async {
      final String inputPassword = passwordController.text.trim();

      // 입력값이 비어있다면 불필요한 서버 통신을 차단하는 기본 예외 가드
      if (inputPassword.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔑 패스워드를 입력해 주세요.'),
            duration: Duration(milliseconds: 1500),
          ),
        );
        return;
      }

      final bool isCorrect =
          await globalProviderFnRead.checkAdminPassword(inputPassword);

      if (isCorrect) {
        adminSettingsRead.adminModeFn();
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 관리자 편집 모드가 활성화되었습니다.')),
          );
        }
      } else {
        if (context.mounted) {
          // 100번 연타 및 연속 엔터를 쳐도 이전 스낵바 큐를 통째로 청소하고 단 1개만 노출
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 비밀번호가 올바르지 않습니다!'),
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      }
    }

    return CustomWidget.dialogCustomForm(
      child: Column(
        children: [
          CustomWidget.customDialogTitle(
            context,
            ref,
            title: '관리자 인증',
            isShowCloseBtn: true, // 💡 취소 버튼이 없을 수 있으므로 닫기 X 버튼 활성화 권장
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: passwordController,
                  // obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '관리자 패스워드 입력',
                    border: OutlineInputBorder(),
                  ),
                  // 🚀 키보드 완료/엔터 키를 쳤을 때도 공용 인증 로직 강제 연동
                  onSubmitted: (_) => handleVerification(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6FA5),
                    minimumSize:
                        const Size(double.infinity, 48), // 버튼 터치 영역 살짝 최적화
                  ),
                  // 🚀 마우스로 버튼을 클릭했을 때도 동일 로직 연동
                  onPressed: handleVerification,
                  child: const Text('인증하기',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
