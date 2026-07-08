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
import 'package:more_pic/utils/dialog/dlg_form.dart';
import 'package:more_pic/utils/dialog/product_upload_dlg.dart';

showProductUploadDlgFn(BuildContext context,
    {String? msg, bool isShowPercent = false}) {
  return showCustomDialog(
      context, (context) => customDialogForm(content: ProductUploadDlg()));
}
