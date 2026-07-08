import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final globalProviderFunction =
    StateNotifierProvider<GlobalProviderFunction, Function>(
        (ref) => GlobalProviderFunction());

class GlobalProviderFunction extends StateNotifier<Function> {
  GlobalProviderFunction() : super(() {});

  ///```
  /// Dialog pop Function
  ///```
  void dialogCloseFn(BuildContext context) {
    Navigator.pop(context);
  }
}
