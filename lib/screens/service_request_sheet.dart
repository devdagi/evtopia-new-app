import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/service_request_provider.dart';
import '../services/service_request_service.dart';

/// Shows a top notification banner (e.g. "Service request sent").
void _showTopNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final theme = Theme.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _TopNotificationBanner(
      message: message,
      theme: theme,
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2500), () => entry.remove());
}

/// Top-of-screen success banner with slide-in and auto-dismiss.
class _TopNotificationBanner extends StatefulWidget {
  const _TopNotificationBanner({
    required this.message,
    required this.theme,
  });

  final String message;
  final ThemeData theme;

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF2E7D32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to submit a service request (evtopia-ecom POST /api/service-requests).
/// Optional [serviceId] and [serviceName] when requesting a specific service.
/// Use [ServiceRequestSheet.show] for blur overlay, rounded corners, drag-to-close.
class ServiceRequestSheet extends ConsumerStatefulWidget {
  const ServiceRequestSheet({
    super.key,
    this.serviceId,
    this.serviceName,
  });

  final int? serviceId;
  final String? serviceName;

  /// Shows the request sheet with blur overlay, 32px rounded top, drag-to-close, spring animation.
  static Future<void> show(
    BuildContext context, {
    int? serviceId,
    String? serviceName,
  }) {
    return Navigator.of(context).push<void>(
      _ServiceRequestRoute(
        builder: (ctx) => ServiceRequestSheet(
          serviceId: serviceId,
          serviceName: serviceName,
        ),
      ),
    );
  }

  @override
  ConsumerState<ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestRoute extends PageRoute<void> {
  _ServiceRequestRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  bool get opaque => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final curve = Curves.easeOutCubic;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: curve));
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: animation, curve: curve));
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: AnimatedBuilder(
              animation: fadeAnimation,
              builder: (context, _) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * fadeAnimation.value, sigmaY: 8 * fadeAnimation.value),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4 * fadeAnimation.value),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: SlideTransition(
            position: slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
                    Navigator.of(context).pop();
                  }
                },
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Design tokens
const _kSheetRadius = 32.0;
const _kInputRadius = 16.0;
const _kInputBg = Color(0xFFF3F4F6);
const _kFocusGreen = Color(0xFF22C55E);
const _kGradientStart = Color(0xFF22C55E);
const _kGradientEnd = Color(0xFF16A34A);
const _kSpacing = 20.0;
const _kTitleSize = 22.0;

class _ServiceRequestSheetState extends ConsumerState<ServiceRequestSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _requestedDateController = TextEditingController();
  final _requestedTimeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _showSuccess = false;
  double _slideThumbOffset = 0;
  bool _slideLocked = false;

  late AnimationController _enterController;
  late AnimationController _successController;
  late Animation<Offset> _enterSlide;
  late Animation<double> _enterFade;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      _nameController.text = auth.user!.name;
      _phoneController.text = auth.user!.phone ?? '';
    }
    final now = DateTime.now();
    _requestedDateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _requestedTimeController.text = '09:00';

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _enterSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _enterFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enterController.forward();
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _successController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _carModelController.dispose();
    _requestedDateController.dispose();
    _requestedTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _slideLocked = false;
        _slideThumbOffset = 0;
      });
      HapticFeedback.lightImpact();
      return;
    }
    final auth = ref.read(authProvider);
    if (auth.user == null || !auth.isAuthenticated) {
      setState(() => _error = 'Please log in to submit a request.');
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final payload = ServiceRequestPayload(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        carModel: _carModelController.text.trim(),
        requestedDate: _requestedDateController.text.trim(),
        requestedTime: _requestedTimeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        serviceId: widget.serviceId,
      );
      await ref.read(serviceRequestServiceProvider).submitRequest(payload);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showSuccess = true;
      });
      _successController.forward();
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      _showTopNotification(context, 'Service request sent');
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Failed to submit request. Try again.';
      if (e.response?.statusCode == 401) {
        msg = 'Please log in to submit a request.';
      } else if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else if (data is Map && data['errors'] != null) {
          final err = data['errors'] as Map;
          if (err.isNotEmpty) {
            final first = err.values.first;
            msg = first is List ? first.join(' ') : first.toString();
          }
        }
      }
      setState(() {
        _loading = false;
        _slideLocked = false;
        _slideThumbOffset = 0;
        _error = msg;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _slideLocked = false;
        _slideThumbOffset = 0;
        _error = 'Failed to submit request. Try again.';
      });
      HapticFeedback.lightImpact();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onSlideChanged(double dx, double trackWidth) {
    if (_slideLocked || _loading) return;
    setState(() {
      _slideThumbOffset = (_slideThumbOffset + dx).clamp(0.0, trackWidth - 56).toDouble();
    });
  }

  void _onSlideEnd(double trackWidth) {
    if (_slideLocked || _loading) return;
    final threshold = trackWidth - 80;
    if (_slideThumbOffset >= threshold) {
      HapticFeedback.mediumImpact();
      setState(() => _slideLocked = true);
      _submit();
    } else {
      setState(() => _slideThumbOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = ref.watch(authProvider);

    if (_showSuccess || _successController.isAnimating || _successController.isCompleted) {
    return _buildSheetContainer(
      context,
      isDark: isDark,
      child: _buildSuccessState(theme),
    );
  }

  return _buildSheetContainer(
    context,
    isDark: isDark,
    child: SlideTransition(
        position: _enterSlide,
        child: FadeTransition(
          opacity: _enterFade,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildDragHandle(isDark),
                  const SizedBox(height: 24),
                  Text(
                    widget.serviceId != null ? 'Request Service' : 'Garage Request',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: _kTitleSize,
                    ),
                  ),
                  if (widget.serviceName != null && widget.serviceName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Requesting: ${widget.serviceName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: _kSpacing),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                    const SizedBox(height: _kSpacing),
                  ],
                  _buildModernInput(
                    context: context,
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: _kSpacing),
                  _buildModernInput(
                    context: context,
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: _kSpacing),
                  _buildModernInput(
                    context: context,
                    controller: _carModelController,
                    label: 'Car Model',
                    icon: Icons.directions_car_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: _kSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernInput(
                          context: context,
                          controller: _requestedDateController,
                          label: 'Date',
                          icon: Icons.calendar_today_rounded,
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null && mounted) {
                              _requestedDateController.text =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: _kSpacing),
                      Expanded(
                        child: _buildModernInput(
                          context: context,
                          controller: _requestedTimeController,
                          label: 'Time',
                          icon: Icons.schedule_rounded,
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              _requestedTimeController.text =
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _kSpacing),
                  _buildModernInput(
                    context: context,
                    controller: _descriptionController,
                    label: 'Description / Needs',
                    icon: Icons.notes_rounded,
                    maxLines: null,
                    minLines: 3,
                  ),
                  const SizedBox(height: 28),
                  if (!auth.isAuthenticated)
                    Text(
                      'You must be logged in to submit a request.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final trackWidth = constraints.maxWidth;
                        return _SlideToSubmit(
                          trackWidth: trackWidth,
                          thumbOffset: _slideThumbOffset,
                          loading: _loading,
                          locked: _slideLocked,
                          onSlide: _onSlideChanged,
                          onSlideEnd: () => _onSlideEnd(trackWidth),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetContainer(BuildContext context, {required bool isDark, required Widget child}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C21) : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(_kSheetRadius)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.black26,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(theme.brightness == Brightness.dark),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: _successController,
            builder: (context, _) {
              final scale = 0.5 + 0.5 * Curves.elasticOut.transform(_successController.value);
              final opacity = _successController.value.clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kFocusGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 48, color: _kFocusGreen),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Request submitted!',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll get back to you soon.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLines = 1,
    int? minLines,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF25282E) : _kInputBg;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines ?? (maxLines != null && maxLines > 1 ? maxLines : 1),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kInputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kInputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kInputRadius),
          borderSide: const BorderSide(color: _kFocusGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kInputRadius),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kInputRadius),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _SlideToSubmit extends StatelessWidget {
  const _SlideToSubmit({
    required this.trackWidth,
    required this.thumbOffset,
    required this.loading,
    required this.locked,
    required this.onSlide,
    required this.onSlideEnd,
  });

  final double trackWidth;
  final double thumbOffset;
  final bool loading;
  final bool locked;
  final void Function(double dx, double trackWidth) onSlide;
  final VoidCallback onSlideEnd;

  @override
  Widget build(BuildContext context) {
    final maxSlide = (trackWidth - 56).clamp(0.0, double.infinity);
    return GestureDetector(
      onHorizontalDragUpdate: locked || loading
          ? null
          : (d) => onSlide(d.delta.dx, trackWidth),
      onHorizontalDragEnd: locked || loading ? null : (_) => onSlideEnd(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGradientStart, _kGradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _kGradientStart.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (loading)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  thumbOffset > 20 ? '' : 'Slide to Request Service',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            Positioned(
              left: 4 + thumbOffset.clamp(0.0, maxSlide),
              top: 4,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _kGradientEnd,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
