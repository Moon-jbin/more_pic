import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:more_pic/main.dart';
import 'package:more_pic/screen/general_screen.dart'; // 각 스크린이 정의되어 있다고 가정
import 'package:more_pic/screen/product_detail_screen.dart';
import 'package:more_pic/utils/routing/router_name.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // ==========================================
    // 🏠 메인 페이지
    // ==========================================
    GoRoute(
      name: MainRoute,
      path: MainRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: MorePicWebService());
      },
    ),

    // ==========================================
    // 👶 신생아~3M (Newborn)
    // ==========================================
    GoRoute(
      name: NewbornClothesRoute,
      path: NewbornClothesRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: NewbornClothesScreen());
      },
    ),
    GoRoute(
      name: NewbornSocksRoute,
      path: NewbornSocksRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: NewbornSocksScreen());
      },
    ),

    // ==========================================
    // 🍼 BABY (0~18m)
    // ==========================================
    GoRoute(
      name: BabyOuterJumperJacketRoute,
      path: BabyOuterJumperJacketRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: BabyOuterJumperJacketScreen());
      },
    ),
    GoRoute(
      name: BabyOuterCardiganCroppedRoute,
      path: BabyOuterCardiganCroppedRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: BabyOuterCardiganCroppedScreen());
      },
    ),
    GoRoute(
      name: BabyOuterCardiganGraphicTeesRoute,
      path: BabyOuterCardiganGraphicTeesRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(
            child: BabyOuterCardiganGraphicTeesScreen());
      },
    ),
    GoRoute(
      name: BabyOuterVestRoute,
      path: BabyOuterVestRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: BabyOuterVestScreen());
      },
    ),
    GoRoute(
      name: BabyTopRoute,
      path: BabyTopRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: BabyTopScreen());
      },
    ),
    GoRoute(
      name: BabyBottomRoute,
      path: BabyBottomRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: BabyBottomScreen());
      },
    ),
    GoRoute(
      name: BabySetDressRoute,
      path: BabySetDressRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: BabySetDressScreen());
      },
    ),

    // ==========================================
    // 🧸 KIDS (24m~)
    // ==========================================
    GoRoute(
      name: KidsOuterJumperJacketRoute,
      path: KidsOuterJumperJacketRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: KidsOuterJumperJacketScreen());
      },
    ),
    GoRoute(
      name: KidsOuterCardiganCroppedRoute,
      path: KidsOuterCardiganCroppedRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: KidsOuterCardiganCroppedScreen());
      },
    ),
    GoRoute(
      name: KidsOuterCardiganGraphicTeesRoute,
      path: KidsOuterCardiganGraphicTeesRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(
            child: KidsOuterCardiganGraphicTeesScreen());
      },
    ),
    GoRoute(
      name: KidsOuterVestRoute,
      path: KidsOuterVestRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: KidsOuterVestScreen());
      },
    ),
    GoRoute(
      name: KidsTopRoute,
      path: KidsTopRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: KidsTopScreen());
      },
    ),
    GoRoute(
      name: KidsBottomRoute,
      path: KidsBottomRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: KidsBottomScreen());
      },
    ),
    GoRoute(
      name: KidsSetDressRoute,
      path: KidsSetDressRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: KidsSetDressScreen());
      },
    ),

    // ==========================================
    // 🩲 내복 (Innerwear)
    // ==========================================
    GoRoute(
      name: InnerRoute,
      path: InnerRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: InnerScreen());
      },
    ),

    // ==========================================
    // 🎀 ACC (악세사리)
    // ==========================================
    GoRoute(
      name: AccSocksBabyRoute,
      path: AccSocksBabyRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: AccSocksBabyScreen());
      },
    ),
    GoRoute(
      name: AccSocksKidsRoute,
      path: AccSocksKidsRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: AccSocksKidsScreen());
      },
    ),
    GoRoute(
      name: AccHatsBeaniesRoute,
      path: AccHatsBeaniesRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: AccHatsBeaniesScreen());
      },
    ),
    GoRoute(
      name: AccHairAccessoriesRoute,
      path: AccHairAccessoriesRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: AccHairAccScreen());
      },
    ),
    GoRoute(
      name: AccOtherRoute,
      path: AccOtherRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: AccOtherScreen());
      },
    ),

    // ==========================================
    // ☀️ SEASON (시즌 상품)
    // ==========================================
    GoRoute(
      name: SeasonSummerRoute,
      path: SeasonSummerRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: SeasonSummerScreen());
      },
    ),
    GoRoute(
      name: SeasonWinterRoute,
      path: SeasonWinterRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: SeasonWinterScreen());
      },
    ),
    GoRoute(
      name: SeasonHolidaysRoute,
      path: SeasonHolidaysRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: SeasonHolidaysScreen());
      },
    ),

    // ==========================================
    // 🏷️ SALE (세일 상품)
    // ==========================================
    GoRoute(
      name: SaleRoute,
      path: SaleRoute,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const NoTransitionPage(child: SaleScreen());
      },
    ),

    // ===========================================
    // 아이템 상세 페이지
    //============================================
    GoRoute(
      // 💡 주소창에 :category와 :id 라는 구멍 두 개를 뚫어놓습니다.
      path: '/product/:category/:id',
      name: 'productDetail',
      pageBuilder: (BuildContext context, GoRouterState state) {
        String category = state.params['category'] ?? '';
        String productId = (state.params['id'] ?? '-1');
        return NoTransitionPage(
            child:
                ProductDetailScreen(category: category, productId: productId));
      },
    ),
  ],
);
