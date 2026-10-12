// profiles_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'profile_settings_screen.dart';
import 'widgets/app_dialogs.dart';

class ProfilesTab extends StatefulWidget {
  final String activeProfileId;
  final String userName;
  final Function(String, String, String?)? onActiveProfileChanged;
  final VoidCallback? onDataChanged;

  const ProfilesTab({
    super.key,
    this.activeProfileId = 'main',
    this.userName = 'ผู้ใช้งาน',
    this.onActiveProfileChanged,
    this.onDataChanged,
  });

  @override
  State<ProfilesTab> createState() => ProfilesTabState();
}

class ProfilesTabState extends State<ProfilesTab> {
  late String _activeProfileId;
  late String _userName;
  String? _mainImageUrl;
  String? _mainGender;
  String? _mainBirthDate;
  List<Map<String, dynamic>> _subProfiles = [];
  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _activeProfileId = widget.activeProfileId;
    _userName = widget.userName;
    _fetchUserData();
    _fetchSubProfiles();
  }

  @override
  void didUpdateWidget(covariant ProfilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      _activeProfileId = widget.activeProfileId;
    }
    if (oldWidget.userName != widget.userName) {
      _userName = widget.userName;
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name, image_url, gender, date_of_birth')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            if (data['full_name'] != null) _userName = data['full_name'];
            _mainImageUrl = data['image_url'];
            _mainGender = data['gender'];
            _mainBirthDate = data['date_of_birth'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchSubProfiles() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('sub_profiles')
            .select('*')
            .eq('parent_user_id', user.id)
            .order('created_at', ascending: true);

        if (mounted) {
          setState(() {
            _subProfiles = List<Map<String, dynamic>>.from(data);
            _isLoadingProfiles = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  Future<void> _addSubProfile(String profileName) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('sub_profiles').insert({
          'parent_user_id': user.id,
          'name': profileName,
        });
        await _fetchSubProfiles();
        widget.onDataChanged?.call();
        if (mounted) {
          AppSnackBar.showSuccess(context, 'เพิ่มโปรไฟล์เรียบร้อย');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'เกิดข้อผิดพลาดในการเพิ่มโปรไฟล์: $e');
      }
    }
  }

  Future<void> _handleDeleteProfile(String id) async {
    try {
      setState(() => _isLoadingProfiles = true);

      // 1. ลบประวัติการสแกนของโปรไฟล์นี้ทิ้งทั้งหมด
      await Supabase.instance.client.from('scan_history').delete().eq('profile_id', id);

      // 2. ลบโปรไฟล์ออกจากตาราง sub_profiles
      await Supabase.instance.client.from('sub_profiles').delete().eq('id', id);

      if (_activeProfileId == id) {
        _activeProfileId = 'main';
        widget.onActiveProfileChanged?.call('main', _userName, _mainImageUrl);
      }

      await _fetchSubProfiles();
      widget.onDataChanged?.call();

      if (mounted) {
        AppSnackBar.showSuccess(context, 'ลบโปรไฟล์เรียบร้อย');
      }
    } catch (e) {
      setState(() => _isLoadingProfiles = false);
      if (mounted) {
        AppSnackBar.showError(context, 'เกิดข้อผิดพลาดในการลบโปรไฟล์: $e');
      }
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _switchProfile(String profileId, String name, String? imageUrl) {
    setState(() {
      _activeProfileId = profileId;
    });
    widget.onActiveProfileChanged?.call(profileId, name, imageUrl);
  }

  void _showAddProfileDialog() async {
    final profileName = await AppDialog.showTextInput(
      context: context,
      title: 'สร้างโปรไฟล์ใหม่',
      message: 'กรุณากรอกชื่อสำหรับโปรไฟล์ใหม่นี้',
      hintText: 'กรอกชื่อโปรไฟล์',
      confirmText: 'บันทึก',
      cancelText: 'ยกเลิก',
      icon: Icons.person_add_outlined,
    );

    if (profileName != null && profileName.isNotEmpty) {
      setState(() => _isLoadingProfiles = true);
      await _addSubProfile(profileName);
    }
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, bool isActive) {
    bool isMain = profile['isMain'] ?? false;
    String profileId = profile['id'];
    String profileName = profile['name'] ?? '';
    String? imageUrl = profile['image_url'];
    String? gender = profile['gender'];
    String? dob = profile['date_of_birth'];

    String roleText = isMain ? "โปรไฟล์หลัก" : "โปรไฟล์รอง";
    String displayName = isMain ? (profileName.startsWith("คุณ") ? profileName : "คุณ$profileName") : profileName;

    return Padding(
      padding: EdgeInsets.only(bottom: isActive ? 0 : 12.0),
      child: GestureDetector(
        onTap: () => _switchProfile(profileId, profileName, imageUrl),
        onDoubleTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSettingsScreen(
                isMain: isMain,
                profileId: profileId,
                profileName: profileName,
                imageUrl: imageUrl,
                onDelete: _handleDeleteProfile,
                onLogout: _handleLogout,
              ),
            ),
          );
          if (result == true) {
            if (isMain) {
              await _fetchUserData();
            }
            await _fetchSubProfiles();
            widget.onDataChanged?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? const Color(0xFF009688) : Colors.grey.shade200,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1)] : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: isActive ? 24 : 20,
                backgroundColor: const Color(0xFFF5F5F5),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? ResizeImage(NetworkImage(imageUrl), width: 120, height: 120)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Icon(Icons.person_outline, color: Colors.grey, size: isActive ? 28 : 24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(roleText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (isActive) ...[
                      if (gender != null && gender.toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text("เพศ: $gender", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                      if (dob != null && dob.toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text("วันเกิด: $dob", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ],
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "กำลังใช้งาน",
                    style: TextStyle(fontSize: 12, color: Color(0xFF009688), fontWeight: FontWeight.bold),
                  ),
                ),
              if (!isActive) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> mainProfileData = {
      'id': 'main',
      'name': _userName,
      'image_url': _mainImageUrl,
      'gender': _mainGender,
      'date_of_birth': _mainBirthDate,
      'isMain': true,
    };

    List<Map<String, dynamic>> allProfiles = [
      mainProfileData,
      ..._subProfiles.map((p) => {
        'id': p['id'],
        'name': p['name'],
        'image_url': p['image_url'],
        'gender': p['gender'],
        'date_of_birth': p['date_of_birth'],
        'isMain': false,
      })
    ];

    Map<String, dynamic> activeProfile = allProfiles.firstWhere(
      (p) => p['id'] == _activeProfileId, 
      orElse: () => mainProfileData
    );
    List<Map<String, dynamic>> inactiveProfiles = allProfiles.where((p) => p['id'] != _activeProfileId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "โปรไฟล์",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 32),

          // 1. โปรไฟล์ที่กำลังใช้งาน (Active Profile)
          _buildProfileCard(activeProfile, true),

          const SizedBox(height: 32),
          const Text("โปรไฟล์อื่น", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 2. ลิสต์โปรไฟล์ที่ไม่ได้ใช้งาน
          if (_isLoadingProfiles)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF009688)),
              ),
            )
          else
            ...inactiveProfiles.map((profile) => _buildProfileCard(profile, false)),

          const SizedBox(height: 16),

          // 3. ปุ่มเพิ่มโปรไฟล์
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: _showAddProfileDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF009688), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFF009688)),
                  SizedBox(width: 8),
                  Text(
                    "เพิ่มโปรไฟล์",
                    style: TextStyle(fontSize: 16, color: Color(0xFF009688), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
