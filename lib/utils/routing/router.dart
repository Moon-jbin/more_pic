// FILE: lib/utils/routing/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:more_pic/main.dart';
import 'package:more_pic/global/component/product_list_page.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/screen/order_form_screen.dart';
import 'package:more_pic/screen/product_detail_screen.dart';
import 'package:more_pic/utils/routing/router_name.dart';

CustomTransitionPage buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.05);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeOutQuart));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // 1. 메인 홈
    GoRoute(
      name: '/',
      path: '/',
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const MorePicWebService(),
      ),
    ),
    GoRoute(
      name: OrderFormScreenRoute,
      path: OrderFormScreenRoute,
      pageBuilder: (context, state) => buildPageWithTransition(
        context: context,
        state: state,
        child: const OrderFormScreen(),
      ),
    ),

    // 2. 아이템 상세 페이지
    GoRoute(
      path: '/product/:category/:id',
      name: 'productDetail',
      pageBuilder: (context, state) {
        String category = state.params['category'] ?? '';
        String productId = state.params['id'] ?? '-1';
        
        ProductModel? extraProduct = state.extra as ProductModel?;

        return buildPageWithTransition(
          context: context,
          state: state,
          child: ProductDetailScreen(
            category: category, 
            productId: productId,
            productExtra: extraProduct,
          ),
        );
      },
    ),

    // 3. 카테고리 매칭 Catch-All 라우트
    GoRoute(
      path: '/:pathSegments(.*)',
      pageBuilder: (context, state) {
        final rawSegments = state.params['pathSegments'] ?? '';
        final List<String> segments =
            rawSegments.split('/').where((s) => s.isNotEmpty).toList();

        if (segments.isEmpty) {
          return buildPageWithTransition(
            context: context,
            state: state,
            // ⭐️ CustomScaffold 래퍼 제거!
            child: const ProductListPage(category: 'all'),
          );
        }

        String combinedCat = segments.first;
        for (int i = 1; i < segments.length; i++) {
          final s = segments[i];
          final subParts = s.split('_');
          for (var sub in subParts) {
            if (sub.isNotEmpty) {
              combinedCat += '${sub[0].toUpperCase()}${sub.substring(1)}';
            }
          }
        }

        return buildPageWithTransition(
          context: context,
          state: state,
          // ⭐️ CustomScaffold 래퍼 제거!
          child: ProductListPage(category: combinedCat),
        );
      },
    ),
  ],
);