import 'package:flutter/material.dart';

///```
/// Dialog 생성 함수
/// @param {BuildContext} context - BuildContext
/// @param {Function} showWidget - Dialog에 보일 위젯
/// @param {bool} dismissible - Dialog 이외 공간 클릭 허용 값 (선택사항)(기본값 true)
/// @param {RouteSettings?} routeSettings - Dialog 호출 시 Route 적용 값
///```
showCustomDialog(BuildContext context, Function showWidget,
    {bool dismissible = false, RouteSettings? routeSettings}) async {
  return await showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0),
      barrierLabel: '',
      barrierDismissible: dismissible,
      transitionDuration: Duration.zero,
      context: context,
      routeSettings: routeSettings,
      pageBuilder: (context, animation1, animation2) => showWidget(context));
}

///```
/// Dialog 기본 틀 위젯
/// @param {Widget} content - Dialog 내용 위젯
///```
customDialogForm({required Widget content}) {
  return AlertDialog(
    contentPadding: EdgeInsets.zero,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(0))),
    content: content,
  );
}
