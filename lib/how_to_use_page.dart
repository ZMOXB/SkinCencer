// how_to_use_page.dart
import 'package:flutter/material.dart';
import 'scan.dart';

class HowToUsePage extends StatelessWidget {
  final String profileId;

  const HowToUsePage({super.key, this.profileId = 'main'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF009688), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'วิธีใช้งาน',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ปุ่มไปหน้าประเมินรอยโรค
            _buildHeroBanner(context),
            const SizedBox(height: 28),

            // 2. หัวข้อขั้นตอนการใช้งาน
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF009688), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ขั้นตอนการประเมินความเสี่ยง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ขั้นตอนที่ 1 ถึง 6
            _buildStepCard(
              stepNumber: 1,
              title: 'เข้าสู่เมนูประเมินความเสี่ยง',
              description: 'เปิดแอปพลิเคชันมาที่หน้าหลัก ตรวจสอบชื่อโปรไฟล์ผู้ใช้งาน แล้วกดปุ่ม "สแกนรอยโรคทันที" บนการ์ดสีเขียว Teal',
              icon: Icons.touch_app_rounded,
            ),
            _buildStepCard(
              stepNumber: 2,
              title: 'อัปโหลดหรือถ่ายรูปรอยโรค',
              description: 'เลือกนำเข้ารูปภาพรอยโรคที่ต้องการตรวจ โดยสามารถเลือก "ถ่ายรูปใหม่" ผ่านกล้องมือถือ หรือ "เลือกจากคลังภาพ" ในเครื่อง',
              icon: Icons.add_a_photo_rounded,
            ),
            _buildStepCard(
              stepNumber: 3,
              title: 'ครอบตัดรูปภาพ (Crop Image)',
              description: 'ปรับกรอบสี่เหลี่ยมจัตุรัส (1:1) ให้รอยโรคอยู่กึ่งกลางภาพพอดี เห็นรายละเอียดชัดเจน และตัดพื้นที่ส่วนเกินออก',
              icon: Icons.crop_rounded,
            ),
            _buildStepCard(
              stepNumber: 4,
              title: 'ระบุตำแหน่งบริเวณที่เป็น (Body Part)',
              description: 'กดเลือกตำแหน่งบนร่างกายจากเมนูดรอปดาวน์ที่ตรงกับรอยโรค เช่น คอ, แขน, ขา, หน้า หรือ หลัง',
              icon: Icons.accessibility_new_rounded,
            ),
            _buildStepCard(
              stepNumber: 5,
              title: 'เริ่มการวิเคราะห์ด้วย AI',
              description: 'กดปุ่ม "เริ่มวิเคราะห์" ระบบ AI จะประมวลผลและแสดงผลตรวจเบื้องต้น พร้อมบอกค่าความน่าจะเป็น (Confidence Score %)',
              icon: Icons.psychology_rounded,
            ),
            _buildStepCard(
              stepNumber: 6,
              title: 'ดูรายละเอียดและการปฏิบัติตัว',
              description: 'กด "รายละเอียดเพิ่มเติม" เพื่อดูระดับความเสี่ยง (สูง/ต่ำ) ลักษณะที่พบ สาเหตุ การดูแลเบื้องต้น และสัญญาณเตือนที่ควรไปพบแพทย์',
              icon: Icons.assignment_turned_in_rounded,
              isLast: true,
            ),

            const SizedBox(height: 32),

            // 3. หัวข้อคำแนะนำในการถ่ายรูป
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF009688), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'คำแนะนำในการถ่ายรูป',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'เพื่อช่วยให้ระบบ AI วิเคราะห์รอยโรคได้อย่างถูกต้องและแม่นยำสูงสุด',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // การ์ดสิ่งที่ควรทำ (Do)
            _buildTipBox(
              title: 'สิ่งที่ควรทำ (Do)',
              isPositive: true,
              items: [
                'ถ่ายในที่ที่มีแสงสว่างธรรมชาติเพียงพอ และกระจายทั่วถึง',
                'ถือกล้องให้นิ่ง โฟกัสรอยโรคให้คมชัด ไม่เบลอหรือสั่นไหว',
                'ครอบตัดให้รอยโรคอยู่ตรงกึ่งกลางภาพพอดี',
                'ทำความสะอาดผิว ไม่ให้มีคราบแป้ง ครีม หรือเครื่องสำอางบดบัง',
              ],
            ),
            const SizedBox(height: 16),

            // การ์ดสิ่งที่ไม่ควรทำ (Don\'t)
            _buildTipBox(
              title: 'สิ่งที่ไม่ควรทำ (Don\'t)',
              isPositive: false,
              items: [
                'ถ่ายในที่มืด สลัว หรือมีแสงสะท้อนจ้า (แฟลช) บนผิวหนัง',
                'ภาพหลุดโฟกัส เบลอ หรือเห็นขอบรอยโรคไม่ชัดเจน',
                'รอยโรคอยู่ไกลเกินไป หรืออยู่ชิดขอบมุมภาพ',
                'มีเงา เสื้อผ้า ขนหนา หรือเครื่องประดับบดบังรอยโรค',
              ],
            ),
            const SizedBox(height: 28),

            // 4. กล่องข้อความแจ้งเตือนทางการแพทย์ (Disclaimer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อควรระวังทางการแพทย์',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ระบบนี้เป็นการประเมินความเสี่ยงเบื้องต้นโดย AI เท่านั้น ไม่สามารถใช้ทดแทนการวินิจฉัยโดยแพทย์ผู้เชี่ยวชาญได้ หากพบรอยโรคผิดปกติหรือมีความกังวล แนะนำให้พบแพทย์ผิวหนังเพื่อตรวจรักษาทันที',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5D4037),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ปุ่มไปหน้าประเมินรอยโรค
  Widget _buildHeroBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanScreen(profileId: profileId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF009688), Color(0xFF00796B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF009688).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประเมินความเสี่ยงรอยโรค',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'แตะที่นี่เพื่อสแกนและวิเคราะห์รอยโรคทันที',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // การ์ดแสดงแต่ละขั้นตอน
  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ฝั่งไอคอนและเส้นเชื่อม
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF009688),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF009688).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFB2DFDB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // ฝั่งเนื้อหาการ์ด
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: const Color(0xFF009688)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF616161),
                      height: 1.5,
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

  // การ์ดคำแนะนำ (Do / Don't)
  Widget _buildTipBox({
    required String title,
    required bool isPositive,
    required List<String> items,
  }) {
    final primaryColor = isPositive ? const Color(0xFF009688) : const Color(0xFFE53935);
    final bgColor = isPositive ? const Color(0xFFE0F2F1).withValues(alpha: 0.5) : const Color(0xFFFFEBEE).withValues(alpha: 0.6);
    final iconColor = isPositive ? const Color(0xFF00897B) : const Color(0xFFD32F2F);
    final itemIcon = isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(itemIcon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Icon(
                        isPositive ? Icons.done : Icons.close,
                        size: 14,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF37474F),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
