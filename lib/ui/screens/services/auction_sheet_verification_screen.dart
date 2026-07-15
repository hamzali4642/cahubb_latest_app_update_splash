import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class AuctionSheetVerificationScreen extends StatefulWidget {
  const AuctionSheetVerificationScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuctionSheetVerificationScreen(),
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
  void dispose() {
    _chassisController.dispose();
    super.dispose();
  }

  void _verifyAuctionSheet() {
    if (_chassisController.text.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(context, 'Please enter chassis number.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AuctionSheetNotifySheet(
          chassisNumber: _chassisController.text.trim(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onVerify: _verifyAuctionSheet,
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
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              color: Colors.white.withValues(alpha: 0.92),
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
            color: const Color(0xFFEAF3FF),
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
  const _AuctionInputCard({required this.controller, required this.onVerify});

  final TextEditingController controller;
  final VoidCallback onVerify;

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
          Center(
            child: CustomText(
              'PKR 2,950 · Delivered in minutes',
              fontSize: context.font.small,
              color: context.color.textLightColor,
            ),
          ),
        ],
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
              color: const Color(0xFFF7F9FE),
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
  const _AuctionSheetNotifySheet({required this.chassisNumber});

  final String chassisNumber;

  @override
  State<_AuctionSheetNotifySheet> createState() =>
      _AuctionSheetNotifySheetState();
}

class _AuctionSheetNotifySheetState extends State<_AuctionSheetNotifySheet> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (HiveUtils.isUserAuthenticated()) {
      _phoneController.text = HiveUtils.getUserDetails().mobile ?? '';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _notifyMe() {
    if (_phoneController.text.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(context, 'Please enter phone number.');
      return;
    }

    Navigator.of(context).pop();
    HelperUtils.showSnackBarMessage(
      context,
      'Auction sheet alert saved for ${widget.chassisNumber}. Backend will be connected next.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 56),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  colors: [Color(0xFF2C4A8A), Color(0xFF2A67D7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
            Transform.translate(
              offset: const Offset(0, -34),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A67D7), width: 8),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 42,
                  color: Color(0xFFF6B81A),
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
