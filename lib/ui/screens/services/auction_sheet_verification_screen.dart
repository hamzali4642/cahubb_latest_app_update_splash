import 'package:eClassify/data/cubits/service/auction_sheet_verification_cubit.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AuctionSheetVerificationScreen extends StatefulWidget {
  const AuctionSheetVerificationScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => BlocProvider(
        create: (_) => AuctionSheetVerificationCubit()..initialize(),
        child: const AuctionSheetVerificationScreen(),
      ),
    );
  }

  @override
  State<AuctionSheetVerificationScreen> createState() =>
      _AuctionSheetVerificationScreenState();
}

class _AuctionSheetVerificationScreenState
    extends State<AuctionSheetVerificationScreen> {
  final TextEditingController _chassisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuctionSheetVerificationCubit>();
    _chassisController.text = cubit.state.chassisNumber;
    _chassisController.addListener(() {
      cubit.updateChassisNumber(_chassisController.text);
    });
  }

  @override
  void dispose() {
    _chassisController.dispose();
    super.dispose();
  }

  Future<void> _verifyAuctionSheet() async {
    final cubit = context.read<AuctionSheetVerificationCubit>();
    if (!cubit.requestVerification()) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocProvider.value(
          value: cubit,
          child: const _AuctionSheetNotifySheet(),
        );
      },
    );
    if (!mounted || submitted != true) return;
    HelperUtils.showSnackBarMessage(
      context,
      'Request received. We will notify you once the auction sheet is available.',
      messageDuration: 4,
      type: MessageType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      AuctionSheetVerificationCubit,
      AuctionSheetVerificationState
    >(
      listenWhen: (previous, current) =>
          previous.feedbackToken != current.feedbackToken ||
          previous.chassisNumber != current.chassisNumber,
      listener: (context, state) {
        if (_chassisController.text != state.chassisNumber) {
          _chassisController.value = _chassisController.value.copyWith(
            text: state.chassisNumber,
            selection: TextSelection.collapsed(
              offset: state.chassisNumber.length,
            ),
            composing: TextRange.empty,
          );
        }
        final cubit = context.read<AuctionSheetVerificationCubit>();
        if (state.feedbackMessage != null) {
          HelperUtils.showSnackBarMessage(
            context,
            state.feedbackMessage!,
            type: MessageType.error,
          );
          cubit.clearFeedback();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: 'Auction Sheet Verification',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AuctionHeroSection(),
                18.vGap,
                _AuctionInputCard(
                  controller: _chassisController,
                  state: state,
                  onVerify: _verifyAuctionSheet,
                  onRetryPrice: () => context
                      .read<AuctionSheetVerificationCubit>()
                      .fetchPrice(),
                ),
                20.vGap,
                const _AuctionStatsRow(),
                28.vGap,
                const _InfoSection(
                  title: 'Three things sellers often hide',
                  subtitle:
                      'Auction sheet verification helps bring those hidden details out early.',
                  children: [
                    _InfoTile(
                      icon: Icons.speed_rounded,
                      title: 'Meter reverse',
                      description:
                          'Spot mileage inconsistencies before you commit to the car.',
                    ),
                    _InfoTile(
                      icon: Icons.gavel_rounded,
                      title: 'Fake auction sheets',
                      description:
                          'Catch edited or manipulated reports that misrepresent the grade.',
                    ),
                    _InfoTile(
                      icon: Icons.car_crash_rounded,
                      title: 'Hidden repairs',
                      description:
                          'Understand if accident work or repainting is being covered up.',
                    ),
                  ],
                ),
                28.vGap,
                const _InfoSection(
                  title: 'Why choose CA Hubb',
                  subtitle:
                      'Designed around clarity, fast turnaround, and trusted verification.',
                  children: [_FeatureGrid()],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuctionHeroSection extends StatelessWidget {
  const _AuctionHeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: serviceHeroGradient(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Japanese Car Auction Sheet Verification',
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w700,
                ),
                8.vGap,
                CustomText(
                  'Get the original report details in a cleaner, easier flow before you buy.',
                  fontSize: context.font.normal,
                  color: context.color.textLightColor,
                  height: 1.45,
                ),
                16.vGap,
                const _HeroBullet(label: 'Instant delivery'),
                10.vGap,
                const _HeroBullet(label: "Know your car's history"),
                10.vGap,
                const _HeroBullet(
                  label: 'Protection against fake auction sheets',
                ),
              ],
            ),
          ),
          12.hGap,
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: serviceImageSurface(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset('assets/images/auctionSheet.png'),
          ),
        ],
      ),
    );
  }
}

class _HeroBullet extends StatelessWidget {
  const _HeroBullet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: serviceAccentSurface(context),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 15,
            color: context.color.territoryColor,
          ),
        ),
        10.hGap,
        Expanded(
          child: CustomText(
            label,
            fontSize: context.font.normal,
            color: context.color.textDefaultColor,
          ),
        ),
      ],
    );
  }
}

class _AuctionInputCard extends StatelessWidget {
  const _AuctionInputCard({
    required this.controller,
    required this.state,
    required this.onVerify,
    required this.onRetryPrice,
  });

  final TextEditingController controller;
  final AuctionSheetVerificationState state;
  final VoidCallback onVerify;
  final VoidCallback onRetryPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Enter chassis number',
            fontSize: context.font.larger,
            fontWeight: FontWeight.w700,
          ),
          10.vGap,
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'e.g. NCP165-1234567',
              filled: true,
              fillColor: context.color.secondaryColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.color.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.color.territoryColor),
              ),
            ),
          ),
          14.vGap,
          UiUtils.buildButton(
            context,
            onPressed: onVerify,
            buttonTitle: 'Verify Auction Sheet',
            radius: 12,
            height: 52,
          ),
          10.vGap,
          _AuctionPriceLabel(state: state, onRetry: onRetryPrice),
        ],
      ),
    );
  }
}

class _AuctionPriceLabel extends StatelessWidget {
  const _AuctionPriceLabel({required this.state, required this.onRetry});

  final AuctionSheetVerificationState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isPriceLoading) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.color.territoryColor,
              ),
            ),
            8.hGap,
            CustomText(
              'Loading current price...',
              fontSize: context.font.small,
              color: context.color.textLightColor,
            ),
          ],
        ),
      );
    }

    final price = state.price;
    if (price != null) {
      final formattedAmount = NumberFormat('#,##0.##').format(price.amount);
      return Center(
        child: CustomText(
          '${price.currencyCode} $formattedAmount · Delivered in minutes',
          fontSize: context.font.small,
          color: context.color.textLightColor,
        ),
      );
    }

    return Center(
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 16, color: errorMessageColor),
              6.hGap,
              CustomText(
                'Price unavailable · Tap to retry',
                fontSize: context.font.small,
                color: errorMessageColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuctionStatsRow extends StatelessWidget {
  const _AuctionStatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _StatTile(
              icon: Icons.verified_user_outlined,
              title: '9+ years',
              subtitle: 'in service',
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatTile(
              icon: Icons.description_outlined,
              title: '100k+',
              subtitle: 'sheets reviewed',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: context.color.territoryColor, size: 22),
        10.hGap,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              title,
              fontSize: context.font.normal,
              fontWeight: FontWeight.w700,
            ),
            CustomText(
              subtitle,
              fontSize: context.font.small,
              color: context.color.textLightColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: context.color.borderColor);
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: context.font.extraLarge,
          fontWeight: FontWeight.w700,
        ),
        6.vGap,
        CustomText(
          subtitle,
          fontSize: context.font.normal,
          color: context.color.textLightColor,
        ),
        14.vGap,
        ...children.expand((child) => [child, 12.vGap]).toList()..removeLast(),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: serviceMutedSurface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.color.territoryColor),
          ),
          14.hGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: context.font.normal,
                  fontWeight: FontWeight.w600,
                  color: context.color.textLightColor,
                ),
                6.vGap,
                CustomText(
                  description,
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        title: 'No conflict of interest',
        description:
            'Built to verify the sheet itself, not to push a car sale.',
      ),
      (
        title: 'Direct from source',
        description: 'A cleaner way to understand the original auction record.',
      ),
      (
        title: 'Fast delivery',
        description:
            'Request now and get notified the moment the record is available.',
      ),
      (
        title: 'Clearer buying decisions',
        description: 'Know what to ask the seller before you move further.',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                item.title,
                fontSize: context.font.large,
                fontWeight: FontWeight.w700,
              ),
              10.vGap,
              Expanded(
                child: CustomText(
                  item.description,
                  fontSize: context.font.normal,
                  color: context.color.textLightColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuctionSheetNotifySheet extends StatefulWidget {
  const _AuctionSheetNotifySheet();

  @override
  State<_AuctionSheetNotifySheet> createState() =>
      _AuctionSheetNotifySheetState();
}

class _AuctionSheetNotifySheetState extends State<_AuctionSheetNotifySheet> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuctionSheetVerificationCubit>();
    _phoneController.text = cubit.state.phoneNumber;
    _phoneController.addListener(() {
      cubit.updatePhoneNumber(_phoneController.text);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _notifyMe() async {
    final shouldClose = await context
        .read<AuctionSheetVerificationCubit>()
        .notifyMe();
    if (!mounted) return;
    if (!shouldClose) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final state = context.watch<AuctionSheetVerificationCubit>().state;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      serviceSurface(
                        context,
                        lightAlpha: 0.12,
                        darkAlpha: 0.32,
                      ),
                      context.color.territoryColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 56),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: CustomText(
                          'Auction sheet update',
                          textAlign: TextAlign.center,
                          color: Colors.white,
                          fontSize: context.font.extraLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.color.territoryColor.withValues(alpha: 0.8),
                    width: 8,
                  ),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 42,
                  color: serviceWarningForeground(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Be the first to know',
                    fontSize: context.font.extraLarge,
                    fontWeight: FontWeight.w700,
                  ),
                  10.vGap,
                  CustomText(
                    'We will notify you as soon as the auction sheet becomes available for this car.',
                    fontSize: context.font.normal,
                    color: context.color.textLightColor,
                    height: 1.45,
                  ),
                  22.vGap,
                  CustomText(
                    'Phone number',
                    fontSize: context.font.larger,
                    fontWeight: FontWeight.w600,
                  ),
                  10.vGap,
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.color.secondaryColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.color.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.color.territoryColor,
                        ),
                      ),
                    ),
                  ),
                  20.vGap,
                  UiUtils.buildButton(
                    context,
                    onPressed: _notifyMe,
                    buttonTitle: 'Notify Me',
                    isInProgress: state.isSubmitting,
                    disabled: state.isSubmitting,
                    radius: 12,
                    height: 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
