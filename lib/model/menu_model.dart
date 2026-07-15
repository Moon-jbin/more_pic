class MenuModel {
  final String title;
  final String? path; // 대분류가 바로 이동할 경로가 있을 경우
  final List<SubMenuModel> children;

  MenuModel({
    required this.title,
    this.path,
    required this.children,
  });

  // Firestore Map 데이터를 객체로 안전하게 변환하는 팩토리 생성자
  factory MenuModel.fromMap(Map<String, dynamic> map) {
    // children 필드가 null이거나 비어있을 때를 대비한 안전한 처리
    var childrenList = map['children'] as List<dynamic>? ?? [];
    List<SubMenuModel> parsedChildren = childrenList
        .map((item) => SubMenuModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return MenuModel(
      title: map['title'] as String? ?? '',
      path: map['path'] as String?,
      children: parsedChildren,
    );
  }

  // 역으로 Firestore에 올릴 때 쓸 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (path != null) 'path': path,
      'children': children.map((child) => child.toMap()).toList(),
    };
  }
}

class SubMenuModel {
  final String title;
  final String path;

  SubMenuModel({
    required this.title,
    required this.path,
  });

  factory SubMenuModel.fromMap(Map<String, dynamic> map) {
    return SubMenuModel(
      title: map['title'] as String? ?? '',
      path: map['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'path': path,
    };
  }
}