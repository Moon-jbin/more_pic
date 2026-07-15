import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/global_provider.dart';

class OkCancelDialog extends HookConsumerWidget {
  final Icon? icon;
  final String? title;
  final String? msg;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final VoidCallback? onCancel;
  final VoidCallback? onClosePressed;

  const OkCancelDialog({
    super.key,
    required this.title,
    required this.msg,
    this.width,
    this.height,
    required this.onTap,
    this.onCancel,
    this.onClosePressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalProviderRead = ref.read(globalProviderFunction.notifier);

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            event is KeyDownEvent) {
          if (onTap != null) {
            onTap!();
          } else {
            globalProviderRead.dialogCloseFn(context);
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape &&
            event is KeyDownEvent) {
          if (onCancel != null) {
            onCancel!();
          } else {
            globalProviderRead.dialogCloseFn(context);
          }
        }
      },
      // 🌟 외부에서 고정 width를 안 줬다면 최소 320 ~ 최대 500 사이에서 동적으로 계산합니다.
      child: width != null
          ? _buildDialogContent(context, ref, globalProviderRead, width)
          : IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 320, // 최소 너비
                  maxWidth: 500, // 최대 너비
                ),
                child:
                    _buildDialogContent(context, ref, globalProviderRead, null),
              ),
            ),
    );
  }

  Widget _buildDialogContent(BuildContext context, WidgetRef ref,
      dynamic globalProviderRead, double? targetWidth) {
    return CustomWidget.dialogCustomForm(
      width: targetWidth, // 동적 계산을 위해 null 또는 외부 지정 값 전달
      height: height ?? 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // customDialogTitle 호출
          CustomWidget.customDialogTitle(
            context,
            ref,
            title: title ?? '',
            isShowCloseBtn: true, // X 버튼 필요시 활성화
            onClosePressed: onClosePressed,
          ),

          const SizedBox(height: 15),

          // 본문 메시지 구역 (줄바꿈 자동 지원)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: icon ??
                      const Icon(Icons.error, size: 36, color: Colors.blue),
                ),
                Expanded(
                  child: Text(
                    msg ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 하단 버튼 제어 구역
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomWidget.customTextButton(
                title: "예",
                onPressed:
                    onTap ?? () => globalProviderRead.dialogCloseFn(context),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(width: 10),
              CustomWidget.customTextButton(
                title: "아니요",
                onPressed:
                    onCancel ?? () => globalProviderRead.dialogCloseFn(context),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
