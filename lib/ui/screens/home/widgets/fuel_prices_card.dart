import 'package:eClassify/data/cubits/fuel_prices/fetch_fuel_prices_cubit.dart';
import 'package:eClassify/data/model/fuel_price_model.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FuelPricesSection extends StatelessWidget {
  const FuelPricesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchFuelPricesCubit, FetchFuelPricesState>(
      builder: (context, state) {
        if (state is FetchFuelPricesSuccess) {
          return FuelPricesCard(fuelPrices: state.fuelPrices);
        }
        if (state is FetchFuelPricesFailure) {
          return _FuelPricesError(
            message: state.message,
            onRetry: context.read<FetchFuelPricesCubit>().fetch,
          );
        }
        return const _FuelPricesLoading();
      },
    );
  }
}

class FuelPricesCard extends StatelessWidget {
  const FuelPricesCard({required this.fuelPrices, super.key});

  final FuelPriceModel fuelPrices;

  @override
  Widget build(BuildContext context) {
    final prices = <_FuelPriceRow>[
      _FuelPriceRow('Petrol (Super)', fuelPrices.petrolSuper),
      _FuelPriceRow('High Octane', fuelPrices.highOctane),
      _FuelPriceRow('High Speed Diesel', fuelPrices.highSpeedDiesel),
      _FuelPriceRow('LPG', fuelPrices.lpg),
      _FuelPriceRow('Kerosene Oil', fuelPrices.keroseneOil),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Current Fuel Prices',
            fontSize: context.font.larger,
            fontWeight: FontWeight.w700,
          ),
          if (fuelPrices.createdDate.isNotEmpty) ...[
            4.vGap,
            CustomText(
              'Last updated ${fuelPrices.createdDate.formatDate(format: 'd MMM, yyyy')}',
              fontSize: context.font.small,
              color: context.color.textLightColor,
            ),
          ],
          16.vGap,
          const _TableHeader(),
          ...prices.map((price) => _PriceRow(item: price)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.color.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              'Type',
              fontSize: context.font.normal,
              color: context.color.textLightColor,
            ),
          ),
          CustomText(
            'Price Per Liter',
            fontSize: context.font.normal,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.item});

  final _FuelPriceRow item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              item.label,
              fontSize: context.font.normal,
              maxLines: 1,
            ),
          ),
          12.hGap,
          CustomText(
            'PKR ',
            fontSize: context.font.small,
            color: context.color.textLightColor,
          ),
          CustomText(
            item.price,
            fontSize: context.font.large,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class _FuelPriceRow {
  const _FuelPriceRow(this.label, this.price);

  final String label;
  final String price;
}

class _FuelPricesLoading extends StatelessWidget {
  const _FuelPricesLoading();

  @override
  Widget build(BuildContext context) {
    return const CustomShimmer(
      height: 330,
      width: double.infinity,
      borderRadius: 16,
      margin: EdgeInsets.only(top: 14, bottom: 10),
    );
  }
}

class _FuelPricesError extends StatelessWidget {
  const _FuelPricesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        children: [
          CustomText(
            message,
            fontSize: context.font.normal,
            textAlign: TextAlign.center,
            color: context.color.textLightColor,
          ),
          10.vGap,
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
