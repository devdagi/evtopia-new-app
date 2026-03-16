import 'dart:ui';
import 'package:flutter/material.dart';

/// Evtopia logo asset path (local).
const String kEvtopiaLogoAsset = 'assets/images/evtopia.png';

/// Shared styling and widgets for auth screens (login, register, forgot password, OTP).
class AuthUiCommon {
  AuthUiCommon._();

  /// Input decoration used across auth screens.
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      counterText: counterText,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
    );
  }

  /// Primary green used for buttons and accents.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);

  /// Glass effect decoration for cards.
  static BoxDecoration glassDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Primary button style for auth screens.
  static ButtonStyle primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}


/// Logo widget with fade-in animation. Used on all auth screens.
class AuthLogo extends StatefulWidget {
  const AuthLogo({
    super.key,
    this.height = 80,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  State<AuthLogo> createState() => _AuthLogoState();
}

class _AuthLogoState extends State<AuthLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Image.asset(
        kEvtopiaLogoAsset,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.electric_car_rounded,
            size: widget.height,
            color: AuthUiCommon.primaryGreen,
          );
        },
      ),
    );
  }
}

/// Error banner for auth screens.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.onErrorContainer,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps auth form content in a glass card with staggered child animation.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.showLogo = true,
    this.logoHeight = 80,
    required this.children,
    this.padding,
    this.trailing,
  });

  final String? title;
  final String? subtitle;
  final bool showLogo;
  final double logoHeight;
  final List<Widget> children;
  final EdgeInsets? padding;
  /// Optional widget shown in the header (e.g. Skip button on login).
  final Widget? trailing;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    final count = widget.children.length +
        (widget.showLogo ? 1 : 0) +
        (widget.title != null ? 1 : 0) +
        (widget.subtitle != null ? 1 : 0);
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animations = List.generate(
      count,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            (i * 0.1).clamp(0.0, 0.8),
            (0.4 + i * 0.1).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int index = 0;

    Widget wrapChild(Widget child) {
      final i = index++;
      if (i >= _animations.length) return child;
      return FadeTransition(
        opacity: _animations[i],
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(_animations[i]),
          child: child,
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: AuthUiCommon.glassDecoration(),
                  padding: widget.padding ?? const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.showLogo) ...[
                        wrapChild(
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: AuthLogo(height: widget.logoHeight),
                            ),
                          ),
                        ),
                      ],
                      if (widget.title != null) ...[
                        wrapChild(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: widget.trailing != null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.title!,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      widget.trailing!,
                                    ],
                                  )
                                : Text(
                                    widget.title!,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
                      if (widget.subtitle != null) ...[
                        wrapChild(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                      ...widget.children.map((c) => wrapChild(c)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Footer text or extra buttons can be outside glass card if needed, 
            // but for now we keep them inside for a clean look.
          ],
        ),
      ),
    );
  }
}

