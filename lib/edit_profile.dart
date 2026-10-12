// edit_profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/app_dialogs.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isMain;
  final String profileId;
  final String profileName;
  final VoidCallback onLogout;
  final Function(String) onDelete;

  const EditProfileScreen({
    super.key,
    required this.isMain,
    required this.profileId,
    required this.profileName,
    required this.onLogout,
    required this.onDelete,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  String _selectedGender = 'ไม่ระบุ';
  String _selectedDate = '';
  
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;

  final List<String> _monthsThai = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  @override
  void initState() {
    super.initState();
    String initialName = widget.profileName;
    if (widget.isMain && initialName.startsWith('คุณ')) {
      initialName = initialName.substring(3);
    }
    _nameController = TextEditingController(text: initialName);
    _loadProfileData();
  }

  // โหลดข้อมูลเดิมจาก Supabase
  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final targetId = widget.isMain ? user?.id : widget.profileId;
      if (targetId == null) return;

      final tableName = widget.isMain ? 'profiles' : 'sub_profiles';
      final nameColumn = widget.isMain ? 'full_name' : 'name';
      final data = await Supabase.instance.client
          .from(tableName)
          .select('$nameColumn, image_url, gender, date_of_birth')
          .eq('id', targetId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          final dbName = data[nameColumn];
          if (dbName != null && dbName.toString().trim().isNotEmpty) {
            String nameStr = dbName.toString().trim();
            if (widget.isMain && nameStr.startsWith('คุณ')) {
              nameStr = nameStr.substring(3);
            }
            _nameController.text = nameStr;
          }
          _currentImageUrl = data['image_url'];
          if (data['gender'] != null) _selectedGender = data['gender'];
          if (data['date_of_birth'] != null) _selectedDate = data['date_of_birth'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  // เลือกรูปภาพจากคลัง
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  // เลือกวันเกิด
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        int yearBuddhist = picked.year + 543;
        _selectedDate = "${picked.day} ${_monthsThai[picked.month - 1]} $yearBuddhist";
      });
    }
  }

  // บันทึกข้อมูล
  Future<void> _saveData() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      AppSnackBar.showWarning(context, 'กรุณากรอกชื่อเรียก');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final targetId = widget.isMain ? user?.id : widget.profileId;
      if (targetId == null) {
        AppSnackBar.showError(context, 'ไม่พบข้อมูลผู้ใช้งาน');
        return;
      }

      String? imageUrl = _currentImageUrl;

      // 1. อัปโหลดรูปภาพลง Bucket 'image_profile' (ถ้ามีการเปลี่ยนรูป)
      if (_imageFile != null) {
        final fileExt = _imageFile!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '$targetId/$fileName';

        await Supabase.instance.client.storage
            .from('image_profile')
            .upload(filePath, _imageFile!);

        imageUrl = Supabase.instance.client.storage
            .from('image_profile')
            .getPublicUrl(filePath);
      }

      // 2. อัปเดตข้อมูลตาราง profiles หรือ sub_profiles
      final tableName = widget.isMain ? 'profiles' : 'sub_profiles';
      final updateData = {
        if (widget.isMain) 'full_name': trimmedName else 'name': trimmedName,
        'gender': _selectedGender,
        'date_of_birth': _selectedDate,
        'image_url': imageUrl,
      };

      await Supabase.instance.client
          .from(tableName)
          .update(updateData)
          .eq('id', targetId);

      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'บันทึกข้อมูลเรียบร้อยแล้ว');
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConfirmDialog() async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      isDanger: true,
      icon: widget.isMain ? Icons.logout_rounded : Icons.delete_forever_rounded,
      title: widget.isMain ? 'ออกจากระบบ' : 'ลบโปรไฟล์นี้',
      message: widget.isMain
          ? 'คุณต้องการออกจากระบบใช่หรือไม่?'
          : 'คุณแน่ใจหรือไม่ที่จะลบโปรไฟล์นี้?\n\nข้อมูลการสแกนทั้งหมดจะถูกลบและไม่สามารถกู้คืนได้',
      confirmText: widget.isMain ? 'ออกจากระบบ' : 'ลบโปรไฟล์',
      cancelText: 'ยกเลิก',
    );

    if (confirmed == true && mounted) {
      if (widget.isMain) {
        widget.onLogout();
      } else {
        widget.onDelete(widget.profileId);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF009688);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('แก้ไขข้อมูลโปรไฟล์', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryTeal))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            image: _imageFile != null 
                                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                : (_currentImageUrl != null 
                                    ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover) 
                                    : null),
                          ),
                          child: (_imageFile == null && _currentImageUrl == null)
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryTeal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                const Text('ชื่อเรียก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal)),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('เพศ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGenderOption('ชาย'),
                    const SizedBox(width: 12),
                    _buildGenderOption('หญิง'),
                    const SizedBox(width: 12),
                    _buildGenderOption('ไม่ระบุ'),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('วันเกิด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedDate.isEmpty ? 'เลือกวันเกิด' : _selectedDate, style: TextStyle(color: _selectedDate.isEmpty ? Colors.grey : Colors.black87, fontSize: 16)),
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _saveData,
                    child: const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF44336), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showConfirmDialog,
                    child: Text(
                      widget.isMain ? 'ออกจากระบบ' : 'ลบโปรไฟล์นี้',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF44336)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildGenderOption(String title) {
    bool isSelected = _selectedGender == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF009688) : Colors.white,
            border: Border.all(color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }
}