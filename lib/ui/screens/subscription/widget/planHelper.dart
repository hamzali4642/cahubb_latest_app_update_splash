import 'package:eClassify/data/cubits/subscription/assign_free_package_cubit.dart';
import 'package:eClassify/data/cubits/subscription/get_payment_intent_cubit.dart';
import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/payment/payment_settings.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanHelper {
  Widget purchaseButtonWidget(
    BuildContext mainContext,
    SubscriptionPackageModel plan,
    String? selectedGateway, {
    Function? changePaymentGateway,
    String? btnTitle,
  }) {
    return BlocConsumer<GetPaymentIntentCubit, GetPaymentIntentState>(
      bloc: mainContext.read<GetPaymentIntentCubit>(),
      listener: (context, state) {
        if (selectedGateway == Constant.paymentTypeBankTransfer) {
          return;
        }
        if (state is GetPaymentIntentInSuccess) {
          showHideLoaderWithMsg(false, context);
        } else if (state is GetPaymentIntentFailure) {
          showHideLoaderWithMsg(false, context, msg: state.error.toString());
        } else if (state is GetPaymentIntentInProgress) {
          showHideLoaderWithMsg(true, context);
        }
      },
      builder: (context, state) {
        return BlocListener<AssignFreePackageCubit, AssignFreePackageState>(
          bloc: mainContext.read<AssignFreePackageCubit>(),
          listener: (context, state) {
            if (state is AssignFreePackageInSuccess) {
              showHideLoaderWithMsg(false, context, msg: state.responseMessage);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } else if (state is AssignFreePackageFailure) {
              showHideLoaderWithMsg(
                false,
                context,
                msg: state.error.toString(),
              );
            } else if (state is AssignFreePackageInProgress) {
              showHideLoaderWithMsg(true, context);
            }
          },
          child: UiUtils.buildButton(
            context,
            onPressed: () {
              UiUtils.checkUser(
                onNotGuest: () {
                  if (!plan.isActive!) {
                    if (plan.finalPrice! > 0) {
                      paymentGatewayBottomSheet(
                        mainContext,
                        selectedGateway,
                        plan.id!,
                      ).then((value) {
                        if (value != null && changePaymentGateway != null) {
                          changePaymentGateway(value);
                        }
                      });
                    } else {
                      mainContext
                          .read<AssignFreePackageCubit>()
                          .assignFreePackage(packageId: plan.id!);
                    }
                  }
                },
                context: context,
              );
            },
            radius: 10,
            height: 46,
            fontSize: context.font.large,
            buttonColor: plan.isActive!
                ? context.color.textLightColor.withValues(alpha: 0.01)
                : context.color.territoryColor,
            textColor: plan.isActive!
                ? context.color.textDefaultColor.withValues(alpha: 0.5)
                : context.color.secondaryColor,
            buttonTitle:
                btnTitle ??
                (plan.finalPrice! > 0
                    ? "${"payLbl".translate(context)}\t${plan.formattedFinalPrice ?? plan.finalPrice!.currencyFormat}"
                    : "purchaseThisPackage".translate(context)),
            outerPadding: const EdgeInsets.all(20),
          ),
        );
      },
    );
  }

  void showHideLoaderWithMsg(bool isShow, BuildContext context, {String? msg}) {
    isShow
        ? LoadingWidgets.showLoader(context)
        : LoadingWidgets.hideLoader(context);
    if (msg != null) {
      HelperUtils.showSnackBarMessage(context, msg);
    }
  }

  String getSelectedPaymentMethod(String? selectedGateway) {
    return switch (selectedGateway) {
      Constant.paymentTypeBankTransfer => "bankTransfer",
      _ => "",
    };
  }

  Future<void> fetchBankDetailsAndShowDialog(
    BuildContext mcontext,
    int packageId,
  ) async {
    showDialog(
      context: mcontext,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: CustomText(
          'bankAccountDetails'.translate(mcontext),
          fontWeight: FontWeight.bold,
        ),
        content: BlocListener<GetPaymentIntentCubit, GetPaymentIntentState>(
          bloc: mcontext.read<GetPaymentIntentCubit>(),
          listener: (context, state) {
            if (state is GetPaymentIntentInSuccess) {
              Navigator.pop(context);
              showHideLoaderWithMsg(
                false,
                context,
                msg: state.message.toString(),
              );
            } else if (state is GetPaymentIntentInProgress) {
              showHideLoaderWithMsg(true, context);
            } else if (state is GetPaymentIntentFailure) {
              Navigator.pop(context);
              showHideLoaderWithMsg(
                false,
                context,
                msg: state.error.toString(),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'pleaseTransferAmountToFollowingBank'.translate(mcontext),
                fontSize: 14,
              ),
              _buildDetailField(
                mcontext,
                'accountHolder'.translate(mcontext),
                PaymentSettings.bankAccountHolderName,
              ),
              _buildDetailField(
                mcontext,
                'accountNumber'.translate(mcontext),
                PaymentSettings.bankAccountNumber,
              ),
              _buildDetailField(
                mcontext,
                'bankName'.translate(mcontext),
                PaymentSettings.bankName,
              ),
              _buildDetailField(
                mcontext,
                'swiftIfscCode'.translate(mcontext),
                PaymentSettings.bankIfscSwiftCode,
              ),
              Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  UiUtils.buildButton(
                    mcontext,
                    height: 42,
                    radius: 8,
                    fontSize: 14,
                    width: mcontext.screenWidth / 4,
                    showElevation: false,
                    onPressed: () {
                      Navigator.pop(mcontext);
                    },
                    buttonTitle: "cancel".translate(mcontext),
                    buttonColor: mcontext.color.textDefaultColor,
                    textColor: mcontext.color.secondaryColor,
                  ),
                  Expanded(
                    child: UiUtils.buildButton(
                      mcontext,
                      height: 42,
                      radius: 8,
                      fontSize: 14,
                      showElevation: false,
                      width: mcontext.screenWidth / 4,
                      onPressed: () {
                        mcontext.read<GetPaymentIntentCubit>().getPaymentIntent(
                          paymentMethod: "bankTransfer",
                          packageId: packageId,
                        );
                      },
                      buttonTitle: "confirmPayment".translate(mcontext),
                      buttonColor: mcontext.color.territoryColor,
                      textColor: mcontext.color.secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(BuildContext context, String label, String value) {
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.color.textDefaultColor,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.color.backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: CustomText(
            value,
            fontSize: 14,
            color: context.color.textDefaultColor,
          ),
        ),
      ],
    );
  }

  Future<String?> paymentGatewayBottomSheet(
    BuildContext context,
    String? mselectedGateway,
    int pkgid,
  ) async {
    List<PaymentGateway> enabledGateways =
        PaymentSettings.getEnabledPaymentGateways();

    if (enabledGateways.isEmpty) {
      return null;
    }

    String? selectedGateway = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0),
          topRight: Radius.circular(18.0),
        ),
      ),
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: false,
      builder: (BuildContext context) {
        String? _localSelectedGateway = mselectedGateway;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  children: [
                    CustomText(
                      'selectPaymentMethod'.translate(context),
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.larger,
                      color: context.color.textDefaultColor,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 15),
                      itemCount: enabledGateways.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return PaymentMethodTile(
                          gateway: enabledGateways[index],
                          isSelected:
                              _localSelectedGateway ==
                              enabledGateways[index].type,
                          onSelect: (String? value) {
                            setState(() {
                              _localSelectedGateway = value;
                            });
                            Navigator.pop(
                              context,
                              value,
                            ); // Return the selected value
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedGateway != null) {
      processForPaymentGateway(context, selectedGateway, pkgid);
    }
    return selectedGateway;
  }

  void processForPaymentGateway(
    BuildContext context,
    String selectedPaymentGateway,
    int pkgId,
  ) {
    if (selectedPaymentGateway == Constant.paymentTypeBankTransfer) {
      fetchBankDetailsAndShowDialog(context, pkgId);
    } else {
      context.read<GetPaymentIntentCubit>().getPaymentIntent(
        paymentMethod: getSelectedPaymentMethod(selectedPaymentGateway),
        packageId: pkgId,
      );
    }
  }
}

class PaymentMethodTile extends StatelessWidget {
  final PaymentGateway gateway;
  final bool isSelected;
  final ValueChanged<String?> onSelect;

  PaymentMethodTile({
    required this.gateway,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UiUtils.getSvg(
        gatewayIcon(gateway.type),
        width: 23,
        height: 23,
        fit: BoxFit.contain,
      ),
      title: CustomText(gateway.name),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: context.color.territoryColor)
          : Icon(
              Icons.radio_button_unchecked,
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
            ),
      onTap: () => onSelect(gateway.type),
    );
  }

  String gatewayIcon(String type) {
    switch (type) {
      case Constant.paymentTypeBankTransfer:
        return AppIcons.bankTransferIcon;
      default:
        return "";
    }
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path
      ..moveTo(size.width / 2, 0) // moving to topCenter 1st, then draw the path
      ..lineTo(size.width, size.height * .25)
      ..lineTo(size.width, size.height * .75)
      ..lineTo(size.width * .5, size.height)
      ..lineTo(0, size.height * .75)
      ..lineTo(0, size.height * .25)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class CapShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.15,
        size.height,
        size.width * 0.1,
        size.height * 0.1,
        size.width * 0.25,
        size.height * 0.1,
      )
      ..lineTo(size.width * 0.75, size.height * 0.1)
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.1,
        size.width * 0.85,
        size.height,
        size.width,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
