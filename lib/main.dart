// FILE: lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/firebase_options.dart';
import 'package:more_pic/global/component/hover_menu.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/product_filter_bar.dart';
import 'package:more_pic/global/custom_widget/recently_viewed_floationg_bar.dart';
import 'package:more_pic/global/custom_widget/scrollable_category_bar.dart';
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

    // ⭐️ 1. 기존 리버팟 페이징 상태 그대로 사용
    final paginatedStateAsync =
        ref.watch(paginatedProductProvider(currentCategory));
    final items = paginatedStateAsync.value?.items ?? [];
    final hasMore = paginatedStateAsync.value?.hasMore ?? false;
    final isFetching =
        paginatedStateAsync.isLoading || paginatedStateAsync.isRefreshing;

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
    final searchContentWatch = ref.watch(searchContentProvider);
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final popupConfigAsync = ref.watch(popupConfigProvider);

    final menuAsync = ref.watch(globalMenuProvider);
    final currentMenuData = menuAsync.value ?? [];

    final bool mobileMode = isMobile(context);
    final cartCount = ref.watch(cartProvider).length;

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
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    final double headerHeight = mobileMode ? 110 : 130;
    double screenWidth = MediaQuery.of(context).size.width;

    double horizontalPadding = mobileMode ? 16 : 40;
    if (!mobileMode && screenWidth > 1360) {
      horizontalPadding = (screenWidth - 1280) / 2;
    }

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

    final bool isSearchMode = searchContentWatch.searchContent.isNotEmpty;
    final displayItems = isSearchMode ? globalSearchWatch : items;

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
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 관리자 툴바
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
                              onPressed: () => showProductUploadDlgFn(context),
                              icon: const Icon(Icons.add_a_photo,
                                  color: Colors.red),
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
                                        content: Text('일반 조회 모드로 전환되었습니다.'),
                                        duration: Duration(seconds: 1)));
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
                                          content: Text('운영자 편집 모드가 활성화되었습니다.'),
                                          duration: Duration(seconds: 1)));
                                },
                                icon: const Icon(Icons.edit,
                                    color: Colors.orangeAccent, size: 18),
                                label: const Text('편집 시작',
                                    style:
                                        TextStyle(color: Colors.orangeAccent)),
                              )
                            else
                              const Text('로그인시 회원가 확인 가능합니다',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // 헤더 바
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
                          height: 56,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (mobileMode)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Builder(
                                    builder: (context) => IconButton(
                                      icon: const Icon(Icons.menu,
                                          color: Colors.black, size: 28),
                                      onPressed: () =>
                                          Scaffold.of(context).openDrawer(),
                                    ),
                                  ),
                                ),
                              CustomWidget.customLogo(context, ref,
                                  fontSize: mobileMode ? 28 : 38),
                              if (mobileMode)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.search,
                                            color: Colors.black),
                                        onPressed: () => ref
                                            .read(
                                                searchBarOpenProvider.notifier)
                                            .open(),
                                      ),
                                      CustomWidget.buildCartBadgeIcon(
                                          context, cartCount),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (mobileMode)
                          ScrollableCategoryBar(menuData: currentMenuData)
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: currentMenuData
                                    .map((menu) => DesktopHoverMenu(
                                        title: menu['title'],
                                        items: menu['children'] ?? []))
                                    .toList(),
                              ),
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
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('로그아웃 되었습니다.👋'),
                                                  duration:
                                                      Duration(seconds: 1)));
                                        }
                                      } else {
                                        showAdminLoginDialog(context);
                                      }
                                    },
                                    icon: Icon(
                                        isLoggedIn
                                            ? Icons.logout
                                            : Icons.person_outline,
                                        color: Colors.black87),
                                    tooltip: isLoggedIn ? '로그아웃' : '로그인/ 회원가입',
                                  )
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // 제목 및 필터
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
                            onPressed: () {
                              searchContentRead.initState();
                              ref.invalidate(
                                  paginatedProductProvider(currentCategory));
                            },
                            child: const Text('전체보기 돌아가기')),
                      ],
                      const SizedBox(height: 20),
                      ProductFilterBar(
                        totalCount: searchContentWatch.searchContent.isNotEmpty
                            ? globalSearchWatch.length
                            : totalCategoryCount,
                      ),
                    ],
                  ),
                ),
              ),
              // ⭐️ [수정 후] 기존 아이템이 있으면 일단 그리드를 먼저 그리고,
// 다음 페이지를 로딩 중일 때만 맨 아래에 로딩 스피너를 덧붙입니다.

// 1. 기존 데이터가 있든 없든 그리드를 뿌려줌
              if (displayItems.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: crossAxisCount == 3 ? 12 : 35,
                      crossAxisSpacing: crossAxisCount == 3 ? 8 : 20,
                      childAspectRatio: crossAxisCount == 3 ? 0.55 : 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 스크롤이 끝에 도달하기 전(끝에서 3번째) 미리 다음 페이지 감지
                        if (!isSearchMode &&
                            index >= displayItems.length - 3 &&
                            hasMore &&
                            !isFetching) {
                          Future.microtask(() {
                            ref
                                .read(paginatedProductProvider(currentCategory)
                                    .notifier)
                                .fetchNextPage();
                          });
                        }
                        return ProductCard(
                          key: ValueKey(displayItems[index].id),
                          product: displayItems[index],
                          currentCategory: currentCategory,
                        );
                      },
                      childCount: displayItems.length,
                    ),
                  ),
                ),

// 2. 맨 처음 첫 페이지를 불러오는 중일 때만 중앙 대형 로딩바 표시
              if (displayItems.isEmpty && isFetching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 100),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF4A6FA5)),
                    ),
                  ),
                ),

// 3. 기존 데이터가 있는 상태에서 '다음 페이지'를 불러올 때 하단에만 소형 로딩바 표시
              if (displayItems.isNotEmpty && isFetching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF4A6FA5)),
                      ),
                    ),
                  ),
                ),

// 4. 아이템이 진짜 없을 때
              if (displayItems.isEmpty && !isFetching)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('아직 등록된 상품이 없습니다.',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),

              if (isFetching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF4A6FA5)),
                    ),
                  ),
                ),

              // 푸터
              SliverToBoxAdapter(
                child: CustomWidget.customFooter(context, ref,
                    isMobile: mobileMode),
              ),
            ],
          ),
          SlidingSearchBar(currentScreenItems: displayItems),
        ],
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const RecentlyViewedFloatingBar(),
          const SizedBox(height: 15),
          CustomWidget.buildChannelTalkFloatingBtn(context),
          CustomWidget.customFloatingBtn(
              showButton: showButton, scrollController: scrollController),
        ],
      ),
    );
  }
}

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
        constraints: const BoxConstraints(maxHeight: 600),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 30),
                    ],
                    if (content.isNotEmpty)
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.8,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF444444)),
                      ),
                  ],
                ),
              ),
            ),
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
                        child: const Text('24시간 동안 다시 열람하지 않습니다.',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: closePopup,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        foregroundColor: Colors.white),
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
