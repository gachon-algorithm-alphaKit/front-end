import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../../model/user_profile.dart';
import 'additional_info_page.dart';
import '../dashboard_page.dart';

// 지원 대학교 목록
const List<String> kSupportedUniversities = [
  '가천대학교',
  '가톨릭대학교',
  '건국대학교',
  '경희대학교',
  '고려대학교',
  '국민대학교',
  '동국대학교',
  '서강대학교',
  '서울대학교',
  '성균관대학교',
  '세종대학교',
  '숭실대학교',
  '아주대학교',
  '연세대학교',
  '이화여자대학교',
  '인하대학교',
  '중앙대학교',
  '한국외국어대학교',
  '한양대학교',
  '홍익대학교',
];

class LoginPage extends StatefulWidget {
  final bool sessionExpired;
  const LoginPage({super.key, this.sessionExpired = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자동 인증이 초기화 되었습니다. 다시 로그인 해주세요.')),
        );
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _loginIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String _selectedUniversity = '가천대학교';
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final username = _loginIdCtrl.text.trim();
      final password = _passwordCtrl.text;
      
      final response = await AuthApi.login(username, password, 1);
      
      if (response['status'] == 'success') {
        if (response['data'] == null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdditionalInfoPage(
                username: username,
                password: password,
                schoolId: 1,
              ),
            ),
          );
        } else {
          final data = response['data'];
          await AuthApi.saveTokens(data['access_token'], data['refresh_token']);
          if (!mounted) return;
          
          final profile = UserProfile.fromJson(data as Map<String, dynamic>);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainDashboardPage(initialProfile: profile),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? '로그인 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 통신 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/icon/alphakit.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AlphaKit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '학교 계정으로 로그인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── 대학교 선택 ──────────────────────────────────
                    _UniversityDropdown(
                      value: _selectedUniversity,
                      onChanged: (v) => setState(() => _selectedUniversity = v!),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _loginIdCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: '아이디',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? '아이디를 입력해주세요.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      onFieldSubmitted: (_) => _login(),
                      decoration: _inputDecoration(
                        label: '비밀번호',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? '비밀번호를 입력해주세요.'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton.icon(
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('로그인'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ── 대학교 선택 드롭다운 위젯 ────────────────────────────────────
class _UniversityDropdown extends StatelessWidget {
  const _UniversityDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: kSupportedUniversities
              .map(
                (uni) => DropdownMenuItem(
                  value: uni,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 10),
                      Text(uni),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
