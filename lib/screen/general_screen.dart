import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:more_pic/data/acc_hair_acc_data.dart';
import 'package:more_pic/data/acc_hats_beanies_data.dart';
import 'package:more_pic/data/acc_other_data.dart';
import 'package:more_pic/data/acc_socks_baby_data.dart';
import 'package:more_pic/data/acc_socks_kids_data.dart';
import 'package:more_pic/data/baby_bottom_data.dart';
import 'package:more_pic/data/baby_outer_cardigan_grapich_tees_data.dart';
import 'package:more_pic/data/baby_outer_jumper_jacket_data.dart';
import 'package:more_pic/data/baby_outer_vest_data.dart';
import 'package:more_pic/data/baby_outter_cardigan_cropped_data.dart';
import 'package:more_pic/data/baby_set_dress_data.dart';
import 'package:more_pic/data/baby_top_data.dart';
import 'package:more_pic/data/inner_data.dart';
import 'package:more_pic/data/kids_bottom_data.dart';
import 'package:more_pic/data/kids_outer_cardigan_grapich_tees_data.dart';
import 'package:more_pic/data/kids_outer_jumper_jacket_data.dart';
import 'package:more_pic/data/kids_outer_vest_data.dart';
import 'package:more_pic/data/kids_outter_cardigan_cropped_data.dart';
import 'package:more_pic/data/kids_set_dress_data.dart';
import 'package:more_pic/data/kids_top_data.dart';
import 'package:more_pic/data/new_born_clothes_data.dart';
import 'package:more_pic/data/new_born_socks_data.dart';
import 'package:more_pic/data/sale_data.dart';
import 'package:more_pic/data/season_holidays_data.dart';
import 'package:more_pic/data/season_summer_data.dart';
import 'package:more_pic/data/season_winter_data.dart';
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
        itemData: newBornClothesProducts,
        category: 'newbornClothes', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: newBornClothesProducts,
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
        itemData: newBornSocksProducts,
        category: 'newbornSocks', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: newBornSocksProducts,
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
        itemData: babyOuterJumperJacketData,
        category: 'babyOuterJumperJacket', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: babyOuterJumperJacketData,
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
        itemData: babyOuterCardiganCroppedData,
        category: 'babyOuterCardiganCropped', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: babyOuterCardiganCroppedData,
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
        itemData: babyOuterCardiganGrapichTeesData,
        category: 'babyOuterCardiganGraphicTees', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: babyOuterCardiganGrapichTeesData,
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
        itemData: babyOuterVestData,
        category: 'babyOuterVest', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
            itemData: babyOuterVestData,
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
        itemData: babyTopData,
        category: 'babyTop', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: babyTopData,
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
        itemData: babyBottomData,
        category: 'babyBottom', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: babyBottomData,
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
        itemData: babySetDressData,
        category: 'babySetDress', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: babySetDressData,
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
        itemData: kidsOuterJumperJacketData,
        category: 'kidsOuterJumperJacket', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsOuterJumperJacketData,
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
        itemData: kidsOuterCardiganCroppedData,
        category: 'kidsOuterCardiganCropped', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsOuterCardiganCroppedData,
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
        itemData: kidsOuterCardiganGrapichTeesData,
        category: 'kidsOuterCardiganGraphicTees', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsOuterCardiganGrapichTeesData,
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
        itemData: kidsOuterVestData,
        category: 'kidsOuterVest', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsOuterVestData,
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
        itemData: kidsTopData,
        category: 'kidsTop', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsTopData,
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
        itemData: kidsBottomData,
        category: 'kidsBottom', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsBottomData,
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
        itemData: kidsSetDressData,
        category: 'kidsSetDress', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: kidsSetDressData,
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
        itemData: innerData,
        category: 'inner', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: innerData,
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
        itemData: accSocksBabyData,
        category: 'accSocksBaby', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: accSocksBabyData,
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
        itemData: accSocksKidsData,
        category: 'accSocksKids', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: accSocksKidsData,
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
        itemData: accHatsBeaniesData,
        category: 'accHatsBeanies', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: accHatsBeaniesData,
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
        itemData: accHairAccData,
        category: 'accHairAcc', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: accHairAccData,
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
        itemData: accOtherData,
        category: 'accOther', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: accOtherData,
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
        itemData: seasonSummerData,
        category: 'seasonSummer', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: seasonSummerData,
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
        itemData: seasonWinterData,
        category: 'seasonWinter', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: seasonWinterData,
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
        itemData: seasonHolidaysData,
        category: 'seasonHolidays', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: seasonHolidaysData,
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
        itemData: saleData,
        category: 'sale', // 👈 CustomScaffold 추가
        bodyBuilder: (context, scrollController) {
          return ProductListPage(
              itemData: saleData,
              scrollController: scrollController,
              category: 'sale');
        });
  }
}
