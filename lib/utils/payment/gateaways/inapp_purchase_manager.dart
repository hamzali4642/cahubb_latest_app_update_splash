import 'dart:async';

import 'package:eClassify/data/cubits/subscription/in_app_purchase_cubit.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseManager {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  StreamSubscription<InAppPurchaseState>? _cubitSubscription;
  BuildContext? _context;
  String? _packageId;

  static Future<void> getPending() async {
    await _inAppPurchase.isAvailable();
  }

  void listenIAP(BuildContext context) {
    _context = context;
    _subscription ??= _inAppPurchase.purchaseStream.listen(
      _handlePurchases,
      onError: (error) {
        final context = _context;
        if (context == null || !context.mounted) {
          return;
        }
        HelperUtils.showSnackBarMessage(
          context,
          error.toString(),
          type: MessageType.error,
        );
      },
    );
    _cubitSubscription ??= context.read<InAppPurchaseCubit>().stream.listen((
      state,
    ) {
      final context = _context;
      if (context == null || !context.mounted) {
        return;
      }

      if (state is InAppPurchaseInProgress) {
        LoadingWidgets.showLoader(context);
      } else if (state is InAppPurchaseInSuccess) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(
          context,
          state.responseMessage,
          type: MessageType.success,
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (state is InAppPurchaseFailure) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(
          context,
          state.error.toString(),
          type: MessageType.error,
        );
      }
    });
  }

  Future<void> buy(String productId, String packageId) async {
    final context = _context;
    if (context == null || !context.mounted) {
      return;
    }

    _packageId = packageId;
    LoadingWidgets.showLoader(context);

    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(
          context,
          "purchaseFailed".translate(context),
          type: MessageType.error,
        );
        return;
      }

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails({productId});

      if (response.error != null || response.productDetails.isEmpty) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(
          context,
          response.error?.message ?? "purchaseFailed".translate(context),
          type: MessageType.error,
        );
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      LoadingWidgets.hideLoader(context);
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: MessageType.error,
      );
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final context = _context;
      if (context == null || !context.mounted) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        LoadingWidgets.showLoader(context);
        continue;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _completePurchase(context, purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(
          context,
          "purchaseHasBeenCanceled".translate(context),
        );
      } else if (purchase.status == PurchaseStatus.error) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(
          context,
          purchase.error?.message ?? "purchaseError".translate(context),
          type: MessageType.error,
        );
      }
    }
  }

  void _completePurchase(BuildContext context, PurchaseDetails purchase) {
    final packageId = _packageId;
    final purchaseId = purchase.purchaseID;

    if (packageId == null || purchaseId == null) {
      LoadingWidgets.hideLoader(context);
      HelperUtils.showSnackBarMessage(
        context,
        "purchaseFailed".translate(context),
        type: MessageType.error,
      );
      return;
    }

    context.read<InAppPurchaseCubit>().inAppPurchase(
      method: "in_app_purchase",
      packageId: packageId,
      paymentTransactionId: purchaseId,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _cubitSubscription?.cancel();
    _subscription = null;
    _cubitSubscription = null;
  }
}
