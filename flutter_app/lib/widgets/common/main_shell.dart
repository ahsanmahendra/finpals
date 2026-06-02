import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/dashboard', icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded, label: 'Beranda'),
    _TabItem(path: '/transactions', icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded, label: 'Transaksi'),
    _TabItem(path: '/scan', icon: Icons.qr_code_scanner_rounded,
        activeIcon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    _TabItem(path: '/budget', icon: Icons.pie_chart_outline_rounded,
        activeIcon: Icons.pie_chart_rounded, label: 'Budget'),
    _TabItem(path: '/profile', icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  int _currentIndex(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _FinpalsNavBar(
        currentIndex: currentIndex,
        tabs: _tabs,
        onTap: (i) {
          if (i != currentIndex) context.go(_tabs[i].path);
        },
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Custom bottom nav with FAB-style scan button ──
class _FinpalsNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final void Function(int) onTap;

  const _FinpalsNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;
              final isScan = i == 2; // center button

              if (isScan) {
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emerald400, AppColors.emerald600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald500.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.emerald50
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        color: isActive
                            ? AppColors.emerald500
                            : AppColors.gray400,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.emerald500
                              : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
