import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'widgets/app_dialogs.dart';

class ProfileSettingsScreen extends StatelessWidget {
  final bool isMain;
  final String profileId;
  final String profileName;
  final String? imageUrl;
  final Function(String) onDelete;
  final VoidCallback onLogout;

  const ProfileSettingsScreen({
    super.key,
    required this.isMain,
    required this.profileId,
    required this.profileName,
    this.imageUrl,
    required this.onDelete,
    required this.onLogout,
  });

  void _showConfirmDialog(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      isDanger: true,
      icon: isMain ? Icons.logout_rounded : Icons.delete_forever_rounded,
      title: isMain ? 'ออกจากระบบ' : 'ลบโปรไฟล์',
      message: isMain
          ? 'คุณต้องการออกจากระบบใช่หรือไม่?'
          : 'คุณแน่ใจหรือไม่ที่จะลบโปรไฟล์ "$profileName"?\n\nข้อมูลประวัติการสแกนของโปรไฟล์นี้จะถูกลบทั้งหมดและไม่สามารถกู้คืนได้',
      confirmText: isMain ? 'ออกจากระบบ' : 'ลบโปรไฟล์',
      cancelText: 'ยกเลิก',
    );

    if (confirmed == true && context.mounted) {
      if (isMain) {
        onLogout();
      } else {
        onDelete(profileId);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'โปรไฟล์ของฉัน',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // --- รูปโปรไฟล์ ---
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0F2F1),
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF009688), size: 60)
                  : null,
            ),
            const SizedBox(height: 24),

            // --- ชื่อและสถานะ ---
            Text(
              isMain
                  ? (profileName.startsWith('คุณ') ? profileName : 'คุณ$profileName')
                  : profileName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'ผู้ใช้งานทั่วไป',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // --- ปุ่มแก้ไขข้อมูลโปรไฟล์ (สีเขียวทึบ) ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'แก้ไขข้อมูลโปรไฟล์',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () async {
                  final cleanName = isMain && profileName.startsWith('คุณ')
                      ? profileName.substring(3)
                      : profileName;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        isMain: isMain,
                        profileId: profileId,
                        profileName: cleanName,
                        onLogout: onLogout,
                        onDelete: onDelete,
                      ),
                    ),
                  );
                  // 🌟 ถ้าบันทึกสำเร็จ (return true) ให้เด้งกลับไปหน้าโปรไฟล์หลักเพื่อรีเฟรชข้อมูล
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- ปุ่มออกจากระบบ / ลบโปรไฟล์ (สีขาวขอบแดง) ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF44336), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  isMain ? Icons.logout : Icons.delete_outline,
                  color: const Color(0xFFF44336),
                  size: 20,
                ),
                label: Text(
                  isMain ? 'ออกจากระบบ' : 'ลบโปรไฟล์นี้',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF44336)),
                ),
                onPressed: () => _showConfirmDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
