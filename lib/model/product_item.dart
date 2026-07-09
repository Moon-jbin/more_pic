class ProductItem {
  final String id;
  final String name;
  final int price;
  final String categoryName;
  final List<String> images;
  final String size;
  final String productDetail;
  final String color;
  final String shippingType;   // 예: '국내배송' 또는 '해외배송'
  final String shippingMethod; // 예: 'CJ대한통운 기본배송' 등

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.categoryName,
    required this.size,
    required this.productDetail,
    required this.color,
    required this.shippingType,
    required this.shippingMethod,
  });

  // 📥 DB에서 긁어온 Map 데이터를 플러터 객체로 변환
  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      categoryName: json['categoryName'] ?? '',
      size: json['size'] ?? '',
      productDetail: json['productDetail'] ?? '',
      color: json['color'] ?? '',
      shippingType: json['shippingType'] ?? '국내배송', 
      shippingMethod: json['shippingMethod'] ?? '',
    );
  }

  // 📤 플러터 객체를 DB에 집어넣을 Map 형태로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'images': images,
      'size': size,
      'categoryName': categoryName,
      'productDetail': productDetail,
      'color': color,
      'shippingType': shippingType,
      'shippingMethod': shippingMethod,
    };
  }
}