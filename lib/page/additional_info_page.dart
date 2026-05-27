import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../api/auth_api.dart';
import '../component/picker_option.dart';
import '../model/user_profile.dart';
import 'dashboard_page.dart';

class AdditionalInfoPage extends StatefulWidget {
  final String username;
  final String password;
  final int schoolId;

  const AdditionalInfoPage({super.key, this.username = '', this.password = '', this.schoolId = 1});

  @override
  State<AdditionalInfoPage> createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // 필수 필드
  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  String _selectedGrade = '1학년';

  // 선택 필드
  final _gpaCtrl = TextEditingController();
  int? _incomeBracket;
  XFile? _profileImage;
  bool _isLoading = false;

  final _picker = ImagePicker();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _grades = ['1학년', '2학년', '3학년', '4학년', '5학년(초과학기)'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    _departmentCtrl.dispose();
    _gpaCtrl.dispose();
    super.dispose();
  }

  // ── 이미지 선택 ────────────────────────────────────────────
  Future<void> _pickImage(ImageSource src) async {
    Navigator.pop(context);
    final p = await _picker.pickImage(source: src, imageQuality: 90);
    if (p != null) setState(() => _profileImage = p);
  }

  void _showImagePicker() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
          ),
          const Text('프로필 사진 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          PickerOption(icon: Icons.photo_library_rounded, label: '갤러리에서 선택', color: Colors.indigo, onTap: () => _pickImage(ImageSource.gallery)),
          PickerOption(icon: Icons.camera_alt_rounded, label: '카메라로 촬영', color: Colors.blueAccent, onTap: () => _pickImage(ImageSource.camera)),
          if (_profileImage != null)
            PickerOption(
              icon: Icons.delete_outline_rounded,
              label: '사진 제거',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                setState(() => _profileImage = null);
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  // ── 완료 ───────────────────────────────────────────────────
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    double? gpa;
    if (_gpaCtrl.text.trim().isNotEmpty) {
      gpa = double.tryParse(_gpaCtrl.text.trim());
      if (gpa == null || gpa < 0.0 || gpa > 4.5) {
        _showError('학점은 0.0 ~ 4.5 사이의 숫자를 입력해주세요.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final gradeString = _selectedGrade.replaceAll(RegExp(r'[^0-9]'), '');
      final gradeInt = int.tryParse(gradeString) ?? 1;

      final data = {
        "login_id": widget.username,
        "school_id": widget.schoolId,
        "student_id": _studentIdCtrl.text.trim(),
        "name": _nameCtrl.text.trim(),
        "password": widget.password,
        "grade": gradeInt,
        "major": _departmentCtrl.text.trim(),
        "gpa": gpa ?? 0.0,
        "income_bracket": _incomeBracket ?? 0,
      };

      final response = await AuthApi.submitAdditionalInfo(
        data,
        imagePath: _profileImage?.path,
      );
      if (response['status'] == 'success') {
        final resData = response['data'];
        await AuthApi.saveTokens(resData['access_token'], resData['refresh_token']);

        final profile = UserProfile(
          name: _nameCtrl.text.trim(),
          studentId: _studentIdCtrl.text.trim(),
          department: _departmentCtrl.text.trim(),
          grade: _selectedGrade,
          gpa: gpa,
          incomeBracket: _incomeBracket,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDashboardPage(initialProfile: profile, initialProfileImage: _profileImage),
          ),
        );
      } else {
        if (!mounted) return;
        _showError(response['message'] ?? '정보 등록 실패');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('서버 통신 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // ── 헤더 ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 28, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '추가 정보 입력',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      Text('서비스 이용을 위해 학생 정보를 입력해주세요.', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 14)),
                    ],
                  ),
                ),
              ),

              // ── 프로필 사진 (선택) ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    children: [
                      _sectionLabel('프로필 사진', isRequired: false),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _showImagePicker,
                          child: Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.indigo.shade100,
                                  border: Border.all(color: Colors.indigo.shade200, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
                                  image: _profileImage != null ? DecorationImage(image: FileImage(File(_profileImage!.path)), fit: BoxFit.cover) : null,
                                ),
                                child: _profileImage == null ? Icon(Icons.person_rounded, size: 52, color: Colors.indigo.shade300) : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('탭하여 사진 선택 (선택)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),

              // ── 필수 정보 ──────────────────────────────────
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('필수 정보'),
                        const SizedBox(height: 12),
                        _buildCard([
                          _inputField(
                            controller: _nameCtrl,
                            label: '이름',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? '이름을 입력해주세요.' : null,
                          ),
                          const SizedBox(height: 14),
                          _inputField(
                            controller: _studentIdCtrl,
                            label: '학번',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => v == null || v.trim().isEmpty ? '학번을 입력해주세요.' : null,
                          ),
                          const SizedBox(height: 14),
                          _inputField(
                            controller: _departmentCtrl,
                            label: '학과',
                            icon: Icons.school_outlined,
                            validator: (v) => v == null || v.trim().isEmpty ? '학과를 입력해주세요.' : null,
                          ),
                          const SizedBox(height: 14),
                          _gradeDropdown(),
                        ]),

                        // ── 선택 정보 ────────────────────────
                        const SizedBox(height: 24),
                        _sectionLabel('선택 정보', isRequired: false),
                        const SizedBox(height: 12),
                        _buildCard([
                          _inputField(
                            controller: _gpaCtrl,
                            label: '학점 (GPA)',
                            icon: Icons.grade_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isRequired: false,
                          ),
                          const SizedBox(height: 14),
                          _incomeBracketSelector(),
                        ]),

                        const SizedBox(height: 32),

                        // ── 완료 버튼 ────────────────────────
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('정보 입력 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF3949AB),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                        SizedBox(height: bottom + 28),
                      ],
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

  // ── 헬퍼 위젯들 ───────────────────────────────────────────

  Widget _sectionLabel(String label, {bool isRequired = true}) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      const SizedBox(width: 6),
      if (isRequired)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: const Text(
            '필수',
            style: TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: Text(
            '선택',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
        ),
    ],
  );

  Widget _buildCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    textInputAction: TextInputAction.next,
    decoration: _inputDeco(label: label, icon: icon, hint: hint),
    validator: isRequired ? validator : null,
  );

  Widget _gradeDropdown() => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedGrade,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo.shade400),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: _grades
            .map(
              (g) => DropdownMenuItem(
                value: g,
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 18, color: Colors.indigo.shade400),
                    const SizedBox(width: 10),
                    Text(g),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedGrade = v!),
      ),
    ),
  );

  Widget _incomeBracketSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.indigo.shade400),
          const SizedBox(width: 10),
          Text('소득분위', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          const Spacer(),
          if (_incomeBracket != null)
            Text(
              '$_incomeBracket분위',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
            )
          else
            Text('선택 안 함', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(10, (i) {
          final bracket = i + 1;
          final isSelected = _incomeBracket == bracket;
          return GestureDetector(
            onTap: () => setState(() => _incomeBracket = isSelected ? null : bracket),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3949AB) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? const Color(0xFF3949AB) : Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  '$bracket',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade600),
                ),
              ),
            ),
          );
        }),
      ),
    ],
  );

  InputDecoration _inputDeco({required String label, required IconData icon, String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: Colors.indigo.shade400, size: 20),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
