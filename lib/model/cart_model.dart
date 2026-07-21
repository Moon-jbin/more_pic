import 'dart:convert';

class CartItem {
  final String id; // 고유 ID (보통 상품ID + 색상 + 사이즈 조합)
  final String name; // 상품명
  final String color; // 색상
  final String size; // 사이즈
  final int quantity; // 수량
  final int price; // 단가

  CartItem({
    required this.id,
    required this.name,
    required this.color,
    required this.size,
    required this.quantity,
    required this.price,
  });

  // 수량 변경을 위한 copyWith
  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      color: color,
      size: size,
      quantity: quantity ?? this.quantity,
      price: price,
    );
  }

  // SharedPreferences 저장을 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'size': size,
      'quantity': quantity,
      'price': price,
    };
  }

  // SharedPreferences에서 불러오기 위한 Map 변환
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '',
      size: map['size'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: map['price']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory CartItem.fromJson(String source) => CartItem.fromMap(json.decode(source));
}