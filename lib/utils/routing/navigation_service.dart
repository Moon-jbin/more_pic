import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _singleton = NavigationService._internal();

  factory NavigationService() {
    return _singleton;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void routerGo(BuildContext context, String routeName,
      {Map<String, dynamic> queryParams = const {}}) {
    // clearHomeData(ref);
    context.goNamed(routeName, queryParams: queryParams);
  }

  void routerReplace(BuildContext context, String routeName,
      {Map<String, dynamic> queryParams = const {}}) {
    context.replaceNamed(routeName, queryParams: queryParams);
  }
}
