// FILE: lib/global/component/hover_menu.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/global.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'dart:html' as html;

MenuController? _globalActiveController;
VoidCallback? _globalActiveCloseTrigger;

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

      // 1단계 [말단 아이템]: 자식이 없는 최종 단독 노드 (정상 이동)
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

      // 2단계 [중간 그룹]: 자식이 있는 그룹 (맨 위에 '전체보기' 자동 삽입 및 부모 자체 클릭 이동 차단)
      List<Widget> processedChildren = [];

      processedChildren.add(
        MouseRegion(
          onEnter: (_) {
            if (isMouseConnected(context)) incrementHover();
          },
          onExit: (_) {
            if (isMouseConnected(context)) decrementHover();
          },
          child: MenuItemButton(
            onPressed: () {
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
            child: const Text('전체보기',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6FA5))),
          ),
        ),
      );

      processedChildren.addAll(
        children
            .map<Widget>((child) =>
                buildMenuChild(ref, Map<String, dynamic>.from(child)))
            .toList(),
      );

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
                  children: processedChildren,
                ),
              ),
            )
          ],
          // 👉 부모 그룹 클릭 시 이동 로직 제거 (오직 하위 메뉴 창만 열림)
          child: Text(itemTitle,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
        ),
      );
    }

    final bool isMobileMode = MediaQuery.of(context).size.width < 960;

    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(right: isMobileMode ? 16 : 25),
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
              if (title == '이너웨어') targetPath = '/inner';
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
              padding: EdgeInsets.only(right: isMobileMode ? 16 : 25),
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
