import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/provider/product_filter_provider.dart';

class ProductFilterBar extends HookConsumerWidget {
  final int totalCount;

  const ProductFilterBar({super.key, required this.totalCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(productFilterProvider);
    final filterNotifier = ref.read(productFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 노출된 상품 개수
          Text(
            '총 $totalCount개',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),

          Theme(
            data: Theme.of(context).copyWith(
              // 💡 못생긴 진회색 호버 효과를 아주 연하고 고급스러운 회색으로 변경
              hoverColor: Colors.grey.shade50,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<ProductSortOption>(
              initialValue: filterState.sortOption,
              tooltip: '', // 길게 눌렀을 때 뜨는 불필요한 툴팁 제거
              elevation: 2, // 붕 뜨는 그림자를 은은하게 축소
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.grey.shade200), // 테두리를 얇고 깔끔하게
              ),
              position: PopupMenuPosition.under, // 클릭 시 버튼 바로 아래에 깔끔하게 열림
              offset: const Offset(0, 4), // 버튼과 메뉴 사이 4px 여백
              constraints:
                  const BoxConstraints(minWidth: 100), // 가로 너비를 타이트하게 제한
              onSelected: (newValue) {
                filterNotifier.setSortOption(newValue);
              },
              itemBuilder: (context) => ProductSortOption.values.map((option) {
                final isSelected = filterState.sortOption == option;
                return PopupMenuItem<ProductSortOption>(
                  value: option,
                  height:
                      36, // 💡 핵심: 항목 간의 패딩(높이)을 36px로 좁혀서 심플하게 만듦 (기본 48px)
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      // 선택된 정렬 기준은 브랜드 포인트 컬러로 강조
                      color:
                          isSelected ? const Color(0xFF4A6FA5) : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),

              // 화면에 보여지는 버튼(트리거) UI
              child: Container(
                height: 30, // 품절 버튼과 높이 동일하게 통일
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filterState.sortOption.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 14, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
