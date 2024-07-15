import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/home/cuisine/cuisineCubit.dart';
import 'package:wakDak/cubit/product/productCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/ui/screen/cart/cart_screen.dart';
import 'package:wakDak/ui/screen/home/menu/menu_view_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/ui/widgets/simmer/bottomCartSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/categoryVerticallySimmer.dart';
import 'package:wakDak/ui/widgets/simmer/menuDetailSimmer.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  MenuScreenState createState() => MenuScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => MenuScreen());
  }
}

class MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  double? width, height;
  TabController? tabController;
  int selectedIndex = 0;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  var db = DatabaseHelper();
  String? categoryId = "";
  bool enableList = false;
  int? _selectedIndex;
  String? statusFoodType = "";
  String? costStatus = "";
  int? costStatusIndex;
  int? statusFoodTypeIndex;
  String? sort = "";
  StateSetter? bottomState;

  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    cuisineApi();
    cartApi();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  cuisineApi() {
    context.read<CuisineCubit>().fetchCuisine(perPage, "", context.read<SettingsCubit>().getSettings().branchId);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  cartApi() {
    if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
    } else {
      context
          .read<GetCartCubit>()
          .getCartUser(userId: context.read<AuthCubit>().getId(), branchId: context.read<SettingsCubit>().getSettings().branchId);
    }
  }

  productApi() {
    context.read<ProductCubit>().fetchProduct(
        perPage,
        context.read<AuthCubit>().getId(),
        context.read<SettingsCubit>().getSettings().branchId,
        categoryId,
        statusFoodType,
        costStatus,
        "");
  }

  Future<void> refreshList() async {
    cartApi();
    cuisineApi();
  }

  onChanged(int position) {
    bottomState!(() {
      _selectedIndex = position;
      enableList = !enableList;
    });
  }

  onTap() {
    bottomState!(() {
      enableList = !enableList;
    });
  }

  Widget cuisineList() {
    return BlocConsumer<CuisineCubit, CuisineState>(
        bloc: context.read<CuisineCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CuisineProgress || state is CuisineInitial) {
            return Center(child: CuisineVerticallySimmer(length: 9, width: width!, height: height!));
          }
          if (state is CuisineFailure) {}
          final cuisineList = (state as CuisineSuccess).cuisineList;
          return Container(
            decoration: DesignConfig.boxDecorationContainerCardShadow(Theme.of(context).colorScheme.onBackground, shadow, 10.0, 0.0, 0.0, 10.0, 0.0),
            margin: EdgeInsetsDirectional.only(top: height! / 99.0),
            child: ListView.builder(
                padding: EdgeInsetsDirectional.only(top: height! / 99.9, bottom: height! / 99.0),
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: cuisineList.length,
                itemBuilder: (context, position) {
                  return InkWell(
                    onTap: () {
                      onChanged(position);
                      categoryId = cuisineList[position].id!;
                      selectedIndex = position;
                    },
                    child: Container(
                        padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, top: height! / 99.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cuisineList[position].name!,
                              style: TextStyle(
                                  fontSize: 14.0, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontWeight: FontWeight.w500),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(top: height! / 99.0),
                              child: Divider(
                                color: lightFont.withOpacity(0.50),
                                height: 1.0,
                              ),
                            ),
                          ],
                        )),
                  );
                }),
          );
        });
  }

  Widget cuisineDropdown() {
    return BlocConsumer<CuisineCubit, CuisineState>(
        bloc: context.read<CuisineCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CuisineProgress || state is CuisineInitial) {
            return Center(child: CuisineVerticallySimmer(length: 9, width: width!, height: height!));
          }
          if (state is CuisineFailure) {}
          final cuisineList = (state as CuisineSuccess).cuisineList;
          return InkWell(
            onTap: onTap,
            child: Container(
              margin: EdgeInsetsDirectional.only(bottom: height! / 50.0),
              decoration: DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
              padding: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 99.0, top: height! / 80.0, bottom: height! / 80.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                      child: Text(
                    _selectedIndex != null ? cuisineList[_selectedIndex!].text! : UiUtils.getTranslatedLabel(context, selectCuisineLabel),
                    style: TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontWeight: FontWeight.w500),
                  )),
                  Icon(enableList ? Icons.expand_less : Icons.expand_more, size: 24.0, color: Theme.of(context).colorScheme.onPrimary),
                ],
              ),
            ),
          );
        });
  }

  filterBottomSheet() {
    showModalBottomSheet(
        useSafeArea: true,
        isDismissible: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState1) {
            bottomState = setState1;
            return Container(
              padding: EdgeInsetsDirectional.only(bottom: MediaQuery.of(context).viewInsets.bottom, start: width! / 20.0, end: width! / 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                          child: Text(
                            UiUtils.getTranslatedLabel(context, foodTypeLabel),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal),
                          ),
                        ),
                        Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: Theme.of(context).colorScheme.secondary,
                                  disabledColor: Theme.of(context).colorScheme.secondary),
                              child: Container(
                                decoration: DesignConfig.boxDecorationContainerBorder(
                                    statusFoodType == "1" ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                                    statusFoodType == "1"
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                                        : Theme.of(context).colorScheme.onBackground,
                                    4.0,
                                    status: true),
                                child: RadioListTile(
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  title: Text(
                                    UiUtils.getTranslatedLabel(context, vegLabel),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal),
                                  ),
                                  value: 0,
                                  groupValue: statusFoodTypeIndex,
                                  contentPadding: EdgeInsets.all(5.0),
                                  dense: true,
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                  onChanged: (value) {
                                    setState(() {
                                      bottomState!(() {
                                        statusFoodType = "1";
                                        statusFoodTypeIndex = 0;
                                      });
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: width! / 40.0),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor: Theme.of(context).colorScheme.secondary,
                                disabledColor: Theme.of(context).colorScheme.secondary,
                              ),
                              child: Container(
                                decoration: DesignConfig.boxDecorationContainerBorder(
                                    statusFoodType == "2" ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                                    statusFoodType == "2"
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                                        : Theme.of(context).colorScheme.onBackground,
                                    4.0,
                                    status: true),
                                child: RadioListTile(
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  title: Text(
                                    UiUtils.getTranslatedLabel(context, nonVegLabel),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal),
                                  ),
                                  value: 1,
                                  groupValue: statusFoodTypeIndex,
                                  contentPadding: EdgeInsets.all(5.0),
                                  dense: true,
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                  onChanged: (value) {
                                    setState(() {
                                      bottomState!(() {
                                        statusFoodType = "2";
                                        statusFoodTypeIndex = 1;
                                      });
                                    });
                                  },
                                ),
                              ),
                            ),
                          )
                        ]),
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: height! / 40.0, bottom: height! / 80.0),
                          child: Text(
                            UiUtils.getTranslatedLabel(context, priceLabel),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal),
                          ),
                        ),
                        Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: Theme.of(context).colorScheme.secondary,
                                  disabledColor: Theme.of(context).colorScheme.secondary),
                              child: Container(
                                decoration: DesignConfig.boxDecorationContainerBorder(
                                    costStatus == "ASC" ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                                    costStatus == "ASC"
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                                        : Theme.of(context).colorScheme.onBackground,
                                    4.0,
                                    status: true),
                                child: RadioListTile(
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  title: Text(
                                    UiUtils.getTranslatedLabel(context, lowToHighLabel),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal),
                                  ),
                                  value: 0,
                                  groupValue: costStatusIndex,
                                  contentPadding: EdgeInsets.all(5.0),
                                  dense: true,
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                  onChanged: (value) {
                                    setState(() {
                                      bottomState!(() {
                                        costStatus = "ASC";
                                        sort = sortPriceKey;
                                        costStatusIndex = 0;
                                      });
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: width! / 40.0),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor: Theme.of(context).colorScheme.secondary,
                                disabledColor: Theme.of(context).colorScheme.secondary,
                              ),
                              child: Container(
                                decoration: DesignConfig.boxDecorationContainerBorder(
                                    costStatus == "DESC" ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                                    costStatus == "DESC"
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                                        : Theme.of(context).colorScheme.onBackground,
                                    4.0,
                                    status: true),
                                child: RadioListTile(
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  title: Text(
                                    UiUtils.getTranslatedLabel(context, highToLowLabel),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal),
                                  ),
                                  value: 1,
                                  groupValue: costStatusIndex,
                                  contentPadding: EdgeInsets.all(5.0),
                                  dense: true,
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                  onChanged: (value) {
                                    setState(() {
                                      bottomState!(() {
                                        costStatus = "DESC";
                                        sort = sortPriceKey;
                                        costStatusIndex = 1;
                                      });
                                    });
                                  },
                                ),
                              ),
                            ),
                          )
                        ]),
                      ],
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      child: ButtonContainer(
                        color: Theme.of(context).colorScheme.onBackground,
                        height: height,
                        width: width,
                        text: UiUtils.getTranslatedLabel(context, clearLabel),
                        start: 0,
                        end: width! / 40.0,
                        bottom: height! / 55.0,
                        top: height! / 40.0,
                        status: false,
                        borderColor: Theme.of(context).colorScheme.onPrimary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          setState(() {
                            bottomState!(() {
                              statusFoodType = "";
                              costStatus = "";
                              sort = "";
                              costStatusIndex = null;
                              statusFoodTypeIndex = null;
                              
                            });
                          });
                          Future.delayed(Duration(seconds: 2), () {
                            List.generate(context.read<CuisineCubit>().cuisineList().length, (index) => globalKey?[index].currentState?.productApi());
                            tabController!.animateTo(selectedIndex);
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ButtonContainer(
                        color: Theme.of(context).colorScheme.primary,
                        height: height,
                        width: width,
                        text: UiUtils.getTranslatedLabel(context, applyLabel),
                        start: width! / 40.0,
                        end: 0,
                        bottom: height! / 55.0,
                        top: height! / 40.0,
                        status: false,
                        borderColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          
                          List.generate(context.read<CuisineCubit>().cuisineList().length, (index) => globalKey?[index].currentState?.productApi());
                          tabController!.animateTo(selectedIndex);
                          Navigator.pop(context);
                        },
                      ),
                    )
                  ])
                ],
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : BlocConsumer<CuisineCubit, CuisineState>(
              bloc: context.read<CuisineCubit>(),
              listener: (context, state) {
                if (state is CuisineSuccess && state.cuisineList.isNotEmpty) {
                  if (globalKey == null) {
                    globalKey = List.generate((state.cuisineList).length, (index) => GlobalObjectKey(index));
                  }
                  tabController = TabController(length: state.cuisineList.length, vsync: this, initialIndex: selectedIndex);
                  tabController!.addListener(() {
                    setState(() {
                      selectedIndex = tabController!.index;
                      categoryId = state.cuisineList[selectedIndex].id;
                      
                    });
                  });

                  categoryId = state.cuisineList[selectedIndex].id;
                  if (selectedIndex == 0) {
                    
                  }
                }
              },
              builder: (context, state) {
                if (state is CuisineProgress || state is CuisineInitial) {
                  return Scaffold(
                      backgroundColor: Theme.of(context).colorScheme.onBackground, body: MenuDetailSimmer(width: width!, height: height!));
                }
                if (state is CuisineFailure) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.onBackground,
                    appBar: DesignConfig.appBar(context, width!, UiUtils.getTranslatedLabel(context, menuLabel),
                        const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
                  );
                }
                final categoryList = (state as CuisineSuccess).cuisineList;
                return Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.onBackground,
                    appBar: PreferredSize(
                        preferredSize: Size.fromHeight(height! / 8.0),
                        child: DefaultTabController(
                          
                          length: categoryList.length,
                          child: Container(
                            decoration: BoxDecoration(boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                                offset: Offset(0, 2.0),
                                blurRadius: 12.0,
                              )
                            ]),
                            child: AppBar(
                              leading: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                      padding: EdgeInsetsDirectional.only(start: width! / 20),
                                      child: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                                          color: Theme.of(context).colorScheme.onPrimary))),
                              backgroundColor: Theme.of(context).colorScheme.onBackground,
                              shadowColor: textFieldBackground,
                              elevation: 0,
                              centerTitle: false,
                              title: Text(UiUtils.getTranslatedLabel(context, menuLabel),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w500)),
                              bottom: PreferredSize(
                                preferredSize: Size.fromHeight(80),
                                child: TabBar(
                                  indicatorWeight: 2.0,
                                  onTap: (int val) {
                                    setState(() {
                                      selectedIndex = val;
                                      categoryId = state.cuisineList[val].id;
                                      
                                    });
                                  },
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  isScrollable: true,
                                  labelColor: Theme.of(context).colorScheme.onPrimary,
                                  unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
                                  indicatorColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  controller: tabController,
                                  indicatorPadding: EdgeInsetsDirectional.zero,
                                  labelPadding: EdgeInsetsDirectional.zero,
                                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                  tabs: categoryList
                                      .map((t) => Container(
                                            height: 35,
                                            alignment: Alignment.center,
                                            margin: EdgeInsetsDirectional.only(
                                                start: width! / 40.0, end: width! / 40.0, top: height! / 80.0, bottom: height! / 80.0),
                                            padding: const EdgeInsetsDirectional.only(
                                              start: 20,
                                              end: 20,
                                            ),
                                            decoration: categoryId == t.id
                                                ? DesignConfig.boxDecorationContainerBorder(
                                                    Theme.of(context).colorScheme.onPrimary, Theme.of(context).colorScheme.primary, 100.0)
                                                : DesignConfig.boxDecorationContainerBorder(
                                                    Theme.of(context).colorScheme.onPrimary, Theme.of(context).colorScheme.onBackground, 100.0),
                                            child: Tab(
                                              text: t.name,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                              actions: [
                                GestureDetector(
                                  onTap: () {
                                    filterBottomSheet();
                                  },
                                  child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
                                      child: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onPrimary)),
                                ),
                              ],
                            ),
                          ),
                        )),
                    bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                      return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
                          ? BlocConsumer<SettingsCubit, SettingsState>(
                              bloc: context.read<SettingsCubit>(),
                              listener: (context, state) {},
                              builder: (context, state) {
                                return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) &&
                                        (state.settingsModel!.cartCount == "0" ||
                                            state.settingsModel!.cartCount == "" ||
                                            state.settingsModel!.cartCount == "0.0") &&
                                        (state.settingsModel!.cartTotal == "0" ||
                                            state.settingsModel!.cartTotal == "" ||
                                            state.settingsModel!.cartTotal == "0.0" ||
                                            state.settingsModel!.cartTotal == "0.00")
                                    ? const SizedBox.shrink()
                                    : Container(
                                        margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 40.0),
                                        width: width,
                                        padding: EdgeInsetsDirectional.only(
                                            top: height! / 55.0, bottom: height! / 55.0, start: width! / 20.0, end: width! / 20.0),
                                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 100.0),
                                        child: Row(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text("${state.settingsModel!.cartCount} ${UiUtils.getTranslatedLabel(context, itemTagLabel)} | ",
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                                Text(
                                                    context.read<SystemConfigCubit>().getCurrency() + state.settingsModel!.cartTotal.toString() == ""
                                                        ? "0"
                                                        : double.parse(state.settingsModel!.cartTotal.toString()).toStringAsFixed(2),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                            const Spacer(),
                                            InkWell(
                                                onTap: () {
                                                  clearAll();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (BuildContext context) => const CartScreen(from: "restaurantDetail"),
                                                    ),
                                                  );
                                                },
                                                child: Text(UiUtils.getTranslatedLabel(context, viewCartLabel),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w500))),
                                          ],
                                        ),
                                      );
                              })
                          : BlocConsumer<GetCartCubit, GetCartState>(
                              bloc: context.read<GetCartCubit>(),
                              listener: (context, state) {},
                              builder: (context, state) {
                                if (state is GetCartProgress || state is GetCartInitial) {
                                  return Container(
                                      alignment: Alignment.center, height: height! / 20.0, child: BottomCartSimmer(width: width!, height: height!));
                                }
                                if (state is GetCartFailure) {
                                  return const SizedBox.shrink();
                                }
                                final cartList = (state as GetCartSuccess).cartModel;
                                var sum = 0;
                                final currentCartModel = context.read<GetCartCubit>().getCartModel(); //cartList;
                                for (int i = 0; i < currentCartModel.data!.length; i++) {
                                  sum += int.parse(currentCartModel.data![i].qty!);
                                }
                                return cartList.data!.isEmpty
                                    ? const SizedBox.shrink()
                                    : Container(
                                        margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 40.0),
                                        width: width,
                                        padding: EdgeInsetsDirectional.only(
                                            top: height! / 55.0, bottom: height! / 55.0, start: width! / 20.0, end: width! / 20.0),
                                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.primary, 100.0),
                                        child: Row(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text("$sum ${UiUtils.getTranslatedLabel(context, itemTagLabel)} | ",
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                                Text(
                                                    context.read<SystemConfigCubit>().getCurrency() +
                                                        (double.parse(cartList.subTotal.toString())).toStringAsFixed(2),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                            const Spacer(),
                                            InkWell(
                                                onTap: () {
                                                  clearAll();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (BuildContext context) => const CartScreen(from: "restaurantDetail"),
                                                    ),
                                                  );
                                                },
                                                child: Text(UiUtils.getTranslatedLabel(context, viewCartLabel),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w500))),
                                          ],
                                        ),
                                      );
                              });
                    }),
                    body: TabBarView(
                        controller: tabController,
                        children: List<Widget>.generate(categoryList.length, (int index) {
                          return RefreshIndicator(
                              onRefresh: refreshList,
                              color: Theme.of(context).colorScheme.primary,
                              child: BlocProvider(
                                create: (context) => ProductCubit(),
                                child: MenuViewScreen(
                                  categoryId: categoryList[index].id!,
                                  key: globalKey?[index],
                                  statusFoodType: statusFoodType!,
                                  costStatus: costStatus!,
                                  sort: sort!,
                                  productCubit: context.read<ProductCubit>(),
                                ),
                              ));
                        })));
              },
            ),
    );
  }
}
