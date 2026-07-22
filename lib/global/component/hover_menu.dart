import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'dart:html' as html;

MenuController? _globalActiveController;
VoidCallback? _globalActiveCloseTrigger;

// 🌟 [최종 완치]: 하위 그룹이 있는 대분류는 클릭해도 절대 이동 없이 서브메뉴 전개 역할만 수행하는 버전
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

    // 마우스 접속 여부 판별기
    bool isMouseConnected(BuildContext context) {
      return kIsWeb &&
          !RegExp(r'Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini',
                  caseSensitive: false)
              .hasMatch(html.window.navigator.userAgent);
    }

    Widget buildMenuChild(WidgetRef ref, Map<String, dynamic> item) {
      final List? children = item['children'];
      final bool hasChildren = children != null && children.isNotEmpty;
      final String itemTitle = item['title'] ?? '';

      // 1️⃣ [끝단 아이템]: 자식이 없는 최종 단독 노드 (예: '점퍼/자켓', '가디건', '조끼')
      if (!hasChildren) {
        return MouseRegion(
          onEnter: (_) {
            if (isMouseConnected(context)) incrementHover();
          },
          onExit: (_) {
            if (isMouseConnected(context)) decrementHover();
          },
          child: MenuItemButton(
            onPressed: () {
              // print("🟢 [끝단 클릭] '$itemTitle' 카테고리 이동!");
              String targetPath = item['path'] ?? '/';

              if (targetPath.startsWith('/category')) {
                targetPath = targetPath.replaceFirst('/category', '');
              }
              if (targetPath.isEmpty) targetPath = '/';

              controller.close();
              context.go(targetPath);
              searchContentRead.initState();
            },
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              overlayColor: const Color(0xFFD4CBE5).withOpacity(0.2),
            ),
            child: Text(itemTitle,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        );
      }

      // 2단계 [중간 그룹]: 자식이 있는 중간 노드 (예: 'OUTER', 'TOP', 'BOTTOM')
      // 🔥 [위치]: 텍스트를 클릭하면 페이지 이동이 가능하도록 GestureDetector 추가
      return MouseRegion(
        onEnter: (_) {
          if (isMouseConnected(context)) incrementHover();
        },
        onExit: (_) {
          if (isMouseConnected(context)) decrementHover();
        },
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
              onEnter: (_) {
                if (isMouseConnected(context)) incrementHover();
              },
              onExit: (_) {
                if (isMouseConnected(context)) decrementHover();
              },
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
          // 🔥 여기서 Text를 GestureDetector로 감싸줍니다.
          child: GestureDetector(
            onTap: () {
              String targetPath = item['path'] ?? '/';
              if (targetPath.startsWith('/category')) {
                targetPath = targetPath.replaceFirst('/category', '');
              }
              if (targetPath.isEmpty) targetPath = '/';
              controller.close();
              context.go(targetPath);
              searchContentRead.initState();
            },
            child: Text(itemTitle,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
          ),
        ),
      );
    }

    // 단독 루트 카테고리 (자식이 없는 대분류)
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 25),
        child: InkWell(
          onTap: () {
            String targetPath = '/';
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
              if (title == '내복') targetPath = '/inner';
              if (title == 'SALE') targetPath = '/sale';
            }

            if (targetPath.startsWith('/category')) {
              targetPath = targetPath.replaceFirst('/category', '');
            }
            if (targetPath.isEmpty) targetPath = '/';

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

    return MouseRegion(
      onEnter: (_) {
        if (isMouseConnected(context)) incrementHover();
      },
      onExit: (_) {
        if (isMouseConnected(context)) decrementHover();
      },
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
            onEnter: (_) {
              if (isMouseConnected(context)) incrementHover();
            },
            onExit: (_) {
              if (isMouseConnected(context)) decrementHover();
            },
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
          return GestureDetector(
            onTap: () {
              if (!isMouseConnected(context)) {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              }
            },
            child: Padding(
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
            ),
          );
        },
      ),
    );
  }
}

///////////////////////////////========================================================================================================================
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
