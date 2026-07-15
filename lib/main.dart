import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:more_pic/firebase_options.dart';
import 'package:more_pic/global/component/product_card.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';
import 'package:more_pic/global/custom_widget/sliding_search_bar.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/admin_settings_provider.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/provider/product_db_provider.dart';
import 'package:more_pic/utils/delegate/sliverHeaderDelegate.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/utils/routing/router.dart';

MenuController? _globalActiveController;
VoidCallback? _globalActiveCloseTrigger;

// 🌟 [호버 버그 완치]: 유저님의 오리지널 MouseRegion 센서 레이어를 100% 완벽 복구했습니다!
class DesktopHoverMenu extends HookConsumerWidget {
  final String title;
  final List<dynamic> items;

  const DesktopHoverMenu({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchContentRead = ref.read(searchContentProvider.notifier);
    final menuAsync = ref.watch(globalMenuProvider);
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
      // 💡 마우스가 대분류-소분류 사이의 미세한 틈새를 지나갈 때 터지지 않도록 250ms 버퍼를 둡니다.
      debounceTimer.value = Timer(const Duration(milliseconds: 250), () {
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

      if (!hasChildren) {
        return MouseRegion(
          onEnter: (_) => incrementHover(),
          onExit: (_) => decrementHover(),
          child: MenuItemButton(
            onPressed: () {
              String targetPath = item['path'] ?? '/';

              // 🌟 [완치 가드 1]: 혹시라도 데이터베이스에 '/category/...' 형태로 저장되어 있다면
              // 앞에 겹치는 '/category' 네임스페이스를 제거하고 순수 주소만 발라냅니다.
              if (targetPath.startsWith('/category')) {
                targetPath = targetPath.replaceFirst('/category', '');
              }

              // 슬래시 구문 정리 (빈 값 방지)
              if (targetPath.isEmpty) targetPath = '/';

              // print("🚀 [이동 타격 완치] Go To Path: $targetPath");

              context.go(targetPath);
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
                      .map<Widget>((child) =>
                          buildMenuChild(ref, Map<String, dynamic>.from(child)))
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

    // 🌟 [완치 가드]: 하위 자식이 아예 없는 단독 대분류 카테고리 클릭 시
    // 하드코딩 이름 매핑을 철거하고, 들고 있는 실제 동적 주소(path)로 다이렉트 점프시킵니다!
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 25),
        child: InkWell(
          onTap: () {
            // 1️⃣ 기본 목적지 방어선 구축
            String targetPath = '/';

            // 2️⃣ 부모나 혹은 전달받은 아이템 뭉치 내에서 매칭되는 실제 주소(path)를 색출합니다.
            // menuData 전체에서 현재 대분류 타이틀과 일치하는 오리지널 객체를 타격합니다.
            final List<Map<String, dynamic>> menuDataList =
                (menuAsync.value ?? [])
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();

            final matchingRootNode = menuDataList.firstWhere(
              (node) => node['title'] == title,
              orElse: () => {},
            );

            if (matchingRootNode.containsKey('path') &&
                matchingRootNode['path'].toString().isNotEmpty) {
              targetPath = matchingRootNode['path'].toString();
            } else {
              // 폴백 방어선: 혹시 예전 데이터 매핑 찌꺼기가 남아있을 경우를 대비한 하드코딩 구 버전 호환
              if (title == '내복') targetPath = '/inner';
              if (title == 'SALE') targetPath = '/sale';
            }

            // 3️⃣ 중복 슬래시 소독 가드 적용
            if (targetPath.startsWith('/category')) {
              targetPath = targetPath.replaceFirst('/category', '');
            }
            if (targetPath.isEmpty) targetPath = '/';

            print("🎯 [단독 대분류 완치 클릭] '$title' 카테고리 -> Go To: $targetPath");

            context.go(targetPath);
            searchContentRead.initState();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87)),
          ),
        ),
      );
    }

    // 🌟 [핵심 마우스 트래킹 감지선 전면 복구]:
    // 최상단을 MouseRegion이 완전히 지키고 서서 묵묵히 쉴드쳐주는 오리지널 정석 구조 환원!
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
                    .map<Widget>((item) =>
                        buildMenuChild(ref, Map<String, dynamic>.from(item)))
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

class SubMenuHoverWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  const SubMenuHoverWidget({super.key, required this.item});

  @override
  State<SubMenuHoverWidget> createState() => _SubMenuHoverWidgetState();
}

class _SubMenuHoverWidgetState extends State<SubMenuHoverWidget> {
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
                              .map<Widget>(
                                  (child) => SubMenuHoverWidget(item: child))
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
