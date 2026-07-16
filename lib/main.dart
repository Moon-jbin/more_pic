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
    // 🌟 [완치 포인트 1]: Scaffold를 수동으로 직접 제어할 마스터 리모컨(GlobalKey)을 Hooks 규격으로 개설합니다.
    final scaffoldKey = useMemoized(() => GlobalKey<ScaffoldState>());
    final adminSettingsWatch = ref.watch(adminSettingsProvider);
    final adminSettingsRead = ref.read(adminSettingsProvider.notifier);
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
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    width: double.infinity,
                    color: const Color(0xFFD4CBE5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          if (adminSettingsWatch) ...[
                            IconButton(
                                onPressed: () =>
                                    showProductUploadDlgFn(context),
                                icon: const Icon(Icons.add_a_photo)),
                            IconButton(
                                onPressed: () => adminSettingsRead.initState(),
                                icon: const Icon(Icons.lock_open,
                                    color: Colors.red)),
                            if (!mobileMode)
                              IconButton(
                                  onPressed: () => showMenuEditDialog(
                                      context, currentMenuData),
                                  icon: const Icon(Icons.category,
                                      color: Colors.blue))
                          ] else ...[
                            IconButton(
                                onPressed: () =>
                                    showPasswordCheckDialog(context),
                                icon: const Icon(Icons.lock)),
                          ]
                        ]),
                        const Text('🖤 🖤 가격은 카톡방에서 확인 해주세요 🖤 🖤',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 48)
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
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🌟 [완치 핵심 가드]: Builder 위젯으로 감싸서 새로운 하위 context를 공급합니다.
                              // 이렇게 하면 현재 카테고리 화면에 떠 있는 CustomScaffold 내부의 Scaffold를 자석처럼 정확하게 낚아챕니다!
                              if (mobileMode)
                                Builder(
                                  builder: (BuildContext innerContext) {
                                    return IconButton(
                                      icon: const Icon(Icons.menu,
                                          color: Colors.black, size: 28),
                                      onPressed: () {
                                        // 🔓 innerContext를 사용하여 현재 활성화된 화면의 서랍장을 안전하게 엽니다.
                                        Scaffold.of(innerContext).openDrawer();
                                      },
                                    );
                                  },
                                ),
                              CustomWidget.customLogo(context, ref,
                                  fontSize: 38),
                              if (mobileMode)
                                IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () => ref
                                        .read(searchBarOpenProvider.notifier)
                                        .open()),
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
                                IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () => ref
                                        .read(searchBarOpenProvider.notifier)
                                        .open()),
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
