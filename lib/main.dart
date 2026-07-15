// import 'dart:async';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:more_pic/data/menu_data.dart';
// import 'package:more_pic/firebase_options.dart';
// import 'package:more_pic/global/component/product_card.dart';
// import 'package:more_pic/global/custom_widget/custom_widget.dart';
// import 'package:more_pic/global/global.dart';
// import 'package:more_pic/provider/admin_settings_provider.dart';
// import 'package:more_pic/provider/search_provider.dart';
// import 'package:more_pic/provider/product_db_provider.dart'; // 💡 상품 프로바이더 임포트
// import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
// import 'package:more_pic/utils/dialog/dlg_function.dart';
// import 'package:more_pic/utils/routing/navigation_service.dart';
// import 'package:more_pic/utils/routing/router.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:more_pic/utils/routing/router_name.dart';

// // [DesktopHoverMenu 및 이하 하위 호버 위젯 로직 변동 없이 기존과 완전히 동일]
// MenuController? _globalActiveController;
// VoidCallback? _globalActiveCloseTrigger;

// class DesktopHoverMenu extends HookConsumerWidget {
//   final String title;
//   final List<dynamic> items;

//   const DesktopHoverMenu({super.key, required this.title, required this.items});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final searchContentRead = ref.read(searchContentProvider.notifier);
//     final controller = useMemoized(() => MenuController());
//     final hoverCount = useState(0);
//     final debounceTimer = useRef<Timer?>(null);

//     useEffect(() {
//       return () {
//         debounceTimer.value?.cancel();
//         if (_globalActiveController == controller) {
//           _globalActiveController = null;
//           _globalActiveCloseTrigger = null;
//         }
//       };
//     }, []);

//     void decrementHover() {
//       hoverCount.value--;
//       debounceTimer.value?.cancel();
//       debounceTimer.value = Timer(const Duration(milliseconds: 100), () {
//         if (hoverCount.value <= 0) {
//           controller.close();
//           if (_globalActiveController == controller) {
//             _globalActiveController = null;
//             _globalActiveCloseTrigger = null;
//           }
//         }
//       });
//     }

//     void incrementHover() {
//       debounceTimer.value?.cancel();
//       hoverCount.value++;

//       if (_globalActiveController != null &&
//           _globalActiveController != controller) {
//         try {
//           _globalActiveController!.close();
//         } catch (_) {}
//         if (_globalActiveCloseTrigger != null) {
//           try {
//             _globalActiveCloseTrigger!();
//           } catch (_) {}
//         }
//       }

//       _globalActiveController = controller;
//       _globalActiveCloseTrigger = () {
//         hoverCount.value = 0;
//         decrementHover();
//       };
//       controller.open();
//     }

//     Widget buildMenuChild(WidgetRef ref, Map<String, dynamic> item) {
//       final List? children = item['children'];
//       final bool hasChildren = children != null && children.isNotEmpty;
//       final bool isTouchDevice = kIsWeb &&
//           (defaultTargetPlatform == TargetPlatform.iOS ||
//               defaultTargetPlatform == TargetPlatform.android);

//       if (!hasChildren) {
//         return MouseRegion(
//           onEnter: (_) => incrementHover(),
//           onExit: (_) => decrementHover(),
//           child: MenuItemButton(
//             onPressed: () {
//               NavigationService().routerGo(context, item['path'] ?? '/');
//               searchContentRead.initState();
//             },
//             style: TextButton.styleFrom(
//               alignment: Alignment.centerLeft,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2),
//             ),
//             child: Text(item['title'],
//                 style: const TextStyle(fontSize: 13, color: Colors.black87)),
//           ),
//         );
//       }

//       if (isTouchDevice) {
//         return PopupMenuButton<String>(
//           tooltip: item['title'],
//           offset: const Offset(120, 0),
//           style: TextButton.styleFrom(
//               alignment: Alignment.centerLeft,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
//           onSelected: (path) {
//             NavigationService().routerGo(context, path);
//             searchContentRead.initState();
//           },
//           itemBuilder: (BuildContext context) {
//             return children.map<PopupMenuEntry<String>>((child) {
//               return PopupMenuItem<String>(
//                   value: child['path'] ?? '/',
//                   child: Text(child['title'],
//                       style: const TextStyle(fontSize: 13)));
//             }).toList();
//           },
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(item['title'],
//                   style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black)),
//               Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
//             ],
//           ),
//         );
//       }

//       return MouseRegion(
//         onEnter: (_) => incrementHover(),
//         onExit: (_) => decrementHover(),
//         child: SubmenuButton(
//           menuStyle: const MenuStyle(
//             backgroundColor: WidgetStatePropertyAll(Colors.white),
//             surfaceTintColor: WidgetStatePropertyAll(Colors.white),
//             elevation: WidgetStatePropertyAll(3),
//             padding: WidgetStatePropertyAll(EdgeInsets.zero),
//           ),
//           style: TextButton.styleFrom(
//               alignment: Alignment.centerLeft,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               iconColor: Colors.grey.shade400,
//               overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2)),
//           menuChildren: [
//             MouseRegion(
//               onEnter: (_) => incrementHover(),
//               onExit: (_) => decrementHover(),
//               child: IntrinsicWidth(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: children
//                       .map<Widget>((child) => buildMenuChild(ref, child))
//                       .toList(),
//                 ),
//               ),
//             )
//           ],
//           child: Text(item['title'],
//               style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black)),
//         ),
//       );
//     }

//     if (items.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.only(right: 25),
//         child: InkWell(
//           onTap: () {
//             if (title == '내복') {
//               NavigationService().routerGo(context, InnerRoute);
//             } else if (title == 'SALE') {
//               NavigationService().routerGo(context, SaleRoute);
//             }
//             searchContentRead.initState();
//           },
//           child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Text(title,
//                   style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87))),
//         ),
//       );
//     }

//     return MouseRegion(
//       onEnter: (_) => incrementHover(),
//       onExit: (_) => decrementHover(),
//       child: MenuAnchor(
//         controller: controller,
//         style: const MenuStyle(
//           backgroundColor: WidgetStatePropertyAll(Colors.white),
//           surfaceTintColor: WidgetStatePropertyAll(Colors.white),
//           elevation: WidgetStatePropertyAll(3),
//           padding: WidgetStatePropertyAll(EdgeInsets.zero),
//         ),
//         menuChildren: [
//           MouseRegion(
//             onEnter: (_) => incrementHover(),
//             onExit: (_) => decrementHover(),
//             child: IntrinsicWidth(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: items
//                     .map<Widget>((item) => buildMenuChild(ref, item))
//                     .toList(),
//               ),
//             ),
//           )
//         ],
//         builder: (context, menuController, child) {
//           return Padding(
//             padding: const EdgeInsets.only(right: 25),
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               decoration: BoxDecoration(
//                   border: Border(
//                       bottom: BorderSide(
//                           color: menuController.isOpen
//                               ? const Color(0xFFD4CBE5)
//                               : Colors.transparent,
//                           width: 2))),
//               child: Text(title,
//                   style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87)),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class SubHoverMenu extends StatefulWidget {
//   final Map<String, dynamic> item;
//   const SubHoverMenu({super.key, required this.item});

//   @override
//   State<SubHoverMenu> createState() => _SubHoverMenuState();
// }

// class _SubHoverMenuState extends State<SubHoverMenu> {
//   final LayerLink _subLayerLink = LayerLink();
//   final OverlayPortalController _subController = OverlayPortalController();
//   bool _isTargetHovered = false;
//   bool _isOverlayHovered = false;

//   void _showMenu() {
//     _subController.show();
//   }

//   void _hideMenu() {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (!mounted) return;
//       if (!_isTargetHovered && !_isOverlayHovered) {
//         _subController.hide();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List? children = widget.item['children'];
//     final bool hasChildren = children != null && children.isNotEmpty;

//     return MouseRegion(
//       onEnter: (_) {
//         _isTargetHovered = true;
//         if (hasChildren) _showMenu();
//       },
//       onExit: (_) {
//         _isTargetHovered = false;
//         if (hasChildren) _hideMenu();
//       },
//       child: CompositedTransformTarget(
//         link: _subLayerLink,
//         child: OverlayPortal(
//           controller: _subController,
//           overlayChildBuilder: (context) {
//             return CompositedTransformFollower(
//                 link: _subLayerLink,
//                 targetAnchor: Alignment.topRight,
//                 followerAnchor: Alignment.topLeft,
//                 offset: const Offset(1, -1),
//                 child: MouseRegion(
//                   onEnter: (_) {
//                     _isOverlayHovered = true;
//                     _showMenu();
//                   },
//                   onExit: (_) {
//                     _isOverlayHovered = false;
//                     _hideMenu();
//                   },
//                   child: Align(
//                     alignment: Alignment.topLeft,
//                     child: Material(
//                       type: MaterialType.transparency,
//                       child: Container(
//                         decoration: BoxDecoration(
//                             color: Colors.white,
//                             border: Border.all(color: Colors.grey.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                   color: Colors.black.withOpacity(0.06),
//                                   blurRadius: 10,
//                                   offset: const Offset(4, 4))
//                             ]),
//                         constraints: const BoxConstraints(minWidth: 150),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: children!
//                               .map<Widget>((child) => SubHoverMenu(item: child))
//                               .toList(),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ));
//           },
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             color: (_isTargetHovered || _isOverlayHovered)
//                 ? const Color(0xFFF8F9FA)
//                 : Colors.white,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(widget.item['title'],
//                     style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: (_isTargetHovered || _isOverlayHovered)
//                             ? FontWeight.w500
//                             : FontWeight.w400,
//                         color: (_isTargetHovered || _isOverlayHovered)
//                             ? Colors.black
//                             : Colors.grey.shade700)),
//                 if (hasChildren)
//                   Icon(Icons.chevron_right,
//                       size: 14, color: Colors.grey.shade400),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   if (kIsWeb) {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//   } else {
//     await Firebase.initializeApp();
//   }

//   runApp(
//     const ProviderScope(
//       child: MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: '모어픽 | 본질에 집중한 미니멀 쇼핑',
//       theme: ThemeData(
//         scaffoldBackgroundColor: Colors.white,
//         fontFamily: 'NotoSansKR',
//       ),
//       debugShowCheckedModeBanner: false,
//       routerConfig: router,
//     );
//   }
// }

// // // 💡 메인 웹 서비스 컴포넌트 (신상품 나열 레이아웃 장착)
// // class MorePicWebService extends HookConsumerWidget {
// //   const MorePicWebService({super.key});

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final adminSettingsWatch = ref.watch(adminSettingsProvider);
// //     final adminSettingsRead = ref.read(adminSettingsProvider.notifier);
// //     final scrollController = useScrollController();
// //     final showButton = useState(false);
// //     final isScrolled = useState(false);

// //     final bool mobileMode = isMobile(context);

// //     // 📊 메인 홈화면에 보여줄 신상품 카테고리 데이터 실시간 로드
// //     // (현재 메인은 'all' 분류를 관장하므로 고정 주입)
// //     const String currentCategory = 'all';

// //     useEffect(() {
// //       void listener() {
// //         if (scrollController.hasClients) {
// //           // 1. 위로 가기 버튼 처리
// //           if (scrollController.offset > 150) {
// //             if (!showButton.value) showButton.value = true;
// //           } else {
// //             if (showButton.value) showButton.value = false;
// //           }

// //           // 2. 스크롤 섀도우/헤더 감축 가드 처리
// //           if (scrollController.offset > 0) {
// //             if (!isScrolled.value) isScrolled.value = true;
// //           } else {
// //             if (isScrolled.value) isScrolled.value = false;
// //           }

// //           // 🔥🔥🔥 [무한 스크롤 바닥 감지 엔진 도킹] ⭐⭐⭐
// //           // 사용자의 현재 스크롤 위치가 맨 최하단 길이에서 200px 대역 안으로 진입했는지 실시간 서칭
// //           if (scrollController.position.pixels >=
// //               scrollController.position.maxScrollExtent - 200) {
// //             // 물리적인 센서가 바닥에 충돌했으므로, 10개 끊어 읽기 노티파이어의 fetchNextPage를 딸깍 실행!
// //             ref
// //                 .read(paginatedProductProvider(currentCategory).notifier)
// //                 .fetchNextPage();
// //           }
// //         }
// //       }

// //       scrollController.addListener(listener);
// //       return () => scrollController.removeListener(listener);
// //     }, [scrollController]); // 디펜던시 스크롤 유지

// //     final double headerHeight = mobileMode ? 70 : 120;

// //     // 💡 디바이스 너비에 따라 한 줄에 몇 개의 아이템을 배치할지 격자 갯수 동적 계산
// //     double screenWidth = MediaQuery.of(context).size.width;
// //     int crossAxisCount = 4; // PC 모니터 기본 4열
// //     if (screenWidth < 600) {
// //       crossAxisCount = 3; // 모바일 2열 기본 국룰
// //     } else if (screenWidth < 1100) {
// //       crossAxisCount = 3; // 태블릿 3열
// //     }

// //     return Scaffold(
// //         backgroundColor: Colors.white,
// //         drawer: mobileMode
// //             ? CustomWidget.customDrawer(context, ref, menuData)
// //             : null,
// //         body: CustomScrollView(
// //           controller: scrollController, // 🌟 물리 센서와 캔버스 스크롤뷰 완벽 밀착 바인딩!
// //           slivers: [
// //             // 📌 [구조 1]: 상단 안내 배너
// //             SliverToBoxAdapter(
// //               child: Container(
// //                 margin: const EdgeInsets.only(bottom: 30),
// //                 width: double.infinity,
// //                 color: const Color(0xFFD4CBE5),
// //                 padding: const EdgeInsets.symmetric(vertical: 8),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           if (adminSettingsWatch) ...[
// //                             IconButton(
// //                               onPressed: () => showProductUploadDlgFn(context),
// //                               icon: const Icon(Icons.add_a_photo,
// //                                   color: Colors.black),
// //                               tooltip: '상품 업로드',
// //                             ),
// //                             IconButton(
// //                               onPressed: () => adminSettingsRead.initState(),
// //                               icon: const Icon(Icons.lock_open,
// //                                   color: Colors.red),
// //                               tooltip: '편집 모드 종료',
// //                             ),
// //                           ] else ...[
// //                             IconButton(
// //                               onPressed: () => showPasswordCheckDialog(context),
// //                               icon:
// //                                   const Icon(Icons.lock, color: Colors.black87),
// //                               tooltip: '관리자 편집모드 진입',
// //                             ),
// //                           ]
// //                         ]),
// //                     const Text(
// //                       '🖤 🖤 가격은 카톡방에서 확인 해주세요 🖤 🖤',
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(
// //                           color: Colors.black,
// //                           fontWeight: FontWeight.bold,
// //                           fontSize: 14),
// //                     ),
// //                     const SizedBox(width: 48)
// //                   ],
// //                 ),
// //               ),
// //             ),

// //             // 📌 [구조 2]: 상단 고정(Floating) 헤더 섹션
// //             SliverPersistentHeader(
// //               pinned: true,
// //               delegate: SliverHeaderDelegate(
// //                 height: headerHeight,
// //                 isScrolled: isScrolled.value,
// //                 child: Padding(
// //                   padding:
// //                       EdgeInsets.symmetric(horizontal: mobileMode ? 16 : 40),
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           if (mobileMode)
// //                             Builder(
// //                               builder: (context) => IconButton(
// //                                 icon: const Icon(Icons.menu,
// //                                     color: Colors.black, size: 28),
// //                                 onPressed: () =>
// //                                     Scaffold.of(context).openDrawer(),
// //                               ),
// //                             ),
// //                           CustomWidget.customLogo(context, ref,
// //                               fontSize: 38, letterSpacing: 1.5),
// //                           if (mobileMode)
// //                             IconButton(
// //                                 icon: const Icon(Icons.search,
// //                                     color: Colors.black, size: 26),
// //                                 onPressed: () {}),
// //                         ],
// //                       ),
// //                       if (!mobileMode) ...[
// //                         const SizedBox(height: 10),
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                           children: [
// //                             Row(
// //                               children: menuData.map((menu) {
// //                                 return DesktopHoverMenu(
// //                                   title: menu['title'],
// //                                   items: menu['children'] ?? [],
// //                                 );
// //                               }).toList(),
// //                             ),
// //                             IconButton(
// //                                 icon: const Icon(Icons.search,
// //                                     color: Colors.black, size: 26),
// //                                 onPressed: () {}),
// //                           ],
// //                         ),
// //                       ]
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),

// //             // 📌 [구조 3]: NEW ARRIVALS 타이틀 바 섹션
// //             SliverToBoxAdapter(
// //               child: Padding(
// //                 padding: EdgeInsets.fromLTRB(
// //                     mobileMode ? 16 : 40, 40, mobileMode ? 16 : 40, 16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       'NEW ARRIVALS',
// //                       style: TextStyle(
// //                           fontSize: 20,
// //                           fontWeight: FontWeight.w900,
// //                           letterSpacing: 1.2,
// //                           color: Colors.black),
// //                     ),
// //                     const SizedBox(height: 4),
// //                     Container(
// //                         width: 45, height: 3, color: const Color(0xFF4A6FA5)),
// //                   ],
// //                 ),
// //               ),
// //             ),

// //             // 📌 [구조 4]: 10개씩 끊어 읽는 무한 스크롤 격자 리스트 구역 (튕김 박멸 버전)
// //             // .when 대신 .skipLoadingOnTrigger를 주거나 상태 데이터를 직접 분해합니다.
// //             ref.watch(paginatedProductProvider(currentCategory)).when(
// //                   // 🌟 [핵심 변경]: 처음 앱 켤 때 '완전 최초 로딩'일 때만 화면 중앙 로딩바를 띄웁니다.
// //                   loading: () => const SliverToBoxAdapter(
// //                     child: Center(
// //                       child: Padding(
// //                         padding: EdgeInsets.symmetric(vertical: 100),
// //                         child:
// //                             CircularProgressIndicator(color: Color(0xFF4A6FA5)),
// //                       ),
// //                     ),
// //                   ),
// //                   error: (err, stack) => SliverToBoxAdapter(
// //                     child: Center(
// //                       child: Text('❌ 상품 로드 오류: $err',
// //                           style: const TextStyle(color: Colors.red)),
// //                     ),
// //                   ),
// //                   data: (stateData) {
// //                     final items = stateData.items;

// //                     if (items.isEmpty) {
// //                       return const SliverToBoxAdapter(
// //                         child: Center(
// //                           child: Padding(
// //                             padding: EdgeInsets.symmetric(vertical: 120),
// //                             child: Text('신상 상품이 존재하지 않습니다.',
// //                                 style: TextStyle(color: Colors.grey)),
// //                           ),
// //                         ),
// //                       );
// //                     }

// //                     // 💡 현재 리버팟 창고가 "기존 데이터를 들고 있는 채로 추가 로딩 중(isRefreshing)"인지 파악합니다.
// //                     final isNextPageLoading = ref
// //                         .watch(paginatedProductProvider(currentCategory))
// //                         .isRefreshing;

// //                     return SliverMainAxisGroup(
// //                       slivers: [
// //                         // 1️⃣ 기존에 불러온 상품 격자는 어떤 순간에도 화면에서 지우지 않고 철통 사수합니다! (높이 유지 = 스크롤 고정)
// //                         SliverPadding(
// //                           padding: EdgeInsets.symmetric(
// //                               horizontal: mobileMode ? 16 : 40, vertical: 10),
// //                           sliver: SliverGrid(
// //                             gridDelegate:
// //                                 SliverGridDelegateWithFixedCrossAxisCount(
// //                               crossAxisCount: crossAxisCount,
// //                               mainAxisSpacing: 30,
// //                               crossAxisSpacing: 16,
// //                               childAspectRatio: 0.68,
// //                             ),
// //                             delegate: SliverChildBuilderDelegate(
// //                               (context, index) {
// //                                 final product = items[index];
// //                                 return ProductCard(
// //                                   product: product,
// //                                   onDelete: () async {
// //                                     // 🎉 해당 개별 카테고리 가방을 즉시 리셋 시켜 새로 고쳐 읽습니다.
// //                                     ref.invalidate(paginatedProductProvider(
// //                                         currentCategory));

// //                                     // 피드백 스낵바 전송
// //                                     if (context.mounted) {
// //                                       ScaffoldMessenger.of(context)
// //                                           .clearSnackBars();
// //                                       ScaffoldMessenger.of(context)
// //                                           .showSnackBar(
// //                                         const SnackBar(
// //                                             content: Text(
// //                                                 '🎉 상품 진열이 정상적으로 철수되었습니다.')),
// //                                       );
// //                                     }
// //                                   },
// //                                 );
// //                               },
// //                               childCount: items.length,
// //                             ),
// //                           ),
// //                         ),

// //                         // 2️⃣ 다음 페이지를 조용히 긁어오는 중일 때만, 격자 바로 밑에 미니 로딩바를 스르륵 끼워 넣어 줍니다.
// //                         if (isNextPageLoading)
// //                           const SliverToBoxAdapter(
// //                             child: Padding(
// //                               padding: EdgeInsets.symmetric(vertical: 24),
// //                               child: Center(
// //                                 child: SizedBox(
// //                                   width: 24,
// //                                   height: 24,
// //                                   child: CircularProgressIndicator(
// //                                       strokeWidth: 2, color: Color(0xFF4A6FA5)),
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                       ],
// //                     );
// //                   },
// //                 ),

// //             // 📌 [구조 5]: 바닥 고정 푸터 통합 바인딩
// //             SliverToBoxAdapter(
// //               child: Column(
// //                 children: [
// //                   CustomWidget.customFooter(context, ref, isMobile: mobileMode),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //         floatingActionButton: CustomWidget.customFloatingBtn(
// //             showButton: showButton, scrollController: scrollController));
// //   }
// // }

// // 💡 메인 웹 서비스 컴포넌트 (상품 리스트만 PC 여백 격리 장착 버전)
// // class MorePicWebService extends HookConsumerWidget {
// //   const MorePicWebService({super.key});

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final adminSettingsWatch = ref.watch(adminSettingsProvider);
// //     final adminSettingsRead = ref.read(adminSettingsProvider.notifier);
// //     final scrollController = useScrollController();
// //     final showButton = useState(false);
// //     final isScrolled = useState(false);

// //     final bool mobileMode = isMobile(context);
// //     const String currentCategory = 'all';

// //     useEffect(() {
// //       void listener() {
// //         if (scrollController.hasClients) {
// //           if (scrollController.offset > 150) {
// //             if (!showButton.value) showButton.value = true;
// //           } else {
// //             if (showButton.value) showButton.value = false;
// //           }

// //           if (scrollController.offset > 0) {
// //             if (!isScrolled.value) isScrolled.value = true;
// //           } else {
// //             if (isScrolled.value) isScrolled.value = false;
// //           }

// //           if (scrollController.position.pixels >=
// //               scrollController.position.maxScrollExtent - 200) {
// //             ref
// //                 .read(paginatedProductProvider(currentCategory).notifier)
// //                 .fetchNextPage();
// //           }
// //         }
// //       }

// //       scrollController.addListener(listener);
// //       return () => scrollController.removeListener(listener);
// //     }, [scrollController]);

// //     final double headerHeight = mobileMode ? 70 : 120;

// //     // 💡 [동적 화면 계산식]: 모니터 너비에 따라 상품 리스트 구역만 양옆 공백 패딩을 실시간 계산합니다.
// //     double screenWidth = MediaQuery.of(context).size.width;
// //     int crossAxisCount = 3; // 상품은 무조건 3열 고정

// //     // PC 대화면일 때 상품 구역 가로 최대폭을 1280으로 묶기 위한 반응형 패딩 연산
// //     double horizontalPadding = mobileMode ? 16 : 40;
// //     if (!mobileMode && screenWidth > 1360) {
// //       // (현재 전체 모니터 너비 - 목표 1280px) / 2 = 좌우에 줘야 할 완벽한 공백값 계산식 작동!
// //       horizontalPadding = (screenWidth - 1280) / 2;
// //     }

// //     return Scaffold(
// //         backgroundColor: Colors.white,
// //         drawer: mobileMode
// //             ? CustomWidget.customDrawer(context, ref, menuData)
// //             : null,
// //         // 🌟 [해제 완료]: 전체를 가두던 제한 가방을 풀어서 헤더/푸터가 좌우 100% 꽉 차게 복구했습니다!
// //         body: CustomScrollView(
// //           controller: scrollController,
// //           slivers: [
// //             // 📌 [구조 1]: 상단 안내 배너 (화면 끝까지 100% 확장)
// //             SliverToBoxAdapter(
// //               child: Container(
// //                 margin: const EdgeInsets.only(bottom: 30),
// //                 width: double.infinity,
// //                 color: const Color(0xFFD4CBE5),
// //                 padding: const EdgeInsets.symmetric(vertical: 8),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           if (adminSettingsWatch) ...[
// //                             IconButton(
// //                               onPressed: () => showProductUploadDlgFn(context),
// //                               icon: const Icon(Icons.add_a_photo,
// //                                   color: Colors.black),
// //                               tooltip: '상품 업로드',
// //                             ),
// //                             IconButton(
// //                               onPressed: () => adminSettingsRead.initState(),
// //                               icon: const Icon(Icons.lock_open,
// //                                   color: Colors.red),
// //                               tooltip: '편집 모드 종료',
// //                             ),
// //                           ] else ...[
// //                             IconButton(
// //                               onPressed: () => showPasswordCheckDialog(context),
// //                               icon:
// //                                   const Icon(Icons.lock, color: Colors.black87),
// //                               tooltip: '관리자 편집모드 진입',
// //                             ),
// //                           ]
// //                         ]),
// //                     const Text(
// //                       '🖤 🖤 가격은 카톡방에서 확인 해주세요 🖤 🖤',
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(
// //                           color: Colors.black,
// //                           fontWeight: FontWeight.bold,
// //                           fontSize: 14),
// //                     ),
// //                     const SizedBox(width: 48)
// //                   ],
// //                 ),
// //               ),
// //             ),

// //             // 📌 [구조 2]: 상단 고정(Floating) 헤더 섹션 (메뉴바 전체 100% 확장 수용)
// //             SliverPersistentHeader(
// //               pinned: true,
// //               delegate: SliverHeaderDelegate(
// //                 height: headerHeight,
// //                 isScrolled: isScrolled.value,
// //                 child: Padding(
// //                   padding: const EdgeInsets.symmetric(
// //                       horizontal: 40), // 헤더는 기존 와이드 패딩 유지
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           if (mobileMode)
// //                             Builder(
// //                               builder: (context) => IconButton(
// //                                 icon: const Icon(Icons.menu,
// //                                     color: Colors.black, size: 28),
// //                                 onPressed: () =>
// //                                     Scaffold.of(context).openDrawer(),
// //                               ),
// //                             ),
// //                           CustomWidget.customLogo(context, ref,
// //                               fontSize: 38, letterSpacing: 1.5),
// //                           if (mobileMode)
// //                             IconButton(
// //                                 icon: const Icon(Icons.search,
// //                                     color: Colors.black, size: 26),
// //                                 onPressed: () {}),
// //                         ],
// //                       ),
// //                       if (!mobileMode) ...[
// //                         const SizedBox(height: 10),
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                           children: [
// //                             Row(
// //                               children: menuData.map((menu) {
// //                                 return DesktopHoverMenu(
// //                                   title: menu['title'],
// //                                   items: menu['children'] ?? [],
// //                                 );
// //                               }).toList(),
// //                             ),
// //                             IconButton(
// //                                 icon: const Icon(Icons.search,
// //                                     color: Colors.black, size: 26),
// //                                 onPressed: () {}),
// //                           ],
// //                         ),
// //                       ]
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),

// //             // 📌 [구조 3]: NEW ARRIVALS 타이틀 바 섹션 (상품 리스트와 시작 줄을 맞추기 위해 가변 패딩 적용!)
// //             SliverToBoxAdapter(
// //               child: Padding(
// //                 padding: EdgeInsets.fromLTRB(
// //                     horizontalPadding, 40, horizontalPadding, 16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       'NEW ARRIVALS',
// //                       style: TextStyle(
// //                           fontSize: 20,
// //                           fontWeight: FontWeight.w900,
// //                           letterSpacing: 1.2,
// //                           color: Colors.black),
// //                     ),
// //                     const SizedBox(height: 4),
// //                     Container(
// //                         width: 45, height: 3, color: const Color(0xFF4A6FA5)),
// //                   ],
// //                 ),
// //               ),
// //             ),

// //             // 📌 [구조 4]: 10개씩 끊어 읽는 무한 스크롤 격자 리스트 구역
// //             ref.watch(paginatedProductProvider(currentCategory)).when(
// //                   loading: () => const SliverToBoxAdapter(
// //                     child: Center(
// //                       child: Padding(
// //                         padding: EdgeInsets.symmetric(vertical: 100),
// //                         child:
// //                             CircularProgressIndicator(color: Color(0xFF4A6FA5)),
// //                       ),
// //                     ),
// //                   ),
// //                   error: (err, stack) => SliverToBoxAdapter(
// //                     child: Center(
// //                       child: Text('❌ 상품 로드 오류: $err',
// //                           style: const TextStyle(color: Colors.red)),
// //                     ),
// //                   ),
// //                   data: (stateData) {
// //                     final items = stateData.items;

// //                     if (items.isEmpty) {
// //                       return const SliverToBoxAdapter(
// //                         child: Center(
// //                           child: Padding(
// //                             padding: EdgeInsets.symmetric(vertical: 120),
// //                             child: Text('신상 상품이 존재하지 않습니다.',
// //                                 style: TextStyle(color: Colors.grey)),
// //                           ),
// //                         ),
// //                       );
// //                     }

// //                     final isNextPageLoading = ref
// //                         .watch(paginatedProductProvider(currentCategory))
// //                         .isRefreshing;

// //                     return SliverMainAxisGroup(
// //                       slivers: [
// //                         // 🌟 [핵심 변경 타겟 파트]
// //                         SliverPadding(
// //                           // 실시간으로 계산해 낸 horizontalPadding을 주입하여 오직 이 상품 구역만 1280px로 가지런히 모읍니다!
// //                           padding: EdgeInsets.symmetric(
// //                               horizontal: horizontalPadding, vertical: 10),
// //                           sliver: SliverGrid(
// //                             gridDelegate:
// //                                 SliverGridDelegateWithFixedCrossAxisCount(
// //                               crossAxisCount: crossAxisCount,
// //                               mainAxisSpacing: mobileMode ? 12 : 35,
// //                               crossAxisSpacing: mobileMode ? 8 : 20,
// //                               childAspectRatio: mobileMode ? 0.55 : 0.65,
// //                             ),
// //                             delegate: SliverChildBuilderDelegate(
// //                               (context, index) {
// //                                 final product = items[index];
// //                                 return ProductCard(
// //                                     product: product,
// //                                     onDelete: () async {
// //                                       // 🎉 해당 개별 카테고리 가방을 즉시 리셋 시켜 새로 고쳐 읽습니다.
// //                                       ref.invalidate(paginatedProductProvider(
// //                                           currentCategory));

// //                                       // 피드백 스낵바 전송
// //                                       if (context.mounted) {
// //                                         ScaffoldMessenger.of(context)
// //                                             .clearSnackBars();
// //                                         ScaffoldMessenger.of(context)
// //                                             .showSnackBar(
// //                                           const SnackBar(
// //                                               content: Text(
// //                                                   '🎉 상품 진열이 정상적으로 철수되었습니다.')),
// //                                         );
// //                                       }
// //                                     });
// //                               },
// //                               childCount: items.length,
// //                             ),
// //                           ),
// //                         ),
// //                         if (isNextPageLoading)
// //                           SliverPadding(
// //                             padding: EdgeInsets.symmetric(
// //                                 horizontal: horizontalPadding),
// //                             sliver: const SliverToBoxAdapter(
// //                               child: Padding(
// //                                 padding: EdgeInsets.symmetric(vertical: 24),
// //                                 child: Center(
// //                                   child: SizedBox(
// //                                     width: 24,
// //                                     height: 24,
// //                                     child: CircularProgressIndicator(
// //                                         strokeWidth: 2,
// //                                         color: Color(0xFF4A6FA5)),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                       ],
// //                     );
// //                   },
// //                 ),

// //             // 📌 [구조 5]: 바닥 고정 푸터 통합 바인딩 (다시 화면 끝까지 와이드하게 확장)
// //             SliverToBoxAdapter(
// //               child: Column(
// //                 children: [
// //                   CustomWidget.customFooter(context, ref, isMobile: mobileMode),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //         floatingActionButton: CustomWidget.customFloatingBtn(
// //             showButton: showButton, scrollController: scrollController));
// //   }
// // }

// // 💡 메인 웹 서비스 컴포넌트 (멀티 카테고리 배열 스펙 완벽 연동 완료!)
// class MorePicWebService extends HookConsumerWidget {
//   const MorePicWebService({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final adminSettingsWatch = ref.watch(adminSettingsProvider);
//     final adminSettingsRead = ref.read(adminSettingsProvider.notifier);
//     final scrollController = useScrollController();
//     final showButton = useState(false);
//     final isScrolled = useState(false);

//     final bool mobileMode = isMobile(context);
//     const String currentCategory = 'all';

//     useEffect(() {
//       void listener() {
//         if (scrollController.hasClients) {
//           if (scrollController.offset > 150) {
//             if (!showButton.value) showButton.value = true;
//           } else {
//             if (showButton.value) showButton.value = false;
//           }

//           if (scrollController.offset > 0) {
//             if (!isScrolled.value) isScrolled.value = true;
//           } else {
//             if (isScrolled.value) isScrolled.value = false;
//           }

//           if (scrollController.position.pixels >=
//               scrollController.position.maxScrollExtent - 200) {
//             ref
//                 .read(paginatedProductProvider(currentCategory).notifier)
//                 .fetchNextPage();
//           }
//         }
//       }

//       scrollController.addListener(listener);
//       return () => scrollController.removeListener(listener);
//     }, [scrollController]);

//     final double headerHeight = mobileMode ? 70 : 120;

//     // 💡 [동적 화면 계산식]: 모니터 너비에 따라 상품 리스트 구역만 양옆 공백 패딩을 실시간 계산합니다.
//     double screenWidth = MediaQuery.of(context).size.width;
//     int crossAxisCount = 3; // 상품은 무조건 3열 고정

//     // PC 대화면일 때 상품 구역 가로 최대폭을 1280으로 묶기 위한 반응형 패딩 연산
//     double horizontalPadding = mobileMode ? 16 : 40;
//     if (!mobileMode && screenWidth > 1360) {
//       horizontalPadding = (screenWidth - 1280) / 2;
//     }

//     return Scaffold(
//         backgroundColor: Colors.white,
//         drawer: mobileMode
//             ? CustomWidget.customDrawer(context, ref, menuData)
//             : null,
//         body: CustomScrollView(
//           controller: scrollController,
//           slivers: [
//             // 📌 [구조 1]: 상단 안내 배너
//             SliverToBoxAdapter(
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 30),
//                 width: double.infinity,
//                 color: const Color(0xFFD4CBE5),
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           if (adminSettingsWatch) ...[
//                             IconButton(
//                               onPressed: () => showProductUploadDlgFn(context),
//                               icon: const Icon(Icons.add_a_photo,
//                                   color: Colors.black),
//                               tooltip: '상품 업로드',
//                             ),
//                             IconButton(
//                               onPressed: () => adminSettingsRead.initState(),
//                               icon: const Icon(Icons.lock_open,
//                                   color: Colors.red),
//                               tooltip: '편집 모드 종료',
//                             ),
//                           ] else ...[
//                             IconButton(
//                               onPressed: () => showPasswordCheckDialog(context),
//                               icon:
//                                   const Icon(Icons.lock, color: Colors.black87),
//                               tooltip: '관리자 편집모드 진입',
//                             ),
//                           ]
//                         ]),
//                     const Text(
//                       '🖤 🖤 가격은 카톡방에서 확인 해주세요 🖤 🖤',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14),
//                     ),
//                     const SizedBox(width: 48)
//                   ],
//                 ),
//               ),
//             ),

//             // 📌 [구조 2]: 상단 고정(Floating) 헤더 섹션
//             SliverPersistentHeader(
//               pinned: true,
//               delegate: SliverHeaderDelegate(
//                 height: headerHeight,
//                 isScrolled: isScrolled.value,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 40),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           if (mobileMode)
//                             Builder(
//                               builder: (context) => IconButton(
//                                 icon: const Icon(Icons.menu,
//                                     color: Colors.black, size: 28),
//                                 onPressed: () =>
//                                     Scaffold.of(context).openDrawer(),
//                               ),
//                             ),
//                           CustomWidget.customLogo(context, ref,
//                               fontSize: 38, letterSpacing: 1.5),
//                           if (mobileMode)
//                             IconButton(
//                                 icon: const Icon(Icons.search,
//                                     color: Colors.black, size: 26),
//                                 onPressed: () {
//                                   ref
//                                       .read(searchBarOpenProvider.notifier)
//                                       .open();
//                                 }),
//                         ],
//                       ),
//                       if (!mobileMode) ...[
//                         const SizedBox(height: 10),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               children: menuData.map((menu) {
//                                 return DesktopHoverMenu(
//                                   title: menu['title'],
//                                   items: menu['children'] ?? [],
//                                 );
//                               }).toList(),
//                             ),
//                             IconButton(
//                                 icon: const Icon(Icons.search,
//                                     color: Colors.black, size: 26),
//                                 onPressed: () {
//                                   print('클릭');
//                                   ref
//                                       .read(searchBarOpenProvider.notifier)
//                                       .open();
//                                 }),
//                           ],
//                         ),
//                       ]
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // 📌 [구조 3]: NEW ARRIVALS 타이틀 바 섹션
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(
//                     horizontalPadding, 40, horizontalPadding, 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'NEW ARRIVALS',
//                       style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w900,
//                           letterSpacing: 1.2,
//                           color: Colors.black),
//                     ),
//                     const SizedBox(height: 4),
//                     Container(
//                         width: 45, height: 3, color: const Color(0xFF4A6FA5)),
//                   ],
//                 ),
//               ),
//             ),

//             // 📌 [구조 4]: 신형 무한 스크롤 격자 리스트 구역 도킹 완료 ⚡
//             ref.watch(paginatedProductProvider(currentCategory)).when(
//                   loading: () => const SliverToBoxAdapter(
//                     child: Center(
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(vertical: 100),
//                         child:
//                             CircularProgressIndicator(color: Color(0xFF4A6FA5)),
//                       ),
//                     ),
//                   ),
//                   error: (err, stack) => SliverToBoxAdapter(
//                     child: Center(
//                       child: Text('❌ 상품 로드 오류: $err',
//                           style: const TextStyle(color: Colors.red)),
//                     ),
//                   ),
//                   data: (stateData) {
//                     // 🌟 [완치 포인트 1]: 이제 장부 구조가 명화개졌으므로 .items 안에서 신형 ProductModel 배열을 안전하게 꺼냅니다.
//                     final List<ProductModel> items = stateData.items;

//                     if (items.isEmpty) {
//                       return const SliverToBoxAdapter(
//                         child: Center(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(vertical: 120),
//                             child: Text('신상 상품이 존재하지 않습니다.',
//                                 style: TextStyle(color: Colors.grey)),
//                           ),
//                         ),
//                       );
//                     }

//                     final isNextPageLoading = ref
//                         .watch(paginatedProductProvider(currentCategory))
//                         .isRefreshing;

//                     return SliverMainAxisGroup(
//                       slivers: [
//                         SliverPadding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: horizontalPadding, vertical: 10),
//                           sliver: SliverGrid(
//                             gridDelegate:
//                                 SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: crossAxisCount,
//                               mainAxisSpacing: mobileMode ? 12 : 35,
//                               crossAxisSpacing: mobileMode ? 8 : 20,
//                               childAspectRatio: mobileMode ? 0.55 : 0.65,
//                             ),
//                             // 🌟 [완치 포인트 2]: 레거시 ProductItem 타겟팅 연산을 완전히 도려내고
//                             // 오직 청정 단일 ID 및 신구조 갱신 루틴으로 정석 이식!
//                             delegate: SliverChildBuilderDelegate(
//                               (context, index) {
//                                 final product = items[index];
//                                 return ProductCard(
//                                   product: product,
//                                   onDelete: () async {
//                                     // 🗑️ 부모 위젯 리셋 신호 연동
//                                     ref.invalidate(paginatedProductProvider(
//                                         currentCategory));

//                                     if (context.mounted) {
//                                       ScaffoldMessenger.of(context)
//                                           .clearSnackBars();
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                             content: Text(
//                                                 '🎉 상품 진열이 정상적으로 철수되었습니다.')),
//                                       );
//                                     }
//                                   },
//                                 );
//                               },
//                               childCount: items.length,
//                             ),
//                           ),
//                         ),
//                         if (isNextPageLoading)
//                           SliverPadding(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: horizontalPadding),
//                             sliver: const SliverToBoxAdapter(
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(vertical: 24),
//                                 child: Center(
//                                   child: SizedBox(
//                                     width: 24,
//                                     height: 24,
//                                     child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Color(0xFF4A6FA5)),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     );
//                   },
//                 ),

//             // 📌 [구조 5]: 바닥 고정 푸터
//             SliverToBoxAdapter(
//               child: Column(
//                 children: [
//                   CustomWidget.customFooter(context, ref, isMobile: mobileMode),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         floatingActionButton: CustomWidget.customFloatingBtn(
//             showButton: showButton, scrollController: scrollController));
//   }
// }

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/data/menu_data.dart';
import 'package:more_pic/firebase_options.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart'; // 💡 슬라이딩 서치바 정상 바인딩
import 'package:more_pic/global/global.dart';
import 'package:more_pic/model/search_content.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'package:more_pic/utils/routing/navigation_service.dart';
import 'package:more_pic/utils/routing/router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/utils/routing/router_name.dart';

MenuController? _globalActiveController;
VoidCallback? _globalActiveCloseTrigger;

class DesktopHoverMenu extends HookConsumerWidget {
  final String title;
  final List<dynamic> items;

  const DesktopHoverMenu({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final controller = useMemoized(() => MenuController());
    final hoverCount = useState(0);
    final debounceTimer = useRef<Timer?>(null);

    useEffect(() {
      return () {
        debounceTimer.value?.cancel();
        if (_globalActiveController == controller) {
          _globalActiveController = null;
          _globalActiveCloseTrigger = null;
        }
      };
    }, []);

    void decrementHover() {
      hoverCount.value--;
      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(const Duration(milliseconds: 100), () {
        if (hoverCount.value <= 0) {
          controller.close();
          if (_globalActiveController == controller) {
            _globalActiveController = null;
            _globalActiveCloseTrigger = null;
          }
        }
      });
    }

    void incrementHover() {
      debounceTimer.value?.cancel();
      hoverCount.value++;

      if (_globalActiveController != null &&
          _globalActiveController != controller) {
        try {
          _globalActiveController!.close();
        } catch (_) {}
        if (_globalActiveCloseTrigger != null) {
          try {
            _globalActiveCloseTrigger!();
          } catch (_) {}
        }
      }

      _globalActiveController = controller;
      _globalActiveCloseTrigger = () {
        hoverCount.value = 0;
        decrementHover();
      };
      controller.open();
    }

    Widget buildMenuChild(WidgetRef ref, Map<String, dynamic> item) {
      final List? children = item['children'];
      final bool hasChildren = children != null && children.isNotEmpty;
      final bool isTouchDevice = kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android);

      if (!hasChildren) {
        return MouseRegion(
          onEnter: (_) => incrementHover(),
          onExit: (_) => decrementHover(),
          child: MenuItemButton(
            onPressed: () {
              NavigationService().routerGo(context, item['path'] ?? '/');
              searchContentRead.initState();
            },
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2),
            ),
            child: Text(item['title'],
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        );
      }

      if (isTouchDevice) {
        return PopupMenuButton<String>(
          tooltip: item['title'],
          offset: const Offset(120, 0),
          style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          onSelected: (path) {
            NavigationService().routerGo(context, path);
            searchContentRead.initState();
          },
          itemBuilder: (BuildContext context) {
            return children.map<PopupMenuEntry<String>>((child) {
              return PopupMenuItem<String>(
                  value: child['path'] ?? '/',
                  child: Text(child['title'],
                      style: const TextStyle(fontSize: 13)));
            }).toList();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['title'],
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black)),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            ],
          ),
        );
      }

      return MouseRegion(
        onEnter: (_) => incrementHover(),
        onExit: (_) => decrementHover(),
        child: SubmenuButton(
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: WidgetStatePropertyAll(Colors.white),
            elevation: WidgetStatePropertyAll(3),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              iconColor: Colors.grey.shade400,
              overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2)),
          menuChildren: [
            MouseRegion(
              onEnter: (_) => incrementHover(),
              onExit: (_) => decrementHover(),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children
                      .map<Widget>((child) => buildMenuChild(ref, child))
                      .toList(),
                ),
              ),
            )
          ],
          child: Text(item['title'],
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 25),
        child: InkWell(
          onTap: () {
            if (title == '내복') {
              NavigationService().routerGo(context, InnerRoute);
            } else if (title == 'SALE') {
              NavigationService().routerGo(context, SaleRoute);
            }
            searchContentRead.initState();
          },
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87))),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => incrementHover(),
      onExit: (_) => decrementHover(),
      child: MenuAnchor(
        controller: controller,
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStatePropertyAll(3),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        menuChildren: [
          MouseRegion(
            onEnter: (_) => incrementHover(),
            onExit: (_) => decrementHover(),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items
                    .map<Widget>((item) => buildMenuChild(ref, item))
                    .toList(),
              ),
            ),
          )
        ],
        builder: (context, menuController, child) {
          return Padding(
            padding: const EdgeInsets.only(right: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: menuController.isOpen
                              ? const Color(0xFFD4CBE5)
                              : Colors.transparent,
                          width: 2))),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
            ),
          );
        },
      ),
    );
  }
}

class SubHoverMenu extends StatefulWidget {
  final Map<String, dynamic> item;
  const SubHoverMenu({super.key, required this.item});

  @override
  State<SubHoverMenu> createState() => _SubHoverMenuState();
}

class _SubHoverMenuState extends State<SubHoverMenu> {
  final LayerLink _subLayerLink = LayerLink();
  final OverlayPortalController _subController = OverlayPortalController();
  bool _isTargetHovered = false;
  bool _isOverlayHovered = false;

  void _showMenu() {
    _subController.show();
  }

  void _hideMenu() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isTargetHovered && !_isOverlayHovered) {
        _subController.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List? children = widget.item['children'];
    final bool hasChildren = children != null && children.isNotEmpty;

    return MouseRegion(
      onEnter: (_) {
        _isTargetHovered = true;
        if (hasChildren) _showMenu();
      },
      onExit: (_) {
        _isTargetHovered = false;
        if (hasChildren) _hideMenu();
      },
      child: CompositedTransformTarget(
        link: _subLayerLink,
        child: OverlayPortal(
          controller: _subController,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
                link: _subLayerLink,
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(1, -1),
                child: MouseRegion(
                  onEnter: (_) {
                    _isOverlayHovered = true;
                    _showMenu();
                  },
                  onExit: (_) {
                    _isOverlayHovered = false;
                    _hideMenu();
                  },
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(4, 4))
                            ]),
                        constraints: const BoxConstraints(minWidth: 150),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children!
                              .map<Widget>((child) => SubHoverMenu(item: child))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: (_isTargetHovered || _isOverlayHovered)
                ? const Color(0xFFF8F9FA)
                : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.item['title'],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: (_isTargetHovered || _isOverlayHovered)
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: (_isTargetHovered || _isOverlayHovered)
                            ? Colors.black
                            : Colors.grey.shade700)),
                if (hasChildren)
                  Icon(Icons.chevron_right,
                      size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '모어픽 | 본질에 집중한 미니멀 쇼핑',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'NotoSansKR',
      ),
      routerConfig: router,
    );
  }
}

// 💡 메인 웹 서비스 컴포넌트 (멀티 카테고리 배열 스펙 완벽 연동 + 검색 연동 완료!)
class MorePicWebService extends HookConsumerWidget {
  const MorePicWebService({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminSettingsWatch = ref.watch(adminSettingsProvider);
    final adminSettingsRead = ref.read(adminSettingsProvider.notifier);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    // 🔍 [검색 연동 가드 노티파이어 확보]
    final globalSearchWatch = ref.watch(globalSearchProvider);
    final globalSearchRead = ref.read(globalSearchProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);

    final bool mobileMode = isMobile(context);
    const String currentCategory = 'all';

    // 📊 메인 'all' 상태 가방 로드 및 items 추출 (.cast 안전조치 포함)
    final paginatedStateAsync =
        ref.watch(paginatedProductProvider(currentCategory));
    final List<ProductModel> items = paginatedStateAsync.maybeWhen(
      data: (stateData) => stateData.items.cast<ProductModel>(),
      orElse: () => const <ProductModel>[],
    );

    // 🌟 [실시간 동기화 센서]: 메인 화면 무한 스크롤 다운 시 검색 필터 실시간 갱신 전파
    useEffect(() {
      paginatedStateAsync.whenData((stateData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (searchContentWatch.searchContent.isNotEmpty) {
            globalSearchRead.filterProducts(
              query: searchContentWatch.searchContent,
              targetList: stateData.items.cast<ProductModel>(),
            );
          } else {
            globalSearchRead
                .allProductsFn(stateData.items.cast<ProductModel>());
          }
        });
      });
      return null;
    }, [paginatedStateAsync.value?.items, searchContentWatch.searchContent]);

    useEffect(() {
      void listener() {
        if (scrollController.hasClients) {
          if (scrollController.offset > 150) {
            if (!showButton.value) showButton.value = true;
          } else {
            if (showButton.value) showButton.value = false;
          }

          if (scrollController.offset > 0) {
            if (!isScrolled.value) isScrolled.value = true;
          } else {
            if (isScrolled.value) isScrolled.value = false;
          }

          if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
            ref
                .read(paginatedProductProvider(currentCategory).notifier)
                .fetchNextPage();
          }
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    final double headerHeight = mobileMode ? 70 : 120;

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;

    double horizontalPadding = mobileMode ? 16 : 40;
    if (!mobileMode && screenWidth > 1360) {
      horizontalPadding = (screenWidth - 1280) / 2;
    }

    return Scaffold(
        backgroundColor: Colors.white,
        drawer: mobileMode
            ? CustomWidget.customDrawer(context, ref, menuData)
            : null,
        body: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                // 📌 [구조 1]: 상단 안내 배너
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    width: double.infinity,
                    color: const Color(0xFFD4CBE5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (adminSettingsWatch) ...[
                                IconButton(
                                  onPressed: () =>
                                      showProductUploadDlgFn(context),
                                  icon: const Icon(Icons.add_a_photo,
                                      color: Colors.black),
                                  tooltip: '상품 업로드',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      adminSettingsRead.initState(),
                                  icon: const Icon(Icons.lock_open,
                                      color: Colors.red),
                                  tooltip: '편집 모드 종료',
                                ),
                              ] else ...[
                                IconButton(
                                  onPressed: () =>
                                      showPasswordCheckDialog(context),
                                  icon: const Icon(Icons.lock,
                                      color: Colors.black87),
                                  tooltip: '관리자 편집모드 진입',
                                ),
                              ]
                            ]),
                        const Text(
                          '🖤 🖤 가격은 카톡방에서 확인 해주세요 🖤 🖤',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 48)
                      ],
                    ),
                  ),
                ),

                // 📌 [구조 2]: 상단 고정(Floating) 헤더 섹션 (돋보기 클릭 시 검색창 트리거 바인딩 완료)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverHeaderDelegate(
                    height: headerHeight,
                    isScrolled: isScrolled.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (mobileMode)
                                Builder(
                                  builder: (context) => IconButton(
                                    icon: const Icon(Icons.menu,
                                        color: Colors.black, size: 28),
                                    onPressed: () =>
                                        Scaffold.of(context).openDrawer(),
                                  ),
                                ),
                              CustomWidget.customLogo(context, ref,
                                  fontSize: 38, letterSpacing: 1.5),
                              if (mobileMode)
                                IconButton(
                                    icon: const Icon(Icons.search,
                                        color: Colors.black, size: 26),
                                    onPressed: () {
                                      ref
                                          .read(searchBarOpenProvider.notifier)
                                          .open();
                                    }),
                            ],
                          ),
                          if (!mobileMode) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: menuData.map((menu) {
                                    return DesktopHoverMenu(
                                      title: menu['title'],
                                      items: menu['children'] ?? [],
                                    );
                                  }).toList(),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.search,
                                        color: Colors.black, size: 26),
                                    onPressed: () {
                                      ref
                                          .read(searchBarOpenProvider.notifier)
                                          .open();
                                    }),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),

                // 📌 [구조 3]: NEW ARRIVALS 타이틀 바 섹션
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding, 40, horizontalPadding, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          searchContentWatch.searchContent.isEmpty
                              ? 'NEW ARRIVALS'
                              : "SEARCH RESULT (${globalSearchWatch.length})",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Container(
                            width: 45,
                            height: 3,
                            color: const Color(0xFF4A6FA5)),

                        // 🌟 [신규 추가]: 메인 홈화면 전용 '전체보기 돌아가기' 리셋 버튼 가드
                        if (searchContentWatch.searchContent.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              // 검색어 상태를 밀어서 전체보기 피드로 즉시 유턴시킵니다.
                              searchContentRead.setState(const SearchContent(
                                  searchContent: '', page: 1));
                            },
                            icon: const Icon(Icons.refresh,
                                size: 14, color: Color(0xFF4A6FA5)),
                            label: const Text(
                              '전체보기 돌아가기',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A6FA5)),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              backgroundColor:
                                  const Color(0xFF4A6FA5).withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 📌 [구조 4]: 신형 무한 스크롤 격자 리스트 구역
                paginatedStateAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 100),
                        child:
                            CircularProgressIndicator(color: Color(0xFF4A6FA5)),
                      ),
                    ),
                  ),
                  error: (err, stack) => SliverToBoxAdapter(
                    child: Center(
                      child: Text('❌ 상품 로드 오류: $err',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  data: (stateData) {
                    if (items.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 120),
                            child: Text('신상 상품이 존재하지 않습니다.',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      );
                    }

                    final isNextPageLoading = ref
                        .watch(paginatedProductProvider(currentCategory))
                        .isRefreshing;

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 10),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: mobileMode ? 12 : 35,
                              crossAxisSpacing: mobileMode ? 8 : 20,
                              childAspectRatio: mobileMode ? 0.55 : 0.65,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // 🌟 [완치]: 검색 상태에 따라 알맹이를 동적으로 교환 분기합니다. 유령 격자 박멸!
                                final product =
                                    searchContentWatch.searchContent.isEmpty
                                        ? items[index]
                                        : globalSearchWatch[index];

                                return ProductCard(
                                  product: product,
                                  currentCategory: currentCategory,
                                  onDelete: () async {
                                    // 부모 위젯 리셋 신호 자동 연동
                                  },
                                );
                              },
                              // 🌟 검색 상태에 맞춰 동적으로 카운트 수식을 지정합니다.
                              childCount:
                                  searchContentWatch.searchContent.isEmpty
                                      ? items.length
                                      : globalSearchWatch.length,
                            ),
                          ),
                        ),
                        if (isNextPageLoading)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            sliver: const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF4A6FA5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // 📌 [구조 5]: 바닥 고정 푸터
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      CustomWidget.customFooter(context, ref,
                          isMobile: mobileMode),
                    ],
                  ),
                ),
              ],
            ),
            // 🌟 [전형적 마스터 피스]: 와이드한 슬라이딩 검색창을 메인 스택 최상단에 투하합니다! 에러 제로 도킹 성공!
            SlidingSearchBar(currentScreenItems: items)
          ],
        ),
        floatingActionButton: CustomWidget.customFloatingBtn(
            showButton: showButton, scrollController: scrollController));
  }
}
