import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TagInputWidget extends HookWidget {
  final String labelText;
  final String hintText;
  final ValueNotifier<List<String>> tagsNotifier;
  final IconData prefixIcon;

  const TagInputWidget({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.tagsNotifier,
    required this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();

    // 텍스트를 리스트에 추가하는 로직
    void addTag(String value) {
      final trimmed =
          value.trim().replaceAll(RegExp(r'[,/|]'), ''); // 구분자 기호 제거
      if (trimmed.isNotEmpty && !tagsNotifier.value.contains(trimmed)) {
        tagsNotifier.value = [...tagsNotifier.value, trimmed];
      }
      textController.clear();
      focusNode.requestFocus(); // 계속 입력할 수 있게 포커스 유지
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(prefixIcon),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF4A6FA5)),
              onPressed: () => addTag(textController.text),
            ),
          ),
          onSubmitted: addTag,
          onChanged: (value) {
            // 쉼표(,)를 입력하면 자동으로 태그 생성
            if (value.endsWith(',')) {
              addTag(value.substring(0, value.length - 1));
            }
          },
        ),
        if (tagsNotifier.value.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagsNotifier.value.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFF4A6FA5).withOpacity(0.1),
                deleteIconColor: const Color(0xFF4A6FA5),
                onDeleted: () {
                  tagsNotifier.value =
                      tagsNotifier.value.where((t) => t != tag).toList();
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
