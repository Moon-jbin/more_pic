import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';

class LoginDlg extends HookConsumerWidget {
  const LoginDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Flutter Hooks 기반 컨트롤러 선언 (메모리 누수 방지 자동 처리)
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final passwordConfirmController = useTextEditingController();

    // 2. 상태 관리 (useState)
    final isLoading = useState<bool>(false);
    final isInitLoading = useState<bool>(true); // 로컬 저장값 불러오는 중인지 여부
    final obscurePw = useState<bool>(true);
    final isLoginMode = useState<bool>(true); // 로그인 vs 회원가입 모드 스위치

    // 💾 아이디 저장 및 자동 로그인 체크박스 상태
    final rememberId = useState<bool>(false);
    final autoLogin = useState<bool>(false);

    final adminSettingsRead = ref.read(adminSettingsProvider.notifier);

    // 🌟 [Hooks 라이프사이클]: 다이얼로그가 켜질 때 SharedPreferences에서 아이디/체크박스 정보 즉시 복원
    useEffect(() {
      Future<void> loadSavedSettings() async {
        try {
          final prefs = await SharedPreferences.getInstance();

          // 기존에 이상한 타입으로 박혀있을 캐시 충돌을 방어하기 위해
          // 형변환 에러를 캐치하거나 강제로 디폴트 처리를 박아둡니다.
          final rawRemember = prefs.get('remember_id');
          final rawAuto = prefs.get('auto_login');

          rememberId.value = (rawRemember is bool) ? rawRemember : false;
          autoLogin.value = (rawAuto is bool) ? rawAuto : false;

          if (rememberId.value) {
            final saved = prefs.getString('saved_email');
            emailController.text = saved ?? '';
          }
        } catch (e) {
          // 에러가 나면 캐시를 아예 안 쓰고 빈칸으로 초기화하여 먹통 방지
          rememberId.value = false;
          autoLogin.value = false;
        } finally {
          isInitLoading.value = false;
        }
      }

      loadSavedSettings();
      return null;
    }, []);

    // 🎯 [전송 처리 장부]: 로그인 및 회원가입 비즈니스 로직
    Future<void> handleSubmit() async {
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();
      final String passwordConfirm = passwordConfirmController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일과 비밀번호를 모두 입력해 주세요.')),
        );
        return;
      }

      // 🌟 [추가]: 비밀번호 유효성 검사 (6자리 이상 & 한글 포함 불가 정규식)
      // 자음/모음(ㄱ-ㅎ, ㅏ-ㅣ) 및 완성형 한글(가-힣)을 원천 차단합니다.
      final RegExp hangulRegExp = RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]');

      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호는 최소 6자리 이상이어야 합니다.')),
        );
        return;
      }

      if (hangulRegExp.hasMatch(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🚨 비밀번호에는 한글을 사용할 수 없습니다. (영어/숫자/특수문자 권장)')),
        );
        return;
      }

      if (!isLoginMode.value && password != passwordConfirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 서로 일치하지 않습니다.')),
        );
        return;
      }

      try {
        isLoading.value = true;

        if (isLoginMode.value) {
          // 🔵 로그인 호출 (반환값 성공 여부 동기화)
          final bool success = await adminSettingsRead.login(
            email,
            password,
            rememberId: rememberId.value,
            autoLogin: autoLogin.value,
          );

          if (success) {
            // 💾 로그인 성공 시 로컬 세팅 기기에 박제
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('remember_id', rememberId.value);
            await prefs.setBool('auto_login', autoLogin.value);
            if (rememberId.value) {
              await prefs.setString('saved_email', email);
            } else {
              await prefs.remove('saved_email');
            }

            if (!context.mounted) return;

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).clearSnackBars();

              if (adminSettingsRead.isMasterAdmin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔓 관리자 모드로 로그인되었습니다.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 모어픽에 오신 것을 환영합니다!')),
                );
              }
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🚨 이메일 또는 비밀번호가 올바르지 않습니다.')),
              );
            }
          }
        } else {
          // 🟢 회원가입
          await adminSettingsRead.register(email, password);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎉 회원가입이 완료되었습니다. 환영합니다!')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (context.mounted) {
          String errorMessage = '처리 중 오류가 발생했습니다.';
          if (e.code == 'user-not-found' ||
              e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다.';
          } else if (e.code == 'invalid-email') {
            errorMessage = '유효하지 않은 이메일 형식입니다.';
          } else if (e.code == 'email-already-in-use') {
            errorMessage = '이미 가입된 이메일입니다.';
          } else if (e.code == 'weak-password') {
            errorMessage = '비밀번호는 6자리 이상이어야 합니다.';
          }

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🚨 $errorMessage')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    if (isInitLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 400.0;

    return CustomWidget.dialogCustomForm(
      width: dialogWidth,
      height: isLoginMode.value ? 450 : 510, // 체크박스 영역 높이 확보
      isScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomWidget.customDialogTitle(
            context,
            ref,
            title: isLoginMode.value ? 'MORE PICK 로그인' : 'MORE PICK 회원가입',
            isShowCloseBtn: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // 1. 이메일 주소 입력창 (엔터 시 비번 창 포커스 이동)
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '이메일 주소',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                  onSubmitted: (_) {
                    FocusScope.of(context).nextFocus();
                  },
                ),
                const SizedBox(height: 16),

                // 2. 비밀번호 입력창 (엔터 시 즉시 전송 또는 다음 칸 이동)
                TextField(
                  controller: passwordController,
                  obscureText: obscurePw.value,
                  textInputAction: isLoginMode.value
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '비밀번호 (6자리 이상)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePw.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => obscurePw.value = !obscurePw.value,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                  ),
                  onSubmitted: (_) {
                    if (isLoginMode.value) {
                      handleSubmit();
                    } else {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),

                // 3. 회원가입 확인 입력창 (가입 모드 전용)
                if (!isLoginMode.value) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordConfirmController,
                    obscureText: obscurePw.value,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_reset),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    onSubmitted: (_) => handleSubmit(),
                  ),
                ],

                // 🌟 [체크박스 영역]: 로그인 모드 전용
                if (isLoginMode.value) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              activeColor: const Color(0xFF4A6FA5),
                              value: rememberId.value,
                              onChanged: (val) {
                                rememberId.value = val ?? false;
                              },
                            ),
                            const Text('아이디 저장',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              activeColor: const Color(0xFF4A6FA5),
                              value: autoLogin.value,
                              onChanged: (val) {
                                autoLogin.value = val ?? false;
                                if (autoLogin.value) {
                                  rememberId.value =
                                      true; // 자동 로그인 활성화 시 아이디 저장 세트 처리
                                }
                              },
                            ),
                            const Text('자동 로그인',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 4. 가입/로그인 최종 승인 버튼
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6FA5),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading.value ? null : handleSubmit,
                  child: isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isLoginMode.value ? '로그인' : '가입하기',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // 🌟 로그인 <-> 회원가입 스위처 버튼 최종 수정
                TextButton(
                  onPressed: () async {
                    // 1. 먼저 모드를 전환합니다.
                    isLoginMode.value = !isLoginMode.value;

                    // 2. 비밀번호 입력칸들은 어떤 모드로 가든 무조건 청소!
                    passwordController.clear();
                    passwordConfirmController.clear();

                    if (isLoginMode.value) {
                      // 🔵 [회원가입 -> 로그인 모드로 돌아올 때]
                      final prefs = await SharedPreferences.getInstance();
                      final bool isRemember =
                          prefs.getBool('remember_id') ?? false;

                      if (isRemember) {
                        // 아이디 저장이 켜져 있다면 저장된 이메일을 슥 불러옵니다.
                        emailController.text =
                            prefs.getString('saved_email') ?? '';
                      } else {
                        // 아이디 저장이 꺼져 있다면 깔끔하게 비웁니다.
                        emailController.clear();
                      }
                    } else {
                      // 🟢 [로그인 -> 회원가입 모드로 갈 때]
                      // 가입을 위해 이메일 칸을 깨끗하게 비워줍니다.
                      emailController.clear();
                    }
                  },
                  child: Text(
                    isLoginMode.value
                        ? '아직 계정이 없으신가요? 회원가입'
                        : '이미 계정이 있으신가요? 로그인',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
