import 'package:flutter/material.dart';
import 'scan.dart';

// โมเดลสำหรับเก็บข้อมูลแต่ละโรค
class SkinDisease {
  final String name;
  final String thaiName;
  final String description;
  final String symptoms;
  final String causes;
  final String treatment;
  final bool isHighRisk;

  SkinDisease({
    required this.name,
    this.thaiName = '',
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatment,
    this.isHighRisk = false,
  });
}

// ฐานข้อมูลคำอธิบายโรคผิวหนัง 8 ชนิด
final List<SkinDisease> skinDiseasesData = [
  SkinDisease(
    name: 'Melanoma',
    thaiName: 'มะเร็งเมลาโนมา',
    isHighRisk: true,
    description: 'มะเร็งผิวหนังเมลาโนมาเป็นมะเร็งผิวหนังชนิดร้ายแรงที่พัฒนาในเซลล์เมลาโนไซต์ (Melanocytes) ที่ทำหน้าที่สร้างเม็ดสีบนผิวหนัง มะเร็งชนิดนี้สามารถแพร่กระจายไปยังต่อมน้ำเหลืองและอวัยวะส่วนอื่นๆ ของร่างกายได้อย่างรวดเร็วหากไม่ได้รับการรักษาตั้งแต่ระยะเริ่มต้น',
    symptoms: 'สังเกตความผิดปกติของไฝเดิมหรือรอยโรคใหม่ตามหลัก ABCDE:\n• A (Asymmetry): รูปร่างไม่สมมาตร สองข้างไม่เท่ากัน\n• B (Border): ขอบหยัก ไม่เรียบ ไม่สม่ำเสมอ\n• C (Color): มีหลายสีปะปนในเม็ดเดียว เช่น ดำ น้ำตาล แดง ขาว\n• D (Diameter): ขนาดเส้นผ่านศูนย์กลางใหญ่กว่า 6 มิลลิเมตร\n• E (Evolving): มีการเปลี่ยนแปลงขนาด รูปร่าง สี หรือมีเลือดออกและคัน',
    causes: 'เกิดจากการสัมผัสรังสีอัลตราไวโอเลต (UV) จากแสงแดดสะสมเป็นเวลานานจน DNA ของเซลล์สร้างเม็ดสีถูกทำลาย ร่วมกับปัจจัยทางพันธุกรรม และการมีประวัติคนในครอบครัวเป็นมะเร็งผิวหนัง',
    treatment: 'การรักษาหลักคือการผ่าตัดเอารอยโรคและเนื้อเยื่อรอบข้างออก สำหรับระยะที่มีการแพร่กระจาย อาจต้องใช้วิธีรักษาด้วยภูมิคุ้มกันบำบัด (Immunotherapy), ยามุ่งเป้า (Targeted Therapy), หรือการฉายรังสี',
  ),
  SkinDisease(
    name: 'BCC',
    thaiName: 'มะเร็งผิวหนังเบซัลเซลล์ (BCC)',
    isHighRisk: true,
    description: 'มะเร็งผิวหนังที่พบได้บ่อยที่สุดในคนไทย มักพบในผู้ที่มีอายุ 40-60 ปีขึ้นไป เป็นมะเร็งที่โตช้าและไม่ค่อยแพร่กระจายไปยังอวัยวะอื่น แต่มักทำลายเนื้อเยื่อบริเวณข้างเคียงหากปล่อยทิ้งไว้',
    symptoms: '• ปรากฏเป็นตุ่มนูนผิวเรียบ สีชมพู แดง หรือดำมันวาวคล้ายมุก\n• ขอบตุ่มมักยกนูนและม้วนเข้า\n• อาจพบเส้นเลือดฝอยเล็กๆ พาดผ่านบริเวณรอยโรค\n• พบบ่อยบริเวณที่โดนแดด เช่น ใบหน้า จมูก ลำคอ และใบหู\n• บางรายอาจมีสะเก็ด เลือดออก หรือเป็นแผลเรื้อรังที่ไม่ยอมหายเกิน 1 เดือน',
    causes: 'เกิดจากเซลล์ผิวหนังชั้นฐาน (Basal Cells) ถูกทำลายโดยรังสี UV จากแสงแดดสะสมเป็นเวลานานหลายปี',
    treatment: 'สามารถรักษาให้หายขาดได้ด้วยการผ่าตัด (เช่น การผ่าตัดมาตรฐาน หรือ Mohs Micrographic Surgery) รวมถึงการจี้ด้วยความเย็น (Cryosurgery) หรือการฉายรังสีในผู้ป่วยสูงอายุที่ไม่สามารถผ่าตัดได้',
  ),
  SkinDisease(
    name: 'SCC',
    thaiName: 'มะเร็งผิวหนังชนิดสความัสเซลล์ (SCC)',
    isHighRisk: true,
    description: 'มะเร็งผิวหนังชนิดที่พบได้บ่อยเป็นอันดับสอง เกิดจากเซลล์ผิวหนังชั้นนอก (Squamous Cells) แบ่งตัวผิดปกติ สามารถลุกลามลงสู่ชั้นลึกและแพร่กระจายไปยังต่อมน้ำเหลืองได้หากปล่อยทิ้งไว้',
    symptoms: '• เป็นก้อนเนื้อหรือตุ่มแข็ง สีแดงหรือชมพู ผิวหยาบขรุขระ คล้ายหูด\n• มีขุยหนาหรือสะเก็ดปกคลุม\n• เป็นแผลเรื้อรังที่ขอบแผลนูนแข็ง เจ็บ และมีเลือดหรือน้ำเหลืองไหลซึม\n• มักพบบริเวณที่โดนแดด เช่น ใบหน้า ริมฝีปาก ใบหู หนังศีรษะ หลังมือ และแขน',
    causes: 'เกิดจากการสะสมของรังสี UV จากแสงแดด การสัมผัสสารเคมีอันตราย การติดเชื้อไวรัส HPV บางสายพันธุ์ หรือเกิดจากรอยแผลเป็นเรื้อรังและแผลไฟไหม้เดิม',
    treatment: 'การผ่าตัดเอารอยโรคออกทั้งหมด การขูดและจี้ไฟฟ้า การใช้รังสีรักษา หรือการใช้ยาภูมิคุ้มกันบำบัดในกรณีที่มีการลุกลาม',
  ),
  SkinDisease(
    name: 'Actinic Keratosis',
    thaiName: 'ระยะก่อนมะเร็ง',
    isHighRisk: true,
    description: 'รอยโรคผิวหนังที่มีความเสี่ยงพัฒนาไปเป็นมะเร็งผิวหนังชนิด SCC ในอนาคต มีลักษณะเป็นผื่นหรือตุ่มสากคล้ายกระดาษทราย เกิดจากผิวหนังชั้นนอกถูกทำลายด้วยแสงแดดอย่างต่อเนื่อง',
    symptoms: '• ผื่นหรือตุ่มสีแดง ชมพู น้ำตาล หรือสีเดียวกับผิวหนัง\n• ผิวสัมผัสหยาบกร้าน เป็นสะเก็ดขุยติดแน่น ลูบแล้วรู้สึกสากมือ\n• อาจมีอาการคัน แสบร้อน หรือเจ็บเมื่อสัมผัส\n• พบบ่อยบริเวณใบหน้า หน้าผาก หนังศีรษะ หลังมือ และแขน',
    causes: 'การได้รับรังสีอัลตราไวโอเลต (UV) จากแสงแดดสะสมเป็นระยะเวลานานหลายปี ทำให้ DNA ของเซลล์เคอราติโนไซต์เสียหาย',
    treatment: 'ควรรับการรักษาตั้งแต่เนิ่นๆ เช่น การจี้ด้วยไนโตรเจนเหลว (Cryotherapy), การทายารักษาเฉพาะที่ (Topical Creams), การผลัดเซลล์ผิวด้วยสารเคมี (Chemical Peel) หรือการบำบัดด้วยแสง (PDT)',
  ),
  SkinDisease(
    name: 'Melanocytic Nevi',
    thaiName: 'ไฝ / ปาน',
    isHighRisk: false,
    description: 'เนื้องอกชนิดไม่ร้ายแรงของเซลล์สร้างเม็ดสี (Melanocytes) พบได้ทั่วไปในคนทุกเพศทุกวัย ขนาดมักเล็กกว่า 6 มม. ผิวเรียบ ขอบสม่ำเสมอ และไม่มีอันตราย',
    symptoms: '• จุดหรือตุ่มนูนเล็กๆ สีน้ำตาลเข้ม น้ำตาลอ่อน หรือสีดำ\n• รูปร่างกลมหรือรี สมมาตร ขอบเขตชัดเจนเรียบเนียน\n• ผิวอาจเรียบหรือนูนเล็กน้อย บางเม็ดอาจมีเส้นขนงอกออกมา\n• ปกติไม่มีอาการเจ็บ คัน หรือเลือดออก',
    causes: 'เกิดจากการรวมกลุ่มกันของเซลล์สร้างเม็ดสีผิวหนัง ซึ่งได้รับอิทธิพลจากพันธุกรรมและการสัมผัสแสงแดด',
    treatment: 'ปกติไม่จำเป็นต้องรักษา หากต้องการเอาออกเพื่อความสวยงามหรือสงสัยความผิดปกติ สามารถทำได้โดยการผ่าตัดเล็ก จี้เลเซอร์ หรือจี้ไฟฟ้า',
  ),
  SkinDisease(
    name: 'Keratosis',
    thaiName: 'กระเนื้อ',
    isHighRisk: false,
    description: 'เนื้องอกผิวหนังชนิดไม่ร้ายแรงที่พบได้บ่อยมากในผู้สูงอายุหรือวัยกลางคนขึ้นไป มีลักษณะคล้ายตุ่มขี้ไคลแปะติดอยู่บนผิวหนัง ไม่ใช่มะเร็งและไม่กลายเป็นมะเร็ง',
    symptoms: '• ตุ่มนูนสีน้ำตาลอ่อน น้ำตาลเข้ม หรือสีดำ ผิวขรุขระเป็นมันคล้ายเม็ดทรายหรือขี้ไคล\n• ขอบเขตชัดเจน ดูเหมือนแปะติดอยู่บนผิวหนัง\n• พบบ่อยบริเวณใบหน้า ลำคอ หน้าอก และหลัง\n• อาจมีอาการคันเล็กน้อย หรือเจ็บเมื่อเสียดสีกับเสื้อผ้า',
    causes: 'เกิดจากความเสื่อมตามวัยและปัจจัยทางพันธุกรรม ไม่ได้เกิดจากการติดเชื้อและไม่ติดต่อ',
    treatment: 'ไม่จำเป็นต้องรักษา ยกเว้นกรณีคัน อักเสบ หรือต้องการกำจัดเพื่อความสวยงาม สามารถทำได้ด้วยการจี้เย็น (ไนโตรเจนเหลว), การขูดออก, เลเซอร์ หรือจี้ไฟฟ้า',
  ),
  SkinDisease(
    name: 'Tinea',
    thaiName: 'เชื้อราผิวหนัง (กลาก)',
    isHighRisk: false,
    description: 'โรคติดเชื้อราบนผิวหนังชั้นหนังกำพร้า สามารถเกิดได้ทั่วร่างกาย เช่น ลำตัว (กลากลำตัว), ขาหนีบ (สังคัง), เท้า (ฮ่องกงฟุต) หรือหนังศีรษะ',
    symptoms: '• ผื่นแดงรูปวงแหวนหรือวงกลม ขอบนูนแดงชัดเจนและมีขุยสะเก็ด\n• ตรงกลางวงมักมีสีผิวจางลงหรือดูปกติ\n• มีอาการคันมาก โดยเฉพาะเวลาเหงื่อออกหรืออากาศร้อนชื้น\n• ผื่นสามารถขยายวงกว้างขึ้นเรื่อยๆ',
    causes: 'เกิดจากเชื้อรากลุ่มเดอร์มาโตไฟต์ (Dermatophytes) เจริญเติบโตได้ดีในที่อับชื้น ติดต่อได้จากการสัมผัสผู้ป่วย สัตว์เลี้ยง หรือใช้ของร่วมกัน',
    treatment: 'รักษาด้วยการทายาฆ่าเชื้อราเฉพาะที่อย่างสม่ำเสมอติดต่อกัน 2-4 สัปดาห์ หรือรับประทานยาฆ่าเชื้อราในรายที่เป็นบริเวณกว้าง พร้อมทั้งรักษาความสะอาดและไม่อับชื้น',
  ),
  SkinDisease(
    name: 'Psoriasis',
    thaiName: 'สะเก็ดเงิน',
    isHighRisk: false,
    description: 'โรคผิวหนังอักเสบเรื้อรังที่เกิดจากความผิดปกติของระบบภูมิคุ้มกัน ส่งผลให้เซลล์ผิวหนังแบ่งตัวเร็วกว่าปกติจนหนาตัวและหลุดลอกเป็นสะเก็ด ไม่ใช่โรคติดต่อ',
    symptoms: '• ปื้นหนาสีแดง ขอบเขตชัดเจน คลุมด้วยขุยสะเก็ดสีขาวเงินหนา\n• เมื่อแกะสะเก็ดออกอาจพบจุดเลือดออกเล็กๆ (Auspitz sign)\n• พบบ่อยบริเวณข้อศอก หัวเข่า แผ่นหลัง หนังศีรษะ และเล็บ\n• มีอาการคันหรือแสบตึงผิวหนัง',
    causes: 'เกิดจากความผิดปกติของระบบภูมิคุ้มกันและพันธุกรรม โดยมีปัจจัยกระตุ้น เช่น ความเครียด, การติดเชื้อ, การบาดเจ็บของผิวหนัง, อากาศหนาว, แอลกอฮอล์ และการสูบบุหรี่',
    treatment: 'รักษาเพื่อควบคุมอาการด้วยยาทา (สเตียรอยด์, วิตามินดี), การฉายแสงอาทิตย์เทียม (Phototherapy), ยารับประทานกดภูมิคุ้มกัน หรือยาชีววัตถุ (Biologics)',
  ),
];

// 1. หน้า List View (แสดงรายการโรคทั้ง 8 ชนิด)
class SkinDiseasesListPage extends StatelessWidget {
  const SkinDiseasesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'คำอธิบายโรคเบื้องต้น',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF009688), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
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
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'คลังข้อมูลโรคผิวหนัง',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'รวบรวมลักษณะ อาการ และวิธีดูแล 8 โรคผิวหนังที่ AI ประเมินได้',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'เลือกโรคที่ต้องการดูรายละเอียด',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),

            // รายการโรคทั้ง 8 รายการ
            ...List.generate(skinDiseasesData.length, (index) {
              final disease = skinDiseasesData[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SkinDiseaseDetailPage(disease: disease),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.science_outlined,
                              color: Color(0xFF009688),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  disease.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                if (disease.thaiName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    disease.thaiName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ป้ายบอกระดับความเสี่ยง
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: disease.isHighRisk
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              disease.isHighRisk ? 'เสี่ยงสูง' : 'เสี่ยงต่ำ',
                              style: TextStyle(
                                color: disease.isHighRisk
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF009688),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 2. หน้า Detail View (แสดงข้อมูลแต่ละโรคในธีม Teal เดียวกัน)
class SkinDiseaseDetailPage extends StatelessWidget {
  final SkinDisease disease;

  const SkinDiseaseDetailPage({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'รายละเอียดโรค',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF009688), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ส่วนหัว (Hero Card แสดงชื่อโรคและป้ายความเสี่ยง)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          disease.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: disease.isHighRisk
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          disease.isHighRisk ? 'ความเสี่ยงสูง' : 'ความเสี่ยงต่ำ',
                          style: TextStyle(
                            color: disease.isHighRisk
                                ? const Color(0xFFC62828)
                                : const Color(0xFF009688),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (disease.thaiName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      disease.thaiName,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF009688),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: ลักษณะเบื้องต้น
            _buildInfoCard(
              title: 'ลักษณะเบื้องต้น',
              icon: Icons.info_outline_rounded,
              content: disease.description,
            ),
            const SizedBox(height: 16),

            // Section 2: อาการที่พบ
            _buildInfoCard(
              title: 'อาการที่พบ',
              icon: Icons.sick_outlined,
              content: disease.symptoms,
            ),
            const SizedBox(height: 16),

            // Section 3: สาเหตุการเกิด
            _buildInfoCard(
              title: 'สาเหตุการเกิด',
              icon: Icons.biotech_outlined,
              content: disease.causes,
            ),
            const SizedBox(height: 16),

            // Section 4: แนวทางการรักษาและการดูแล
            _buildInfoCard(
              title: 'แนวทางการรักษาและการดูแล',
              icon: Icons.healing_outlined,
              content: disease.treatment,
            ),
            const SizedBox(height: 24),

            // กล่องแจ้งเตือนทางการแพทย์ตามระดับความเสี่ยง
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: disease.isHighRisk ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: disease.isHighRisk ? const Color(0xFFFFCDD2) : const Color(0xFFB2DFDB),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    disease.isHighRisk ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    color: disease.isHighRisk ? const Color(0xFFC62828) : const Color(0xFF009688),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      disease.isHighRisk
                          ? 'คำเตือน: หากท่านสังเกตรอยโรคที่มีลักษณะข้างต้น ขยายขนาดเร็ว หรือมีเลือดออก แนะนำให้เข้าพบแพทย์ผิวหนัง (Dermatologist) เพื่อตรวจชิ้นเนื้อและวินิจฉัยทันที'
                          : 'คำแนะนำ: รอยโรคนี้มักไม่มีอันตรายร้ายแรง แต่ควรหมั่นสังเกตการเปลี่ยนแปลง หากมีอาการเจ็บ คัน หรือลุกลาม ควรรีบปรึกษาแพทย์หรือเภสัชกร',
                      style: TextStyle(
                        fontSize: 12,
                        color: disease.isHighRisk ? const Color(0xFFC62828) : const Color(0xFF00796B),
                        height: 1.5,
                        fontWeight: disease.isHighRisk ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มไปหน้าสแกนประเมินรอยโรค
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'สแกนประเมินรอยโรคนี้',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget สร้าง Card ข้อมูลในธีมเดียวกับทั้งแอป
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
