import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/utils/platform_helper.dart';

/// A navigation destination for the desktop shell
class DesktopNavDestination {
  const DesktopNavDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The main destinations in the app
const _destinations = [
  DesktopNavDestination(
    path: '/',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  DesktopNavDestination(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

/// An adaptive shell that provides desktop-style navigation on desktop/web
/// and passes through the child directly on mobile
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  final Widget child;
  final String currentPath;

  int get _selectedIndex {
    // Match the current path to find the index
    for (int i = 0; i < _destinations.length; i++) {
      if (_destinations[i].path == currentPath) {
        return i;
      }
    }
    // Default to dashboard if path not found
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On mobile, just return the child directly
    if (PlatformHelper.isMobile) {
      return child;
    }

    // On desktop/web, use LayoutBuilder to be responsive
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          // Narrow desktop window - use bottom navigation
          return _MobileLayoutShell(
            currentPath: currentPath,
            selectedIndex: _selectedIndex,
            child: child,
          );
        }

        // Wide desktop - use rail or full sidebar
        final isExpanded = constraints.maxWidth >= 1200;

        return _DesktopLayoutShell(
          currentPath: currentPath,
          selectedIndex: _selectedIndex,
          isExpanded: isExpanded,
          child: child,
        );
      },
    );
  }
}

/// Desktop layout with navigation rail or sidebar
class _DesktopLayoutShell extends ConsumerWidget {
  const _DesktopLayoutShell({
    required this.currentPath,
    required this.selectedIndex,
    required this.isExpanded,
    required this.child,
  });

  final String currentPath;
  final int selectedIndex;
  final bool isExpanded;
  final Widget child;

  void _onDestinationSelected(BuildContext context, int index) {
    final destination = _destinations[index];
    if (destination.path != currentPath) {
      context.go(destination.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Navigation rail or sidebar
          if (isExpanded)
            _ExpandedSidebar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
            )
          else
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: colorScheme.surfaceContainerLow,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SvgPicture.asset(
                  'assets/images/nutrinutri.svg',
                  height: 36,
                ),
              ),
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Expanded sidebar for very wide screens
class _ExpandedSidebar extends StatelessWidget {
  const _ExpandedSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 250,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App branding
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/nutrinutri.svg', height: 40),
                const SizedBox(width: 12),
                Text(
                  'NutriNutri',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Navigation items
          ..._destinations.asMap().entries.map((entry) {
            final index = entry.key;
            final destination = entry.value;
            final isSelected = index == selectedIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onDestinationSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? destination.selectedIcon
                              : destination.icon,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          destination.label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Version or footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'NutriNutri v1.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile/narrow layout with bottom navigation
class _MobileLayoutShell extends StatelessWidget {
  const _MobileLayoutShell({
    required this.currentPath,
    required this.selectedIndex,
    required this.child,
  });

  final String currentPath;
  final int selectedIndex;
  final Widget child;

  void _onDestinationSelected(BuildContext context, int index) {
    final destination = _destinations[index];
    if (destination.path != currentPath) {
      context.go(destination.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}
