// FILE: lib/utils/dialog/popup_setting_dlg.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';

class PopupSettingDlg extends HookConsumerWidget {
  const PopupSettingDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final isActive = useState<bool>(false);
    final isLoading = useState<bool>(true);
    final isSaving = useState<bool>(false);

    // 파이어베이스에서 기존 설정 불러오기
    useEffect(() {
      FirebaseFirestore.instance
          .collection('system_settings')
          .doc('popup_config')
          .get()
          .then((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          titleController.text = data['title'] ?? '';
          contentController.text = data['content'] ?? '';
          isActive.value = data['isActive'] ?? false;
        }
      }).whenComplete(() => isLoading.value = false);
      return null;
    }, []);

    // 설정 저장
    Future<void> saveSettings() async {
      isSaving.value = true;
      try {
        await FirebaseFirestore.instance
            .collection('system_settings')
            .doc('popup_config')
            .set({
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'isActive': isActive.value,
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📢 팝업 설정이 저장되었습니다!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e')),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 500.0;

    return CustomWidget.dialogCustomForm(
      width: dialogWidth,
      isScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomWidget.customDialogTitle(
            context,
            ref,
            title: '메인 화면 팝업 설정',
            isShowCloseBtn: true,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('팝업 노출 활성화',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  value: isActive.value,
                  activeColor: Colors.blueAccent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => isActive.value = val,
                ),
                const Divider(height: 24),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '팝업 제목',
                    hintText: '예: 브랜드 거래처 리스트',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 8, // 본문을 길게 적을 수 있도록
                  decoration: const InputDecoration(
                    labelText: '팝업 내용',
                    hintText: '거래처 리스트 등을 줄바꿈하여 입력하세요.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: isSaving.value ? null : saveSettings,
                  child: isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('저장하기',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}