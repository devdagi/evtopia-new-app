import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/notification_provider.dart';
import 'home_tab_screen.dart';
import 'our_service_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';

/// Invisible widget that polls notification count every 20 seconds. Must be built
/// under a [ProviderScope] so [ref] is available.
class _NotificationPollingController extends ConsumerStatefulWidget {
  const _NotificationPollingController();

  @override
  ConsumerState<_NotificationPollingController> createState() =>
      _NotificationPollingControllerState();
}

class _NotificationPollingControllerState
    extends ConsumerState<_NotificationPollingController> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
  }

  void _startPolling() {
    _timer?.cancel();
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      final uid = ref.read(authProvider).user?.id;
      if (uid != null) {
        ref.read(notificationProvider.notifier).refreshUnreadCount(uid);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Main shell after login: bottom nav with Home, Products, Our Service, Profile.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  /// Lazy tabs: only build screens after user has visited that tab (reduces initial jank).
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    mainTabRequestNotifier.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    mainTabRequestNotifier.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final index = mainTabRequestNotifier.value;
    if (index != null && index >= 0 && index <= 3 && mounted) {
      mainTabRequestNotifier.value = null;
      setState(() {
        _visitedTabs.add(index);
        _currentIndex = index;
      });
    }
  }

  void _onTabTap(int index) {
    setState(() {
      _visitedTabs.add(index);
      _currentIndex = index;
    });
  }

  static const List<_NavItem> _tabs = [
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: "EV's", icon: Icons.electric_car_rounded),
    _NavItem(label: 'Service', icon: Icons.build_circle_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: (_currentIndex == 0 || _currentIndex == 1)
          ? null
          : AppBar(
              title: Text(_tabs[_currentIndex].label),
            ),
      body: Consumer(
        builder: (context, ref, _) {
          final showBanner = ref.watch(authProvider).shouldShowVerifyEmailBanner;
          final dismissed = ref.watch(verifyBannerDismissedProvider);
          return Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: [
                  if (_visitedTabs.contains(0)) const HomeTabScreen() else const SizedBox.shrink(),
                  if (_visitedTabs.contains(1)) const ProductsScreen() else const SizedBox.shrink(),
                  if (_visitedTabs.contains(2)) const OurServiceScreen() else const SizedBox.shrink(),
                  if (_visitedTabs.contains(3)) const ProfileScreen() else const SizedBox.shrink(),
                ],
              ),
              const Positioned(left: 0, top: 0, child: _NotificationPollingController()),
              if (showBanner && !dismissed)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _VerifyEmailDropBanner(
                    onDismiss: () {
                      ref.read(verifyBannerDismissedProvider.notifier).state = true;
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _CurvedBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        items: _tabs,
      ),
    );
  }
}

/// Drop-from-top banner: "Verify your email" with action to go to verify flow. Can be dismissed (hide).
class _VerifyEmailDropBanner extends StatefulWidget {
  const _VerifyEmailDropBanner({this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  State<_VerifyEmailDropBanner> createState() => _VerifyEmailDropBannerState();
}

class _VerifyEmailDropBannerState extends State<_VerifyEmailDropBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  final AudioPlayer _notificationPlayer = AudioPlayer();
  static const _displayDuration = Duration(seconds: 4);
  static const _notificationSoundAsset = 'sounds/notification.mp3';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward().then((_) {
      if (mounted) _playNotificationSound();
    });
    // Auto-hide: after display duration, slide up then dismiss
    Future.delayed(_displayDuration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismiss?.call();
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _notificationPlayer.play(AssetSource(_notificationSoundAsset));
    } catch (_) {
      // Ignore if asset missing or playback fails
    }
  }

  @override
  void dispose() {
    _notificationPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SlideTransition(
      position: _slide,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
                        ]
                      : [
                          theme.colorScheme.surface.withValues(alpha: 0.98),
                          theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify your email',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to secure your account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/verify-email');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('Verify'),
                  ),
                  if (widget.onDismiss != null) ...[
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onDismiss,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// Floating glass-style bottom nav: blur, semi-transparent, pill capsule.
class _CurvedBottomNav extends StatelessWidget {
  const _CurvedBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.65)
                  : colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == currentIndex;
                final content = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 16 : 8,
                          vertical: 8,
                        ),
                        decoration: selected
                            ? BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: isDark ? 0.5 : 0.85,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              )
                            : null,
                        child: content,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
