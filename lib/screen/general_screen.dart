import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/global/component/product_list_page.dart';
import 'package:more_pic/global/custom_widget/custom_widget.dart';

// ======================== 신생아~3M ========================
///```
/// 신생아~3M / 옷 Page
///```
class NewbornClothesScreen extends HookConsumerWidget {
  const NewbornClothesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'newbornClothes',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'newbornClothes');
        });
  }
}

///```
/// 신생아~3M / 양말 등 잡화 Page
///```
class NewbornSocksScreen extends HookConsumerWidget {
  const NewbornSocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'newbornSocks',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'newbornSocks');
        });
  }
}

// ===================== BABY (0~18m) =====================
///```
/// BABY (0~18) / OUTER / 점퍼 자켓 Page
///```
class BabyOuterJumperJacketScreen extends HookConsumerWidget {
  const BabyOuterJumperJacketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babyOuterJumperJacket',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'babyOuterJumperJacket');
        });
  }
}

///```
/// BABY (0~18) / OUTER / 가디건 / Cropped Page
///```
class BabyOuterCardiganCroppedScreen extends HookConsumerWidget {
  const BabyOuterCardiganCroppedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babyOuterCardiganCropped',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'babyOuterCardiganCropped');
        });
  }
}

///```
/// BABY (0~18) / OUTER / 가디건 / Graphic Tees Page
///```
class BabyOuterCardiganGraphicTeesScreen extends HookConsumerWidget {
  const BabyOuterCardiganGraphicTeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babyOuterCardiganGraphicTees',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'babyOuterCardiganGraphicTees');
        });
  }
}

///```
/// BABY (0~18) / OUTER / vest Page
///```
class BabyOuterVestScreen extends HookConsumerWidget {
  const BabyOuterVestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babyOuterVest',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
            scrollController: scrollController,
            category: 'babyOuterVest',
          );
        });
  }
}

///```
/// BABY (0~18) / TOP Page
///```
class BabyTopScreen extends HookConsumerWidget {
  const BabyTopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babyTop',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'babyTop');
        });
  }
}

///```
/// BABY (0~18) / BOTTOM Page
///```
class BabyBottomScreen extends HookConsumerWidget {
  const BabyBottomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babyBottom',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'babyBottom');
        });
  }
}

///```
/// BABY (0~18) / SET_DRESS Page
///```
class BabySetDressScreen extends HookConsumerWidget {
  const BabySetDressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'babySetDress',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'babySetDress');
        });
  }
}

// ============================ KIDS (24M~) ============================
///```
/// KIDS (24M~) / OUTER / 점퍼 자켓 Page
///```
class KidsOuterJumperJacketScreen extends HookConsumerWidget {
  const KidsOuterJumperJacketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsOuterJumperJacket',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsOuterJumperJacket');
        });
  }
}

///```
/// KIDS (24M~) / OUTER / 가디건 / Cropped Page
///```
class KidsOuterCardiganCroppedScreen extends HookConsumerWidget {
  const KidsOuterCardiganCroppedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsOuterCardiganCropped',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsOuterCardiganCropped');
        });
  }
}

///```
/// KIDS (24M~) / OUTER / 가디건 / Graphic Tees Page
///```
class KidsOuterCardiganGraphicTeesScreen extends HookConsumerWidget {
  const KidsOuterCardiganGraphicTeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsOuterCardiganGraphicTees',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsOuterCardiganGraphicTees');
        });
  }
}

///```
/// KIDS (24M~) / OUTER / vest Page
///```
class KidsOuterVestScreen extends HookConsumerWidget {
  const KidsOuterVestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsOuterVest',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsOuterVest');
        });
  }
}

///```
/// KIDS (24M~) / TOP Page
///```
class KidsTopScreen extends HookConsumerWidget {
  const KidsTopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsTop',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsTop');
        });
  }
}

///```
/// KIDS (24M~) / BOTTOM Page
///```
class KidsBottomScreen extends HookConsumerWidget {
  const KidsBottomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsBottom',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsBottom');
        });
  }
}

///```
/// KIDS (24M~) / SET_DRESS Page
///```
class KidsSetDressScreen extends HookConsumerWidget {
  const KidsSetDressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'kidsSetDress',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'kidsSetDress');
        });
  }
}

// ======================= 내복 =======================
///```
/// 내복 Page
///```
class InnerScreen extends HookConsumerWidget {
  const InnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'inner',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'inner');
        });
  }
}

// ======================== ACC ========================
///```
/// ACC / 양말(BABY) Page
///```
class AccSocksBabyScreen extends HookConsumerWidget {
  const AccSocksBabyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'accSocksBaby',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'accSocksBaby');
        });
  }
}

///```
/// ACC / 양말(KIDS) Page
///```
class AccSocksKidsScreen extends HookConsumerWidget {
  const AccSocksKidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'accSocksKids',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'accSocksKids');
        });
  }
}

///```
/// ACC / 모자_보넷 Page
///```
class AccHatsBeaniesScreen extends HookConsumerWidget {
  const AccHatsBeaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'accHatsBeanies',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'accHatsBeanies');
        });
  }
}

///```
/// ACC / 헤어악세사리 Page
///```
class AccHairAccScreen extends HookConsumerWidget {
  const AccHairAccScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'accHairAcc',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'accHairAcc');
        });
  }
}

///```
/// ACC / 기타 Page
///```
class AccOtherScreen extends HookConsumerWidget {
  const AccOtherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'accOther',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'accOther');
        });
  }
}

// ======================== SEASON ========================
///```
/// SEASON / 여름(수영복 등) Page
///```
class SeasonSummerScreen extends HookConsumerWidget {
  const SeasonSummerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'seasonSummer',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'seasonSummer');
        });
  }
}

///```
/// SEASON / 겨울(방한아이템 등) Page
///```
class SeasonWinterScreen extends HookConsumerWidget {
  const SeasonWinterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'seasonWinter',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'seasonWinter');
        });
  }
}

///```
/// SEASON / 명절(한복 등) Page
///```
class SeasonHolidaysScreen extends HookConsumerWidget {
  const SeasonHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'seasonHolidays',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'seasonHolidays');
        });
  }
}

// ======================== SALE ========================
///```
/// Sale Page
///```
class SaleScreen extends HookConsumerWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
        category: 'sale',
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              scrollController: scrollController,
              category: 'sale');
        });
  }
}