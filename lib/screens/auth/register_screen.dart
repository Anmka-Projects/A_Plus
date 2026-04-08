import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/auth_service.dart';
import '../../services/courses_service.dart';
import '../../data/registration_categories_catalog.dart';
import '../../l10n/app_localizations.dart';

/// Register: name, code, phone, category, and subcategory.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _phoneE164;
  bool _isLoading = false;

  List<Map<String, dynamic>> _allCategories = [];
  bool _isLoadingCategories = false;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories =
          await CoursesService.instance.getCategoriesForRegistration();
      if (mounted && categories.isNotEmpty) {
        setState(() => _allCategories = categories);
        return;
      }

      // Fallback: if filtered registration list is empty, load raw categories.
      final rawCategories = await CoursesService.instance.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = rawCategories.isNotEmpty
              ? rawCategories
              : RegistrationCategoriesCatalog.seededFallbackCategories();
        });
      }
    } catch (e) {
      // Keep UI informative if backend payload changes unexpectedly.
      debugPrint('Failed to load registration categories: $e');
      if (mounted) {
        setState(() {
          _allCategories = RegistrationCategoriesCatalog.seededFallbackCategories();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  List<Map<String, dynamic>> _subcategoriesOf(Map<String, dynamic> category) {
    for (final key in ['subcategories', 'sub_categories', 'children']) {
      final raw = category[key];
      if (raw is List) {
        return raw
            .map((e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }

  String _entityName(Map<String, dynamic> map) {
    return map['name']?.toString() ??
        map['name_en']?.toString() ??
        map['name_ar']?.toString() ??
        '';
  }

  String? _entityId(Map<String, dynamic>? map) => map?['id']?.toString();

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedCategory == null || _entityId(_selectedCategory) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectCategory, style: GoogleFonts.cairo()),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final subs = _subcategoriesOf(_selectedCategory!);
    if (subs.isNotEmpty &&
        (_selectedSubcategory == null ||
            _entityId(_selectedSubcategory) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectSubcategory, style: GoogleFonts.cairo()),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final phoneE164 = (_phoneE164 ?? '').trim();
        final subId = subs.isNotEmpty ? _entityId(_selectedSubcategory) : null;

        final authResponse = await AuthService.instance.register(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          phone: phoneE164,
          categoryId: _entityId(_selectedCategory)!,
          subcategoryId: subId,
        );

        if (!mounted) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasLaunched', true);

        if (mounted) {
          final role = authResponse.user.role.toLowerCase();
          if (role == 'instructor' || role == 'teacher') {
            context.go(RouteNames.instructorHome);
          } else {
            context.go(RouteNames.home);
          }
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.destructive,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.whiteOverlay20,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.pureWhite,
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.register,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.joinUsMessage,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: AppColors.whiteOverlay40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.fullName),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: l10n.pleaseEnterName,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(l10n.studentCode),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _codeController,
                          hint: l10n.enterStudentCode,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(l10n.phone),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blackOverlay20,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IntlPhoneField(
                            controller: _phoneController,
                            initialCountryCode: 'EG',
                            disableLengthCheck: true,
                            showDropdownIcon: true,
                            dropdownIconPosition: IconPosition.trailing,
                            dropdownIcon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            flagsButtonPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            flagsButtonMargin: const EdgeInsets.only(
                              left: 10,
                              top: 10,
                              bottom: 10,
                              right: 6,
                            ),
                            dropdownTextStyle: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                            style: GoogleFonts.cairo(fontSize: 15),
                            dropdownDecoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.secondary,
                                width: 1,
                              ),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.pureWhite,
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: AppColors.purple,
                                size: 22,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                            validator: (phone) {
                              final digitsOnly = (phone?.number ?? '')
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              if (digitsOnly.isEmpty) return l10n.fieldRequired;
                              if (digitsOnly.length < 6 ||
                                  digitsOnly.length > 15) {
                                return l10n.invalidPhone;
                              }
                              return null;
                            },
                            onChanged: (phone) {
                              _phoneE164 = phone.completeNumber;
                            },
                            onCountryChanged: (country) {
                              final digitsOnly = _phoneController.text
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              _phoneE164 = '+${country.dialCode}$digitsOnly';
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(l10n.category),
                        const SizedBox(height: 8),
                        _buildCategoryPicker(context),
                        const SizedBox(height: 16),
                        _buildLabel(l10n.subcategory),
                        const SizedBox(height: 8),
                        _buildSubcategoryPicker(context),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: AppColors.brandGradient,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.brandPurple.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: AppColors.primaryForeground,
                                disabledForegroundColor:
                                    AppColors.primaryForeground,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryForeground,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      l10n.createAccount,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyHaveAccount,
                                style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: AppColors.mutedForeground),
                              ),
                              TextButton(
                                onPressed: () => context.go(RouteNames.login),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                child: ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: AppColors.brandGradient,
                                      ).createShader(bounds),
                                  child: Text(
                                    l10n.login,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.category,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isLoadingCategories
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.purple,
                                ),
                              )
                            : _allCategories.isEmpty
                                ? Center(
                                    child: Text(
                                      l10n.categoriesComingSoon,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _allCategories.length,
                                    itemBuilder: (context, index) {
                                      final category = _allCategories[index];
                                      final id =
                                          category['id']?.toString() ?? '';
                                      final name = _entityName(category);
                                      final isSelected =
                                          _entityId(_selectedCategory) == id;
                                      return RadioListTile<String>(
                                        value: id,
                                        groupValue:
                                            _entityId(_selectedCategory),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedCategory = category;
                                            _selectedSubcategory = null;
                                          });
                                          Navigator.of(ctx).pop();
                                        },
                                        title: Text(
                                          name,
                                          style: GoogleFonts.cairo(fontSize: 14),
                                        ),
                                        selected: isSelected,
                                      );
                                    },
                                  ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackOverlay20,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined,
                size: 22, color: AppColors.purple),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCategory != null
                    ? _entityName(_selectedCategory!)
                    : l10n.tapToSelectCategory,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: _selectedCategory != null
                      ? AppColors.foreground
                      : AppColors.mutedForeground,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subs = _selectedCategory != null
        ? _subcategoriesOf(_selectedCategory!)
        : <Map<String, dynamic>>[];

    if (_selectedCategory == null) {
      return _buildPickerShell(
        child: Text(
          l10n.selectCategoryFirst,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        onTap: null,
      );
    }

    if (subs.isEmpty) {
      return _buildPickerShell(
        child: Text(
          l10n.noSubcategoriesForCategory,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        onTap: null,
      );
    }

    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.subcategory,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: subs.length,
                      itemBuilder: (context, index) {
                        final sub = subs[index];
                        final id = sub['id']?.toString() ?? '';
                        final name = _entityName(sub);
                        final isSelected =
                            _entityId(_selectedSubcategory) == id;
                        return RadioListTile<String>(
                          value: id,
                          groupValue: _entityId(_selectedSubcategory),
                          onChanged: (_) {
                            setState(() => _selectedSubcategory = sub);
                            Navigator.of(ctx).pop();
                          },
                          title: Text(
                            name,
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                          selected: isSelected,
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: _buildPickerShell(
        child: Text(
          _selectedSubcategory != null
              ? _entityName(_selectedSubcategory!)
              : l10n.tapToSelectSubcategory,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: _selectedSubcategory != null
                ? AppColors.foreground
                : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildPickerShell({
    required Widget child,
    Widget? subtitle,
    VoidCallback? onTap,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          subtitle,
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackOverlay20,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.subdirectory_arrow_right_rounded,
                size: 22, color: AppColors.purple),
            const SizedBox(width: 10),
            Expanded(child: content),
            if (onTap != null)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: AppColors.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.blackOverlay20,
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.pureWhite,
          hintText: hint,
          hintStyle:
              GoogleFonts.cairo(color: AppColors.mutedForeground, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.purple, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.fieldRequired;
          }
          return null;
        },
      ),
    );
  }
}
