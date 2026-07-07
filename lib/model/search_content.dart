// 1. 상품 데이터 모델 정의
class SearchContent {
  final String searchContent;
  final int page;

  const SearchContent({
    required this.searchContent,
    required this.page,
  });
}
