import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/academic_structure_service.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Register: quad name, national ID, code, phone, faculty → section → grade (API).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _headerNavy = Color(0xFF102027);
  static const Color _buttonTealEnd = Color(0xFF4DD0E1);
  static const Color _fieldFill = Color(0xFFD8D8D8);

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _sections = [];
  bool _loadingFaculties = false;
  bool _loadingSections = false;
  bool _facultiesLoadFailed = false;

  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedSection;
  Map<String, dynamic>? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _loadingFaculties = true;
      _facultiesLoadFailed = false;
    });
    try {
      final list = await AcademicStructureService.instance.getFaculties();
      if (!mounted) return;
      setState(() {
        _faculties = list;
        _facultiesLoadFailed = list.isEmpty;
      });
    } catch (e) {
      debugPrint('Faculties load failed: $e');
      if (mounted) {
        setState(() {
          _faculties = [];
          _facultiesLoadFailed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingFaculties = false);
    }
  }

  Future<void> _loadSections(String facultyId) async {
    setState(() {
      _loadingSections = true;
      _sections = [];
      _selectedSection = null;
      _selectedGrade = null;
    });
    try {
      final list = await AcademicStructureService.instance
          .getSectionsForFaculty(facultyId);
      if (!mounted) return;
      setState(() => _sections = list);
    } catch (e) {
      debugPrint('Sections load failed: $e');
      if (mounted) setState(() => _sections = []);
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _loadGrades(String sectionId) async {
    setState(() {
      _selectedGrade = null;
    });
    try {
      final list = await AcademicStructureService.instance
          .getGradesForSection(sectionId);
      if (!mounted) return;
      setState(() {
        _selectedGrade = list.isNotEmpty ? list.first : null;
      });
    } catch (e) {
      debugPrint('Grades load failed: $e');
    }
  }

  String _entityName(Map<String, dynamic> map) {
    return map['name']?.toString() ??
        map['name_ar']?.toString() ??
        map['name_en']?.toString() ??
        '';
  }

  String? _entityId(Map<String, dynamic>? map) => map?['id']?.toString();

  String? _validateQuadName(String? value, AppLocalizations l10n) {
    final normalized = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return l10n.fieldRequired;

    final parts = normalized.split(' ');
    if (parts.length != 4) {
      return 'الاسم يجب أن يكون رباعي';
    }

    return null;
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    if (_entityId(_selectedFaculty) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectFaculty, style: GoogleFonts.cairo()),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    if (_entityId(_selectedSection) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectSection, style: GoogleFonts.cairo()),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    if (_entityId(_selectedGrade) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'لا توجد مرحلة دراسية متاحة لهذا القسم'
                : 'No grade available for this section',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authResponse = await AuthService.instance.register(
          fullName: _fullNameController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          code: _codeController.text.trim(),
          phone: _phoneController.text.trim(),
          facultyId: _entityId(_selectedFaculty)!,
          sectionId: _entityId(_selectedSection)!,
          gradeId: _entityId(_selectedGrade)!,
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
    _fullNameController.dispose();
    _nationalIdController.dispose();
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

    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            backgroundColor: AppColors.beige,
            body: Column(
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.beige,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(l10n.quadNameTitle),
                              const SizedBox(height: 8),
                              _buildGrayTextField(
                                context: context,
                                controller: _fullNameController,
                                hint: l10n.quadNameTitle,
                                icon: Icons.person_outline_rounded,
                                validator: (value) =>
                                    _validateQuadName(value, l10n),
                              ),
                              const SizedBox(height: 16),
                              _buildLabel(l10n.phone),
                              const SizedBox(height: 8),
                              _buildPhoneField(context, l10n),
                              const SizedBox(height: 16),
                              _buildLabel(l10n.studentCode),
                              const SizedBox(height: 8),
                              _buildGrayTextField(
                                context: context,
                                controller: _codeController,
                                hint: l10n.enterStudentCode,
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 16),
                              _buildLabel(l10n.nationalId),
                              const SizedBox(height: 8),
                              _buildNationalIdField(context, l10n),
                              const SizedBox(height: 16),
                              _buildLabel(l10n.faculty),
                              const SizedBox(height: 8),
                              _buildFacultyPicker(context, l10n),
                              const SizedBox(height: 16),
                              _buildLabel(l10n.section),
                              const SizedBox(height: 8),
                              _buildSectionPicker(context, l10n),
                              const SizedBox(height: 24),
                              _buildSignUpButton(l10n),
                              const SizedBox(height: 20),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.alreadyHaveAccount,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.go(RouteNames.login),
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
                                          colors: [
                                            _headerNavy,
                                            _buttonTealEnd,
                                          ],
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
                              const SizedBox(height: 8),
                              _buildFooter(l10n),
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
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -40,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: _headerNavy.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 40,
            left: -50,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: _headerNavy.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 40,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: _headerNavy.withValues(alpha: 0.22),
            ),
          ),
          SafeArea(
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
        ],
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context, AppLocalizations l10n) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      style: GoogleFonts.cairo(fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldFill,
        hintText: l10n.phone,
        hintStyle:
            GoogleFonts.cairo(color: AppColors.mutedForeground, fontSize: 14),
        prefixIcon: const Icon(
          Icons.phone_outlined,
          color: AppColors.purple,
          size: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (value) {
        final digitsOnly = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.isEmpty) return l10n.fieldRequired;
        if (digitsOnly.length < 6 || digitsOnly.length > 15) {
          return l10n.invalidPhone;
        }
        return null;
      },
    );
  }

  Widget _buildNationalIdField(BuildContext context, AppLocalizations l10n) {
    return TextFormField(
      controller: _nationalIdController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(14),
      ],
      style: GoogleFonts.cairo(fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldFill,
        hintText: l10n.nationalIdHint,
        hintStyle:
            GoogleFonts.cairo(color: AppColors.mutedForeground, fontSize: 14),
        prefixIcon: const Icon(
          Icons.credit_card_outlined,
          color: AppColors.purple,
          size: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (v) {
        final s = v?.trim() ?? '';
        if (s.isEmpty) return l10n.fieldRequired;
        if (!RegExp(r'^\d{14}$').hasMatch(s)) {
          return l10n.invalidNationalId;
        }
        return null;
      },
    );
  }

  Widget _buildGrayTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldFill,
        hintText: hint,
        hintStyle:
            GoogleFonts.cairo(color: AppColors.mutedForeground, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.purple, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return l10n.fieldRequired;
            }
            return null;
          },
    );
  }

  Widget _buildFacultyPicker(BuildContext context, AppLocalizations l10n) {
    final canOpenList = !_loadingFaculties && _faculties.isNotEmpty;
    final canRetryLoad =
        !_loadingFaculties && _faculties.isEmpty && _facultiesLoadFailed;

    return _buildAcademicPickerTile(
      context: context,
      icon: Icons.school_outlined,
      placeholder: _loadingFaculties
          ? l10n.academicDataLoading
          : (_facultiesLoadFailed
              ? l10n.academicDataUnavailable
              : l10n.tapToSelectFaculty),
      selectedName:
          _selectedFaculty != null ? _entityName(_selectedFaculty!) : null,
      enabled: canOpenList || canRetryLoad,
      onTap: canRetryLoad
          ? _loadFaculties
          : canOpenList
              ? () => _openAcademicSheet(
                    title: l10n.faculty,
                    items: _faculties,
                    selectedId: _entityId(_selectedFaculty),
                    onPick: (map) {
                      setState(() => _selectedFaculty = map);
                      final id = _entityId(map);
                      if (id != null) _loadSections(id);
                    },
                  )
              : null,
    );
  }

  Widget _buildSectionPicker(BuildContext context, AppLocalizations l10n) {
    final ready = _entityId(_selectedFaculty) != null;
    return _buildAcademicPickerTile(
      context: context,
      icon: Icons.groups_2_outlined,
      placeholder: !ready
          ? l10n.selectFacultyFirst
          : (_loadingSections
              ? l10n.academicDataLoading
              : l10n.tapToSelectSection),
      selectedName:
          _selectedSection != null ? _entityName(_selectedSection!) : null,
      enabled: ready && !_loadingSections && _sections.isNotEmpty,
      onTap: !ready || _loadingSections
          ? null
          : () => _openAcademicSheet(
                title: l10n.section,
                items: _sections,
                selectedId: _entityId(_selectedSection),
                onPick: (map) {
                  setState(() => _selectedSection = map);
                  final id = _entityId(map);
                  if (id != null) _loadGrades(id);
                },
              ),
    );
  }

  Future<void> _openAcademicSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required String? selectedId,
    required void Function(Map<String, dynamic>) onPick,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final map = items[index];
                      final id = map['id']?.toString() ?? '';
                      final name = _entityName(map);
                      return RadioListTile<String>(
                        value: id,
                        groupValue: selectedId,
                        onChanged: (_) {
                          onPick(map);
                          Navigator.of(ctx).pop();
                        },
                        title: Text(
                          name,
                          style: GoogleFonts.cairo(fontSize: 14),
                        ),
                        selected: selectedId == id,
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
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
        );
      },
    );
  }

  Widget _buildAcademicPickerTile({
    required BuildContext context,
    required IconData icon,
    required String placeholder,
    required String? selectedName,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final display = selectedName ?? placeholder;
    final isPlaceholder = selectedName == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackOverlay20,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled ? AppColors.purple : AppColors.mutedForeground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  display,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: isPlaceholder
                        ? AppColors.mutedForeground
                        : AppColors.foreground,
                  ),
                ),
              ),
              if (enabled)
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _headerNavy,
              _buttonTealEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _headerNavy.withValues(alpha: 0.35),
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
            foregroundColor: AppColors.pureWhite,
            disabledForegroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.pureWhite,
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Center(
      child: InkWell(
        onTap: () => context.push(RouteNames.supportAndHelp),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                size: 28,
                color: _headerNavy,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.contactUs,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _headerNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
