///```
/// 홈 화면, 사이드 바 에 있는 메뉴 데이터 구조 정의
///```
// 1. 공용 다단계 카테고리 데이터 구조 정의 (ACC, SEASON 데이터 추가 완료)
final List<Map<String, dynamic>> menuData = [
  {
    'title': '신생아~3M',
    'children': [
      {'title': '옷', 'path': '/newborn/clothes'},
      {'title': '양말 등 잡화', 'path': '/newborn/socks'},
    ]
  },
  {
    'title': 'BABY (0~18m)',
    'children': [
      {
        'title': 'OUTER',
        'children': [
          {'title': '점퍼/자켓', 'path': '/baby/outer/jumper_jacket'},
          {
            'title': '가디건',
            'children': [
              {
                'title': '(상세분류) Cropped',
                'path': '/baby/outer/cardigan/cropped'
              },
              {
                'title': '(상세분류) Graphic Tees',
                'path': '/baby/outer/cardigan/graphic_tees'
              },
            ]
          },
          {'title': '조끼', 'path': '/baby/outer/vest'},
        ]
      },
      {'title': 'TOP', 'path': '/baby/top'},
      {'title': 'BOTTOM', 'path': '/baby/bottom'},
      {'title': 'SET/DRESS', 'path': '/baby/set_dress'},
    ]
  },
  {
    'title': 'KIDS (24m~)',
    'children': [
      {
        'title': 'OUTER',
        'children': [
          {'title': '점퍼/자켓', 'path': '/kids/outer/jumper_jacket'},
          {
            'title': '가디건',
            'children': [
              {
                'title': '(상세분류) Cropped',
                'path': '/kids/outer/cardigan/cropped'
              },
              {
                'title': '(상세분류) Graphic Tees',
                'path': '/kids/outer/cardigan/graphic_tees'
              },
            ]
          },
          {'title': '조끼', 'path': '/kids/outer/vest'},
        ]
      },
      {'title': 'TOP', 'path': '/kids/top'},
      {'title': 'BOTTOM', 'path': '/kids/bottom'},
      {'title': 'SET/DRESS', 'path': '/kids/set_dress'},
    ]
  },
  {'title': '내복', 'path': '/inner'}, // 하위 데이터가 없으므로 일반 탭 버튼으로 작동
  {
    'title': 'ACC',
    'children': [
      {'title': '양말(BABY)', 'path': '/acc/socks_baby'},
      {'title': '양말(KIDS)', 'path': '/acc/socks_kids'},
      {'title': '모자/보넷', 'path': '/acc/hats_beanies'},
      {'title': '헤어악세사리', 'path': '/acc/hair_accessories'},
      {'title': '기타', 'path': '/acc/other'},
    ]
  },
  {
    'title': 'SEASON',
    'children': [
      {'title': '여름(수영복 등)', 'path': '/season/summer'},
      {'title': '겨울(방한아이템 등)', 'path': '/season/winter'},
      {'title': '명절(한복 등)', 'path': '/season/holidays'},
    ]
  },
  {'title': 'SALE', 'path': '/sale'},
];
