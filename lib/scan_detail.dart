// scan_detail.dart
import 'package:flutter/material.dart';
import 'disease_data.dart'; // ดึงไฟล์ข้อมูลโรคมาใช้งาน
import 'scan.dart';

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final Map<String, dynamic> riskInfo;

  const ScanDetailScreen({
    super.key,
    required this.historyItem,
    required this.riskInfo,
  });

  // ฟังก์ชันช่วยแปลงรูปแบบเวลาเป็นวันที่แบบเต็ม
  String _formatThaiDateFull(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      List<String> months = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      int buddhistYear = dt.year + 543;
      return "${dt.day} ${months[dt.month - 1]} $buddhistYear";
    } catch (e) {
      return "ไม่ระบุวันที่";
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลดิบจากประวัติ
    String diseaseRawName = historyItem['result_name'] ?? 'ไม่ทราบผลลัพธ์';
    String bodyPart = historyItem['body_part'] ?? 'ไม่ระบุ';
    String dateStr = _formatThaiDateFull(historyItem['scanned_at'] ?? '');
    String? imageUrl = historyItem['image_url'];
    double confidence = double.tryParse(historyItem['confidence'].toString()) ?? 0.0;

    // คำนวณค่าเปอร์เซ็นต์ความแม่นยำ
    double progressValue = (confidence > 1.0 ? confidence / 100.0 : confidence).clamp(0.0, 1.0);
    double displayPercentage = confidence > 1.0 ? confidence : confidence * 100.0;
    String percentageText;
    if (displayPercentage >= 99.9 || (displayPercentage - displayPercentage.round()).abs() < 0.01) {
      percentageText = '${displayPercentage.round()}%';
    } else {
      percentageText = '${displayPercentage.toStringAsFixed(1)}%';
    }

    // ดึงข้อมูลรายละเอียดโรคจากไฟล์ disease_data.dart
    var diseaseDetails = DiseaseData.getDiseaseInfo(diseaseRawName);

    // 🌟 ดักเงื่อนไขตรวจสอบระดับความเสี่ยงเพื่อเปลี่ยนข้อความเตือนด้านล่างสุด
    bool isHighRisk = riskInfo['text'] == 'ความเสี่ยงสูง';
    
    String warningMessage = '';
    Color warningTextColor = Colors.black87;
    Color warningBgColor = Colors.grey.shade100;

    if (diseaseRawName.contains('ไม่พบโรค') || diseaseRawName.contains('ปกติ') || diseaseRawName.toLowerCase().contains('normal')) {
      // 🌿 ข้อความสำหรับกรณีไม่พบโรค
      warningMessage = '✅ ผลการประเมินเบื้องต้นไม่พบรอยโรค: สภาพผิวหนังอยู่ในเกณฑ์ปกติ ไม่พบรอยโรคหรือความผิดปกติที่ชัดเจน อย่างไรก็ตาม ผลวิเคราะห์นี้เป็นเพียงการคัดกรองเบื้องต้นโดย AI เท่านั้น ควรหมั่นดูแลสุขอนามัยและสังเกตความเปลี่ยนแปลงของผิวหนังเป็นประจำ หากมีความกังวลสามารถปรึกษาแพทย์ผิวหนังได้';
      warningTextColor = const Color(0xFF00796B); // สีเขียวเข้ม
      warningBgColor = const Color(0xFFE0F2F1);   // สีเขียวอ่อน Teal 50
    } else if (isHighRisk) {
      // 🚨 ข้อความเตือนสำหรับกลุ่มความเสี่ยงสูง
      warningMessage = '⚠️ ผลการประเมินพบว่ามีความเสี่ยงสูง: รอยโรคนี้มีลักษณะที่อาจพัฒนาเป็นเนื้อร้ายหรือมะเร็งผิวหนังได้ ผลวิเคราะห์นี้เป็นเพียงการคัดกรองเบื้องต้นโดย AI เท่านั้น แนะนำให้ท่านเข้าพบแพทย์ผิวหนัง (Dermatologist) เพื่อตรวจชิ้นเนื้อและรับการวินิจฉัยอย่างละเอียดทันที';
      warningTextColor = const Color(0xFFC62828); // สีแดงเข้มหม่น อ่านง่าย
      warningBgColor = const Color(0xFFFFEBEE);   // สีแดงอ่อน 50
    } else {
      // ✅ ข้อความเตือนสำหรับกลุ่มความเสี่ยงต่ำ
      warningMessage = 'ผลการประเมินพบว่ามีความเสี่ยงต่ำ: รอยโรคนี้ไม่มีลักษณะที่เป็นอันตรายร้ายแรงในขณะนี้ อย่างไรก็ตาม ผลวิเคราะห์นี้เป็นเพียงการคัดกรองเบื้องต้นโดย AI เท่านั้น ควรหมั่นสังเกตอาการและรักษาความสะอาด หากรอยโรคขยายใหญ่ขึ้น เปลี่ยนสี หรือมีอาการเจ็บ ควรรีบไปพบแพทย์';
      warningTextColor = const Color(0xFF00796B); // สีเขียวเข้ม
      warningBgColor = const Color(0xFFE0F2F1);   // สีเขียวอ่อน Teal 50
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF009688)),
          tooltip: 'ย้อนกลับ',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('รายละเอียดการประเมิน', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF009688)),
            tooltip: 'กลับสู่หน้าหลัก',
            onPressed: () => _goToHome(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. รูปภาพสแกน
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 1024,
                          cacheHeight: 1024,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                        )
                      : const Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                        SizedBox(width: 4),
                        Text('สแกนแล้ว', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. ชื่อโรคและป้ายความเสี่ยง
            Text(
              diseaseDetails['thaiName'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: riskInfo['bgColor'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                riskInfo['text'],
                style: TextStyle(color: riskInfo['color'], fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 3. วันที่และบริเวณที่พบ
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('บริเวณที่พบ: $bodyPart', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            // 4. แถบแสดงความแม่นยำ (Confidence Bar) แบบมาตรฐานสากล
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'ความแม่นยำ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      percentageText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009688),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progressValue),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE0F2F1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 5. ลักษณะที่พบ
            _buildSection(
              icon: Icons.science_outlined,
              title: 'ลักษณะที่พบ',
              content: Text(diseaseDetails['description'], style: const TextStyle(color: Colors.black87, height: 1.5)),
            ),
            const SizedBox(height: 24),

            // 6. สาเหตุทั่วไป
            _buildSection(
              icon: Icons.wb_sunny_outlined,
              title: 'สาเหตุทั่วไป',
              content: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseDetails['causes'].split('\n')[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      diseaseDetails['causes'].split('\n').length > 1 ? diseaseDetails['causes'].split('\n')[1] : '',
                      style: const TextStyle(color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 7. การดูแลเบื้องต้น (แบบมีตัวเลขกำกับ)
            _buildSection(
              icon: Icons.shield_outlined,
              title: 'การดูแลเบื้องต้น',
              content: Column(
                children: List.generate(
                  (diseaseDetails['care'] as List).length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2F1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            diseaseDetails['care'][index],
                            style: const TextStyle(color: Colors.black87, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // 8. เมื่อไหร่ควรไปพบแพทย์ (แบบมีจุดกลมกำกับ)
            _buildSection(
              icon: Icons.medical_services_outlined,
              title: 'เมื่อไหร่ควรไปพบแพทย์',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'โปรดหมั่นสังเกตอาการ และควรนัดตรวจกับแพทย์ผิวหนังหากพบสัญญาณเหล่านี้:',
                    style: TextStyle(color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    (diseaseDetails['doctor'] as List).length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6.0),
                            child: Icon(Icons.circle, size: 6, color: Color(0xFF009688)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              diseaseDetails['doctor'][index],
                              style: const TextStyle(color: Colors.black87, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 9. 🌟 กล่องข้อความแจ้งเตือนอัจฉริยะ (เปลี่ยนสีและคำแนะนำตามระดับความเสี่ยงอัตโนมัติ)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningBgColor,
                borderRadius: BorderRadius.circular(12),
                border: isHighRisk ? Border.all(color: Colors.red.shade200) : null,
              ),
              child: Text(
                warningMessage,
                style: TextStyle(
                  color: warningTextColor, 
                  fontSize: 13, 
                  height: 1.6,
                  fontWeight: isHighRisk ? FontWeight.bold : FontWeight.normal
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 10. ปุ่มการทำงานส่วนท้าย (Dual Action Buttons ตามหลัก UX/UI)
            // ปุ่มหลัก: กลับสู่หน้าหลัก
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                label: const Text(
                  'กลับสู่หน้าหลัก',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () => _goToHome(context),
              ),
            ),
            const SizedBox(height: 12),

            // ปุ่มรอง: สแกนรอยโรคอื่นอีกครั้ง
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009688), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF009688), size: 20),
                label: const Text(
                  'สแกนรอยโรคอื่นอีกครั้ง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                ),
                onPressed: () {
                  final profileId = historyItem['profile_id'] ?? 'main';
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanScreen(profileId: profileId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันนำทางกลับสู่หน้าหลัก
  void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ฟังก์ชันย่อยช่วยสร้างหัวข้อหมวดหมู่
  Widget _buildSection({required IconData icon, required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF009688), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 44.0),
          child: content,
        ),
      ],
    );
  }
}