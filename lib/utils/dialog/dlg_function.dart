// ///```
// /// TEST Dialog 함수
// ///```
// showTestDlg(BuildContext context,
//     {String? msg, bool isShowPercent = false}) {
//   return showCustomDialog(
//       context,
//       (context) => customDialogForm(
//           content: TestDialog(msg: msg, isShowPercent: isShowPercent)));
// }

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/utils/dialog/dlg_form.dart';
import 'package:more_pic/utils/dialog/login_dlg.dart';
import 'package:more_pic/utils/dialog/menu_edit_dlg.dart';
import 'package:more_pic/utils/dialog/ok_cancel_dialog.dart';
import 'package:more_pic/utils/dialog/ok_dialog.dart';
import 'package:more_pic/utils/dialog/password_check_dlg.dart';
import 'package:more_pic/utils/dialog/popup_setting_dlg.dart';
import 'package:more_pic/utils/dialog/product_edit_dlg.dart';
import 'package:more_pic/utils/dialog/product_upload_dlg.dart';
import 'package:more_pic/utils/dialog/shipping_setting_dlg.dart';
import 'package:shared_preferences/shared_preferences.dart';

showProductUploadDlgFn(BuildContext context,
    {String? msg, bool isShowPercent = false}) {
  return showCustomDialog(
      context, (context) => customDialogForm(content: ProductUploadDlg()));
}

// showPasswordCheckDialog(BuildContext context,
//     {String? msg, bool isShowPercent = false}) {
//   return showCustomDialog(
//       context, (context) => customDialogForm(content: PasswordCheckDlg()));
// }

// 별도의 정식 다이얼로그 위젯 클래스로 완벽하게 분리 교정했습니다.
void showMenuEditDialog(
    BuildContext context, List<Map<String, dynamic>> currentMenus) {
  showDialog(
    context: context,
    builder: (context) {
      return MenuEditDialog(currentMenus: currentMenus);
    },
  );
}

///```
/// OK Button Dialog
/// _dialog.dart 전용
///```
showOkDlg(BuildContext context,
    {String? title,
    String? msg,
    VoidCallback? onTap,
    Icon? icon,
    double? width,
    double? height,
    double? contentHeight,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment}) {
  return showCustomDialog(
      dismissible: false,
      context,
      (context) => customDialogForm(
              content: OkDialog(
            title: title,
            msg: msg,
            onTap: onTap,
            icon: icon,
            width: width,
            height: height,
            contentHeight: contentHeight,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
          )));
}

///```
/// OK Cancel Button Dialog
/// _dialog.dart 전용
///```
showOkCancelDlg(BuildContext context,
    {String? title,
    String? msg,
    double? width,
    double? height,
    VoidCallback? onTap,
    VoidCallback? onCancel,
    VoidCallback? onClosePressed}) {
  return showCustomDialog(
      dismissible: false,
      context,
      (context) => customDialogForm(
          content: OkCancelDialog(
              title: title,
              msg: msg,
              width: width,
              height: height,
              onTap: onTap,
              onCancel: onCancel,
              onClosePressed: onClosePressed)));
}

// 🌟 [새 기능 도킹]: 상품 정보 수정 팝업 호출 가이드
showProductEditDlgFn(BuildContext context,
    {required dynamic product, required String currentCategory}) {
  showCustomDialog(
    context,
    (context) => customDialogForm(
      content: ProductEditDlg(
        product: product,
        currentCategory: currentCategory,
      ),
    ),
  );
}

// 기존 showPasswordCheckDialog 함수 교체
showAdminLoginDialog(BuildContext context) {
  return showCustomDialog(
      context, (context) => customDialogForm(content: const LoginDlg()));
}

showShippingSettingDialog(BuildContext context) {
  return showCustomDialog(context,
      (context) => customDialogForm(content: const ShippingSettingDlg()));
}

showPopupSettingDialog(BuildContext context) {
  return showCustomDialog(context,
      (context) => customDialogForm(content: const PopupSettingDlg()));
}
