import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/skeleton_loader.dart';

const int _maxExtraImages = 7;

class _MyProductItem {
  final int id;
  final String name;
  final double price;
  final String thumbnail;
  final bool isApprove;
  final bool isActive;
  final String? declineReason;
  final int visitsCount;
  final int favoritesCount;

  _MyProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.thumbnail,
    required this.isApprove,
    required this.isActive,
    this.declineReason,
    this.visitsCount = 0,
    this.favoritesCount = 0,
  });
}

class PostCarScreen extends ConsumerStatefulWidget {
  const PostCarScreen({super.key});

  @override
  ConsumerState<PostCarScreen> createState() => _PostCarScreenState();
}

class _PostCarScreenState extends ConsumerState<PostCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shortDesc = TextEditingController();
  final _description = TextEditingController();
  final _year = TextEditingController();
  final _kilometer = TextEditingController();
  final _drivingRange = TextEditingController();
  final _batteryCapacity = TextEditingController();
  final _price = TextEditingController();
  final _code = TextEditingController(text: '${10000 + Random().nextInt(89999)}');

  List<String> _imagePaths = [];
  int? _driveTrainId;
  int? _categoryId;
  List<Map<String, dynamic>> _driveTrains = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  bool _dataLoading = true;
  bool _isInitializing = true;
  String? _error;

  int _totalPosted = 0;
  int _approved = 0;
  int _pending = 0;
  int _declined = 0;
  String _listFilter = 'all'; // all, approved, pending, declined
  List<_MyProductItem> _myProducts = [];
  List<_MyProductItem> _popularProducts = [];
  List<_MyProductItem> _mostLikedProducts = [];
  int? _deletingId;
  _MyProductItem? _deleteTarget;
  final GlobalKey _formSectionKey = GlobalKey();
  bool _loadingList = false;
  bool _showPublishForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      _loadMyProducts();
      _loadPopularProducts();
      _loadMostLikedProducts();
      _loadCreateData();
    });

    // Delay showing the heavy dashboard to allow smooth transition
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _shortDesc.dispose();
    _description.dispose();
    _year.dispose();
    _kilometer.dispose();
    _drivingRange.dispose();
    _batteryCapacity.dispose();
    _price.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.get(ApiConstants.userProductStatsPath);
      if (!mounted) return;
      final data = res.data?['data'];
      if (data != null) {
        setState(() {
          _totalPosted = data['total_posted'] as int? ?? 0;
          _approved = data['approved'] as int? ?? 0;
          _pending = data['pending'] as int? ?? 0;
          _declined = data['declined'] as int? ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _setListFilter(String filter) async {
    if (_listFilter == filter) return;
    setState(() {
      _listFilter = filter;
      _loadingList = true;
    });
    await _loadMyProducts();
    if (mounted) setState(() => _loadingList = false);
  }

  Future<void> _loadMyProducts() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.get(
        ApiConstants.userProductMyProductsPath,
        queryParameters: {'filter': _listFilter, 'per_page': 50},
      );
      if (!mounted) return;
      final list = res.data?['data']?['products'] as List? ?? [];
      setState(() {
        _myProducts = list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _MyProductItem(
            id: m['id'] as int,
            name: m['name']?.toString() ?? '',
            price: (m['price'] as num?)?.toDouble() ?? 0,
            thumbnail: m['thumbnail']?.toString() ?? '',
            isApprove: m['is_approve'] as bool? ?? false,
            isActive: m['is_active'] as bool? ?? false,
            declineReason: m['decline_reason']?.toString(),
            visitsCount: m['visits_count'] as int? ?? 0,
            favoritesCount: m['favorites_count'] as int? ?? 0,
          );
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadPopularProducts() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.get(
        ApiConstants.userProductMyProductsPath,
        queryParameters: {'sort': 'popular', 'per_page': 10},
      );
      if (!mounted) return;
      final list = res.data?['data']?['products'] as List? ?? [];
      setState(() {
        _popularProducts = list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _MyProductItem(
            id: m['id'] as int,
            name: m['name']?.toString() ?? '',
            price: (m['price'] as num?)?.toDouble() ?? 0,
            thumbnail: m['thumbnail']?.toString() ?? '',
            isApprove: m['is_approve'] as bool? ?? false,
            isActive: m['is_active'] as bool? ?? false,
            visitsCount: m['visits_count'] as int? ?? 0,
            favoritesCount: m['favorites_count'] as int? ?? 0,
          );
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadMostLikedProducts() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.get(
        ApiConstants.userProductMyProductsPath,
        queryParameters: {'sort': 'most_liked', 'per_page': 10},
      );
      if (!mounted) return;
      final list = res.data?['data']?['products'] as List? ?? [];
      setState(() {
        _mostLikedProducts = list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _MyProductItem(
            id: m['id'] as int,
            name: m['name']?.toString() ?? '',
            price: (m['price'] as num?)?.toDouble() ?? 0,
            thumbnail: m['thumbnail']?.toString() ?? '',
            isApprove: m['is_approve'] as bool? ?? false,
            isActive: m['is_active'] as bool? ?? false,
            visitsCount: m['visits_count'] as int? ?? 0,
            favoritesCount: m['favorites_count'] as int? ?? 0,
          );
        }).toList();
      });
    } catch (_) {}
  }

  void _scrollToForm() {
    setState(() => _showPublishForm = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _formSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _loadCreateData() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.get(ApiConstants.userProductCreateDataPath);
      if (!mounted) return;
      final data = res.data?['data'];
      if (data != null) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from((data['categories'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
          _driveTrains = List<Map<String, dynamic>>.from((data['drive_trains'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
          if (_categories.isNotEmpty && _categoryId == null) _categoryId = _categories.first['id'] as int?;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _dataLoading = false);
  }

  Future<void> _pickImage(bool main) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() {
      if (main) {
        if (_imagePaths.isEmpty) {
          _imagePaths.add(x.path);
        } else {
          _imagePaths[0] = x.path;
        }
      } else {
        if (_imagePaths.isEmpty) {
          _imagePaths.add(x.path);
        } else if (_imagePaths.length < 1 + _maxExtraImages) {
          _imagePaths.add(x.path);
        }
      }
      if (_imagePaths.length > 1 + _maxExtraImages) {
        _imagePaths = _imagePaths.sublist(0, 1 + _maxExtraImages);
      }
    });
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  void _confirmDelete(_MyProductItem item) {
    setState(() => _deleteTarget = item);
  }

  Future<void> _doDelete() async {
    final item = _deleteTarget;
    if (item == null) return;
    setState(() => _deletingId = item.id);
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.delete(ApiConstants.userProductDeletePath(item.id));
      if (!mounted) return;
      setState(() {
        _myProducts = _myProducts.where((p) => p.id != item.id).toList();
        _totalPosted = (_totalPosted - 1).clamp(0, 999999);
        if (item.declineReason != null && item.declineReason!.isNotEmpty) {
          _declined = (_declined - 1).clamp(0, 999999);
        } else if (item.isApprove && item.isActive) {
          _approved = (_approved - 1).clamp(0, 999999);
        } else {
          _pending = (_pending - 1).clamp(0, 999999);
        }
      });
    } catch (_) {}
    if (mounted) setState(() => _deleteTarget = null);
    setState(() => _deletingId = null);
  }

  void _clearForm() {
    _name.clear();
    _shortDesc.clear();
    _description.clear();
    _year.clear();
    _kilometer.clear();
    _drivingRange.clear();
    _batteryCapacity.clear();
    _price.clear();
    _code.text = '${10000 + Random().nextInt(89999)}';
    _imagePaths = [];
    setState(() {});
  }

  Future<void> _submit() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;
    if (_imagePaths.isEmpty) {
      setState(() => _error = 'Please add at least the main image (thumbnail).');
      return;
    }
    if (_categoryId == null && _categories.isNotEmpty) {
      setState(() => _error = 'Please select a category.');
      return;
    }

    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    final formData = FormData.fromMap({
      'name': _name.text.trim(),
      'short_description': _shortDesc.text.trim(),
      'description': _description.text.trim(),
      'code': _code.text.trim(),
      'price': _price.text.trim(),
      'quantity': '1',
      'category': _categoryId.toString(),
      if (_driveTrainId != null) 'drive_train': _driveTrainId.toString(),
      if (_year.text.trim().isNotEmpty) 'year': _year.text.trim(),
      if (_kilometer.text.trim().isNotEmpty) 'kilometer': _kilometer.text.trim(),
      if (_drivingRange.text.trim().isNotEmpty) 'driving_range': _drivingRange.text.trim(),
      if (_batteryCapacity.text.trim().isNotEmpty) 'battery_capacity': _batteryCapacity.text.trim(),
    });
    formData.files.add(MapEntry('thumbnail', await MultipartFile.fromFile(_imagePaths.first)));
    for (int i = 1; i < _imagePaths.length && i <= _maxExtraImages; i++) {
      formData.files.add(MapEntry('additionThumbnail[${i - 1}]', await MultipartFile.fromFile(_imagePaths[i])));
    }

    try {
      final res = await api.dio.post(ApiConstants.userProductStorePath, data: formData);
      if (!mounted) return;
      final msg = res.data?['message']?.toString() ?? '';
      if (msg.toLowerCase().contains('success')) {
        _loadStats();
        _loadMyProducts();
        _clearForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg.isNotEmpty ? msg : 'Product submitted successfully. Waiting for admin approval before it is published.'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      setState(() => _error = msg.isNotEmpty ? msg : 'Failed to submit.');
    } catch (e) {
      if (!mounted) return;
      final String err = e is DioException
          ? (e.response?.data?['message']?.toString() ?? e.toString())
          : e.toString();
      setState(() => _error = err.isNotEmpty ? err : 'Failed to submit.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Publish your car',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : _primaryGreen,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: (_dataLoading || _isInitializing)
          ? const SkeletonPostCar()
          : RefreshIndicator(
              onRefresh: () async {
                await _loadStats();
                await _loadMyProducts();
                await _loadPopularProducts();
                await _loadMostLikedProducts();
                await _loadCreateData();
              },
              color: _primaryGreen,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Analytics Dashboard
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryGreen, Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics_rounded, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatItem(label: 'Total', value: _totalPosted, icon: Icons.directions_car_rounded, selected: _listFilter == 'all', onTap: () => _setListFilter('all')),
                              _StatItem(label: 'Approved', value: _approved, icon: Icons.check_circle_rounded, selected: _listFilter == 'approved', onTap: () => _setListFilter('approved')),
                              _StatItem(label: 'Pending', value: _pending, icon: Icons.hourglass_bottom_rounded, selected: _listFilter == 'pending', onTap: () => _setListFilter('pending')),
                              _StatItem(label: 'Declined', value: _declined, icon: Icons.cancel_rounded, selected: _listFilter == 'declined', onTap: () => _setListFilter('declined')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // My products list (filtered)
                    _SectionHeader(
                      title: _listFilter == 'all'
                          ? 'Total products'
                          : _listFilter == 'approved'
                              ? 'Approved products'
                              : _listFilter == 'pending'
                                  ? 'Pending products'
                                  : 'Declined products',
                      onAction: null,
                    ),
                    const SizedBox(height: 12),
                    if (_loadingList)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(color: _primaryGreen)),
                      )
                    else if (_myProducts.isNotEmpty)
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _myProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final p = _myProducts[index];
                            return SizedBox(
                              width: 280,
                              child: _MyProductCard(
                                item: p,
                                deleting: _deletingId == p.id,
                                onDelete: p.declineReason == null ? () => _confirmDelete(p) : null,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No products in this category.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Your Popular Products
                    if (_popularProducts.isNotEmpty) ...[
                      _SectionHeader(title: 'Your Popular Products', onAction: null),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('By number of visitors', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _popularProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final p = _popularProducts[index];
                            return SizedBox(
                              width: 260,
                              child: _PopularLikedCard(item: p, rank: index + 1, subtitle: '${p.visitsCount} visitors'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Your Most Liked EV
                    if (_mostLikedProducts.isNotEmpty) ...[
                      _SectionHeader(title: 'Your Most Liked EV', onAction: null),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('Products liked by customers', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _mostLikedProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final p = _mostLikedProducts[index];
                            return SizedBox(
                              width: 260,
                              child: _PopularLikedCard(item: p, rank: index + 1, subtitle: '${p.favoritesCount} likes'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Publish Your EV button (shows form and scrolls to it)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FilledButton.icon(
                        onPressed: _scrollToForm,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Publish Your EV'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    // Post form (only visible after "Publish Your EV" is clicked)
                    if (_showPublishForm) ...[
                      _SectionHeader(title: 'Sell your car'),
                      const SizedBox(height: 16),
                      Container(
                        key: _formSectionKey,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Product Images',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 110,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _ImagePickerTile(
                                    path: _imagePaths.isNotEmpty ? _imagePaths.first : null,
                                    onTap: () => _pickImage(true),
                                    label: 'Main Cover',
                                    isMain: true,
                                  ),
                                  ...List.generate(_imagePaths.length > 1 ? _imagePaths.length - 1 : 0, (i) {
                                    return _ImagePickerTile(
                                      path: _imagePaths[i + 1],
                                      onTap: () => _pickImage(false),
                                      onRemove: () => _removeImage(i + 1),
                                      label: 'Extra ${i + 1}',
                                    );
                                  }),
                                  if (_imagePaths.length < 1 + _maxExtraImages)
                                    _ImagePickerTile(
                                      path: null,
                                      onTap: () => _pickImage(false),
                                      label: 'Add More',
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_error != null) _ErrorContainer(message: _error!),

                            _FormGroup(
                              title: 'BASIC INFORMATION',
                              children: [
                                TextFormField(
                                  controller: _name,
                                  decoration: _inputDecoration('Product Name *', Icons.drive_file_rename_outline_rounded),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _shortDesc,
                                  decoration: _inputDecoration('Short description', Icons.description_outlined),
                                  maxLines: 2,
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _description,
                                  decoration: _inputDecoration('Full Details', Icons.article_outlined),
                                  maxLines: 4,
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),

                            _FormGroup(
                              title: 'SPECIFICATIONS',
                              children: [
                                if (_categories.isNotEmpty) ...[
                                  DropdownButtonFormField<int>(
                                    value: _categoryId,
                                    isExpanded: true,
                                    decoration: _inputDecoration('Category *', Icons.category_outlined),
                                    items: _categories.map((c) => DropdownMenuItem(value: c['id'] as int?, child: Text(c['name']?.toString() ?? ''))).toList(),
                                    onChanged: (v) => setState(() => _categoryId = v),
                                    validator: (v) => v == null ? 'Select category' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_driveTrains.isNotEmpty) ...[
                                  DropdownButtonFormField<int>(
                                    value: _driveTrainId,
                                    isExpanded: true,
                                    decoration: _inputDecoration('Drive Train', Icons.settings_input_component_outlined),
                                    items: [const DropdownMenuItem(value: null, child: Text('Select drive train')), ..._driveTrains.map((d) => DropdownMenuItem(value: d['id'] as int?, child: Text(d['name']?.toString() ?? '')))],
                                    onChanged: (v) => setState(() => _driveTrainId = v),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _year,
                                        decoration: _inputDecoration('Year', Icons.calendar_today_rounded),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _kilometer,
                                        decoration: _inputDecoration('Mileage', Icons.speed_rounded),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _drivingRange,
                                        decoration: _inputDecoration('Range (KM)', Icons.electric_car_rounded),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _batteryCapacity,
                                        decoration: _inputDecoration('Bat (KWh)', Icons.battery_charging_full_rounded),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            _FormGroup(
                              title: 'PRICING & CODE',
                              children: [
                                TextFormField(
                                  controller: _price,
                                  decoration: _inputDecoration('Price *', Icons.payments_outlined),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryGreen),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _code,
                                  decoration: _inputDecoration('Product code', Icons.qr_code_rounded),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text(
                                      'Publish Now',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
      bottomSheet: _deleteTarget != null
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Delete Listing?',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Are you sure you want to delete "${_deleteTarget!.name}"? This action cannot be undone.'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _deleteTarget = null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _doDelete,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _StatItem({required this.label, required this.value, required this.icon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: selected ? BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)) : null,
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: const Text('See All', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
      ],
    );
  }
}

class _PopularLikedCard extends StatelessWidget {
  final _MyProductItem item;
  final int rank;
  final String subtitle;

  const _PopularLikedCard({required this.item, required this.rank, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: item.thumbnail.isNotEmpty
                ? Image.network(item.thumbnail, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 56))
                : const Icon(Icons.directions_car, size: 56),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyProductCard extends StatelessWidget {
  final _MyProductItem item;
  final bool deleting;
  final VoidCallback? onDelete;

  const _MyProductCard({required this.item, required this.deleting, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDeclined = item.declineReason != null && item.declineReason!.isNotEmpty;
    final isApproved = !isDeclined && item.isApprove && item.isActive;

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: item.thumbnail.isNotEmpty
                ? Image.network(
                    item.thumbnail,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _carPlaceholder(),
                  )
                : _carPlaceholder(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} ETB',
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDeclined ? Colors.red : isApproved ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDeclined ? 'Declined' : (isApproved ? 'Approved' : 'Pending Approval'),
                    style: TextStyle(
                      color: isDeclined ? Colors.red.shade700 : (isApproved ? Colors.green.shade700 : Colors.orange.shade800),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isDeclined && item.declineReason != null) ...[
                  const SizedBox(height: 6),
                  Text('Reason: ${item.declineReason!}', style: TextStyle(fontSize: 11, color: Colors.red.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            PopupMenuButton<String>(
              icon: deleting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.more_vert_rounded, color: Colors.grey),
              onSelected: (value) {
                if (value == 'delete') onDelete!();
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _carPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade100,
      child: const Icon(Icons.directions_car_rounded, color: Colors.grey),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  final String? path;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String label;
  final bool isMain;

  const _ImagePickerTile({this.path, required this.onTap, this.onRemove, required this.label, this.isMain = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: path != null ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      width: path != null ? 2 : 1,
                    ),
                  ),
                  child: path != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(path!), fit: BoxFit.cover))
                      : Icon(isMain ? Icons.camera_alt_rounded : Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 28),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _FormGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorContainer extends StatelessWidget {
  final String message;

  const _ErrorContainer({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
