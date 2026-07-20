import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/firebase_options.dart';
import 'package:more_pic/global/component/hover_menu.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/secret.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/utils/routing/router.dart';

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

    // 🌟 [실시간 동기화 핵심]: 파이어베이스의 로그인 상태를 실시간으로 완전히 구독(watch)합니다.
    final authState = ref.watch(authStateProvider);
    final bool isLoggedIn = authState.value != null;
    final bool isMasterAdmin =
        authState.value?.email == SecretConfig.masterAdminEmail;

    // 🌟 [편집 상태 제어]: state(bool)는 오직 편집 모드의 ON/OFF만 담당합니다.
    final isEditMode = ref.watch(adminSettingsProvider);
    final adminSettingsController = ref.read(adminSettingsProvider.notifier);

    final scrollController = useScrollController();
    final showButton = useState(false);
    final isScrolled = useState(false);

    final globalSearchWatch = ref.watch(globalSearchProvider);
    final globalSearchRead = ref.read(globalSearchProvider.notifier);
    final searchContentWatch = ref.watch(searchContentProvider);

    final menuAsync = ref.watch(globalMenuProvider);
    final currentMenuData = menuAsync.value ?? [];

    final bool mobileMode = isMobile(context);
    const String currentCategory = 'all';

    final paginatedStateAsync =
        ref.watch(paginatedProductProvider(currentCategory));
    final List<ProductModel> items = paginatedStateAsync.maybeWhen(
      data: (stateData) => stateData.items.cast<ProductModel>(),
      orElse: () => const <ProductModel>[],
    );

    useEffect(() {
      paginatedStateAsync.whenData((stateData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (searchContentWatch.searchContent.isNotEmpty) {
            globalSearchRead.filterProducts(
                query: searchContentWatch.searchContent,
                targetList: stateData.items.cast<ProductModel>());
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
                // 🌟 [최고 관리자 콘솔 띠지]: 어드민일 때만 노출
                if (isMasterAdmin)
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: isEditMode
                          ? Colors.deepPurple[100]
                          : Colors.grey[800],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            // 편집 모드가 활성화되었을 때만 기능용 아이콘 노출
                            if (isEditMode) ...[
                              IconButton(
                                onPressed: () =>
                                    showProductUploadDlgFn(context),
                                icon: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.red,
                                ),
                                tooltip: '상품 업로드',
                              ),
                              IconButton(
                                onPressed: () => showMenuEditDialog(
                                    context, currentMenuData),
                                icon: const Icon(Icons.category,
                                    color: Colors.blue),
                                tooltip: '카테고리 메뉴 편집',
                              )
                            ]
                          ]),

                          // 오른쪽 액션 버튼 분기
                          Row(
                            children: [
                              if (isEditMode) ...[
                                TextButton.icon(
                                  onPressed: () {
                                    adminSettingsController.toggleEditMode();
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('🔒 조회 모드로 전환되었습니다.'),
                                          duration: Duration(seconds: 1)),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_outline,
                                      color: Colors.red, size: 18),
                                  label: const Text('편집 종료',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ] else ...[
                                TextButton.icon(
                                  onPressed: () {
                                    adminSettingsController.toggleEditMode();
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('🔓 편집 모드가 활성화되었습니다.'),
                                          duration: Duration(seconds: 1)),
                                    );
                                  },
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orangeAccent, size: 18),
                                  label: const Text('편집 시작',
                                      style: TextStyle(
                                          color: Colors.orangeAccent)),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: mobileMode ? 10 : 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (mobileMode)
                                Builder(
                                  builder: (BuildContext innerContext) {
                                    return IconButton(
                                      icon: const Icon(Icons.menu,
                                          color: Colors.black, size: 28),
                                      onPressed: () {
                                        Scaffold.of(innerContext).openDrawer();
                                      },
                                    );
                                  },
                                ),
                              CustomWidget.customLogo(context, ref,
                                  fontSize: 38),

                              // 📱 [모바일 뷰 검색 & 로그인/로그아웃 스위처]
                              if (mobileMode)
                                Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => ref
                                            .read(
                                                searchBarOpenProvider.notifier)
                                            .open()),
                                    // IconButton(
                                    //   onPressed: () async {
                                    //     if (isLoggedIn) {
                                    //       await adminSettingsController
                                    //           .logout();
                                    //       if (context.mounted) {
                                    //         ScaffoldMessenger.of(context)
                                    //             .clearSnackBars();
                                    //         ScaffoldMessenger.of(context)
                                    //             .showSnackBar(
                                    //           const SnackBar(
                                    //               content:
                                    //                   Text('로그아웃 되었습니다. 👋'),
                                    //               duration:
                                    //                   Duration(seconds: 1)),
                                    //         );
                                    //       }
                                    //     } else {
                                    //       showAdminLoginDialog(context);
                                    //     }
                                    //   },
                                    //   icon: Icon(
                                    //     isLoggedIn
                                    //         ? Icons.logout
                                    //         : Icons.person_outline,
                                    //     color: Colors.black87,
                                    //   ),
                                    // ),
                                  ],
                                ),
                            ],
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

                                // 💻 [PC 뷰 검색 & 로그인/로그아웃 스위처]
                                Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => ref
                                            .read(
                                                searchBarOpenProvider.notifier)
                                            .open()),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () async {
                                        if (isLoggedIn) {
                                          await adminSettingsController
                                              .logout();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .clearSnackBars();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('로그아웃 되었습니다. 👋'),
                                                  duration:
                                                      Duration(seconds: 1)),
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
                                      tooltip:
                                          isLoggedIn ? '로그아웃' : '로그인 / 회원가입',
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
                        horizontalPadding, 40, horizontalPadding, 16),
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
                        ]
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
            SlidingSearchBar(currentScreenItems: items)
          ],
        ),
        floatingActionButton: CustomWidget.customFloatingBtn(
            showButton: showButton, scrollController: scrollController));
  }
}
