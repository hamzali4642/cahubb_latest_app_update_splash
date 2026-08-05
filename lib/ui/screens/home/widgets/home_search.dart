import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/category/fetch_category_cubit.dart';
import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/item/item_filter.dart';
import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSearchField extends StatefulWidget {
  const HomeSearchField({super.key});

  @override
  State<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<HomeSearchField> {
  static const List<_HomeQuickFilter> _quickFilters = [
    _HomeQuickFilter(
      title: 'Motors',
      hint: 'Search for Motors',
      searchKeyword: 'motors',
      cards: [
        _QuickCardData(
          title: 'Cars',
          label: 'Cars',
          icon: Icons.directions_car_filled_outlined,
          searchKeyword: 'car',
        ),
        _QuickCardData(
          title: 'Bikes',
          label: 'Bikes',
          icon: Icons.two_wheeler_outlined,
          searchKeyword: 'bike',
        ),
        _QuickCardData(
          title: 'Spare Parts',
          label: 'Spare',
          icon: Icons.build_circle_outlined,
          searchKeyword: 'spare parts',
        ),
        _QuickCardData(
          title: 'Trucks',
          label: 'Trucks',
          icon: Icons.local_shipping_outlined,
          searchKeyword: 'truck',
        ),
      ],
    ),
    _HomeQuickFilter(
      title: 'Electronics',
      hint: 'Search for Electronics',
      searchKeyword: 'electronics',
      cards: [
        _QuickCardData(
          title: 'Mobile Phones',
          label: 'Mobiles',
          icon: Icons.smartphone,
          searchKeyword: 'mobile',
        ),
        _QuickCardData(
          title: 'Laptops',
          label: 'Laptops',
          icon: Icons.laptop_mac,
          searchKeyword: 'laptop',
        ),
        _QuickCardData(
          title: 'Appliances',
          label: 'Home',
          icon: Icons.kitchen_outlined,
          searchKeyword: 'appliance',
        ),
        _QuickCardData(
          title: 'Cameras',
          label: 'Cameras',
          icon: Icons.photo_camera_outlined,
          searchKeyword: 'camera',
        ),
      ],
    ),
    _HomeQuickFilter(
      title: 'Property',
      hint: 'Search for Property',
      searchKeyword: 'property',
      cards: [
        _QuickCardData(
          title: 'Houses',
          label: 'Houses',
          icon: Icons.home_work_outlined,
          searchKeyword: 'house',
        ),
        _QuickCardData(
          title: 'Plots',
          label: 'Plots',
          icon: Icons.terrain_outlined,
          searchKeyword: 'plot',
        ),
        _QuickCardData(
          title: 'Shops',
          label: 'Shops',
          icon: Icons.storefront_outlined,
          searchKeyword: 'shop',
        ),
        _QuickCardData(
          title: 'Apartments',
          label: 'Apartments',
          icon: Icons.apartment_outlined,
          searchKeyword: 'apartment',
        ),
      ],
    ),
  ];

  int _selectedIndex = 0;

  void _openSearch(
    BuildContext context, {
    _HomeQuickFilter? filter,
    _QuickCardData? card,
  }) {
    final selectedFilter = filter ?? _quickFilters[_selectedIndex];
    final categoryState = context.read<FetchCategoryCubit>().state;
    if (categoryState is! FetchCategorySuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categories are still loading. Try again.'),
        ),
      );
      return;
    }

    final parentMatch = _findCategory(categoryState.categories, {
      selectedFilter.title,
      ?selectedFilter.searchKeyword,
    }, rootOnly: true);
    if (parentMatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedFilter.title} is unavailable.')),
      );
      return;
    }

    final childMatch = card == null
        ? null
        : _findCategory(parentMatch.category.children ?? const [], {
            card.title,
            card.label,
            card.searchKeyword,
          }, prefixPath: parentMatch.path);
    final selectedMatch = childMatch ?? parentMatch;

    Navigator.pushNamed(
      context,
      Routes.itemsList,
      arguments: CategoryMetaData(
        title: card?.title ?? selectedFilter.title,
        categoryId: selectedMatch.category.id.toString(),
        categoryIds: selectedMatch.path
            .map((category) => category.id.toString())
            .toList(),
        filter: ItemFilter(category: selectedMatch.category),
        // If a matching child is not configured by the API, retain the
        // selected parent category while applying the card keyword.
        search: card != null && childMatch == null ? card.searchKeyword : null,
      ),
    );
  }

  _CategoryMatch? _findCategory(
    List<CategoryModel> categories,
    Set<String> candidates, {
    bool rootOnly = false,
    List<CategoryModel> prefixPath = const [],
  }) {
    final normalizedCandidates = candidates.map(_normalize).toSet();
    for (final category in categories) {
      final name = _normalize(category.name ?? '');
      if (normalizedCandidates.contains(name)) {
        return _CategoryMatch(category, [...prefixPath, category]);
      }
    }

    if (rootOnly) return null;
    for (final category in categories) {
      final match = _findCategory(
        category.children ?? const [],
        normalizedCandidates,
        prefixPath: [...prefixPath, category],
      );
      if (match != null) return match;
    }
    return null;
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final selectedFilter = _quickFilters[_selectedIndex];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -12),
                  child: child,
                ),
              );
            },
            child: Row(
              children: List.generate(
                _quickFilters.length,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: index == _quickFilters.length - 1 ? 0 : 8,
                    ),
                    child: _FilterButton(
                      title: _quickFilters[index].title,
                      isSelected: index == _selectedIndex,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        _openSearch(context, filter: _quickFilters[index]);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _openSearch(context),
                  child: IgnorePointer(
                    ignoring: true,
                    child: TextField(
                      autofocus: false,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.color.textLightColor,
                          ),
                        ),
                        hintText: selectedFilter.hint,
                        hintStyle: TextStyle(
                          color: context.color.textLightColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.color.territoryColor,
                        ),
                        prefixIconConstraints: BoxConstraints.tight(
                          const Size.square(38),
                        ),
                        constraints: const BoxConstraints(maxHeight: 48),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: context.color.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: context.color.borderColor),
                ),
                child: InkWell(
                  onTap: () {
                    UiUtils.checkUser(
                      onNotGuest: () {
                        Navigator.pushNamed(context, Routes.favoritesScreen);
                      },
                      context: context,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.favorite_outline,
                      color: context.color.textDefaultColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: ListView.separated(
                key: ValueKey(selectedFilter.title),
                itemCount: selectedFilter.cards.length,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final card = selectedFilter.cards[index];
                  return _QuickProductCard(
                    card: card,
                    onTap: () => _openSearch(context, card: card),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryMatch {
  const _CategoryMatch(this.category, this.path);

  final CategoryModel category;
  final List<CategoryModel> path;
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBackgroundColor = context.color.territoryColor;
    final selectedTextColor = selectedBackgroundColor.computeLuminance() > 0.9
        ? territoryColor_
        : Colors.white;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      scale: isSelected ? 1.0 : 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? context.color.territoryColor
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : context.color.borderColor.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.18 : 0.06),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? selectedTextColor
                        : context.color.textDefaultColor,
                    fontSize: context.font.normal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeQuickFilter {
  const _HomeQuickFilter({
    required this.title,
    required this.hint,
    required this.cards,
    this.searchKeyword,
  });

  final String title;
  final String hint;
  final String? searchKeyword;
  final List<_QuickCardData> cards;
}

class _QuickCardData {
  const _QuickCardData({
    required this.title,
    required this.label,
    required this.icon,
    required this.searchKeyword,
  });

  final String title;
  final String label;
  final IconData icon;
  final String searchKeyword;
}

class _QuickProductCard extends StatelessWidget {
  const _QuickProductCard({required this.card, required this.onTap});

  final _QuickCardData card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: card.title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 90,
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.color.borderColor.withValues(alpha: 0.9),
              ),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  context.color.secondaryColor,
                  context.color.secondaryColor.withValues(alpha: 0.86),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.color.territoryColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    card.icon,
                    size: 21,
                    color: context.color.territoryColor,
                  ),
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    card.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.font.small - 1,
                      fontWeight: FontWeight.w600,
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
