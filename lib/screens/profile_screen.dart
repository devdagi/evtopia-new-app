import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/image_url.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/skeleton_loader.dart';

/// Profile tab – from old_flutter more_layout: user card at top, then list of options
/// (My Profile, Change Password, Log out). Tapping "My Profile" goes to edit form.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _primaryGreen = Color(0xFF2E7D32);
  bool _notificationCountRefreshed = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user != null && !_notificationCountRefreshed) {
      _notificationCountRefreshed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationProvider.notifier).refreshUnreadCount(user.id);
      });
    }
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _GuestCard(),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    style: AuthUiCommon.primaryButtonStyle(),
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: authState.isLoading
            ? const SkeletonProfile()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _UserInfoCard(user: user),
              const SizedBox(height: 12),
              _buildSection(
                context,
                title: 'Account Settings',
                items: [
                  _ProfileListItem(
                    icon: Icons.person_outline_rounded,
                    text: 'My Profile',
                    onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                  ),
                  if (!user.emailVerified)
                    _ProfileListItem(
                      icon: Icons.mark_email_unread_rounded,
                      text: 'Verify my email',
                      onTap: () => Navigator.of(context).pushNamed('/verify-email'),
                    ),
                  _ProfileListItem(
                    icon: Icons.lock_reset_rounded,
                    text: 'Change Password',
                    onTap: () => Navigator.of(context).pushNamed('/change-password'),
                  ),
                  _ProfileListItem(
                    icon: Icons.notifications_outlined,
                    text: 'Notifications',
                    onTap: () => Navigator.of(context).pushNamed('/notifications'),
                    badgeCount: ref.watch(notificationProvider).unreadCount,
                  ),
                ],
              ),
              _buildSection(
                context,
                title: 'My Activity',
                items: [
                  _ProfileListItem(
                    icon: Icons.favorite_rounded,
                    text: "Liked EV's",
                    onTap: () => Navigator.of(context).pushNamed('/liked-evs'),
                  ),
                  _ProfileListItem(
                    icon: Icons.directions_car_outlined,
                    text: 'Sell your car',
                    onTap: () => Navigator.of(context).pushNamed('/post-car'),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: 'Support & More',
                items: [
                  _ProfileListItem(
                    icon: Icons.help_outline_rounded,
                    text: 'Help Center',
                    onTap: () {}, // Planned feature
                  ),
                  _ProfileListItem(
                    icon: Icons.info_outline_rounded,
                    text: 'About Evtopia',
                    onTap: () {}, // Planned feature
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: _ProfileListItem(
                  icon: Icons.logout_rounded,
                  text: 'Log out',
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  isDestructive: true,
                  showArrow: false,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Version 1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> items}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: entry.value,
            );
          }),
        ],
      ),
    );
  }
}

/// User header card – refined for a premium feel.
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});

  final UserModel user;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _accentGreen = Color(0xFF81C784);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user.name;
    final phone = user.phone ?? '';
    final profilePhoto = user.profilePhoto;

    return Container(
      height: 180,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Stack(
        children: [
          // Background Gradient Container
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [_primaryGreen, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            right: -40,
            top: -40,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: _accentGreen.withValues(alpha: 0.1),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Avatar with premium border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: _primaryGreen.withAlpha(50),
                    backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                        ? NetworkImage(imageUrl(profilePhoto))
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: (profilePhoto == null || profilePhoto.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'User Name',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone.isNotEmpty ? phone : user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Guest state card refined.
class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.person_outline_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Join Evtopia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to sync your favorites and manage your profile.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single list row refined with better styling.
class _ProfileListItem extends StatelessWidget {
  const _ProfileListItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
    this.showArrow = true,
    this.badgeCount,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showArrow;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2E7D32);
    final color = isDestructive ? theme.colorScheme.error : primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeCount! > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (showArrow)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
