import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/lost_found_service.dart';
import '../../component/common_widgets.dart';
import '../../model/lost_found_model.dart';

class LostFoundWritePage extends StatefulWidget {
  final ValueChanged<LostFoundPost> onSubmit;
  final LostFoundPost? initialPost; // null이면 신규 작성, not-null이면 수정 모드
  const LostFoundWritePage({
    super.key,
    required this.onSubmit,
    this.initialPost,
  });
  @override
  State<LostFoundWritePage> createState() => _LostFoundWritePageState();
}

class _LostFoundWritePageState extends State<LostFoundWritePage> {
  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _locationCtrl;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final List<String> _categories = [
    '전자기기',
    '지갑/카드',
    '의류/액세서리',
    '가방/파우치',
    '학용품',
    '열쇠/USB',
    '기타',
  ];
  String? _selectedCategory;

  XFile? _newImageFile;
  String? _existingImageUrl;
  bool _isSubmitting = false;
  bool _isAnonymous = false;
  bool _status = false; // false = 보관중, true = 주인 찾음

  bool get _isEditMode => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPost;
    _itemNameCtrl = TextEditingController(text: p?.itemName ?? '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _locationCtrl = TextEditingController(text: p?.place ?? '');
    _isAnonymous = p?.isAnonymous ?? false;
    _status = p?.status ?? false;

    if (p?.category != null &&
        p!.category.isNotEmpty &&
        _categories.contains(p.category)) {
      _selectedCategory = p.category;
    }

    if (p?.imagePath != null) _existingImageUrl = p!.imagePath;
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _newImageFile = picked;
        _existingImageUrl = null;
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text(
              '사진 첨부',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.indigo,
                ),
              ),
              title: const Text(
                '갤러리에서 선택',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.blueAccent,
                ),
              ),
              title: const Text(
                '카메라로 촬영',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_newImageFile != null || _existingImageUrl != null)
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  '사진 삭제',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _newImageFile = null;
                    _existingImageUrl = null;
                  });
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        final updatedPost = await LostFoundService.editItem(
          itemId: widget.initialPost!.itemId,
          title: _itemNameCtrl.text.trim(),
          isAnonymous: _isAnonymous,
          category: _selectedCategory ?? '기타',
          place: _locationCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          status: _status,
          imagePath: _newImageFile?.path,
        );

        if (updatedPost != null) {
          widget.onSubmit(updatedPost);
        } else {
          // Fallback if API fails/mock
          final post = widget.initialPost!.copyWith(
            itemName: _itemNameCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            category: _selectedCategory ?? '기타',
            place: _locationCtrl.text.trim(),
            isAnonymous: _isAnonymous,
            imagePath: _newImageFile?.path ?? _existingImageUrl,
            status: _status,
            clearImage: _newImageFile == null && _existingImageUrl == null,
          );
          widget.onSubmit(post);
        }
      } else {
        final newPost = await LostFoundService.createPost(
          schoolId: 1,
          title: _itemNameCtrl.text.trim(),
          isAnonymous: _isAnonymous,
          category: _selectedCategory ?? '기타',
          place: _locationCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          imagePath: _newImageFile?.path,
        );

        if (newPost != null) {
          widget.onSubmit(newPost);
        } else {
          final fallbackPost = LostItemPost(
            itemId: DateTime.now().millisecondsSinceEpoch,
            schoolId: 1,
            placeId: null,
            studentId: 1,
            title: _itemNameCtrl.text.trim(),
            category: _selectedCategory ?? '기타',
            place: _locationCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            isAnonymous: _isAnonymous,
            imgFilePath: _newImageFile?.path ?? '',
            createTime: () {
              final now = DateTime.now();
              return "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
            }(),
          );
          widget.onSubmit(fallbackPost);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '신고 내용이 수정되었습니다.' : '분실물 신고가 접수되었습니다.'),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditMode ? '신고 내용 수정' : '분실물 신고 작성',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop =
              await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('취소하시겠습니까?'),
                  content: const Text('내용이 저장되지 않았습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        '아니오',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '예',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSectionLabel('카테고리 *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: _inputDeco(
                            '카테고리를 선택해주세요',
                            Icons.category_outlined,
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCategory = val);
                          },
                          validator: (v) =>
                              v == null || v.isEmpty ? '카테고리를 선택해주세요' : null,
                        ),
                        const SizedBox(height: 16),
                        buildSectionLabel('물건 이름 *'),
                        TextFormField(
                          controller: _itemNameCtrl,
                          decoration: _inputDeco(
                            '예: 에어팟 프로, 검정 지갑',
                            Icons.inventory_2_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? '물건 이름을 입력해주세요'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        buildSectionLabel('물건 특징 *'),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 3,
                          decoration: _inputDeco(
                            '색상, 브랜드, 특이사항 등을 입력해주세요',
                            Icons.description_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? '특징을 입력해주세요'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        buildSectionLabel('분실 장소 *'),
                        TextFormField(
                          controller: _locationCtrl,
                          decoration: _inputDeco(
                            '예: 비전타워 3층 스터디룸',
                            Icons.location_on_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? '분실 장소를 입력해주세요'
                              : null,
                        ),
                        // ── 사진 첨부 ──────────────────────────────────────
                        buildSectionLabel('사진 첨부 (선택, 1장)'),
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height:
                                (_newImageFile == null &&
                                    _existingImageUrl == null)
                                ? 100
                                : 220,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (_newImageFile != null ||
                                        _existingImageUrl != null)
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                                width:
                                    (_newImageFile != null ||
                                        _existingImageUrl != null)
                                    ? 1.5
                                    : 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child:
                                (_newImageFile == null &&
                                    _existingImageUrl == null)
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 36,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '탭하여 사진 추가',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: _newImageFile != null
                                            ? Image.file(
                                                File(_newImageFile!.path),
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                _existingImageUrl!.startsWith(
                                                      'http',
                                                    )
                                                    ? _existingImageUrl!
                                                    : '${LostFoundService.baseUrl}$_existingImageUrl',
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                    ),
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _newImageFile = null;
                                            _existingImageUrl = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _showImagePicker,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '변경',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
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
                        ),
                        const SizedBox(height: 16),
                        // ── 익명 설정 ──────────────────────────────────────
                        GestureDetector(
                          onTap: () => setState(() {
                            _isAnonymous = !_isAnonymous;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _isAnonymous
                                  ? Colors.red.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isAnonymous
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                                width: _isAnonymous ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _isAnonymous
                                        ? Colors.redAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _isAnonymous
                                          ? Colors.redAccent
                                          : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _isAnonymous
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '익명으로 작성하기',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isAnonymous
                                            ? Colors.redAccent
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '선택 시 작성자 정보가 공개되지 않습니다',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (_isAnonymous)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '익명',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // ── 상태 변경 (수정 모드일 때만) ─────────────────────────
                        if (_isEditMode) ...[
                          const SizedBox(height: 16),
                          buildSectionLabel('상태 변경'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _status ? '주인 찾음' : '보관중',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _status
                                        ? Colors.grey.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                                Switch(
                                  value: _status,
                                  activeThumbColor: Colors.grey.shade600,
                                  inactiveThumbColor: Colors.orange.shade400,
                                  inactiveTrackColor: Colors.orange.shade100,
                                  onChanged: (val) {
                                    setState(() => _status = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting
                          ? (_isEditMode ? '수정 중...' : '접수 중...')
                          : (_isEditMode ? '수정 완료' : '신고 접수하기'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
    String hint,
    IconData icon, {
    bool disabled = false,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(
      icon,
      size: 20,
      color: disabled ? Colors.grey.shade400 : Colors.redAccent,
    ),
    filled: true,
    fillColor: disabled ? Colors.grey.shade100 : Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
