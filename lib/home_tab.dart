// home_tab.dart
import 'package:flutter/material.dart';
import 'scan.dart';
import 'skin_diseases_page.dart';
import 'how_to_use_page.dart';

class HomeTab extends StatefulWidget {
  final String activeProfileId;
  final String activeProfileName;
  final String? activeProfileImageUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onViewAllHistory;
  final VoidCallback? onScanCompleted;

  const HomeTab({
    super.key,
    this.activeProfileId = 'main',
    this.activeProfileName = 'ผู้ใช้งาน',
    this.activeProfileImageUrl,
    this.onProfileTap,
    this.onViewAllHistory,
    this.onScanCompleted,
  });

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  bool _isDiseaseMenuExpanded = false;

  // ฟังก์ชันนี้เก็บไว้เพื่อให้ main_navigation_screen เรียกได้โดยไม่พัง (แม้เราจะซ่อนประวัติในหน้านี้แล้ว)
  Future<void> fetchRecentHistory() async {
    // ไม่ได้ใช้แสดงผลในหน้านี้แล้วตามดีไซน์ใหม่
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ส่วน Header
          GestureDetector(
            onTap: widget.onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  image: widget.activeProfileImageUrl != null && widget.activeProfileImageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: ResizeImage(
                            NetworkImage(widget.activeProfileImageUrl!),
                            width: 150,
                            height: 150,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.activeProfileImageUrl == null || widget.activeProfileImageUrl!.isEmpty
                    ? const Icon(Icons.person_outline, color: Colors.grey, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "สวัสดี",
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.2),
                  ),
                  Text(
                    widget.activeProfileName.startsWith('คุณ')
                        ? widget.activeProfileName
                        : "คุณ${widget.activeProfileName}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                  ),
                ],
              ),
            ],
          ),
          ),
          const SizedBox(height: 32),

          // 2. การ์ดสแกนรอยโรค
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF009688), // Teal color
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF009688).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                const Text(
                  "ประเมินความเสี่ยงโรคผิวหนัง",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "ตรวจวิเคราะห์เบื้องต้นด้วยระบบ AI ที่แม่นยำและ\nรวดเร็ว",
                  style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF009688),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScanScreen(profileId: widget.activeProfileId),
                        ),
                      );
                      widget.onScanCompleted?.call();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("สแกนรอยโรคทันที", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 3. เมนูเพิ่มเติม
          const Text(
            "เมนูเพิ่มเติม",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 16),

          // 3.1 เมนูคำอธิบายโรคเบื้องต้น
          _buildExpandableMenu(
            title: "คำอธิบายโรคเบื้องต้น",
            icon: Icons.description_outlined,
            isExpanded: _isDiseaseMenuExpanded,
            onTap: () {
              setState(() {
                _isDiseaseMenuExpanded = !_isDiseaseMenuExpanded;
              });
            },
            items: [
              "Melanoma",
              "BCC",
              "SCC",
              "Actinic Keratosis",
              "Melanocytic Nevi",
              "Keratosis",
              "Tinea",
              "Psoriasis"
            ],
            onItemTap: (String item) {
              try {
                final disease = skinDiseasesData.firstWhere(
                  (d) => d.name.toLowerCase() == item.toLowerCase() ||
                      (d.name.contains('Melanocytic') && item.contains('Melanocytic')),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SkinDiseaseDetailPage(disease: disease),
                  ),
                );
              } catch (e) {
                // Not found
              }
            },
          ),
          const SizedBox(height: 16),



          // 3.3 เมนูวิธีใช้งาน
          _buildSimpleMenu(
            title: "วิธีใช้งาน",
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HowToUsePage(profileId: widget.activeProfileId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับเมนูที่ไม่มี Dropdown (เอาไว้ใช้กับ วิธีใช้งาน)
  Widget _buildSimpleMenu({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1), // Light teal
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF009688), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMenu({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<String> items,
    String? highlightedItem,
    Function(String)? onItemTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // กล่องเมนูหลัก
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1), // Light teal
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF009688), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        // เมนูย่อยเมื่อกางออก
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 36),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // เส้นแนวตั้งเชื่อมเมนู
                Container(
                  width: 2,
                  height: (items.length * 56.0) - 16, // คำนวณความสูงคร่าวๆ
                  color: const Color(0xFFE0F2F1),
                  margin: const EdgeInsets.only(right: 20, top: 8),
                ),
                // รายการเมนูย่อย
                Expanded(
                  child: Column(
                    children: items.map((item) {
                      bool isHighlighted = item == highlightedItem;
                      return GestureDetector(
                        onTap: () {
                          if (onItemTap != null) {
                            onItemTap(item);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isHighlighted ? const Color(0xFFE0F2F1) : Colors.white,
                            border: Border.all(
                              color: isHighlighted ? const Color(0xFFE0F2F1) : Colors.grey.shade200,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              color: isHighlighted ? const Color(0xFF009688) : const Color(0xFF4A4A4A),
                              fontSize: 14,
                              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
