// 1. 상품 데이터 모델 정의
class ProductItem {
  final int id;
  final String name;
  final String option;
  final String size;
  final String originalPrice;
  final String salePrice;

  const ProductItem({
    required this.id,
    required this.name,
    required this.option,
    required this.size,
    required this.originalPrice,
    required this.salePrice,
  });
}