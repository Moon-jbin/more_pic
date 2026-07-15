import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:more_pic/main.dart';
import 'package:more_pic/global/component/product_list_page.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/screen/product_detail_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // 📌 1. 메인 웹 홈화면 대문 게이트 (보존)
    GoRoute(
      name: '/',
      path: '/',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: MorePicWebService());
      },
    ),

    // 📌 2. 아이템 상세 페이지 관문 라우팅 (보존)
    GoRoute(
      path: '/product/:category/:id',
      name: 'productDetail',
      pageBuilder: (BuildContext context, GoRouterState state) {
        String category = state.params['category'] ?? '';
        String productId = state.params['id'] ?? '-1';
        return NoTransitionPage(
            child:
                ProductDetailScreen(category: category, productId: productId));
      },
    ),

    // 📌 3. [완치]: 4단계, 5단계 등 무제한 뎁스 매칭 Catch-All 라우터 가드
    // 주소창 뒤에 슬래시(/)가 몇 개가 들어오든 전부 낚아채서 배열로 쪼갠 후 CamelCase로 조합합니다!
    GoRoute(
      path: '/:pathSegments(.*)', // 👈 들어오는 모든 하위 경로를 통째로 납치합니다.
      pageBuilder: (context, state) {
        final rawSegments =
            state.params['pathSegments'] ?? state.params['pathSegments'] ?? '';

        // 슬래시(/) 기준으로 쪼개서 빈 값 제거한 배열 생성 (예: ['baby', 'outer', 'jumper', 'jacket'])
        final List<String> segments =
            rawSegments.split('/').where((s) => s.isNotEmpty).toList();

        if (segments.isEmpty) {
          return NoTransitionPage(
            child: CustomScaffold(
              category: 'all',
              bodyBuilder: (ctx, sController) => ProductListPage(
                  scrollController: sController, category: 'all'),
            ),
          );
        }

        // 🌟 [무제한 카멜케이스 자동 합성 수식]: segments가 몇 개가 있든 babyOuterJumperJacket 형태로 루프 변환합니다.
        String combinedCat = segments.first;
        for (int i = 1; i < segments.length; i++) {
          final s = segments[i];
          // 언더바(_) 분리 처리 및 CamelCase 합성
          final subParts = s.split('_');
          for (var sub in subParts) {
            if (sub.isNotEmpty) {
              combinedCat += '${sub[0].toUpperCase()}${sub.substring(1)}';
            }
          }
        }

        return NoTransitionPage(
          child: CustomScaffold(
            category: combinedCat,
            bodyBuilder: (ctx, sController) => ProductListPage(
                scrollController: sController, category: combinedCat),
          ),
        );
      },
    ),
  ],
);
