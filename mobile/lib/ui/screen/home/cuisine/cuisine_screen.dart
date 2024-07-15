import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/home/cuisine/cuisineCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/cuisineContainer.dart';
import 'package:wakDak/ui/widgets/simmer/cuisineSimmer.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/uiUtils.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({Key? key}) : super(key: key);

  @override
  CuisineScreenState createState() => CuisineScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (_) => BlocProvider<CuisineCubit>(
              create: (_) => CuisineCubit(),
              child: const CuisineScreen(),
            ));
  }
}

class CuisineScreenState extends State<CuisineScreen> {
  double? width, height;
  ScrollController cuisineController = ScrollController();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  @override
  void initState() {
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    Future.delayed(Duration.zero, () {
      cuisineApi();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.initState();
  }

  cuisineApi() {
    context.read<CuisineCubit>().fetchCuisine(perPage, "", context.read<SettingsCubit>().getSettings().branchId);
  }

  Widget topCuisine() {
    return BlocConsumer<CuisineCubit, CuisineState>(
        bloc: context.read<CuisineCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CuisineProgress || state is CuisineInitial) {
            return Center(child: CuisineSimmer(length: 9, width: width!, height: height! / 1.2));
          }
          if (state is CuisineFailure) {
            return Center(child: Text(state.errorMessage));
          }
          final cuisineList = (state as CuisineSuccess).cuisineList;
          final hasMore = state.hasMore;

          return SizedBox(
            height: height! / 1.1,
            child: GridView.count(
              shrinkWrap: true,
              controller: cuisineController,
              physics: const AlwaysScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.86,
              children: List.generate(cuisineList.length, (index) {
                return hasMore && index == (cuisineList.length)
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(Routes.cuisineDetail, arguments: {'categoryId': cuisineList[index].id!, 'name': cuisineList[index].text!});
                        },
                        child: CuisineContainer(cuisineList: cuisineList, index: index, width: width!, height: height!),
                      );
              }),
            ),
          );
        });
  }

  Future<void> refreshList() async {
    cuisineApi();
  }

  @override
  void dispose() {
    cuisineController.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : Scaffold(
              appBar: DesignConfig.appBar(context, width, UiUtils.getTranslatedLabel(context, deliciousCuisineLabel),
                  const PreferredSize(preferredSize: Size.zero, child: SizedBox())),
              body: Container(
                  alignment: Alignment.topCenter,
                  margin: EdgeInsetsDirectional.only(top: height! / 80.0),
                  padding: EdgeInsetsDirectional.only(end: width! / 30.0),
                  decoration: DesignConfig.boxDecorationContainerHalf(Theme.of(context).colorScheme.onBackground),
                  width: width,
                  child: RefreshIndicator(onRefresh: refreshList, color: Theme.of(context).colorScheme.primary, child: topCuisine())),
            ),
    );
  }
}
