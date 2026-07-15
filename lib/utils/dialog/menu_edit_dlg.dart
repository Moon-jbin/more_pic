// // 📌 정식으로 분리된 어드민 카테고리 편집기 위젯
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/search_provider.dart';
import 'package:more_pic/utils/dialog/dlg_function.dart';

class MenuEditDialog extends HookConsumerWidget {
  final List<Map<String, dynamic>> currentMenus;

  const MenuEditDialog({super.key, required this.currentMenus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 전체 카테고리 트리 상태 관리
    final menuTreeState = useState<List<Map<String, dynamic>>>(
        currentMenus.map((e) => Map<String, dynamic>.from(e)).toList());

    // 🌟 인덱스 기반 고유 경로 추적 스택
    final currentPathStack = useState<List<int>>([]);
    final scrollController = useScrollController();

    // 🌟 [안전 탐색기]: 현재 깊이의 카테고리 리스트를 반환합니다.
    List<Map<String, dynamic>> getCurrentDirectoryNode() {
      List<Map<String, dynamic>> target = menuTreeState.value;
      for (int index in currentPathStack.value) {
        if (index >= 0 && index < target.length) {
          final parent = target[index];
          if (parent.containsKey('children')) {
            target = List<Map<String, dynamic>>.from(parent['children']);
          } else {
            break;
          }
        }
      }
      return target;
    }

    // 🌟 [최종 완치]: 현재 보고 있는 화면의 '진짜 부모 물리 경로'를 100% 안전하게 추출합니다.
    String getAbsoluteParentPath() {
      if (currentPathStack.value.isEmpty) return '';

      List<Map<String, dynamic>> tempLevel = menuTreeState.value;
      String lastFoundPath = '';

      for (int i = 0; i < currentPathStack.value.length; i++) {
        final int targetIdx = currentPathStack.value[i];
        if (targetIdx >= 0 && targetIdx < tempLevel.length) {
          final parentNode = tempLevel[targetIdx];
          // 부모가 가지고 있는 실제 최종 path를 백업합니다.
          if (parentNode['path'] != null &&
              parentNode['path'].toString().isNotEmpty) {
            lastFoundPath = parentNode['path'].toString();
          }

          if (parentNode.containsKey('children') &&
              parentNode['children'] != null) {
            tempLevel = List<Map<String, dynamic>>.from(parentNode['children']);
          } else {
            break;
          }
        }
      }
      return lastFoundPath;
    }

    // 🌟 [완치 동기화 장부]: 트리 수정 시 부모-자식 주소록이 깨지지 않게 전사합니다.
    void syncAndRefreshTree(List<Map<String, dynamic>> updatedSubList) {
      if (currentPathStack.value.isEmpty) {
        menuTreeState.value = updatedSubList;
        return;
      }

      List<Map<String, dynamic>> mainTree =
          menuTreeState.value.map((e) => Map<String, dynamic>.from(e)).toList();
      List<Map<String, dynamic>> currentLevel = mainTree;

      for (int i = 0; i < currentPathStack.value.length; i++) {
        final targetIdx = currentPathStack.value[i];
        if (i == currentPathStack.value.length - 1) {
          currentLevel[targetIdx]['children'] = updatedSubList;
        } else {
          currentLevel[targetIdx]['children'] = List<Map<String, dynamic>>.from(
              currentLevel[targetIdx]['children'] ?? []);
          currentLevel = currentLevel[targetIdx]['children'];
        }
      }

      menuTreeState.value = mainTree;
    }

    final currentList = getCurrentDirectoryNode();
    // 🌟 현재 내 위치의 진짜 부모 경로 고정값 (예: '/test' 또는 '/test/sub_test')
    final String currentParentPath = getAbsoluteParentPath();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('📋 원격 카테고리 디렉토리 편집기',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (currentPathStack.value.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.arrow_upward_rounded, size: 14),
              label: const Text('상위 폴더로'),
              onPressed: () {
                final updatedStack = List<int>.from(currentPathStack.value);
                updatedStack.removeLast();
                currentPathStack.value = updatedStack;
              },
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Text(
                '📍 현재 고정 부모 경로: ${currentParentPath.isEmpty ? "/" : currentParentPath}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A6FA5)),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: currentList.length,
                itemBuilder: (context, index) {
                  final node = currentList[index];
                  final bool holdsChildren = node.containsKey('children') &&
                      (node['children'] as List).isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // 1. 카테고리 명칭 수정
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  key: ValueKey(
                                      'title_${currentPathStack.value.join('_')}_$index'),
                                  initialValue: node['title'],
                                  decoration: const InputDecoration(
                                      labelText: '카테고리 명칭',
                                      isDense: true,
                                      border: OutlineInputBorder()),
                                  onChanged: (newTitle) {
                                    final updated = currentList
                                        .map(
                                            (e) => Map<String, dynamic>.from(e))
                                        .toList();
                                    updated[index]['title'] = newTitle;
                                    syncAndRefreshTree(updated);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. 🌟 [영문 주소 입력] (부모 주소 고정 결합형)
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  key: ValueKey(
                                      'path_${currentPathStack.value.join('_')}_$index'),
                                  initialValue: (() {
                                    final String fullPath = node['path'] ?? '';
                                    final List<String> parts = fullPath
                                        .split('/')
                                        .where((s) => s.isNotEmpty)
                                        .toList();
                                    return parts.isEmpty ? '' : parts.last;
                                  })(),
                                  decoration: InputDecoration(
                                    labelText: holdsChildren
                                        ? '하위 그룹이 주소 관리 중'
                                        : '영문 주소 입력 (영어만)',
                                    isDense: true,
                                    prefixText: holdsChildren ? null : '/',
                                    border: const OutlineInputBorder(),
                                  ),
                                  enabled: !holdsChildren,
                                  onChanged: (newSlug) {
                                    final updated = currentList
                                        .map(
                                            (e) => Map<String, dynamic>.from(e))
                                        .toList();

                                    String sanitizedSlug = newSlug
                                        .trim()
                                        .toLowerCase()
                                        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                                    if (sanitizedSlug.isEmpty)
                                      sanitizedSlug = 'node';

                                    // 🌟 [완치]: 진짜 부모 물리 주소 뒤에 입력한 단어를 즉시 결합합니다.
                                    String finalPath = currentParentPath.isEmpty
                                        ? '/$sanitizedSlug'
                                        : '$currentParentPath/$sanitizedSlug';

                                    updated[index]['path'] = finalPath
                                        .replaceAll(RegExp(r'/+'), '/');
                                    syncAndRefreshTree(updated);
                                  },
                                ),
                              ),

                              // 3. 진입 버튼 (자식 디렉토리 이동)
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: holdsChildren
                                        ? Colors.blue
                                        : Colors.grey),
                                tooltip: '하위 자식 그룹 지정 및 관리',
                                onPressed: () {
                                  final updated = currentList
                                      .map((e) => Map<String, dynamic>.from(e))
                                      .toList();
                                  if (!updated[index].containsKey('children')) {
                                    updated[index]
                                        ['children'] = <Map<String, dynamic>>[];
                                    // 하위 폴더를 개설할 때, 부모 자신의 path는 그대로 보존해야 자식들이 경로를 역추적할 수 있습니다.
                                    syncAndRefreshTree(updated);
                                  }
                                  currentPathStack.value = [
                                    ...currentPathStack.value,
                                    index
                                  ];
                                },
                              ),

                              // 4. 삭제 버튼
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.red),
                                onPressed: () {
                                  final String categoryTitle =
                                      node['title'] ?? '새 카테고리';
                                  showOkCancelDlg(
                                    width: 400,
                                    context,
                                    title: '카테고리 삭제 확인',
                                    msg:
                                        '정말 \'$categoryTitle\' 카테고리를 삭제하시겠습니까?\n'
                                        '(⚠️ 하위 자식 그룹이 있다면 함께 완전히 삭제됩니다.)',
                                    onCancel: () => Navigator.pop(context),
                                    onTap: () {
                                      // '확인'을 눌렀을 때만 실제 장부에서 데이터 삭제 집행
                                      final updated = currentList
                                          .map((e) =>
                                              Map<String, dynamic>.from(e))
                                          .toList();
                                      updated.removeAt(index);
                                      syncAndRefreshTree(updated);

                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // 새 카테고리 추가 구역
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6FA5).withOpacity(0.12),
                foregroundColor: const Color(0xFF4A6FA5),
                minimumSize: const Size(double.infinity, 45),
                elevation: 0,
              ),
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('현재 위치에 새 카테고리 개설'),
              onPressed: () {
                final updated = currentList
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();

                final int uniqueId =
                    DateTime.now().millisecondsSinceEpoch % 1000;
                final String mySlug = 'item_$uniqueId';

                // 🌟 [완치]: 생성 시에도 고정된 진짜 부모 주소값에 찰떡 결합합니다.
                String generatedPath = currentParentPath.isEmpty
                    ? '/$mySlug'
                    : '$currentParentPath/$mySlug';

                generatedPath = generatedPath.replaceAll(RegExp(r'/+'), '/');

                updated.add({'title': '새 카테고리명', 'path': generatedPath});

                syncAndRefreshTree(updated);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              },
            )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: () async {
            await updateRemoteMenuTree(menuTreeState.value);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🚀 구글 클라우드 서버에 동적 메뉴 배치가 무결성 전파되었습니다!')));
            }
          },
          child: const Text('구글 서버 저장 전파'),
        )
      ],
    );
  }
}
