class ProductItem {
  final String id;
  final String name;
  final int price;
  final String image;
  final String categoryName;
  final List<String> detailImages;
  final String size;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.categoryName,
    required this.detailImages,
    required this.size,
  });

  // 📥 DB에서 긁어온 Map 데이터를 플러터 객체로 변환
  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      image: json['image'] ?? '',
      detailImages: List<String>.from(json['detailImages'] ?? []),
      categoryName: json['categoryName'] ?? '',
      size: json['size'] ?? '',
    );
  }

  // 📤 플러터 객체를 DB에 집어넣을 Map 형태로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image': image,
      'detailImages': detailImages,
      'categoryName': categoryName,
      'size': size,
    };
  }
}
