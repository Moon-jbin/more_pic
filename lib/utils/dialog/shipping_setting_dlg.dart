// FILE: lib/utils/dialog/shipping_setting_dlg.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';

class ShippingSettingDlg extends HookConsumerWidget {
  const ShippingSettingDlg({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeController = useTextEditingController(text: '3000');
    final messageController = useTextEditingController();
    final isEvent = useState<bool>(false);
    final isLoading = useState<bool>(true);
    final isSaving = useState<bool>(false);

    // 팝업 열릴 때 기존 파이어베이스 설정값 불러오기
    useEffect(() {
      FirebaseFirestore.instance
          .collection('system_settings')
          .doc('shipping_config')
          .get()
          .then((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          feeController.text = data['fee']?.toString() ?? '3000';
          messageController.text = data['message'] ?? '';
          isEvent.value = data['isEvent'] ?? false;
        }
      }).whenComplete(() => isLoading.value = false);
      return null;
    }, []);

    // 설정 저장 함수
    Future<void> saveSettings() async {
      isSaving.value = true;
      try {
        await FirebaseFirestore.instance
            .collection('system_settings')
            .doc('shipping_config')
            .set({
          'fee': int.tryParse(feeController.text.trim()) ?? 3000,
          'message': messageController.text.trim(),
          'isEvent': isEvent.value,
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🚚 배송비 설정이 성공적으로 저장되었습니다!')),
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
    final double dialogWidth = screenWidth < 600 ? (screenWidth - 40) : 400.0;

    return CustomWidget.dialogCustomForm(
      width: dialogWidth,
      isScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomWidget.customDialogTitle(
            context,
            ref,
            title: '배송비 및 이벤트 설정',
            isShowCloseBtn: true,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '기본 배송비 (원)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEvent.value ? Colors.red.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isEvent.value ? Colors.red.shade200 : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('배송비 이벤트 활성화',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('주문서 화면에 특별 문구가 노출됩니다.',
                            style: TextStyle(fontSize: 12)),
                        value: isEvent.value,
                        activeColor: Colors.redAccent,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => isEvent.value = val,
                      ),
                      if (isEvent.value) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            labelText: '이벤트 강조 문구',
                            hintText: '예: 이번 이벤트 기간! 배송비 2000원!',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.campaign_outlined, color: Colors.redAccent),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
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