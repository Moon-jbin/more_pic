import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/provider/global_provider.dart';

class OkDialog extends HookConsumerWidget {
  Icon? icon;
  String? title;
  String? msg;
  VoidCallback? onTap;
  double? width;
  double? height;
  double? contentHeight;
  MainAxisAlignment? mainAxisAlignment;
  CrossAxisAlignment? crossAxisAlignment;

  OkDialog(
      {super.key,
      required this.icon,
      required this.title,
      required this.msg,
      required this.onTap,
      required this.width,
      required this.height,
      required this.contentHeight,
      required this.mainAxisAlignment,
      required this.crossAxisAlignment});

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
          }
        },
        child: CustomWidget.dialogCustomForm(
          width: width ?? 300,
          height: height ?? 180,
          child: SizedBox(
            height: contentHeight ?? 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomWidget.customDialogTitle(context, ref,
                    title: title ?? ''),
                SizedBox(
                  child: Row(
                    mainAxisAlignment:
                        mainAxisAlignment ?? MainAxisAlignment.center,
                    crossAxisAlignment:
                        crossAxisAlignment ?? CrossAxisAlignment.center,
                    children: [
                      Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: icon ??
                              const Icon(Icons.error,
                                  size: 40, color: Colors.blue)),
                      Text(msg ?? '', softWrap: true),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomWidget.customTextButton(
                      title: "확인",
                      onPressed: onTap ??
                          () {
                            globalProviderRead.dialogCloseFn(context);
                          },
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    const SizedBox(width: 10)
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
