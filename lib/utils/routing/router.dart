import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:more_pic/main.dart';
import 'package:more_pic/screen/newborn/newborn_clothes_screen.dart';
import 'package:more_pic/utils/routing/router_name.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  // initialLocation: '/test2',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    //메인 페이지
    GoRoute(
      name: MainRoute,
      path: MainRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: MorePicWebService());
      },
    ),
    GoRoute(
      name: NewbornClothesRoute,
      path: NewbornClothesRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: NewbornClothesScreen());
      },
    ),
  ],
);
