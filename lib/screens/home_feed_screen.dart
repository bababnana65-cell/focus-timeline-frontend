import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_mark.dart';
import 'recommendations_screen.dart';
import 'tracked_topics_screen.dart';

enum _HomeFeedSection {
  following('关注', Icons.bookmark_border_rounded),
  recommended('推荐', Icons.auto_awesome_rounded),
  hot('热门', Icons.trending_up_rounded),
  explore('探索', Icons.explore_outlined),
  history('历史', Icons.history_rounded);

  const _HomeFeedSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({
    super.key,
    required this.controller,
    required this.onOpenTopic,
    required this.onShareTrackedTopic,
    required this.onToggleTrackedPin,
    required this.onUnfollowTrackedTopic,
  });

  final TimelineController controller;
  final Future<void> Function(Topic topic) onOpenTopic;
  final Future<void> Function(Topic topic) onShareTrackedTopic;
  final Future<void> Function(Topic topic) onToggleTrackedPin;
  final Future<void> Function(Topic topic) onUnfollowTrackedTopic;

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with AutomaticKeepAliveClientMixin<HomeFeedScreen> {
  late _HomeFeedSection _section;
  late final TextEditingController _searchController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _section = widget.controller.isGuest
        ? _HomeFeedSection.hot
        : _HomeFeedSection.following;
    _searchController = TextEditingController(text: _currentSearchValue());
    _applySectionMode(_section);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final currentSearch = _currentSearchValue();
        if (_searchController.text != currentSearch) {
          _searchController.value = TextEditingValue(
            text: currentSearch,
            selection: TextSelection.collapsed(offset: currentSearch.length),
          );
        }

        return NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.pageHorizontalPadding,
                    10,
                    AppTheme.pageHorizontalPadding,
                    4,
                  ),
                  child: _HomeMasthead(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pageHorizontalPadding,
                    8,
                    AppTheme.pageHorizontalPadding,
                    10,
                  ),
                  child: _HomeSearchField(
                    controller: _searchController,
                    onChanged: _setSearchQuery,
                  ),
                ),
              ),
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeSectionHeaderDelegate(
                    section: _section,
                    onChanged: _selectSection,
                  ),
                ),
              ),
            ];
          },
          body: Builder(
            builder: (context) {
              final overlapInjector = SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              );
              return _section == _HomeFeedSection.following
                  ? TrackedTopicsFeed(
                      controller: widget.controller,
                      onOpenTopic: widget.onOpenTopic,
                      onShareTopic: widget.onShareTrackedTopic,
                      onTogglePinTopic: widget.onToggleTrackedPin,
                      onUnfollowTopic: widget.onUnfollowTrackedTopic,
                      topPadding: 12,
                      leadingSlivers: <Widget>[overlapInjector],
                    )
                  : RecommendationsFeed(
                      controller: widget.controller,
                      onOpenTopic: widget.onOpenTopic,
                      topPadding: 12,
                      leadingSlivers: <Widget>[overlapInjector],
                    );
            },
          ),
        );
      },
    );
  }

  String _currentSearchValue() {
    return _section == _HomeFeedSection.following
        ? widget.controller.trackedTopicSearchQuery
        : widget.controller.recommendationSearchQuery;
  }

  void _setSearchQuery(String value) {
    if (_section == _HomeFeedSection.following) {
      widget.controller.setTrackedTopicSearchQuery(value);
    } else {
      widget.controller.setRecommendationSearchQuery(value);
    }
  }

  void _selectSection(_HomeFeedSection section) {
    if (_section == section) {
      return;
    }
    setState(() {
      _section = section;
    });
    _applySectionMode(section);
  }

  void _applySectionMode(_HomeFeedSection section) {
    switch (section) {
      case _HomeFeedSection.following:
        break;
      case _HomeFeedSection.recommended:
        widget.controller.showPersonalizedRecommendations();
        break;
      case _HomeFeedSection.hot:
        widget.controller.showHotRecommendations();
        break;
      case _HomeFeedSection.explore:
        widget.controller.showExploreRecommendations();
        break;
      case _HomeFeedSection.history:
        widget.controller.showHistoryRecommendations();
        break;
    }
  }
}

class _HomeMasthead extends StatelessWidget {
  const _HomeMasthead();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayLabel = DateFormat('EEE', 'en_US').format(now).toUpperCase();
    final dateLabel = DateFormat('MM/dd').format(now);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const BrandLogoMark(size: 30, radius: 7),
        const SizedBox(width: 10),
        Text(
          '焦点时轴',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.05,
                height: 1.1,
              ),
        ),
        const Spacer(),
        Text(
          '$dayLabel · $dateLabel',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
        ),
      ],
    );
  }
}

class _HomeSearchField extends StatelessWidget {
  const _HomeSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索专题',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: AppTheme.surfaceMuted,
          hintStyle: const TextStyle(color: AppTheme.textTertiary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            borderSide: const BorderSide(color: AppTheme.accent, width: 1.3),
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _HomeSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeSectionHeaderDelegate({
    required this.section,
    required this.onChanged,
  });

  final _HomeFeedSection section;
  final ValueChanged<_HomeFeedSection> onChanged;

  @override
  double get minExtent => 57;

  @override
  double get maxExtent => 57;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.98),
          border: const Border(
            bottom: BorderSide(color: AppTheme.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pageHorizontalPadding,
            6,
            AppTheme.pageHorizontalPadding,
            8,
          ),
          child: _HomeSectionTabs(
            section: section,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeSectionHeaderDelegate oldDelegate) {
    return oldDelegate.section != section || oldDelegate.onChanged != onChanged;
  }
}

class _HomeSectionTabs extends StatelessWidget {
  const _HomeSectionTabs({
    required this.section,
    required this.onChanged,
  });

  final _HomeFeedSection section;
  final ValueChanged<_HomeFeedSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _HomeFeedSection.values.map((item) {
        return Expanded(
          child: _HomeSectionTabButton(
            item: item,
            selected: section == item,
            onPressed: () => onChanged(item),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _HomeSectionTabButton extends StatelessWidget {
  const _HomeSectionTabButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _HomeFeedSection item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final contentColor =
        selected ? AppTheme.textPrimary : AppTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          height: 34,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(item.icon, size: 13, color: contentColor),
                  const SizedBox(width: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: contentColor,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          height: 1,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
