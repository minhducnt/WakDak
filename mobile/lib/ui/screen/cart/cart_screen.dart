import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:wakDak/app/routes.dart';
import 'package:wakDak/cubit/address/addressCubit.dart';
import 'package:wakDak/cubit/address/deliveryChargeCubit.dart';
import 'package:wakDak/cubit/address/isOrderDeliverableCubit.dart';
import 'package:wakDak/cubit/address/updateAddressCubit.dart';
import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/cubit/cart/clearCartCubit.dart';
import 'package:wakDak/cubit/cart/getCartCubit.dart';
import 'package:wakDak/cubit/cart/manageCartCubit.dart';
import 'package:wakDak/cubit/cart/removeFromCartCubit.dart';
import 'package:wakDak/cubit/product/offlineCartCubit.dart';
import 'package:wakDak/cubit/product/productCubit.dart';
import 'package:wakDak/cubit/profileManagement/updateUserDetailsCubit.dart';
import 'package:wakDak/cubit/promoCode/validatePromoCodeCubit.dart';
import 'package:wakDak/cubit/settings/settingsCubit.dart';
import 'package:wakDak/cubit/systemConfig/systemConfigCubit.dart';
import 'package:wakDak/data/model/addOnsDataModel.dart';
import 'package:wakDak/data/model/addressModel.dart';
import 'package:wakDak/data/model/cartModel.dart';
import 'package:wakDak/data/model/delivery_tip_model.dart';
import 'package:wakDak/data/model/productAddOnsModel.dart';
import 'package:wakDak/data/model/sectionsModel.dart';
import 'package:wakDak/data/model/variantsModel.dart';
import 'package:wakDak/data/repositories/address/addressRepository.dart';
import 'package:wakDak/data/repositories/cart/cartRepository.dart';
import 'package:wakDak/ui/screen/offerCoupons/offer_coupons_screen.dart';
import 'package:wakDak/ui/screen/settings/no_internet_screen.dart';
import 'package:wakDak/ui/styles/color.dart';
import 'package:wakDak/ui/styles/design.dart';
import 'package:wakDak/ui/widgets/bottomSheetContainer.dart';
import 'package:wakDak/ui/widgets/brachCloseDialog.dart';
import 'package:wakDak/ui/widgets/buttonContainer.dart';
import 'package:wakDak/ui/widgets/customDialog.dart';
import 'package:wakDak/ui/widgets/keyboardOverlay.dart';
import 'package:wakDak/ui/widgets/noDataContainer.dart';
import 'package:wakDak/ui/widgets/simmer/addressSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/buttonSimmer.dart';
import 'package:wakDak/ui/widgets/simmer/cartSimmer.dart';
import 'package:wakDak/utils/SqliteData.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/internetConnectivity.dart';
import 'package:wakDak/utils/labelKeys.dart';
import 'package:wakDak/utils/string.dart';
import 'package:wakDak/utils/uiUtils.dart';

class CartScreen extends StatefulWidget {
  final Function? bottomStatus;
  final String? from;
  const CartScreen({Key? key, this.bottomStatus, this.from}) : super(key: key);

  @override
  CartScreenState createState() => CartScreenState();
}

double finalTotal = 0, subTotal = 0, overAllAmount = 0, deliveryCharge = 0, taxPercentage = 0, taxAmount = 0, deliveryTip = 0, latitude = 0, longitude = 0;
int? selectedAddress = 0, orderTypeIndex = 0;
String? selAddress, paymentMethod = '', selTime, selDate, promoCode = '';
bool? isTimeSlot, isPromoValid = false, isUseWallet = false, isPayLayShow = true;
int? selectedTime, selectedDate, selectedMethod;

double promoAmt = 0;
double remWalBal = 0, walletBalanceUsed = 0;
bool isAvailable = true;
Map? productVariant;
Map? productVariantData;
List<String>? productVariantId = [];
List<String>? productAddOnId = [];

String? razorpayId,
    paystackId,
    stripeId,
    stripeSecret,
    stripeMode = "test",
    stripeCurCode,
    stripePayId,
    paytmMerId,
    paytmMerKey,
    midTranshMerchandId,
    midtransPaymentMethod,
    midtransPaymentMode,
    midtransServerKey,
    midtrasClientKey;
bool payTesting = true;

class CartScreenState extends State<CartScreen> {
  double? width, height;
  TextEditingController addNoteController = TextEditingController(text: "");
  TextEditingController deliveryTipController = TextEditingController(text: "");
  int? selectedIndex = -1, addressIndex;
  bool isScrollingDown = false;
  double bottomBarHeight = 75, oriPrice = 0;

  String activeStatus = "pending";
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  CartModel? cartModel;
  String addressId = "";
  String isRestaurantOpen = "";

  bool? tipOther = false, cartEmpty = false;
  var db = DatabaseHelper();
  String pickupStatus = "", deliveryStatus = "";
  List<String> availableTime = [];
  List<bool> checkTime = [];
  int status = 0;
  bool phoneNumberStatus = false;
  final formKey = GlobalKey<FormState>();
  FocusNode numberFocusNode = FocusNode();
  FocusNode numberFocusNodeAndroid = FocusNode();
  TextEditingController phoneNumberController = TextEditingController(text: "");

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
    if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
      getOffLineCart();
    } else {
      context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
      context
          .read<GetCartCubit>()
          .getCartUser(userId: context.read<AuthCubit>().getId(), branchId: context.read<SettingsCubit>().getSettings().branchId);
    }
    deliveryTipController.addListener(() {
      deliveryTipController;
      setState(() {});
    });
    numberFocusNode.addListener(() {
      bool hasFocus = numberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  bottomStatusUpdate() {
    setState(() {
      widget.bottomStatus!(0);
    });
  }

  Future<void> getOffLineCart() async {
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      productVariant = (await db.getCart());
      productVariantData = (await db.getCartData());
      if (productVariant!.isEmpty) {
      } else {
        productVariantId = productVariant!['VID'];
        productAddOnId = productVariant!['ADDONID'].toString().replaceAll("[", "").replaceAll("]", "").split(",");
        if (productVariantId!.isNotEmpty) {
          if (mounted) {
            await context.read<OfflineCartCubit>().getOfflineCart(
                productVariantIds: productVariantId!.join(','),
                branchId: context.read<SettingsCubit>().getSettings().branchId);
          }
          cartEmpty = false;
        } else {
          cartEmpty = true;
        }
      }
    }
  }

  paymentScreenMove(){
    Navigator.of(context).pushNamed(Routes.payment, arguments: {'cartModel': context.read<GetCartCubit>().getCartModel(), 'addNote': addNoteController.text});
  }
  
  moveFirstScreen(){
    Future.delayed(Duration.zero, () => Navigator.of(context).popUntil((route) => route.isFirst));
  }

  Widget addNote() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsetsDirectional.only(start: width! / 20.0),
      child: Center(
        child: TextField(
          controller: addNoteController,
          cursorColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
          decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, addNotesForFoodPartnerLabel),
              UiUtils.getTranslatedLabel(context, addNotesForFoodPartnerLabel), width!, context),
          keyboardType: TextInputType.multiline,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 16.0, fontWeight: FontWeight.w500),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget phoneNumberField() {
    return Container(
        padding: EdgeInsetsDirectional.only(bottom: height! / 30.0, start: width! / 20.0, end: width! / 20.0),
        margin: EdgeInsets.zero,
        child: IntlPhoneField(
          controller: phoneNumberController,
          textInputAction: TextInputAction.done,
          dropdownIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76)),
          decoration: InputDecoration(
            filled: true,
            fillColor: textFieldBackground,
            contentPadding: const EdgeInsets.only(top: 15, bottom: 15),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            focusedErrorBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(width: 1.0, color: textFieldBorder)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: textFieldBorder),
            ),
            focusColor: white,
            counterStyle: const TextStyle(color: white, fontSize: 0),
            border: InputBorder.none,
            hintText: UiUtils.getTranslatedLabel(context, enterPhoneNumberLabel),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          flagsButtonMargin: EdgeInsets.all(width! / 40.0),
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          focusNode: Platform.isIOS ? numberFocusNode : numberFocusNodeAndroid,
          dropdownIconPosition: IconPosition.trailing,
          initialCountryCode: defaultIsoCountryCode,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.right : TextAlign.left,
          onChanged: (phone) {
            setState(() {});
          },
          onCountryChanged: ((value) {
            setState(() {
              print(value.dialCode);
              //countryCode = value.dialCode;
            });
          }),
        ));
  }

  Widget deliveryTips() {
    return Container(
      height: height! / 24.0,
      width: width!,
      margin: EdgeInsetsDirectional.only(start: width! / 20.0),
      child: Row(
        children: [
          tipOther == false
              ? Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deliveryTipList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, index) {
                        return InkWell(
                            splashFactory: NoSplash.splashFactory,
                            onTap: () {
                              if (selectedIndex == index) {
                                setState(() {
                                  deliveryTipList[index].like = "0";
                                  selectedIndex = -1;
                                  deliveryTip = 0;
                                });
                              } else {
                                setState(() {
                                  deliveryTipList[index].like = "1";
                                  selectedIndex = index;
                                  deliveryTip = double.parse(deliveryTipList[index].price!);
                                });
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              width: width! / 6.8,
                              padding: EdgeInsetsDirectional.only(
                                end: width! / 99.0,
                                start: width! / 99.0,
                              ),
                              margin: EdgeInsetsDirectional.only(end: width! / 32.0),
                              decoration: deliveryTip == double.parse(deliveryTipList[index].price!)
                                  ? DesignConfig.boxDecorationContainerBorder(
                                      Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.10), 4.0)
                                  : DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
                              child: Text(
                                context.read<SystemConfigCubit>().getCurrency() + deliveryTipList[index].price!,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                    color: deliveryTip == double.parse(deliveryTipList[index].price!)
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ));
                      }),
                )
              : const SizedBox(),
          InkWell(
              splashFactory: NoSplash.splashFactory,
              onTap: () {
                setState(() {
                  if (tipOther == false) {
                    tipOther = true;
                    deliveryTipController.clear();
                  } else {
                    tipOther = false;
                    deliveryTipController.clear();
                  }
                });
              },
              child: Container(
                alignment: Alignment.center,
                width: width! / 7.0,
                padding: EdgeInsetsDirectional.only(
                  end: width! / 99.0,
                  start: width! / 99.0,
                ),
                decoration: tipOther == true
                    ? DesignConfig.boxDecorationContainerBorder(
                        Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.10), 4.0)
                    : DesignConfig.boxDecorationContainerBorder(commentBoxBorderColor, textFieldBackground, 4.0),
                child: Text(
                  UiUtils.getTranslatedLabel(context, otherLabel),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                      color: tipOther == true ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              )),
          tipOther == true
              ? Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: DesignConfig.boxDecorationContainerBorder(textFieldBorder, textFieldBackground, 4.0),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsetsDirectional.only(
                            start: width! / 40.0,
                            end: width! / 40.0,
                          ),
                          child: TextField(
                            controller: deliveryTipController,
                            cursorColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsetsDirectional.only(bottom: height! / 60.0, start: width! / 40.0),
                              border: InputBorder.none,
                              hintText: StringsRes.addTip,
                              hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 14.0, fontWeight: FontWeight.w500),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 14.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (deliveryTipController.text.trim().isNotEmpty) {
                              deliveryTip = double.parse(deliveryTipController.text.trim());
                              selectedIndex = -1;
                              tipOther = false;
                            } else {
                              UiUtils.setSnackBar(StringsRes.addTip, context, false, type: "2");
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(
                            deliveryTipController.text.trim().isNotEmpty
                                ? UiUtils.getTranslatedLabel(context, addLabel)
                                : UiUtils.getTranslatedLabel(context, cancelLabel),
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox()
        ],
      ),
    );
  }

  addToCartBottomModelSheet(List<ProductDetails> productList, int index, String variantId, int l) async {
    ProductDetails productDetailsModel = productList[index];
    Map<String, int> qtyData = {};
    int currentIndex = l, qty = 0;
    List<bool> isChecked = List<bool>.filled(productDetailsModel.productAddOns!.length, false);
    String? productVariantId = productDetailsModel.variants![currentIndex].id;

    List<String> addOnIds = [];
    List<String> addOnQty = [];
    List<double> addOnPrice = [];
    List<String> productAddOnIds = [];
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      productAddOnId = (await db.getVariantItemData(productDetailsModel.id!, variantId))!;
      productAddOnIds = productAddOnId.toString().replaceAll("[", "").replaceAll("]", "").split(",");
    } else {
      for (int i = 0; i < productDetailsModel.variants![currentIndex].addOnsData!.length; i++) {
        productAddOnIds.add(productDetailsModel.variants![currentIndex].addOnsData![i].id!);
      }
      for (int j = 0; j < productDetailsModel.variants!.length; j++) {
        if (j == l) {
          currentIndex = j;
          productVariantId = productDetailsModel.variants![currentIndex].id;
        }
      }
    }

    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      productVariantId = variantId;
      qty = int.parse((await db.checkCartItemExists(productDetailsModel.id!, variantId))!);
      if (qty == 0) {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      } else {
        qtyData[productVariantId] = qty;
      }
    } else {
      if (productDetailsModel.variants![currentIndex].cartCount != "0") {
        qty = int.parse(productDetailsModel.variants![currentIndex].cartCount!);
      } else {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      }
      qtyData[productVariantId!] = qty;
    }

    bool descTextShowFlag = false;
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
          return BottomSheetContainer(
              productDetailsModel: productDetailsModel,
              isChecked: isChecked,
              height: height!,
              width: width!,
              productVariantId: productVariantId,
              addOnIds: addOnIds,
              addOnPrice: addOnPrice,
              addOnQty: addOnQty,
              productAddOnIds: productAddOnIds,
              qtyData: qtyData,
              currentIndex: currentIndex,
              descTextShowFlag: descTextShowFlag,
              qty: qty,
              from: "cart");
        });
  }

  Stream<double> checkCartItemTotalOfflineCart(ProductDetails productModel, String productVariantId) async* {
    double overAllTotal = 0;
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      overAllTotal = double.parse((await db.checkCartItemTotal(productModel.id!, productVariantId))!);
    }
    yield overAllTotal;
  }

  double total() {
    if (orderTypeIndex.toString() == "0") {
      return (context.read<GetCartCubit>().getCartModel().overallAmount! + deliveryCharge + deliveryTip - promoAmt);
    } else {
      return (context.read<GetCartCubit>().getCartModel().overallAmount! + deliveryTip - promoAmt);
    }
  }

  changeAddressBottomModelSheetShow() {
    showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
        clipBehavior: Clip.hardEdge,
        isScrollControlled: true,
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState) {
            return Container(
                padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
                height: (MediaQuery.of(context).size.height) / 1.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: BlocProvider<UpdateAddressCubit>(
                        create: (_) => UpdateAddressCubit(AddressRepository()),
                        child: Builder(builder: (context) {
                          return BlocConsumer<AddressCubit, AddressState>(
                              bloc: context.read<AddressCubit>(),
                              listener: (context, state) {},
                              builder: (context, state) {
                                if (state is AddressProgress || state is AddressInitial) {
                                  return AddressSimmer(width: width!, height: height!);
                                }
                                if (state is AddressFailure) {
                                  return NoDataContainer(
                                      image: "address",
                                      title: UiUtils.getTranslatedLabel(context, noAddressYetLabel),
                                      subTitle: UiUtils.getTranslatedLabel(context, noAddressYetSubTitleLabel),
                                      width: width!,
                                      height: height!);
                                }

                                final addressList = (state as AddressSuccess).addressList;
                                return ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: addressList.length,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (BuildContext context, index) {
                                      return addressList.isNotEmpty
                                          ? BlocConsumer<UpdateAddressCubit, UpdateAddressState>(
                                              bloc: context.read<UpdateAddressCubit>(),
                                              listener: (context, state) {
                                                if (state is UpdateAddressSuccess) {
                                                  if (state.addressModel.id! == addressList[index].id!) {
                                                    context.read<AddressCubit>().updateAddress(state.addressModel);
                                                    addressId = state.addressModel.id!;
                                                  }
                                                  if (addressId.isNotEmpty) {
                                                    context.read<DeliveryChargeCubit>().fetchDeliveryCharge(context.read<AuthCubit>().getId(), addressId);
                                                  }
                                                } else if (state is UpdateAddressFailure) {
                                                  print(state.errorMessage.toString());
                                                }
                                              },
                                              builder: (context, state) {
                                                return Container(decoration: addressList[index].isDefault == "1"
                                                      ? DesignConfig.boxDecorationContainerBorder(Theme.of(context).colorScheme.secondary,
                                                          Theme.of(context).colorScheme.secondary.withOpacity(0.05), 8)
                                                      : DesignConfig.boxDecorationContainerBorder(
                                                          Theme.of(context).colorScheme.onPrimary, Theme.of(context).colorScheme.onBackground, 8,
                                                          status: true),
                                                  margin: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                                                  padding: EdgeInsets.symmetric(vertical: height! / 40.0, horizontal: height! / 40.0),
                                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                                    Row(
                                                      children: [
                                                        addressList[index].type == homeKey
                                                            ? SvgPicture.asset(
                                                                DesignConfig.setSvgPath("home_address"),
                                                              ): addressList[index].type == officeKey
                                                                ? SvgPicture.asset(DesignConfig.setSvgPath("work_address"))
                                                                : SvgPicture.asset(DesignConfig.setSvgPath("other_address")),
                                                        SizedBox(width: height! / 99.0),
                                                        Text(addressList[index].type!,
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              color: Theme.of(context).colorScheme.secondary,
                                                              fontWeight: FontWeight.w600),
                                                        ),
                                                        const Spacer(),
                                                        BlocConsumer<UpdateAddressCubit, UpdateAddressState>(
                                                          bloc: context.read<UpdateAddressCubit>(),
                                                          listener: (context, state) {
                                                            if (state is UpdateAddressSuccess) {
                                                              context.read<AddressCubit>().updateAddress(state.addressModel);
                                                            } else if (state is UpdateAddressFailure) {
                                                              print(state.errorMessage.toString());
                                                            }
                                                          },
                                                          builder: (context, state) {
                                                            return Theme(
                                                              data: Theme.of(context).copyWith(unselectedWidgetColor: grayLightColor),
                                                              child: Checkbox(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(4),
                                                                      side: BorderSide(color: Theme.of(context).colorScheme.onPrimary,
                                                                        width: 0.5,
                                                                        strokeAlign: -1.0,
                                                                      )),
                                                                  value: addressList[index].isDefault == "1" ? true : false,
                                                                  side: MaterialStateBorderSide.resolveWith(
                                                                    (states) => BorderSide(
                                                                        width: 1.0,
                                                                        color: addressList[index].isDefault == "1"
                                                                            ? Theme.of(context).colorScheme.secondary
                                                                            : Theme.of(context).colorScheme.onPrimary,
                                                                        strokeAlign: 5),
                                                                  ),
                                                                  activeColor: Theme.of(context).colorScheme.primary,
                                                                  onChanged: (val) {
                                                                    context.read<UpdateAddressCubit>().fetchUpdateAddress(
                                                                        addressList[index].id,
                                                                        addressList[index].userId,
                                                                        addressList[index].mobile,
                                                                        addressList[index].address,
                                                                        addressList[index].city,
                                                                        addressList[index].latitude,
                                                                        addressList[index].longitude,
                                                                        addressList[index].area,
                                                                        addressList[index].type,
                                                                        addressList[index].name,
                                                                        addressList[index].countryCode,
                                                                        addressList[index].alternateCountryCode,
                                                                        addressList[index].alternateMobile,
                                                                        addressList[index].landmark,
                                                                        addressList[index].pincode,
                                                                        addressList[index].state,
                                                                        addressList[index].country,
                                                                        "1");
                                                                  },
                                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  fillColor: MaterialStatePropertyAll(addressList[index].isDefault == "1"
                                                                      ? Theme.of(context).colorScheme.secondary
                                                                      : Theme.of(context).colorScheme.onBackground),
                                                                  checkColor: Theme.of(context).colorScheme.onBackground,
                                                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: height! / 99.0),
                                                    Text(
                                                      "${addressList[index].address!},${addressList[index].city},${addressList[index].state!},${addressList[index].pincode!}",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                          fontWeight: FontWeight.w500),
                                                    ),
                                                  ]),
                                                );
                                              })
                                          : NoDataContainer(
                                              image: "address",
                                              title: UiUtils.getTranslatedLabel(context, noAddressYetLabel),
                                              subTitle: UiUtils.getTranslatedLabel(context, noAddressYetSubTitleLabel),
                                              width: width!,
                                              height: height!);
                                    });
                              });
                        }),
                      ),
                    ),
                    SizedBox(
                      width: width!,
                      child: ButtonContainer(
                        color: Theme.of(context).colorScheme.primary,
                        height: height,
                        width: width,
                        text: UiUtils.getTranslatedLabel(context, addNewAddressLabel),
                        start: 0,
                        end: 0,
                        bottom: height! / 55.0,
                        top: 0,
                        status: false,
                        borderColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(Routes.address, arguments: {'from': '', 'addressModel': AddressModel()}).then((value) => {refreshList()});
                        },
                      ),
                    ),
                  ],
                ));
          });
        });
  }

  offlineCartTotal(List<ProductDetails>? productDetails) async {
    for (int i = 0; i < productDetails!.length; i++) {
      for (int j = 0; j < productDetails[i].variants!.length; j++) {
        if (productVariantId!.contains(productDetails[i].variants![j].id)) {
          String qty = (await db.checkCartItemExists(productDetails[i].id!, productDetails[i].variants![j].id!))!;

          List<ProductDetails>? prList = [];
          productDetails[i].variants![j].cartCount = qty;
          prList.add(productDetails[i]);
          var sum = 0.0;
          for (int a = 0; a < productDetails[i].productAddOns!.length; a++) {
            ProductAddOnsModel addOnData = productDetails[i].productAddOns![a];
            if (productAddOnId!.contains(addOnData.id)) {
              sum += double.parse((double.parse(addOnData.price!.toString()) * int.parse(qty)).toStringAsFixed(2));
            }
          }

          double price = double.parse(productDetails[i].variants![j].specialPrice!);
          if (price == 0) {
            price = double.parse(productDetails[i].variants![j].price!);
          }

          double total = ((price * int.parse(qty)) + (sum * int.parse(qty)));
          setState(() {
            oriPrice = oriPrice + total;

            status = 1;
          });
        }
      }
    }
  }

  Widget noCartData() {
    return NoDataContainer(
        image: "empty_cart",
        title: UiUtils.getTranslatedLabel(context, noOrderYetLabel),
        subTitle: UiUtils.getTranslatedLabel(context, noOrderYetSubTitleLabel),
        width: width!,
        height: height!);
  }

  Widget offLineCartDate() {
    return BlocConsumer<OfflineCartCubit, OfflineCartState>(
        bloc: context.read<OfflineCartCubit>(),
        listener: (context, state) {
          if (state is OfflineCartSuccess) {
            final offlineCartList = (state).productModel;

            if (status == 0) {
              offlineCartTotal(offlineCartList);
            }
          }
        },
        builder: (context, state) {
          if (state is OfflineCartProgress) {
            return CartSimmer(width: width!, height: height!);
          }
          if (state is OfflineCartInitial) {
            return noCartData();
          }
          if (state is OfflineCartFailure) {
            return noCartData();
          }

          final offlineCartList = (state as OfflineCartSuccess).productModel;
          isRestaurantOpen = context.read<SettingsCubit>().getSettings().isBranchOpen;

          return offlineCartList.isEmpty
              ? noCartData()
              : SizedBox(
                  width: width,
                  child: Container(
                    width: width!,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                            margin: EdgeInsetsDirectional.only(top: height! / 80.0),
                            padding: EdgeInsetsDirectional.only(top: height! / 80, start: width! / 20.0, bottom: height! / 80.0, end: width! / 20.0),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Row(children: [
                                SvgPicture.asset(DesignConfig.setSvgPath("shopping_bag_line"),
                                    height: 14,
                                    width: 14,
                                    fit: BoxFit.scaleDown,
                                    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn)),
                                SizedBox(width: width! / 80.0),
                                Text(
                                  UiUtils.getTranslatedLabel(context, foodInYourBagLabel),
                                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                                  return BlocConsumer<ClearCartCubit, ClearCartState>(
                                      bloc: context.read<ClearCartCubit>(),
                                      listener: (context, state) {
                                        if (state is ClearCartSuccess) {
                                          if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                          } else {
                                            UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, clearCartLabel), context, false, type: "1");
                                          }
                                        } else if (state is ClearCartFailure) {
                                            if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                            } else {
                                              UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                            }
                                        }
                                      },
                                      builder: (contextCart, state) {
                                        return InkWell(
                                          onTap: () {
                                            showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return CustomDialog(
                                                      title: UiUtils.getTranslatedLabel(context, deleteAllItemsTitleLabel),
                                                      subtitle: UiUtils.getTranslatedLabel(context, deleteAllItemsSubTitleLabel),
                                                      width: width!,
                                                      height: height!,
                                                      from: UiUtils.getTranslatedLabel(context, clearCartLabel),
                                                      onTap: () {
                                                        db.clearCart();
                                                        offlineCartList.clear();
                                                        getOffLineCart();
                                                        clearOffLineCart(context);
                                                        context.read<OfflineCartCubit>().clearOfflineCartModel();
                                                        setState(() {});
                                                        Navigator.pop(context);
                                                      });
                                                });
                                          },
                                          child: Text(UiUtils.getTranslatedLabel(context, clearCartLabel),
                                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      });
                                }),
                              ]),
                              Padding(
                                padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0, start: width! / 20.0),
                                child: DesignConfig.divider(),
                              ),
                              ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: offlineCartList.length,
                                  itemBuilder: (BuildContext context, i) {
                                    return SizedBox(
                                      width: width!,
                                      child: Container(
                                        margin: EdgeInsetsDirectional.only(start: width! / 20.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(offlineCartList[i].variants!.length, (l) {
                                            VariantsModel variantData = offlineCartList[i].variants![l];
                                            double price = double.parse(variantData.specialPrice!);
                                            if (price == 0) {
                                              price = double.parse(variantData.price!);
                                            }

                                            double off = 0;
                                            if (offlineCartList[i].variants![l].specialPrice! != "0") {
                                              off = (double.parse(variantData.price!) - double.parse(variantData.specialPrice!)).toDouble();
                                              off = off * 100 / double.parse(variantData.price!).toDouble();
                                            }
                                            return (productVariantId!.contains(variantData.id))
                                                ? Container(
                                                    child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          offlineCartList[i].image!.isEmpty
                                                              ? ClipRRect(
                                                                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                                                                  child: SizedBox(width: 65,height: 76))
                                                              : ClipRRect(
                                                                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                                                                  child: ColorFiltered(
                                                                    colorFilter: context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                                        ? const ColorFilter.mode(
                                                                            Colors.transparent,
                                                                            BlendMode.multiply,
                                                                          )
                                                                        : const ColorFilter.mode(
                                                                            Colors.grey,
                                                                            BlendMode.saturation,
                                                                          ),
                                                                    child: DesignConfig.imageWidgets(offlineCartList[i].image!, 76, 65, "2"),
                                                                  ),
                                                                ),
                                                          SizedBox(width: width! / 40.0),
                                                          Expanded(
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    offlineCartList[i].indicator == "1"
                                                                      ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"),width: 15, height: 15)
                                                                      : offlineCartList[i].indicator == "2"
                                                                      ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"),width: 15, height: 15)
                                                                      : const SizedBox(height: 15, width: 15.0),
                                                                      const SizedBox(width: 5.0),
                                                                    Expanded(flex: 2,
                                                                      child: SizedBox(
                                                                        height: height! / 22.0,
                                                                        child: Text("${offlineCartList[i].name}",
                                                                          textAlign: Directionality.of(context) == TextDirection.RTL? TextAlign.right: TextAlign.left,
                                                                          style: TextStyle(
                                                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 14,
                                                                            fontWeight: FontWeight.w500,
                                                                            fontStyle: FontStyle.normal,
                                                                            overflow: TextOverflow.ellipsis),
                                                                            maxLines: 1,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(padding: EdgeInsetsDirectional.only(top: 3.0, bottom: 3.0, start: 5.0, end: 5.0),
                                                                      alignment: Alignment.center,
                                                                      height: 28.0,
                                                                      width: width! / 4.8,
                                                                      decoration: DesignConfig.boxDecorationContainerBorder(Theme.of(context).colorScheme.primary,Theme.of(context).colorScheme.primary.withOpacity(0.12),5.0),
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                          children: [
                                                                            BlocConsumer<RemoveFromCartCubit, RemoveFromCartState>(
                                                                              bloc: context.read<RemoveFromCartCubit>(),
                                                                              listener: (context, state) {
                                                                                if (state is RemoveFromCartSuccess) {
                                                                                  UiUtils.setSnackBar(StringsRes.deleteSuccessFully, context, false,type: "1");
                                                                                  offlineCartList.removeAt(i);
                                                                                  context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId(),branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                                } else if (state is RemoveFromCartFailure) {
                                                                                  UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                                                                }
                                                                              },
                                                                              builder: (contextRemoveCart, state) {
                                                                                return InkWell(overlayColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary.withOpacity(0.10)),
                                                                                  onTap: () async {
                                                                                    productVariant = (await db.getCart());
                                                                                    productVariantData = (await db.getCartData());
                                                                                    List<ProductAddOnsModel> addOnsDataModel = offlineCartList[i].productAddOns!;
                                                                                    List<String> addOnIds = [];
                                                                                    List<String> addOnQty = [];
                                                                                    var totalSum = 0.0;
                                                                                    if (productVariantData!.containsKey(variantData.id)) {
                                                                                      productAddOnId = productVariantData![variantData.id].toString().replaceAll("[", "").replaceAll("]", "").split(",");
                                                                                    }
                                                                                    productAddOnId!.removeWhere((element) => element == '');
                                                                                    for (int qt = 0; qt < addOnsDataModel.length; qt++) {
                                                                                      if (productAddOnId!.contains(addOnsDataModel[qt].id)) {
                                                                                        addOnIds.add(addOnsDataModel[qt].id.toString());
                                                                                        addOnQty.add((int.parse(variantData.cartCount!.toString()) - 1).toString());
                                                                                        totalSum += (double.parse(addOnsDataModel[qt].price!.toString()) * (int.parse(variantData.cartCount!.toString()) - 1));
                                                                                      }
                                                                                    }
                                                                                    double overAllTotalPrice = (price * (int.parse(variantData.cartCount!.toString()) - 1) + totalSum);
                                                                                    print("productVariant${productVariant!["VID"].runtimeType}");

                                                                                    if (int.parse(variantData.cartCount!.toString()) == 1) {
                                                                                      db.removeCart(variantData.id!, offlineCartList[i].id!, context);
                                                                                        oriPrice = (oriPrice - price);
                                                                                        context.read<OfflineCartCubit>().updateQuantity(offlineCartList[i],((int.parse(variantData.cartCount.toString()) - 1)).toString(),variantData.id);
                                                                                        offlineCartList[i].variants!.removeWhere((item) => item.id == variantData.id);
                                                                                        productVariant = (await db.getCart());
                                                                                        productVariantData = (await db.getCartData());
                                                                                        print("productVariant${productVariant!["VID"]}--${productVariant!["VID"].isEmpty}");
                                                                                        if (productVariant!["VID"].isEmpty) {
                                                                                          db.clearCart();
                                                                                          offlineCartList.clear();
                                                                                          getOffLineCart();
                                                                                          clearOffLineCart(context);
                                                                                          context.read<OfflineCartCubit>().clearOfflineCartModel();
                                                                                          setState(() {});
                                                                                            oriPrice = 0;
                                                                                        }
                                                                                    } else {
                                                                                      db.insertCart(offlineCartList[i].id!,variantData.id!, (int.parse(variantData.cartCount!.toString()) - 1).toString(),
                                                                                        addOnIds.isNotEmpty? addOnIds.join(",").toString(): "",
                                                                                        addOnQty.isNotEmpty? addOnQty.join(",").toString(): "",
                                                                                        overAllTotalPrice.toString(),
                                                                                        context.read<SettingsCubit>().getSettings().branchId,context).whenComplete(() async {
                                                                                        oriPrice = (oriPrice - price);
                                                                                        context.read<OfflineCartCubit>().updateQuantity(offlineCartList[i],((int.parse(variantData.cartCount.toString()) - 1)).toString(), variantData.id);
                                                                                      });
                                                                                    }
                                                                                    setState(() {});
                                                                                  },
                                                                                  child: Icon(Icons.remove,
                                                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                                                    size: 15.0),
                                                                              );
                                                                            }),
                                                                                const Spacer(),
                                                                                Text(variantData.cartCount!.toString(),
                                                                                  textAlign: TextAlign.center,
                                                                                  style: TextStyle(
                                                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                                                    fontSize: 10,
                                                                                    fontWeight: FontWeight.w700,
                                                                                    fontStyle: FontStyle.normal,
                                                                                  ),
                                                                                ),
                                                                                const Spacer(),
                                                                                InkWell(
                                                                                  overlayColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary.withOpacity(0.10)),
                                                                                  onTap: () {
                                                                                    List<ProductAddOnsModel> addOnsDataModel = offlineCartList[i].productAddOns!;
                                                                                    List<String> addOnIds = [];
                                                                                    List<String> addOnQty = [];
                                                                                    var totalSum = 0.0;
                                                                                    if (productVariantData!.containsKey(variantData.id)) {
                                                                                      productAddOnId = productVariantData![variantData.id].toString().replaceAll("[", "").replaceAll("]", "").split(",");
                                                                                    }
                                                                                    productAddOnId!.removeWhere((element) => element == '');
                                                                                    for (int qt = 0; qt < addOnsDataModel.length; qt++) {
                                                                                      if (productAddOnId!.contains(addOnsDataModel[qt].id)) {
                                                                                        addOnIds.add(addOnsDataModel[qt].id.toString());
                                                                                        addOnQty.add((int.parse(variantData.cartCount!.toString()) + 1).toString());
                                                                                        totalSum +=(double.parse(addOnsDataModel[qt].price!.toString()) * (int.parse(variantData.cartCount!.toString()) + 1));
                                                                                      }
                                                                                    }
                                                                                    double overAllTotalPrice = (price * (int.parse(variantData.cartCount!.toString()) + 1) + totalSum);
                                                                                    setState(() {
                                                                                      if (int.parse(variantData.cartCount!.toString()) < int.parse(offlineCartList[i].minimumOrderQuantity!)) {
                                                                                        Navigator.pop(context);
                                                                                        UiUtils.setSnackBar( "${StringsRes.minimumQuantityAllowed} ${offlineCartList[i].minimumOrderQuantity!}", context, false, type: "2");
                                                                                      } else if (offlineCartList[i].totalAllowedQuantity != "" && int.parse(variantData.cartCount!.toString()) >= int.parse(offlineCartList[i].totalAllowedQuantity!)) {
                                                                                        UiUtils.setSnackBar( "${StringsRes.minimumQuantityAllowed} ${offlineCartList[i].totalAllowedQuantity!}", context, false, type: "2");
                                                                                      } else {
                                                                                        db.insertCart(offlineCartList[i].id!, variantData.id!,
                                                                                            (int.parse(variantData.cartCount!.toString()) + 1).toString(),
                                                                                            addOnIds.isNotEmpty? addOnIds.join(",").toString(): "",
                                                                                            addOnQty.isNotEmpty? addOnQty.join(",").toString(): "",
                                                                                            overAllTotalPrice.toString(),
                                                                                            context.read<SettingsCubit>().getSettings().branchId,
                                                                                            context).whenComplete(() async {
                                                                                              oriPrice = (oriPrice + price);
                                                                                              context.read<OfflineCartCubit>().updateQuantity(offlineCartList[i],((int.parse(variantData.cartCount.toString()) + 1)).toString(),variantData.id);
                                                                                        });
                                                                                      }
                                                                                      setState(() {});
                                                                                    });
                                                                                  },
                                                                                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 15.0),
                                                                                ),
                                                                              ]),
                                                                        ),
                                                                      ]),
                                                                  SingleChildScrollView(
                                                                    physics: const NeverScrollableScrollPhysics(),
                                                                    scrollDirection: Axis.horizontal,
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        variantData.variantValues != ""? Text("${variantData.variantValues!} ",textAlign: TextAlign.left,style: TextStyle(color: Theme.of(context).colorScheme.secondary,fontSize: 10,fontWeight: FontWeight.w600),)
                                                                        : Container(height: 10.0),
                                                                        Row(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                          children: List.generate(offlineCartList[i].productAddOns!.length, (m) {
                                                                            ProductAddOnsModel addOnData = offlineCartList[i].productAddOns![m];
                                                                            if (productVariantData!.containsKey(variantData.id)) {
                                                                              productAddOnId = productVariantData![variantData.id].toString().replaceAll("[", "").replaceAll("]", "").split(",");
                                                                            }
                                                                            productAddOnId!.removeWhere((element) => element == '');
                                                                            return (productVariantData![variantData.id]!.contains(addOnData.id))
                                                                              ? Text("${addOnData.title!}, ",
                                                                              textAlign: TextAlign.center,
                                                                              style: TextStyle(color: Theme.of(context).colorScheme.secondary,fontSize: 10,fontWeight: FontWeight.w600,overflow: TextOverflow.ellipsis),
                                                                                maxLines: 1,): Container(height: 10.0);
                                                                          })
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 5.0),
                                                                  Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      InkWell(
                                                                        onTap: () {
                                                                          setState(() {
                                                                            addToCartBottomModelSheet(offlineCartList, i, variantData.id!, l);
                                                                          });
                                                                        },
                                                                        child: Container(
                                                                          alignment: Alignment.center,
                                                                          width: width! / 8.0,
                                                                          padding: const EdgeInsets.all(2.0),
                                                                          decoration: DesignConfig.boxDecorationContainer(textFieldBackground, 4.0),
                                                                          child: Row(
                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                            children: [
                                                                              Text(UiUtils.getTranslatedLabel(context, editLabel),
                                                                                style: TextStyle(fontSize: 12,color: Theme.of(context).colorScheme.secondary,fontWeight: FontWeight.w500),
                                                                              ),
                                                                              const SizedBox(width: 2.0),
                                                                              Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.secondary, size: 10.0),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const Spacer(),
                                                                      Row(children: [
                                                                        StreamBuilder<double>(stream: checkCartItemTotalOfflineCart(offlineCartList[i], variantData.id!),
                                                                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                                                                            if (snapshot.hasError) {
                                                                              return SizedBox.shrink();
                                                                            } else {
                                                                              switch (snapshot.connectionState) {
                                                                                  case ConnectionState.none:
                                                                                    return SizedBox.shrink();
                                                                                  case ConnectionState.waiting:
                                                                                    return SizedBox.shrink();
                                                                                  case ConnectionState.active:
                                                                                    return Text(context.read<SystemConfigCubit>().getCurrency() + (snapshot.data ?? 0.0).toStringAsFixed(2),
                                                                                      textAlign: TextAlign.center,
                                                                                      style: TextStyle(
                                                                                          color: Theme.of(context).colorScheme.secondary,
                                                                                          fontSize: 14,
                                                                                          fontWeight: FontWeight.w700),
                                                                                    );
                                                                                  case ConnectionState.done:
                                                                                    return Text(context.read<SystemConfigCubit>().getCurrency() + (snapshot.data ?? 0.0).toStringAsFixed(2),
                                                                                      textAlign: TextAlign.center,
                                                                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                                                          fontSize: 14,fontWeight: FontWeight.w700),
                                                                                    );
                                                                                }
                                                                              }
                                                                            }),
                                                                      ]),
                                                                    ],
                                                                  ),
                                                                ]),
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(padding: EdgeInsetsDirectional.only(top: height! / 99.0,bottom: height! / 99.0,),
                                                        child: DesignConfig.divider(),
                                                      ),
                                                    ],
                                                  )): Container();
                                          }),
                                        ),
                                      ),
                                    );
                                  }),
                              Padding(padding: EdgeInsetsDirectional.only(start: width! / 28.0,end: width! / 40.0,),
                                child: GestureDetector(
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      if (widget.from == 'restaurantDetail') {
                                        Navigator.of(context).pop();
                                      } else {
                                        Navigator.of(context).pushNamed(Routes.menu);
                                      }
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(Icons.add_circle_sharp, color: Theme.of(context).colorScheme.secondary, size: 20.0),
                                      const SizedBox(width: 2.0),
                                      Text(UiUtils.getTranslatedLabel(context, addMoreFoodInCartLabel),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          Container(
                            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                            margin: EdgeInsetsDirectional.only(top: height! / 60.0),
                            padding: EdgeInsetsDirectional.only(top: height! / 80.0, start: width! / 20.0, end: width! / 20.0, bottom: height! / 80.0),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(DesignConfig.setSvgPath("ic_invoice"),
                                          height: 14,
                                          width: 14,
                                          fit: BoxFit.scaleDown,
                                          colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn)),
                                      SizedBox(width: width! / 80.0),
                                      Text(UiUtils.getTranslatedLabel(context, billDetailLabel),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0, start: width! / 20.0),
                                    child: DesignConfig.divider(),
                                  ),
                                  BlocConsumer<SettingsCubit, SettingsState>(
                                      bloc: context.read<SettingsCubit>(),
                                      listener: (context, state) {},
                                      builder: (context, state) {
                                        return Padding(
                                          padding: EdgeInsetsDirectional.only(top: 4.5, bottom: 4.5, start: width! / 20.0),
                                          child: Row(children: [
                                            Text(UiUtils.getTranslatedLabel(context, totalPayLabel),
                                                textAlign: TextAlign.left,
                                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                            const Spacer(),
                                            BlocBuilder<SettingsCubit, SettingsState>(
                                                bloc: context.read<SettingsCubit>(),
                                                builder: (context, state) {
                                                  return (context.read<AuthCubit>().state is AuthInitial ||
                                                              context.read<AuthCubit>().state is Unauthenticated) &&
                                                          (state.settingsModel!.cartCount == "0" ||
                                                              state.settingsModel!.cartCount == "" ||
                                                              state.settingsModel!.cartCount == "0.0") &&
                                                          (state.settingsModel!.cartTotal == "0" ||
                                                              state.settingsModel!.cartTotal == "" ||
                                                              state.settingsModel!.cartTotal == "0.0" ||
                                                              state.settingsModel!.cartTotal == "0.00")
                                                      ? const SizedBox.shrink()
                                                      : Text(context.read<SystemConfigCubit>().getCurrency() + state.settingsModel!.cartTotal.toString() == "" ? "0" : "${context.read<SystemConfigCubit>().getCurrency()}${double.parse(state.settingsModel!.cartTotal.toString()).toStringAsFixed(2)}",
                                                          textAlign: TextAlign.end,
                                                          style: TextStyle(
                                                              color: Theme.of(context).colorScheme.secondary,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w700,
                                                              letterSpacing: 0.8),
                                                        );
                                                })
                                          ]),
                                        );
                                      }),
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        });
  }

  Widget onLineCartData() {
    return context.read<SettingsCubit>().state.settingsModel!.cartCount == "0" &&
            context.read<SettingsCubit>().state.settingsModel!.cartCount == "0.0"
        ? noCartData()
        : BlocConsumer<GetCartCubit, GetCartState>(
            bloc: context.read<GetCartCubit>(),
            listener: (context, state) {
              if (state is GetCartSuccess) {
                final cartList = state.cartModel;
                deliveryStatus = context.read<SettingsCubit>().getSettings().deliverOrder;
                availableTime.clear();
                checkTime.clear();
                for (int i = 0; i < cartList.data!.length; i++) {
                  if (cartList.data![i].productDetails![0].availableTime == "1") {
                    availableTime.add(cartList.data![i].productDetails![0].availableTime!);
                    checkTime.add(getStoreOpenStatus(context.read<GetCartCubit>().getCartModel().data![i].productDetails![0].startTime!,context.read<GetCartCubit>().getCartModel().data![i].productDetails![0].endTime!));
                    print("data:${context.read<GetCartCubit>().getCartModel().data![i].productDetails![0].startTime!}-----${context.read<GetCartCubit>().getCartModel().data![i].productDetails![0].endTime!}");
                  }
                }
              }
            },
            builder: (context, state) {
              if (state is GetCartProgress) {
                return CartSimmer(width: width!, height: height!);
              }
              if (state is GetCartInitial) {
                return noCartData();
              }
              if (state is GetCartFailure) {
                return noCartData();
              }
              final cartList = (state as GetCartSuccess).cartModel;
              taxPercentage = cartList.taxPercentage!.isEmpty ? 0 : double.parse(cartList.taxPercentage!);
              taxAmount = cartList.taxAmount!.isEmpty ? 0 : double.parse(cartList.taxAmount!);
              subTotal = double.parse(cartList.subTotal!);
              overAllAmount = cartList.overallAmount!;
              finalTotal = cartList.overallAmount!;
              cartModel = cartList;
              isRestaurantOpen = context.read<SettingsCubit>().getSettings().isBranchOpen;
              pickupStatus = context.read<SettingsCubit>().getSettings().selfPickup;
              deliveryStatus = context.read<SettingsCubit>().getSettings().deliverOrder;
              if (deliveryStatus == "0") {
                orderTypeIndex = 1;
              }
              return cartList.totalQuantity == "" ? noCartData()
              : Container(width: width,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 40.0, end: width! / 20.0, bottom: height! / 40.0),
                          width: width!,
                          decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            context.read<SettingsCubit>().getSettings().deliverOrder == "1"
                            ? Expanded(
                                child: Theme(data: Theme.of(context).copyWith(unselectedWidgetColor: Theme.of(context).colorScheme.secondary,disabledColor: Theme.of(context).colorScheme.secondary),
                                  child: Container(decoration: DesignConfig.boxDecorationContainerBorder(orderTypeIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                                    orderTypeIndex == 0 ? Theme.of(context).colorScheme.primary.withOpacity(0.10) : Theme.of(context).colorScheme.onBackground,
                                    4.0,status: true),
                                    child: RadioListTile(activeColor: Theme.of(context).colorScheme.primary,
                                      title: Text(UiUtils.getTranslatedLabel(context, deliveryLabel),
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.normal),
                                      ),
                                      value: 0,
                                      groupValue: orderTypeIndex,
                                      contentPadding: EdgeInsets.all(5.0),
                                      dense: true,
                                      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                      onChanged: (value) {
                                        setState(() {
                                          orderTypeIndex = 0;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                            ): const SizedBox.shrink(),
                              context.read<SettingsCubit>().getSettings().selfPickup == "1" && context.read<SettingsCubit>().getSettings().deliverOrder == "1"
                              ? SizedBox(width: width! / 40.0): const SizedBox.shrink(),
                                context.read<SettingsCubit>().getSettings().selfPickup == "1"
                                  ? Expanded(
                                      child: Theme(data: Theme.of(context).copyWith(unselectedWidgetColor: Theme.of(context).colorScheme.secondary,disabledColor: Theme.of(context).colorScheme.secondary,),
                                        child: Container(decoration: DesignConfig.boxDecorationContainerBorder(
                                          orderTypeIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
                                          orderTypeIndex == 1 ? Theme.of(context).colorScheme.primary.withOpacity(0.10) : Theme.of(context).colorScheme.onBackground, 4.0, status: true),
                                            child: RadioListTile(activeColor: Theme.of(context).colorScheme.primary,
                                              title: Text(UiUtils.getTranslatedLabel(context, pickupLabel),
                                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal),
                                              ),
                                              value: 1,
                                              groupValue: orderTypeIndex,
                                              contentPadding: EdgeInsets.all(5.0),
                                              dense: true,
                                              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                              onChanged: (value) {
                                                setState(() {
                                                  orderTypeIndex = 1;
                                                  deliveryTip = 0;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink()
                              ]),
                            ),
                            orderTypeIndex == 1 || context.read<AddressCubit>().gerCurrentAddress().isDefault == ""
                                ? const SizedBox()
                                : Container(padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 80.0, end: width! / 20.0, bottom: height! / 99.0),
                                    width: width!,
                                    margin: EdgeInsetsDirectional.only(top: height! / 52.0,),
                                    decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                                    child: Column(
                                      children: [
                                        BlocConsumer<AddressCubit, AddressState>(
                                          bloc: context.read<AddressCubit>(),
                                          listener: (context, state) {
                                            if (state is AddressSuccess) {
                                              final addressList = state.addressList;
                                              for (int i = 0; i < addressList.length; i++) {
                                                if (addressList[i].isDefault == "1") {
                                                  context.read<DeliveryChargeCubit>().fetchDeliveryCharge(context.read<AuthCubit>().getId(), addressList[i].id!);
                                                }
                                              }
                                            }
                                          },
                                          builder: (context, state) {
                                            if (state is AddressProgress || state is AddressInitial) {
                                              return AddressSimmer(width: width!, height: height!);
                                            }
                                            if (state is AddressFailure) {
                                              return const SizedBox();
                                            }
                                            if (state is AddressSuccess) {
                                              final addressList = state.addressList;
                                              for (int i = 0; i < addressList.length; i++) {
                                                if (addressList[i].isDefault == "1") {
                                                  context.read<DeliveryChargeCubit>().fetchDeliveryCharge(context.read<AuthCubit>().getId(), addressList[i].id!);
                                                }
                                              }
                                              return Row(children: [
                                                SvgPicture.asset(DesignConfig.setSvgPath("map_pin_line"),
                                                  height: 14,
                                                  width: 14,
                                                  fit: BoxFit.scaleDown,colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                                ),
                                                SizedBox(width: width! / 80.0),
                                                Text(UiUtils.getTranslatedLabel(context, deliveryLocationLabel),
                                                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                                                ),
                                                const Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    changeAddressBottomModelSheetShow();
                                                  },
                                                  child: Text(UiUtils.getTranslatedLabel(context, changeLabel),
                                                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              ]);
                                            }
                                            return const SizedBox();
                                          }),
                                        context.read<AddressCubit>().gerCurrentAddress().id == "" || context.read<AddressCubit>().gerCurrentAddress().id!.isEmpty || orderTypeIndex == 1
                                            ? const SizedBox()
                                            : Padding(padding: EdgeInsetsDirectional.only(top: height! / 80.0,bottom: height! / 80.0,start: width! / 20.0,),
                                                child: DesignConfig.divider(),
                                              ),
                                        orderTypeIndex == 1 ? const SizedBox()
                                          : BlocProvider<UpdateAddressCubit>(
                                              create: (_) => UpdateAddressCubit(AddressRepository()),
                                              child: Builder(builder: (context) {
                                                return BlocConsumer<AddressCubit, AddressState>(
                                                  bloc: context.read<AddressCubit>(),
                                                  listener: (context, state) {},
                                                  builder: (context, state) {
                                                    if (state is AddressProgress || state is AddressInitial) {
                                                      return AddressSimmer(width: width!, height: height!);
                                                    }
                                                    if (state is AddressFailure) {
                                                      return const SizedBox();
                                                    }
                                                    if (state is AddressSuccess) {
                                                      return ListView.builder(
                                                        shrinkWrap: true,
                                                        padding: EdgeInsets.zero,
                                                        physics: const NeverScrollableScrollPhysics(),
                                                        itemCount: state.addressList.length,
                                                        itemBuilder: (BuildContext context, i) {
                                                          if (state.addressList[i].isDefault == "1") {
                                                            addressIndex = i;
                                                            selAddress = state.addressList[addressIndex!].id;
                                                            latitude = double.parse(state.addressList[addressIndex!].latitude!);
                                                            longitude = double.parse(state.addressList[addressIndex!].longitude!);
                                                          }
                                                          return state.addressList[i].isDefault == "0" ? Container()
                                                            : Container(margin: EdgeInsetsDirectional.only(top: 5, start: width! / 20.0),
                                                                padding: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                                                                child: Column(children: [
                                                                  Row(children: [
                                                                    state.addressList[i].type == homeKey ? SvgPicture.asset(DesignConfig.setSvgPath("home_address"),)
                                                                      : state.addressList[i].type == officeKey? SvgPicture.asset(DesignConfig.setSvgPath("work_address"))
                                                                      : SvgPicture.asset(DesignConfig.setSvgPath("other_address")),
                                                                      SizedBox(width: height! / 99.0),
                                                                      Text(state.addressList[i].type!,
                                                                        style: TextStyle(fontSize: 16,color: Theme.of(context).colorScheme.secondary,fontWeight: FontWeight.w600),
                                                                      ),
                                                                  ]),
                                                                  SizedBox(height: height! / 99.99),
                                                                  Text("${state.addressList[i].address!},${state.addressList[i].area!},${state.addressList[i].city},${state.addressList[i].state!},${state.addressList[i].pincode!}",
                                                                    style: TextStyle(fontSize: 14,color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),fontWeight: FontWeight.w500),maxLines: 2,
                                                                  ),
                                                                  Padding(padding: EdgeInsetsDirectional.only(top: height! / 80.0),
                                                                    child: Row(
                                                                      children: [
                                                                        ClipOval(child: DesignConfig.imageWidgets(context.read<AuthCubit>().getProfile(), 20, 20, "1")),
                                                                        SizedBox(width: width! / 80.0),
                                                                        Text(context.read<AuthCubit>().getName(),
                                                                          textAlign: TextAlign.start,
                                                                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 14.0,
                                                                            fontWeight: FontWeight.w500,
                                                                            fontStyle: FontStyle.normal)),
                                                                        Text(" | ",
                                                                          textAlign: TextAlign.start,
                                                                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 14.0,
                                                                            fontWeight: FontWeight.w500,
                                                                            fontStyle: FontStyle.normal)),
                                                                        Text(context.read<AuthCubit>().getMobile(),
                                                                          textAlign: TextAlign.start,
                                                                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                            fontSize: 14.0,
                                                                            fontWeight: FontWeight.w500,
                                                                            fontStyle: FontStyle.normal)),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ]),
                                                            );
                                                      });
                                                    }return const SizedBox();
                                                });
                                            }),
                                        ),
                                      ],
                                    ),
                                  ),
                            Container(
                              decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                              margin: EdgeInsetsDirectional.only(top: height! / 60.0),
                              padding: EdgeInsetsDirectional.only(top: height! / 40, start: width! / 20.0, end: width! / 20.0, bottom: height! / 40.0),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Row(children: [
                                  SvgPicture.asset(
                                    DesignConfig.setSvgPath("shopping_bag_line"),
                                    height: 14,
                                    width: 14,
                                    fit: BoxFit.scaleDown,
                                    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                  ),
                                  SizedBox(width: width! / 80.0),
                                  Text(UiUtils.getTranslatedLabel(context, foodInYourBagLabel),
                                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                                    return BlocProvider<ClearCartCubit>(
                                      create: (_) => ClearCartCubit(CartRepository()),
                                      child: Builder(builder: (context) {
                                        return BlocConsumer<ClearCartCubit, ClearCartState>(
                                          bloc: context.read<ClearCartCubit>(),
                                          listener: (context, state) {
                                            if (state is ClearCartSuccess) {
                                              if (context.read<AuthCubit>().state is AuthInitial ||
                                                context.read<AuthCubit>().state is Unauthenticated) {
                                              } else {
                                                UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, clearCartLabel), context, false, type: "1");
                                                context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId(),branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                setState(() {});
                                                  context.read<ProductCubit>().clearQty(cartList.data![0].productDetails);
                                                }
                                            } else if (state is ClearCartFailure) {
                                              if (context.read<AuthCubit>().state is AuthInitial ||
                                                context.read<AuthCubit>().state is Unauthenticated) {
                                              } else {
                                                UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                              }
                                            }
                                          },
                                          builder: (context, state) {
                                            return InkWell(
                                              onTap: () {
                                                showDialog(context: context,
                                                  builder: (BuildContext context) {
                                                    return CustomDialog(title: UiUtils.getTranslatedLabel(context, deleteAllItemsTitleLabel),
                                                      subtitle: UiUtils.getTranslatedLabel(context, deleteAllItemsSubTitleLabel),
                                                      width: width!,
                                                      height: height!,
                                                      from: UiUtils.getTranslatedLabel(context, clearCartLabel));
                                                  });
                                              },
                                              child: Text(UiUtils.getTranslatedLabel(context, clearCartLabel),
                                                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                                              ),
                                            );
                                          }
                                        );
                                      }),
                                    );
                                  }),
                                ]),
                                Padding(padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0, start: width! / 20.0),
                                  child: DesignConfig.divider(),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cartList.data!.length,
                                  itemBuilder: (BuildContext context, i) {
                                    return BlocProvider<RemoveFromCartCubit>(
                                      create: (_) => RemoveFromCartCubit(CartRepository()),
                                        child: Builder(builder: (context) {
                                          return Container(
                                            margin: EdgeInsetsDirectional.only(start: width! / 20.0),
                                            padding: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                                            width: width!,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    cartList.data![i].image!.isEmpty
                                                        ? const ClipRRect(borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                                            child: SizedBox(width: 65,height: 76,),
                                                          )
                                                        : ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(5.0),),
                                                            child: ColorFiltered(
                                                              colorFilter: context.read<SettingsCubit>().getSettings().isBranchOpen == "1"
                                                              ? const ColorFilter.mode(Colors.transparent,BlendMode.multiply,)
                                                              : const ColorFilter.mode(Colors.grey,BlendMode.saturation,),
                                                              child: DesignConfig.imageWidgets(cartList.data![i].image!, 76, 65, "2"),
                                                            ),
                                                          ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Padding(padding: EdgeInsetsDirectional.only(start: width! / 50.0,bottom: height! / 99.0),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Column(children: List.generate(cartList.data![i].productDetails!.length, (j) {
                                                                return Column(
                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Column(children: List.generate(cartList.data![i].productDetails![j].variants!.length, (l) {
                                                                      VariantsModel variantData = cartList.data![i].productDetails![j].variants![l];
                                                                      double price = double.parse(variantData.specialPrice!);
                                                                      if (price == 0) {
                                                                        price = double.parse(variantData.price!);
                                                                      }
                                                                      double off = 0;
                                                                      if (cartList.data![i].specialPrice! != "0") {
                                                                        off = (double.parse(variantData.price!) - double.parse(variantData.specialPrice!)) .toDouble();
                                                                        off = off * 100 / double.parse(variantData.price!).toDouble();
                                                                      }
                                                                      var sum = 0.0;
                                                                      if (cartList.data![i].productDetails![j].variants![l].addOnsData!.isNotEmpty) {
                                                                        for (var k = 0; k < cartList.data![i].productDetails![j].variants![l].addOnsData! .length; k++) {
                                                                          sum += double.parse(cartList.data![i].productDetails![j].variants![l].addOnsData![k].price!.toString());
                                                                        }
                                                                      }
                                                                      return (cartList.data![i].productVariantId == cartList.data![i].productDetails![j].variants![l].id!)
                                                                        ? Column(
                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  cartList.data![i].productDetails![j].indicator == "1"
                                                                                  ? SvgPicture.asset(DesignConfig.setSvgPath("veg_icon"),width: 15,height: 15)
                                                                                  : cartList.data![i].productDetails![j].indicator == "2"
                                                                                  ? SvgPicture.asset(DesignConfig.setSvgPath("non_veg_icon"),width: 15,height: 15)
                                                                                  : const SizedBox(height: 15, width: 15.0),
                                                                                  const SizedBox(width: 5.0),
                                                                                  Expanded(flex: 2,
                                                                                    child: SizedBox(height: height! / 22.0,
                                                                                      child: Text(cartList.data![i].name!,
                                                                                        textAlign: Directionality.of(context) == TextDirection.RTL ? TextAlign.right : TextAlign.left,
                                                                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76),
                                                                                          fontSize: 14,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          fontStyle: FontStyle.normal,
                                                                                          overflow: TextOverflow.ellipsis),
                                                                                          maxLines: 2,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  BlocConsumer<ManageCartCubit, ManageCartState>(
                                                                                    bloc: context.read<ManageCartCubit>(),
                                                                                    listener: (context, state) {
                                                                                      print(state.toString());  
                                                                                      if (state is ManageCartSuccess) {
                                                                                        if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                                                                          return;
                                                                                        } else {
                                                                                            final currentCartModel = context .read<GetCartCubit>() .getCartModel();
                                                                                            context.read<GetCartCubit>().updateCartList(currentCartModel.updateCart(state.data,(/* int.parse(currentCartModel.totalQuantity ??'0') + */
                                                                                              int.parse(state.totalQuantity!)).toString(),
                                                                                              state.subTotal,
                                                                                              state.taxPercentage,
                                                                                              state.taxAmount,
                                                                                              state.overallAmount,
                                                                                              List.from(state.variantId ?? [])..addAll(currentCartModel.variantId ??[])));
                                                                                              print(currentCartModel.variantId);
                                                                                              if(promoCode!=""){
                                                                                              context.read<ValidatePromoCodeCubit>().getValidatePromoCode(promoCode,context.read<AuthCubit>().getId(),state.overallAmount!.toStringAsFixed(2),
                                                                                              context.read<SettingsCubit>().getSettings().branchId);
                                                                                              }
                                                                                        }
                                                                                      } else if (state is ManageCartFailure) {
                                                                                          if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                                                                            return;
                                                                                          } else {
                                                                                              UiUtils.setSnackBar(state.errorMessage, context, false,type: "2");
                                                                                          }
                                                                                        }
                                                                                    },
                                                                                    builder: (context, state) {
                                                                                      return Container(padding: EdgeInsetsDirectional.only(top: 3.0,bottom: 3.0,start: 5.0,end: 5.0),
                                                                                        alignment: Alignment.center,
                                                                                        height: 28.0,
                                                                                        width: width! / 4.8,
                                                                                        decoration: DesignConfig.boxDecorationContainerBorder(Theme.of(context).colorScheme.primary,Theme.of(context).colorScheme.primary.withOpacity(0.12),5.0),
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                            children: [
                                                                                              BlocConsumer<RemoveFromCartCubit, RemoveFromCartState>(
                                                                                                bloc: context.read<RemoveFromCartCubit>(),
                                                                                                listener: (context, state) {
                                                                                                  if (state is RemoveFromCartSuccess) {
                                                                                                    UiUtils.setSnackBar(StringsRes.deleteSuccessFully,context,false,type: "1");
                                                                                                    cartList.data!.removeAt(i);
                                                                                                    context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId(),branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                                                  } else if (state is RemoveFromCartFailure) {
                                                                                                      UiUtils.setSnackBar(state.errorMessage,context,false,type: "2");
                                                                                                  }
                                                                                                },
                                                                                                builder: (context, state) {
                                                                                                  return InkWell(overlayColor:MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary.withOpacity(0.10)),
                                                                                                    onTap: () {
                                                                                                      setState(() {
                                                                                                        if (int.parse(cartList.data![i].qty!) <= int.parse(cartList.data![i].minimumOrderQuantity!)) {
                                                                                                          context.read<RemoveFromCartCubit>().removeFromCart(
                                                                                                            userId: context.read<AuthCubit>().getId(),
                                                                                                            productVariantId:cartList.data![i].productVariantId,
                                                                                                            branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                                                        } else if (int.parse(cartList.data![i].qty!) == 1) {
                                                                                                            context.read<RemoveFromCartCubit>().removeFromCart(userId: context.read<AuthCubit>().getId(),productVariantId:cartList.data![i].productVariantId,
                                                                                                              branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                                                          } else {
                                                                                                              List<AddOnsDataModel> addOnsDataModel = variantData.addOnsData!;
                                                                                                              List<String> addOnIds = [];
                                                                                                              List<String> addOnQty = [];
                                                                                                              for (int qt = 0; qt < addOnsDataModel.length; qt++) {
                                                                                                                addOnIds.add(addOnsDataModel[qt].id.toString());
                                                                                                                addOnQty.add((int.parse(cartList.data![i].qty.toString()) - 1).toString());
                                                                                                              }
                                                                                                              context.read<ManageCartCubit>().manageCartUser(userId: context.read<AuthCubit>().getId(),
                                                                                                                productVariantId: cartList.data![i].productVariantId,
                                                                                                                isSavedForLater: "0",
                                                                                                                qty: (int.parse(cartList.data![i].qty!) - 1).toString(),
                                                                                                                addOnId: addOnIds.isNotEmpty ? addOnIds.join(",").toString(): "",
                                                                                                                addOnQty: addOnQty.isNotEmpty ? addOnQty.join(",").toString(): "",
                                                                                                                branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                                                            }
                                                                                                            if (orderTypeIndex.toString() == "0") {
                                                                                                              finalTotal = cartList.overallAmount! + deliveryCharge;
                                                                                                            } else {
                                                                                                              finalTotal = cartList.overallAmount! - deliveryCharge;
                                                                                                            }
                                                                                                            if(promoCode!=""){
                                                                                                            context.read<ValidatePromoCodeCubit>().getValidatePromoCode(
                                                                                                              promoCode,context.read<AuthCubit>().getId(),cartList.overallAmount!.toString(),
                                                                                                              context.read<SettingsCubit>().getSettings().branchId);
                                                                                                            }
                                                                                                      });
                                                                                                    },
                                                                                                    child: Icon(Icons.remove, color: Theme.of(context).colorScheme.onPrimary,size: 15.0),
                                                                                                  );
                                                                                                }),
                                                                                                Spacer(),
                                                                                                Text(cartList.data![i].qty.toString(),
                                                                                                  textAlign: TextAlign.center,
                                                                                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary,
                                                                                                    fontSize: 10,
                                                                                                    fontWeight: FontWeight.w700,
                                                                                                    fontStyle: FontStyle.normal,
                                                                                                  )
                                                                                                ),
                                                                                                const Spacer(),
                                                                                                InkWell(overlayColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary.withOpacity(0.10)),
                                                                                                  onTap: () {
                                                                                                    setState(() {
                                                                                                      if (int.parse(cartList.data![i].qty!) < int.parse(cartList.data![i].productDetails![l].minimumOrderQuantity!)) {
                                                                                                        Navigator.pop(context);
                                                                                                        UiUtils.setSnackBar("${StringsRes.minimumQuantityAllowed} ${cartList.data![i].productDetails![l].minimumOrderQuantity!}", context, false, type: "2");
                                                                                                      } else if (cartList.data![i].productDetails![l].totalAllowedQuantity != "" && int.parse(cartList.data![i].qty!) >= int.parse(cartList.data![i].productDetails![l].totalAllowedQuantity!)) {
                                                                                                          cartList.data![i].qty = cartList.data![i].productDetails![l].totalAllowedQuantity!;
                                                                                                          UiUtils.setSnackBar("${StringsRes.minimumQuantityAllowed} ${cartList.data![i].productDetails![l].totalAllowedQuantity!}",context,false,type: "2");
                                                                                                      } else {
                                                                                                          List<AddOnsDataModel> addOnsDataModel = variantData.addOnsData!;
                                                                                                          List<String> addOnIds = [];
                                                                                                          List<String> addOnQty = [];
                                                                                                          for (int qt = 0; qt < addOnsDataModel.length; qt++) {
                                                                                                            addOnIds.add(addOnsDataModel[qt].id.toString());
                                                                                                            addOnQty.add((int.parse(addOnsDataModel[qt].qty.toString()) + 1).toString());
                                                                                                          }
                                                                                                          context.read<ManageCartCubit>().manageCartUser(
                                                                                                            userId: context.read<AuthCubit>().getId(),
                                                                                                            productVariantId: cartList.data![i].productVariantId,
                                                                                                            isSavedForLater: "0",
                                                                                                            qty: (int.parse(cartList.data![i].qty!) + 1).toString(),
                                                                                                            addOnId: addOnIds.isNotEmpty ? addOnIds.join(",").toString(): "",
                                                                                                            addOnQty: addOnQty.isNotEmpty ? addOnQty.join(",").toString(): "",
                                                                                                            branchId: context.read<SettingsCubit>().getSettings().branchId);
                                                                                                      }
                                                                                                    });
                                                                                                  },
                                                                                                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 15.0),
                                                                                                ),
                                                                                              ]),
                                                                                            );
                                                                                          }),
                                                                                        ]),
                                                                                        SingleChildScrollView(
                                                                                          physics: const NeverScrollableScrollPhysics(),
                                                                                          scrollDirection: Axis.horizontal,
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              variantData.variantValues != "" ? 
                                                                                              Text("${variantData.variantValues!}: ",
                                                                                                textAlign: TextAlign.left,
                                                                                                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.w600),
                                                                                              ) : Container(height: 10.0),
                                                                                              cartList.data![i].productDetails![j].variants![l] .addOnsData!.isNotEmpty
                                                                                                ? Row(
                                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                                    children: List.generate(cartList.data![i].productDetails![j].variants![l].addOnsData!.length, (m) {
                                                                                                      AddOnsDataModel addOnData = variantData.addOnsData![m];
                                                                                                      return Text("${addOnData.title!}, ",
                                                                                                        textAlign: TextAlign.center,
                                                                                                        style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                                                                          fontSize: 10,
                                                                                                          fontWeight: FontWeight.w600,
                                                                                                          overflow: TextOverflow.ellipsis),
                                                                                                        maxLines: 1,
                                                                                                      );
                                                                                                    }),
                                                                                                  ): Container(height: 10.0),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                        const SizedBox(height: 5.0),
                                                                                        Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                          children: [
                                                                                            InkWell(
                                                                                              onTap: () {
                                                                                                setState(() {
                                                                                                  addToCartBottomModelSheet(cartList.data![i].productDetails!,j,variantData.id!,l);
                                                                                                });
                                                                                              },
                                                                                              child: Container(padding: const EdgeInsets.all(2.0),
                                                                                                decoration: DesignConfig.boxDecorationContainer(textFieldBackground, 4.0),
                                                                                                child: Row(
                                                                                                  children: [
                                                                                                    Text(UiUtils.getTranslatedLabel(context, editLabel),
                                                                                                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500),
                                                                                                    ),
                                                                                                    Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.secondary, size: 12.0),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            const Spacer(),
                                                                                            Row(
                                                                                              mainAxisSize: MainAxisSize.min,
                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                                                              children: [
                                                                                                Text(context.read<SystemConfigCubit>().getCurrency() + (double.parse(price.toString()) * int.parse(cartList.data![i].qty!) + (sum * int.parse(cartList.data![i].qty!))).toStringAsFixed(2),
                                                                                                  textAlign: TextAlign.center,
                                                                                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.w700),
                                                                                                ),
                                                                                              ]),
                                                                                          ],
                                                                                        ),
                                                                                        const SizedBox(height: 5.0),
                                                                                      ])
                                                                                : Container();
                                                                          }),
                                                                        ),
                                                                      ]);
                                                                }),
                                                              ),
                                                            ]),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(padding: EdgeInsetsDirectional.only(top: height! / 99.0,bottom: height! / 99.0,),
                                                  child: DesignConfig.divider(),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      );
                                    }),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: width! / 28.0,
                                    end: width! / 40.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        if (widget.from == 'restaurantDetail') {
                                          Navigator.of(context).pop();
                                        } else {
                                          Navigator.of(context).pushNamed(Routes.menu);
                                        }
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Icon(Icons.add_circle_sharp, color: Theme.of(context).colorScheme.secondary, size: 20.0),
                                        const SizedBox(width: 2.0),
                                        Text(UiUtils.getTranslatedLabel(context, addMoreFoodInCartLabel),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(context,MaterialPageRoute(builder: (BuildContext context) => const OfferCouponsScreen(),),).then((value) {
                                  if (value != null) {
                                    setState(() {
                                      promoCode = value['code'];
                                      if(promoCode!=""){
                                      context.read<ValidatePromoCodeCubit>().getValidatePromoCode(promoCode, context.read<AuthCubit>().getId(), cartList.overallAmount!.toString(), context.read<SettingsCubit>().getSettings().branchId);
                                      }
                                      if (orderTypeIndex.toString() == "0") {
                                        finalTotal = value['finalAmount'] + deliveryCharge;
                                      } else {
                                        finalTotal = value['finalAmount'] - deliveryCharge;
                                      }
                                      promoAmt = value['amount'];
                                    });
                                  }
                                });
                              },
                              child: Container(
                                width: width!,
                                margin: EdgeInsetsDirectional.only(top: height! / 52.0,),
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                                padding: EdgeInsetsDirectional.only(top: height! / 40.0, bottom: height! / 40.0, start: width! / 20.0, end: width! / 20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                      SvgPicture.asset(
                                        DesignConfig.setSvgPath("coupon_line"),
                                        height: 14,
                                        width: 14,
                                        fit: BoxFit.scaleDown,
                                        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                                      ),
                                      SizedBox(width: width! / 80.0),
                                      Text(UiUtils.getTranslatedLabel(context, addCouponLabel),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      Text(UiUtils.getTranslatedLabel(context, viewAllLabel),
                                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500),
                                      ),
                                    ]),
                                    promoCode != ""
                                    ? Padding(padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
                                        child: DesignConfig.divider(),
                                      ): const SizedBox.shrink(),
                                    promoCode != ""
                                    ? Padding(padding: EdgeInsetsDirectional.only(top: height! / 70.0, start: width! / 20.0, bottom: 5.0),
                                        child: Row(
                                          children: [
                                            Text(UiUtils.getTranslatedLabel(context, usedCouponLabel),
                                              textAlign: TextAlign.start,
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                                            const Spacer(),
                                            promoAmt == 0
                                            ? const SizedBox()
                                            : InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    promoCode = "";
                                                    promoAmt = 0;
                                                    if (orderTypeIndex.toString() == "0") {
                                                      finalTotal = cartList.overallAmount! + deliveryCharge;
                                                    } else {
                                                        finalTotal = cartList.overallAmount! - deliveryCharge;
                                                    }
                                                  });
                                                },
                                                child: Text(UiUtils.getTranslatedLabel(context, removeCouponLabel),
                                                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ): Container(),
                                    promoCode != ""
                                    ? Padding(padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                        child: BlocConsumer<ValidatePromoCodeCubit, ValidatePromoCodeState>(
                                        bloc: context.read<ValidatePromoCodeCubit>(),
                                        listener: (context, state) {
                                          if (state is ValidatePromoCodeFetchFailure) {
                                            print(state.errorMessage);
                                          }
                                          if (state is ValidatePromoCodeFetchSuccess) {
                                            promoCode = state.promoCodeValidateModel!.promoCode!.toString();
                                            promoAmt = double.parse(state.promoCodeValidateModel!.finalDiscount!);
                                            if (orderTypeIndex.toString() == "0") {
                                              finalTotal = double.parse(state.promoCodeValidateModel!.finalTotal!) + deliveryCharge;
                                            } else {
                                              finalTotal = double.parse(state.promoCodeValidateModel!.finalTotal!) - deliveryCharge;
                                            }
                                          }
                                        },
                                        builder: (context, state) {
                                          if (state is ValidatePromoCodeFetchSuccess) {
                                            return Row(
                                              children: [
                                                Text(StringsRes.coupon + state.promoCodeValidateModel!.promoCode.toString(),
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12)),
                                                const Spacer(),
                                                Text(context.read<SystemConfigCubit>().getCurrency() + double.parse(state.promoCodeValidateModel!.finalDiscount!).toStringAsFixed(2),
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700),
                                                )
                                              ],
                                            );
                                          } else {
                                              return const SizedBox();
                                          }
                                        }),
                                      ): Container(),
                                  ],
                                ),
                              ),
                            ),
                            orderTypeIndex.toString() == "0"
                            ? Container(width: width!,
                                padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 40.0, end: width! / 20.0, bottom: height! / 40.0),
                                margin: EdgeInsetsDirectional.only(top: height! / 52.0,),
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                                child: Column(children: [
                                  Row(
                                    children: [
                                      Expanded(flex: 18,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                SvgPicture.asset(DesignConfig.setSvgPath("hand_coin_line"), height: 14, width: 14, fit: BoxFit.scaleDown, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn)),
                                                SizedBox(width: width! / 80.0),
                                                Text(UiUtils.getTranslatedLabel(context, tipDeliveryPartnerLabel),
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3.0),
                                            Padding(padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                              child: Text(UiUtils.getTranslatedLabel(context, tipDeliveryPartnerSubTitleLabel),
                                                textAlign: TextAlign.start,
                                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.76), fontSize: 11), maxLines: 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      deliveryTip == 0
                                      ? const SizedBox()
                                      : Column(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedIndex = -1;
                                                  deliveryTip = 0;
                                                  tipOther = false;
                                                  deliveryTipController.clear();
                                                });
                                              },
                                              child: Text(UiUtils.getTranslatedLabel(context, removeTipLabel),
                                                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            const SizedBox(height: 5.0),
                                            Text(context.read<SystemConfigCubit>().getCurrency() + deliveryTip.toStringAsFixed(2),
                                              textAlign: TextAlign.start,
                                              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Padding(padding: EdgeInsetsDirectional.only(top: height! / 70.0, bottom: height! / 70.0, start: width! / 20.0),
                                    child: DesignConfig.divider(),
                                  ),
                                  deliveryTips(),
                                ]),
                              ): const SizedBox.shrink(),
                            Container(width: width!,
                              padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 40.0, end: width! / 20.0, bottom: height! / 40.0),
                              margin: EdgeInsetsDirectional.only(top: height! / 52.0,),
                              decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(DesignConfig.setSvgPath("add_note_line"), height: 14, width: 14, fit: BoxFit.scaleDown, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn)),
                                      SizedBox(width: width! / 80.0),
                                      Text(UiUtils.getTranslatedLabel(context, addNotesForFoodPartnerLabel),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Padding(padding: EdgeInsetsDirectional.only(top: height! / 70.0, bottom: height! / 70.0, start: width! / 20.0),
                                    child: DesignConfig.divider(),
                                  ),
                                  addNote(),
                                ],
                              ),
                            ),
                            Container(padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 40.0, end: width! / 20.0, bottom: height! / 80.0),
                              width: width!,
                              margin: EdgeInsetsDirectional.only(top: height! / 52.0,),
                              decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 0.0),
                              child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(DesignConfig.setSvgPath("ic_invoice"), height: 14, width: 14, fit: BoxFit.scaleDown, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn)),
                                    SizedBox(width: width! / 80.0),
                                    Text(UiUtils.getTranslatedLabel(context, billDetailLabel),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Padding(padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0, start: width! / 20.0),
                                  child: DesignConfig.divider(),
                                ),
                                Padding(padding: EdgeInsetsDirectional.only(bottom: height! / 99.0, start: width! / 20.0),
                                  child: Row(children: [
                                    Text(UiUtils.getTranslatedLabel(context, subTotalLabel),
                                        textAlign: TextAlign.left,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text(context.read<SystemConfigCubit>().getCurrency() + (subTotal).toStringAsFixed(2),
                                      textAlign: TextAlign.end,
                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.8),
                                    ),
                                  ]),
                                ),
                                Padding(padding: EdgeInsetsDirectional.only(bottom: height! / 99.0, start: width! / 20.0),
                                  child: Row(children: [
                                    Text("${UiUtils.getTranslatedLabel(context, chargesAndTaxesLabel)} (${cartList.taxPercentage!}${StringsRes.percentSymbol})",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text(context.read<SystemConfigCubit>().getCurrency() + cartList.taxAmount!,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.8),
                                    ),
                                  ]),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(top: 4.5, bottom: height! / 80.0, start: width! / 20.0),
                                  child: DesignConfig.divider(),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(bottom: height! / 99.0, start: width! / 20.0),
                                  child: Row(children: [
                                    Text(UiUtils.getTranslatedLabel(context, totalLabel),
                                        textAlign: TextAlign.left,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Text(context.read<SystemConfigCubit>().getCurrency() + (subTotal + taxAmount).toStringAsFixed(2),
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8),
                                    ),
                                  ]),
                                ),
                                Padding(padding: EdgeInsetsDirectional.only(top: 4.5, bottom: height! / 80.0, start: width! / 20.0),
                                  child: DesignConfig.divider(),
                                ),
                                promoAmt != 0
                                ? Padding(padding: EdgeInsetsDirectional.only(bottom: height! / 99.0, start: width! / 20.0),
                                    child: BlocConsumer<ValidatePromoCodeCubit, ValidatePromoCodeState>(
                                      bloc: context.read<ValidatePromoCodeCubit>(),
                                      listener: (context, state) {
                                        if (state is ValidatePromoCodeFetchFailure) {
                                          print(state.errorMessage);
                                        }
                                        if (state is ValidatePromoCodeFetchSuccess) {
                                          promoCode = state.promoCodeValidateModel!.promoCode!.toString();
                                          promoAmt = double.parse(state.promoCodeValidateModel!.finalDiscount!);
                                          print(promoAmt);
                                          setState(() {
                                            if (orderTypeIndex.toString() == "0") {
                                              finalTotal = double.parse(state.promoCodeValidateModel!.finalTotal!) + deliveryCharge;
                                            } else {
                                                finalTotal = double.parse(state.promoCodeValidateModel!.finalTotal!) - deliveryCharge;
                                            }
                                          });
                                        }
                                      },
                                      builder: (context, state) {
                                        if (state is ValidatePromoCodeFetchFailure) {}
                                          if (state is ValidatePromoCodeFetchSuccess) {
                                            return Row(children: [
                                              Text(StringsRes.coupon + state.promoCodeValidateModel!.promoCode!.toString(),
                                                textAlign: TextAlign.left,
                                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                              const Spacer(),
                                              Text(" - ${context.read<SystemConfigCubit>().getCurrency()}${state.promoCodeValidateModel!.finalDiscount}",
                                                textAlign: TextAlign.end,
                                                style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.8),
                                              )
                                            ]);
                                          } else {
                                              return const SizedBox();
                                          }
                                      }),
                                    ): Container(),
                                orderTypeIndex.toString() == "0"
                                    ? Padding(padding: EdgeInsetsDirectional.only(bottom: height! / 99.0, start: width! / 20.0),
                                        child: Row(children: [
                                          Text(UiUtils.getTranslatedLabel(context, deliveryTipLabel),
                                            textAlign: TextAlign.left,
                                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          const Spacer(),
                                          Text(context.read<SystemConfigCubit>().getCurrency() + deliveryTip.toString(),
                                            textAlign: TextAlign.end,
                                            style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.8),
                                          ),
                                        ]),
                                      ): const SizedBox.shrink(),
                                orderTypeIndex.toString() == "0"
                                    ? BlocConsumer<DeliveryChargeCubit, DeliveryChargeState>(
                                        bloc: context.read<DeliveryChargeCubit>(),
                                        listener: (context, state) {
                                          if (state is DeliveryChargeFailure) {
                                            print(state.errorMessage);
                                          }
                                          if (state is DeliveryChargeSuccess) {
                                            deliveryCharge = double.parse(state.deliveryCharge.toString());
                                            if (promoAmt == 0) {
                                              if (orderTypeIndex.toString() == "0") {
                                                finalTotal = cartList.overallAmount! + deliveryCharge;
                                              } else {
                                                finalTotal = cartList.overallAmount! - deliveryCharge;
                                              }
                                            } else {}
                                          }
                                        },
                                        builder: (context, state) {
                                          if (state is DeliveryChargeSuccess) {
                                            deliveryCharge = double.parse(state.deliveryCharge.toString());
                                            if (orderTypeIndex.toString() == "0") {
                                              finalTotal = cartList.overallAmount! + deliveryCharge - promoAmt;
                                            }
                                            return Padding(padding: EdgeInsetsDirectional.only(top: 4.5, bottom: height! / 99.0, start: width! / 20.0),
                                              child: Column(children: [
                                                Row(
                                                  children: [
                                                    Text(UiUtils.getTranslatedLabel(context, deliveryChargesLabel),
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                                    ),
                                                    const Spacer(),
                                                    Text(context.read<SystemConfigCubit>().getCurrency() + state.deliveryCharge.toString(),
                                                      textAlign: TextAlign.end,
                                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          letterSpacing: 0.8),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional.only(top: height! / 80.0,bottom: height! / 80.0,),
                                                  child: DesignConfig.divider(),
                                                ),
                                                Padding(padding: EdgeInsetsDirectional.only(bottom: height! / 99.0,),
                                                  child: Row(children: [
                                                    Text(UiUtils.getTranslatedLabel(context, totalPayLabel),
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                                                    ),
                                                    const Spacer(),
                                                    Text(context.read<SystemConfigCubit>().getCurrency() + /* (finalTotal + deliveryTip) */total().toStringAsFixed(2),
                                                      textAlign: TextAlign.end,
                                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.8),
                                                    ),
                                                  ]),
                                                ),
                                              ]),
                                            );
                                          } else {
                                            return Padding(padding: EdgeInsetsDirectional.only(top: 4.5, bottom: height! / 99.0, start: width! / 20.0),
                                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                                Padding(padding: EdgeInsetsDirectional.only(bottom: height! / 80.0,),
                                                  child: DesignConfig.divider(),
                                                ),
                                                Row(children: [
                                                  Text(UiUtils.getTranslatedLabel(context, totalPayLabel),
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                                                  ),
                                                  const Spacer(),
                                                  Text(context.read<SystemConfigCubit>().getCurrency() + /* (finalTotal + deliveryTip - promoAmt) */total().toStringAsFixed(2),
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.8),
                                                  ),
                                                ]),
                                              ]),
                                            );
                                          }
                                        })
                                    : const SizedBox(),
                                promoCode.toString() == ""
                                ? const SizedBox()
                                : Padding(padding: EdgeInsetsDirectional.only(top: 4.5,bottom: 4.5,start: width! / 20.0,),
                                    child: DesignConfig.divider(),
                                  ),
                                orderTypeIndex.toString() == "0"
                                ? const SizedBox()
                                : Padding(padding: EdgeInsetsDirectional.only(top: 4.5, bottom: height! / 99.0, start: width! / 20.0),
                                    child: Row(children: [
                                      Text(UiUtils.getTranslatedLabel(context, totalPayLabel),
                                        textAlign: TextAlign.left,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      Text(context.read<SystemConfigCubit>().getCurrency() + /* (finalTotal + deliveryTip - promoAmt) */total().toStringAsFixed(2),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8),
                                      ),
                                    ]),
                                  ),
                              ]),
                            ),
                            SizedBox(height: height! / 80.0),
                          ],
                        ),
                      ),
                    );
            });
  }

  Widget cartData() {
    return BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
      return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
          ? offLineCartDate()
          : onLineCartData();
    });
  }

  Future<void> refreshList() async {
    clearAll();
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      status = 0;
      oriPrice = 0;
      getOffLineCart();
    } else {
      await context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
      Future.delayed(Duration.zero, () async {
        await context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId(), branchId: context.read<SettingsCubit>().getSettings().branchId);
      });
    }
  }

  addPhoneNumberBottomSheet() {
    showModalBottomSheet(
      isDismissible: true,
      backgroundColor: Theme.of(context).colorScheme.onBackground,
      shape: DesignConfig.setRoundedBorderCard(0.0, 0.0, 16.0, 16.0),
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    phoneNumberField(),
                    BlocConsumer<UpdateUserDetailCubit, UpdateUserDetailState>(
                      bloc: context.read<UpdateUserDetailCubit>(),
                      listener: (context, state) {
                        if (state is UpdateUserDetailFailure) {
                          phoneNumberStatus = false;
                        }
                        if (state is UpdateUserDetailSuccess) {
                          context.read<AuthCubit>().updateUserName(state.authModel.username ?? "");
                          context.read<AuthCubit>().updateUserEmail(state.authModel.email ?? "");
                          context.read<AuthCubit>().updateUserMobile(state.authModel.mobile ?? "");
                          context.read<AuthCubit>().updateUserReferralCode(state.authModel.referralCode ?? "");
                          UiUtils.setSnackBar(StringsRes.updateSuccessFully, context, false, type: "1");
                          phoneNumberController.clear();
                          phoneNumberStatus = false;
                          Navigator.pop(context);
                        } else if (state is UpdateUserDetailFailure) {
                            UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                            phoneNumberStatus = false;
                        }
                      },
                      builder: (context, state) {
                        return SizedBox(
                          width: width!,
                          child: ButtonContainer(
                            color: Theme.of(context).colorScheme.primary,
                            height: height,
                            width: width,
                            text: UiUtils.getTranslatedLabel(context, saveProfileLabel),
                            start: width! / 20.0,
                            end: width! / 20.0,
                            bottom: height! / 55.0,
                            top: 0,
                            status: phoneNumberStatus,
                            borderColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            onPressed: () {
                              setState(() {
                                phoneNumberStatus = true;
                              });
                              if (formKey.currentState!.validate()) {
                                context.read<UpdateUserDetailCubit>().updateProfile(
                                  userId: context.read<AuthCubit>().getId(),
                                  name: context.read<AuthCubit>().getName(),
                                  email: context.read<AuthCubit>().getEmail(),
                                  mobile: phoneNumberController.text,
                                  referralCode: context.read<AuthCubit>().getReferralCode());
                              }
                            },
                          ),
                        );
                      })
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  @override
  void dispose() {
    addNoteController.dispose();
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
                backgroundColor: Theme.of(context).colorScheme.background,
                appBar: DesignConfig.appBar(context,width!,UiUtils.getTranslatedLabel(context, myCartLabel),PreferredSize(preferredSize: Size.zero,child: const SizedBox.shrink(),)),
                bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                  return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
                    ? BlocConsumer<OfflineCartCubit, OfflineCartState>(
                        bloc: context.read<OfflineCartCubit>(),
                        listener: (context, state) {},
                        builder: (context, state) {
                          if (state is OfflineCartInitial || state is OfflineCartProgress) {
                            return ButtonSimmer(width: width!, height: height!);
                          }
                          return ButtonContainer(
                            color: Theme.of(context).colorScheme.primary,
                            height: height,
                            width: width,
                            text: (state is OfflineCartSuccess) ? UiUtils.getTranslatedLabel(context, confirmOrderLabel) : UiUtils.getTranslatedLabel(context, browseMenuLabel),
                            start: width! / 40.0,
                            end: width! / 40.0,
                            bottom: height! / 55.0,
                            top: 0,
                            status: false,
                            borderColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            onPressed: () {
                              if (state is OfflineCartSuccess) {
                                if (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) {
                                  Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'cart'}).then((value) {
                                    appDataRefresh(context);
                                  });
                                  return;
                                }
                                } else {
                                  moveFirstScreen();
                                }
                              },
                            );
                  }): BlocConsumer<GetCartCubit, GetCartState>(
                    bloc: context.read<GetCartCubit>(),
                    listener: (context, state) {},
                    builder: (context, state) {
                      if (state is GetCartSuccess) {
                        deliveryStatus = context.read<SettingsCubit>().getSettings().deliverOrder;
                        if (orderTypeIndex.toString() == "0" && deliveryStatus == "1") {
                          return BlocProvider<UpdateAddressCubit>(
                            create: (_) => UpdateAddressCubit(AddressRepository()),
                            child: Builder(builder: (context) {
                              return BlocConsumer<AddressCubit, AddressState>(
                                bloc: context.read<AddressCubit>(),
                                listener: (context, state) {},
                                builder: (context, state) {
                                  if (state is AddressProgress || state is AddressInitial) {
                                    return Padding(padding: EdgeInsetsDirectional.only(top: height! / 10.0),child: CartSimmer(width: width!, height: height!),);
                                  }
                                  if (state is AddressFailure) {
                                    return ButtonContainer(
                                      color: Theme.of(context).colorScheme.primary,
                                      height: height,
                                      width: width,
                                      text: UiUtils.getTranslatedLabel(context, confirmOrderLabel),
                                      start: width! / 40.0,
                                      end: width! / 40.0,
                                      bottom: height! / 55.0,
                                      top: 0,
                                      status: false,
                                      borderColor: Theme.of(context).colorScheme.primary,
                                      textColor: Theme.of(context).colorScheme.onPrimary,
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(Routes.address,arguments: {'from': '', 'addressModel': AddressModel()}).then((value) => {refreshList()});},
                                    );
                                  }
                                  final addressList = (state as AddressSuccess).addressList;
                                  return BlocConsumer<GetCartCubit, GetCartState>(
                                    bloc: context.read<GetCartCubit>(),
                                    listener: (context, getCartstate) {
                                      if (getCartstate is GetCartSuccess) {
                                        for (int i = 0; i < addressList.length; i++) {
                                          if (addressList[i].isDefault == "1") {
                                            context.read<DeliveryChargeCubit>().fetchDeliveryCharge(context.read<AuthCubit>().getId(), addressList[i].id!);
                                          }
                                        }
                                      }
                                    },
                                    builder: (context, getCartstate) {
                                      return BlocListener<IsOrderDeliverableCubit, IsOrderDeliverableState>(
                                        listener: (context, state) {
                                          if (state is IsOrderDeliverableSuccess) {
                                            final currentCartModel = context.read<GetCartCubit>().getCartModel();
                                            if (context.read<SettingsCubit>().getSettings().isBranchOpen == "1") {
                                              if (currentCartModel.data!.length > int.parse(context.read<SystemConfigCubit>().getCartMaxItemAllow())) {
                                                UiUtils.setSnackBar("${StringsRes.maximumItemAllowed} ${context.read<SystemConfigCubit>().getCartMaxItemAllow()}",context,false,type: "2");
                                              } else {
                                                  if ((context.read<AuthCubit>().getType() == "google")) {
                                                    if (context.read<AuthCubit>().getMobile().isEmpty) {
                                                      addPhoneNumberBottomSheet();
                                                    } else {
                                                        paymentScreenMove();
                                                    }
                                                  } else {
                                                    if (availableTime.contains("1")) {
                                                      if (!checkTime.contains(false)) {
                                                        paymentScreenMove();
                                                      } else {
                                                          UiUtils.setSnackBar(StringsRes.oneOfTheItemInYourCartNotDeliveryOnTheTime, context, false,type: "2");
                                                      }
                                                    } else {
                                                        paymentScreenMove();
                                                    }
                                                  }
                                              }
                                            } else {
                                                showDialog(context: context,builder: (_) => BranchCloseDialog(hours: "", minute: "", status: false, width: width!, height: height!));
                                            }
                                          }
                                          if (state is IsOrderDeliverableFailure) {
                                            UiUtils.setSnackBar(state.errorMessage, context, false, type: "2");
                                          }
                                        },
                                        child: BlocBuilder<DeliveryChargeCubit, DeliveryChargeState>(
                                          bloc: context.read<DeliveryChargeCubit>(),
                                          builder: (context, state) {
                                            if (state is DeliveryChargeProgress) {
                                              return ButtonSimmer(width: width!, height: height!);
                                            }
                                            return ButtonContainer(
                                              color: Theme.of(context).colorScheme.primary,
                                              height: height,
                                              width: width,
                                              text: (getCartstate is GetCartSuccess) ? UiUtils.getTranslatedLabel(context, confirmOrderLabel) : UiUtils.getTranslatedLabel(context, browseMenuLabel),
                                              start: width! / 40.0,
                                              end: width! / 40.0,
                                              bottom: height! / 55.0,
                                              top: 0,
                                              status: false,
                                              borderColor: Theme.of(context).colorScheme.primary,
                                              textColor: Theme.of(context).colorScheme.onPrimary,
                                              onPressed: () {
                                                if (getCartstate is GetCartSuccess) {
                                                  if (orderTypeIndex == 0) {
                                                    context.read<IsOrderDeliverableCubit>().fetchIsOrderDeliverable(context.read<SettingsCubit>().getSettings().branchId,
                                                      latitude.toString(),
                                                      longitude.toString(),
                                                      selAddress);
                                                  } else {
                                                      if ((context.read<AuthCubit>().getType() == "google")) {
                                                        if (context.read<AuthCubit>().getMobile().isEmpty) {
                                                          addPhoneNumberBottomSheet();
                                                        } else {
                                                            paymentScreenMove();
                                                        }
                                                      } else {
                                                          paymentScreenMove();
                                                      }
                                                  }
                                                } else {
                                                    moveFirstScreen();
                                                }
                                              },
                                            );
                                          }),
                                        );
                                      });
                                    });
                                  }),
                                );
                              }
                            }
                            return (state is GetCartProgress)
                                ? ButtonSimmer(height: height, width: width)
                                : BlocConsumer<GetCartCubit, GetCartState>(
                                    bloc: context.read<GetCartCubit>(),
                                    listener: (context, state) {},
                                    builder: (context, state) {
                                      return ButtonContainer(
                                        color: Theme.of(context).colorScheme.primary,
                                        height: height,
                                        width: width,
                                        text: (state is GetCartSuccess) ? UiUtils.getTranslatedLabel(context, confirmOrderLabel) : UiUtils.getTranslatedLabel(context, browseMenuLabel),
                                        start: width! / 40.0,
                                        end: width! / 40.0,
                                        bottom: height! / 55.0,
                                        top: 0,
                                        status: false,
                                        borderColor: Theme.of(context).colorScheme.primary,
                                        textColor: Theme.of(context).colorScheme.onPrimary,
                                        onPressed: () {
                                          if (state is GetCartSuccess) {
                                            if (orderTypeIndex == 0) {
                                              context.read<IsOrderDeliverableCubit>().fetchIsOrderDeliverable(
                                                context.read<SettingsCubit>().getSettings().branchId,
                                                latitude.toString(),
                                                longitude.toString(),
                                                selAddress);
                                            } else {
                                              if ((context.read<AuthCubit>().getType() == "google")) {
                                                if (context.read<AuthCubit>().getMobile().isEmpty) {
                                                  addPhoneNumberBottomSheet();
                                                } else {
                                                  paymentScreenMove();
                                                }
                                              } else {
                                                paymentScreenMove();
                                              }
                                            }
                                          } else {
                                            moveFirstScreen();
                                          }
                                        },
                                      );
                                    });
                          });
                }),
                body: RefreshIndicator(
                  onRefresh: refreshList,
                  color: Theme.of(context).colorScheme.primary,
                  child: Container(width: width, height: height!, child: cartData()),
                ),
              ));
  }
}
