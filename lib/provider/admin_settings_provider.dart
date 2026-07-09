import 'package:hooks_riverpod/hooks_riverpod.dart';

final adminSettingsProvider =
    StateNotifierProvider<AdminSettingsProvider, bool>(
        (ref) => AdminSettingsProvider());

class AdminSettingsProvider extends StateNotifier<bool> {
  AdminSettingsProvider() : super(false);

  // 어드민 모드 해제
  void initState() {
    state = false;
  }

  void adminModeFn() {
    state = true;
  }
}
