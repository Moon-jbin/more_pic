import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/db/product_repository.dart';
import 'package:more_pic/firebase_options.dart';
import 'package:more_pic/global/component/hover_menu.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/product_filter_bar.dart';
import 'package:more_pic/global/custom_widget/recently_viewed_floationg_bar.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/cart_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/provider/system_config_provider.dart';
import 'package:more_pic/secret.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/utils/routing/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '모어픽 | 본질에 집중한 미니멀 쇼핑',
      theme: ThemeData(
          scaffoldBackgroundColor: Colors.white, fontFamily: 'NotoSansKR'),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class MorePicWebService extends HookConsumerWidget {
  const MorePicWebService({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = useMemoized(() => GlobalKey<ScaffoldState>());

    const String currentCategory = 'all';

    final itemCountAsync =
        ref.watch(categoryItemCountProvider(currentCategory));
    final int totalCategoryCount = itemCountAsync.value ?? 0;

    final authState = ref.watch(authStateProvider);
    final bool isLoggedIn = authState.value != null;
    final bool isMasterAdmin =
        authState.value?.email == SecretConfig.masterAdminEmail;

    final isEditMode = ref.watch(adminSettingsProvider);
    final adminSettingsController = ref.read(adminSettingsProvider.notifier);

    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    final globalSearchWatch = ref.watch(globalSearchProvider);
    // final globalSearchRead = ref.read(globalSearchProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);
    final popupConfigAsync = ref.watch(popupConfigProvider);

    final menuAsync = ref.watch(globalMenuProvider);
    final currentMenuData = menuAsync.value ?? [];

    final bool mobileMode = isMobile(context);

    final paginatedStateAsync =
        ref.watch(paginatedProductProvider(currentCategory));
    final List<ProductModel> items = paginatedStateAsync.maybeWhen(
      data: (stateData) => stateData.items.cast<ProductModel>(),
      orElse: () => const <ProductModel>[],
    );

    final cartCount = ref.watch(cartProvider).length;

    // useEffect(() {
    //   paginatedStateAsync.whenData((stateData) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       if (searchContentWatch.searchContent.isNotEmpty) {
    //         globalSearchRead.filterProducts(
    //             query: searchContentWatch.searchContent,
    //             targetList: stateData.items.cast<ProductModel>());
    //       } else {
    //         globalSearchRead
    //             .allProductsFn(stateData.items.cast<ProductModel>());
    //       }
    //     });
    //   });
    //   return null;
    // }, [paginatedStateAsync.value?.items, searchContentWatch.searchContent]);

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

          // 무한 스크롤 하단 도달 감지
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

    double horizontalPadding = mobileMode ? 16 : 40;
    if (!mobileMode && screenWidth > 1360) {
      horizontalPadding = (screenWidth - 1280) / 2;
    }

    // PC 화면은 4열, 모바일/태블릿은 3열로 반응형 분기
    int crossAxisCount = 4;
    if (mobileMode || screenWidth < 768) {
      crossAxisCount = 3;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    }

    useEffect(() {
      Future.microtask(() async {
        if (popupConfigAsync.value == null) return;
        final isActive = popupConfigAsync.value!['isActive'] as bool? ?? false;
        final title = popupConfigAsync.value!['title'] as String? ?? '';
        final content = popupConfigAsync.value!['content'] as String? ?? '';

        if (isActive && (title.isNotEmpty || content.isNotEmpty)) {
          final prefs = await SharedPreferences.getInstance();
          final int? hideUntil = prefs.getInt('hide_popup_until');
          final currentTime = DateTime.now().millisecondsSinceEpoch;

          if (hideUntil == null || currentTime > hideUntil) {
            if (context.mounted) {
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.4),
                builder: (context) =>
                    _TextPopupDialog(title: title, content: content),
              );
            }
          }
        }
      });
      return null;
    }, [popupConfigAsync.value?['isActive']]);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: mobileMode
          ? CustomWidget.customDrawer(context, ref, currentMenuData)
          : null,
      body: Stack(
        children: [
          CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: isMasterAdmin
                      ? (isEditMode ? Colors.deepPurple[100] : Colors.grey[800])
                      : Colors.deepPurple[100],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: isMasterAdmin
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    children: [
                      if (isMasterAdmin)
                        Row(children: [
                          if (isEditMode) ...[
                            IconButton(
                              onPressed: () =>
                                  // migrateProductImageUrlsParallel(),
                                  showProductUploadDlgFn(context),
                              icon: const Icon(
                                Icons.add_a_photo,
                                color: Colors.red,
                              ),
                              tooltip: '상품 업로드',
                            ),
                            IconButton(
                              onPressed: () =>
                                  showMenuEditDialog(context, currentMenuData),
                              icon: const Icon(Icons.category,
                                  color: Colors.blue),
                              tooltip: '카테고리 메뉴 편집',
                            ),
                            IconButton(
                              onPressed: () =>
                                  showShippingSettingDialog(context),
                              icon: const Icon(Icons.local_shipping,
                                  color: Colors.green),
                              tooltip: '배송비 설정',
                            ),
                            IconButton(
                              onPressed: () => showPopupSettingDialog(context),
                              icon: const Icon(Icons.campaign,
                                  color: Colors.deepPurple),
                              tooltip: '메인 팝업창 설정',
                            ),
                          ]
                        ]),
                      Row(
                        children: [
                          if (isEditMode) ...[
                            TextButton.icon(
                              onPressed: () {
                                adminSettingsController.toggleEditMode();
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('👉 조회 모드로 전환되었습니다.'),
                                      duration: Duration(seconds: 1)),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.red, size: 18),
                              label: const Text('편집 종료',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ] else ...[
                            if (isMasterAdmin)
                              TextButton.icon(
                                onPressed: () {
                                  adminSettingsController.toggleEditMode();
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('🛠️ 편집 모드가 활성화되었습니다.'),
                                        duration: Duration(seconds: 1)),
                                  );
                                },
                                icon: const Icon(Icons.edit,
                                    color: Colors.orangeAccent, size: 18),
                                label: const Text('편집 시작',
                                    style:
                                        TextStyle(color: Colors.orangeAccent)),
                              )
                            else
                              Text(
                                '♥ 로그인 시 회원가 확인 가능 ♥',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverHeaderDelegate(
                  height: headerHeight,
                  isScrolled: isScrolled.value,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: mobileMode ? 10 : 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 56, // 상단 바 적절한 높이 설정
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. 가운데 로고 (모바일/데스크톱 모두 중앙 고정)
                              CustomWidget.customLogo(context, ref,
                                  fontSize: 38),

                              // 2. 양쪽 버튼 레이아웃
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 왼쪽: 메뉴 버튼
                                  if (mobileMode)
                                    Builder(
                                      builder: (BuildContext innerContext) {
                                        return IconButton(
                                          icon: const Icon(Icons.menu,
                                              color: Colors.black, size: 28),
                                          onPressed: () {
                                            Scaffold.of(innerContext)
                                                .openDrawer();
                                          },
                                        );
                                      },
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // 오른쪽: 검색 및 장바구니 버튼
                                  if (mobileMode)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.search),
                                          onPressed: () => ref
                                              .read(searchBarOpenProvider
                                                  .notifier)
                                              .open(),
                                        ),
                                        CustomWidget.buildCartBadgeIcon(
                                            context, cartCount), // 주석 해제
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!mobileMode) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                  children: currentMenuData
                                      .map((menu) => DesktopHoverMenu(
                                          title: menu['title'],
                                          items: menu['children'] ?? []))
                                      .toList()),
                              Row(
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () => ref
                                          .read(searchBarOpenProvider.notifier)
                                          .open()),
                                  CustomWidget.buildCartBadgeIcon(
                                      context, cartCount),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () async {
                                      if (isLoggedIn) {
                                        await adminSettingsController.logout();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('로그아웃 되었습니다. 👋'),
                                                duration: Duration(seconds: 1)),
                                          );
                                        }
                                      } else {
                                        showAdminLoginDialog(context);
                                      }
                                    },
                                    icon: Icon(
                                      isLoggedIn
                                          ? Icons.logout
                                          : Icons.person_outline,
                                      color: Colors.black87,
                                    ),
                                    tooltip: isLoggedIn ? '로그아웃' : '로그인 / 회원가입',
                                  )
                                ],
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 40, horizontalPadding, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          searchContentWatch.searchContent.isEmpty
                              ? 'NEW ARRIVALS'
                              : "SEARCH RESULT (${globalSearchWatch.length})",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      if (searchContentWatch.searchContent.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TextButton(
                            onPressed: () => ref
                                .read(searchContentProvider.notifier)
                                .initState(),
                            child: const Text('전체보기 돌아가기')),
                      ],
                      const SizedBox(height: 20),

                      // 🌟 메인 화면용 필터 & 정렬 위젯 부착 🌟
                      ProductFilterBar(
                        totalCount: searchContentWatch.searchContent.isNotEmpty
                            ? globalSearchWatch.length
                            : totalCategoryCount,
                      ),
                    ],
                  ),
                ),
              ),
              paginatedStateAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (err, s) =>
                    SliverToBoxAdapter(child: Text('Error: $err')),
                data: (stateData) {
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.6),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product =
                              searchContentWatch.searchContent.isEmpty
                                  ? items[index]
                                  : globalSearchWatch[index];
                          return ProductCard(
                              key: ValueKey(product.id),
                              product: product,
                              currentCategory: currentCategory);
                        },
                        childCount: searchContentWatch.searchContent.isEmpty
                            ? items.length
                            : globalSearchWatch.length,
                      ),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: CustomWidget.customFooter(context, ref,
                    isMobile: mobileMode),
              ),
            ],
          ),
          SlidingSearchBar(currentScreenItems: items),
        ],
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const RecentlyViewedFloatingBar(),
          const SizedBox(height: 15),
          // 1. 채널톡 Floating 버튼
          CustomWidget.buildChannelTalkFloatingBtn(context),

          // 2. 기존 맨 위로 가기(Top) 버튼
          CustomWidget.customFloatingBtn(
            showButton: showButton,
            scrollController: scrollController,
          ),
        ],
      ),
    );
  }
}
// FILE: lib/main.dart 하단에 추가

class _TextPopupDialog extends HookWidget {
  final String title;
  final String content;

  const _TextPopupDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final isChecked = useState(false);

    void closePopup() async {
      if (isChecked.value) {
        final prefs = await SharedPreferences.getInstance();
        // 24시간 뒤로 설정
        final hideUntil = DateTime.now()
            .add(const Duration(hours: 24))
            .millisecondsSinceEpoch;
        await prefs.setInt('hide_popup_until', hideUntil);
      }
      if (context.mounted) Navigator.pop(context);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600), // 화면 넘어가지 않게 제한
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9), // 사진과 유사한 은은한 회백색 배경
          borderRadius: BorderRadius.circular(0), // 각진 디자인
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 본문 영역 (스크롤 가능하게 처리)
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    if (content.isNotEmpty)
                      Text(
                        content,
                        textAlign: TextAlign.center, // 가운데 정렬
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.8, // 줄간격을 넓혀서 읽기 쉽게
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF444444),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 하단 컨트롤 바 (검정색)
            Container(
              height: 55,
              color: const Color(0xFF191919),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isChecked.value,
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                          side:
                              const BorderSide(color: Colors.white, width: 1.5),
                          onChanged: (val) => isChecked.value = val ?? false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => isChecked.value = !isChecked.value,
                        child: const Text(
                          '24시간 동안 다시 열람하지 않습니다.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: closePopup,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('닫기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
