import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/auth_api.dart';
import '../component/picker_option.dart';
import '../model/user_profile.dart';
import 'login/login_page.dart';
import 'package:alpha_kit/config/api_constants.dart';

class ProfileSettingsPage extends StatefulWidget {
  final UserProfile profile;
  final XFile? profileImage;
  final ValueChanged<UserProfile> onProfileChanged;
  final ValueChanged<XFile?> onImageChanged;
  const ProfileSettingsPage({super.key, required this.profile, required this.profileImage, required this.onProfileChanged, required this.onImageChanged});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _picker = ImagePicker();
  late UserProfile _profile;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _image = widget.profileImage;
  }

  Future<void> _pickImage(ImageSource src) async {
    Navigator.pop(context);
    final p = await _picker.pickImage(source: src, imageQuality: 90);
    if (p != null) {
      setState(() => _image = p);
      widget.onImageChanged(p);
    }
  }

  void _showPicker() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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
          const Text('프로필 사진 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          PickerOption(icon: Icons.photo_library_rounded, label: '갤러리에서 선택', color: Colors.indigo, onTap: () => _pickImage(ImageSource.gallery)),
          PickerOption(icon: Icons.camera_alt_rounded, label: '카메라로 촬영', color: Colors.blueAccent, onTap: () => _pickImage(ImageSource.camera)),
          if (_image != null)
            PickerOption(
              icon: Icons.delete_outline_rounded,
              label: '현재 사진 삭제',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                setState(() => _image = null);
                widget.onImageChanged(null);
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  void _showEdit() {
    final n = TextEditingController(text: _profile.name),
        d = TextEditingController(text: _profile.department),
        id = TextEditingController(text: _profile.studentId),
        gpa = TextEditingController(text: _profile.gpa != null ? _profile.gpa!.toString() : '');
    int gradeInt = int.tryParse(_profile.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    int? incomeBracket = _profile.incomeBracket;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('내 정보 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 필수 항목
                _sectionChip('필수', Colors.indigo),
                const SizedBox(height: 10),
                _editF('이름', n, Icons.person_outline),
                const SizedBox(height: 12),
                _editF('학과', d, Icons.school_outlined),
                const SizedBox(height: 12),
                _editF('학번', id, Icons.badge_outlined, enabled: false),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: gradeInt,
                  decoration: InputDecoration(
                    labelText: '학년',
                    prefixIcon: const Icon(Icons.bar_chart_outlined, size: 20, color: Colors.indigo),
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
                      borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: List.generate(6, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}학년'))),
                  onChanged: (v) => setDialogState(() => gradeInt = v!),
                ),
                const SizedBox(height: 18),
                // 선택 항목
                _sectionChip('선택', Colors.grey),
                const SizedBox(height: 10),
                _editF('학점 (GPA)', gpa, Icons.grade_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                // 소득분위
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text('소득분위', style: TextStyle(fontSize: 13, color: Colors.black87)),
                    const Spacer(),
                    if (incomeBracket != null)
                      Text(
                        '$incomeBracket분위',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(10, (i) {
                    final b = i + 1;
                    final sel = incomeBracket == b;
                    return GestureDetector(
                      onTap: () => setDialogState(() => incomeBracket = sel ? null : b),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 36,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sel ? Colors.indigo : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sel ? Colors.indigo : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            '$b',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
            ),
            FilledButton(
              onPressed: () async {
                final parsedGpa = double.tryParse(gpa.text.trim());

                final reqData = {"name": n.text.trim(), "year": gradeInt, "gpa": parsedGpa ?? 0.0, "income_bracket": incomeBracket ?? 0, "studentId": id.text.trim()};

                try {
                  final response = await AuthApi.updateUserInfo(reqData, imagePath: _image?.path);

                  if (response['status'] == 'success') {
                    final u = _profile.copyWith(
                      name: n.text.trim(),
                      department: d.text.trim(),
                      studentId: id.text.trim(),
                      grade: '$gradeInt학년',
                      gpa: gpa.text.trim().isEmpty ? null : parsedGpa,
                      incomeBracket: incomeBracket,
                    );
                    setState(() => _profile = u);
                    widget.onProfileChanged(u);
                    if (context.mounted) Navigator.pop(ctx);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? '정보 수정 실패')));
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버 통신 중 오류가 발생했습니다.')));
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
    ),
  );

  Widget _editF(String label, TextEditingController ctrl, IconData icon, {TextInputType keyboardType = TextInputType.text, bool enabled = true}) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: enabled ? Colors.indigo : Colors.grey),
      filled: true,
      fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
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
        borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    '설정',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                bottom: -44,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showPicker,
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.indigo.shade200,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                            image: _image != null
                                ? DecorationImage(image: FileImage(File(_image!.path)), fit: BoxFit.cover)
                                : (_profile.profileImgUrl != null
                                      ? DecorationImage(image: NetworkImage('${ApiConstants.baseUrl}${_profile.profileImgUrl}'), fit: BoxFit.cover)
                                      : null),
                          ),
                          child: _image == null && _profile.profileImgUrl == null ? const Icon(Icons.person_rounded, size: 52, color: Colors.white) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.indigo.shade100, width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
                            ),
                            child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.indigo.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 56, bottom: 4),
            child: Column(
              children: [
                Text(
                  _profile.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text('${_profile.department} · ${_profile.grade}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          '내 정보',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, size: 13, color: Colors.indigo.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '수정',
                                  style: TextStyle(fontSize: 12, color: Colors.indigo.shade600, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _infoR(Icons.person_outline, '이름', _profile.name),
                    _infoR(Icons.school_outlined, '학과', _profile.department),
                    _infoR(Icons.badge_outlined, '학번', _profile.studentId),
                    _infoR(Icons.bar_chart_outlined, '학년', _profile.grade, isLast: _profile.gpa == null && _profile.incomeBracket == null),
                    if (_profile.gpa != null) _infoR(Icons.grade_outlined, '학점', _profile.gpa!.toStringAsFixed(2), isLast: _profile.incomeBracket == null),
                    if (_profile.incomeBracket != null) _infoR(Icons.account_balance_wallet_outlined, '소득분위', '${_profile.incomeBracket}분위', isLast: true),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _actBtn(Icons.settings_outlined, '앱 설정', Colors.indigo, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('앱 설정 준비 중입니다.')))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actBtn(
                    Icons.logout_rounded,
                    '로그아웃',
                    Colors.redAccent,
                    () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('정말 로그아웃 하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await AuthApi.logout();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('로그아웃'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 40)),
      ],
    ),
  );

  Widget _infoR(IconData icon, String label, String value, {bool isLast = false}) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    ),
  );
  Widget _actBtn(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 공용 헬퍼
// ══════════════════════════════════════════════════════════════
