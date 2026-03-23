import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryGreen = Color(0xFF2E7D32);
    const deepGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header with Parallax-like effect
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: primaryGreen,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.15),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              centerTitle: true,
              title: Text(
                'About Evtopia',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 2), blurRadius: 4),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [deepGreen, primaryGreen],
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                      ),
                    ),
                  ),
                  // Background Decorative Shapes
                  Positioned(
                    right: -50,
                    top: -20,
                    child: Icon(
                      Icons.electric_car_rounded,
                      size: 260,
                      color: Colors.white.withValues(alpha: 0.05),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: 0, end: 20, duration: 4.seconds),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 20,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  // Centered Logo
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                            gradient: LinearGradient(
                              colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Image.asset(
                            'assets/png/logo.png',
                            height: 70,
                            color: Colors.white,
                            errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, size: 60, color: Colors.white),
                          ),
                        ).animate().scale(delay: 100.ms, duration: 800.ms, curve: Curves.elasticOut),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Innovation Driven By Ethiopia',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('WHO WE ARE'),
                          const Gap(16),
                          Text(
                            'Evtopia is an integrated electric mobility ecosystem dedicated to supporting Ethiopia\'s transition to electric vehicles (EVs) through education, technology, and practical solutions.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              fontSize: 17,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Gap(20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: primaryGreen.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: primaryGreen, size: 28),
                                const Gap(16),
                                Expanded(
                                  child: Text(
                                    'The name "Evtopia" combines "EV" with "Topia," inspired by Ethiopia, symbolizing a sustainable future.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildSectionHeader('OUR FOUNDER\'S MISSION'),
                    ),
                    const Gap(16),
                    _buildFounderCard(context),

                    const Gap(40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildSectionHeader('CORE ECOSYSTEM'),
                    ),
                    const Gap(20),
                    _buildFeatureGrid(context),

                    const Gap(40),
                    _buildContactSection(context),

                    const Gap(60),
                    Center(
                      child: Opacity(
                        opacity: 0.4,
                        child: Column(
                          children: [
                            Image.asset('assets/png/logo.png', height: 30, color: colorScheme.onSurface),
                            const Gap(8),
                            const Text(
                              '© 2026 Evtopia. All rights reserved.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              'Designed for a cleaner future.',
                              style: TextStyle(fontSize: 10, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 13,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildFounderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote_rounded, color: Color(0xFF2E7D32), size: 40),
          const Gap(16),
          Text(
            'Evtopia aims to make electric mobility accessible, trustworthy, and sustainable in Ethiopia by building both human capacity and digital infrastructure.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 1,
                color: Colors.black12,
              ),
              const Gap(12),
              const Text(
                'Isehak Kedir',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2E7D32)),
              ),
              const Gap(12),
              Container(
                width: 32,
                height: 1,
                color: Colors.black12,
              ),
            ],
          ),
          const Text(
            'Founder of Evtopia',
            style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {'icon': Icons.school_rounded, 'title': 'Education', 'desc': 'Simplifying EV tech via Evtopia Media.'},
      {'icon': Icons.shopping_basket_rounded, 'title': 'Marketplace', 'desc': 'Trusted listings for EVs & parts.'},
      {'icon': Icons.settings_suggest_rounded, 'title': 'Services', 'desc': 'Specialized repair & diagnostic hub.'},
      {'icon': Icons.hub_rounded, 'title': 'Infrastructure', 'desc': 'Charging networks & community growth.'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final f = features[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(f['icon'] as IconData, color: const Color(0xFF2E7D32), size: 28),
                ),
                const Gap(16),
                Text(
                  f['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Gap(6),
                Text(
                  f['desc'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5), height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect with Us',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const Gap(20),
          _buildDarkContactRow(Icons.location_on_rounded, 'Kera, Addis Ababa, Ethiopia'),
          const Gap(16),
          _buildDarkContactRow(Icons.alternate_email_rounded, 'info@evtopia.co'),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Visit Website', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkContactRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
