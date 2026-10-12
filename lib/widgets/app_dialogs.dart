// lib/widgets/app_dialogs.dart
import 'package:flutter/material.dart';
import '../disease_data.dart';

/// ประเภทของการแจ้งเตือน SnackBar
enum AppSnackBarType { success, error, warning, info }

/// Class สำหรับแสดง SnackBar สไตล์โมเดิร์น โทนสีมาตรฐานเดียวกันทั้งแอป
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case AppSnackBarType.success:
        backgroundColor = const Color(0xFF009688); // Teal
        iconData = Icons.check_circle_rounded;
        break;
      case AppSnackBarType.error:
        backgroundColor = const Color(0xFFE53935); // Red
        iconData = Icons.error_outline_rounded;
        break;
      case AppSnackBarType.warning:
        backgroundColor = const Color(0xFFF57C00); // Amber/Orange
        iconData = Icons.warning_amber_rounded;
        break;
      case AppSnackBarType.info:
        backgroundColor = const Color(0xFF00838F); // Darker Teal
        iconData = Icons.info_outline_rounded;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// แจ้งเตือนสำเร็จ (สีเขียว Teal)
  static void showSuccess(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message,
      type: AppSnackBarType.success,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// แจ้งเตือนข้อผิดพลาด (สีแดง)
  static void showError(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message,
      type: AppSnackBarType.error,
      title: title,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// แจ้งเตือนข้อควรระวัง / ข้อมูลไม่ครบ (สีส้ม)
  static void showWarning(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message,
      type: AppSnackBarType.warning,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// แจ้งเตือนข้อมูลทั่วไป (สีฟ้า Teal)
  static void showInfo(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message,
      type: AppSnackBarType.info,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}

/// Class สำหรับแสดง Dialog สไตล์โมเดิร์น ที่คุมธีมทั้งแอป
class AppDialog {
  /// แสดง Dialog ยืนยันการทำรายการ (เช่น ลบโปรไฟล์, ออกจากระบบ)
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
    bool isDanger = false,
    IconData? icon,
    VoidCallback? onConfirm,
  }) {
    const primaryTeal = Color(0xFF009688);
    const dangerColor = Color(0xFFE53935);
    final activeColor = isDanger ? dangerColor : primaryTeal;
    final defaultIcon = isDanger ? Icons.warning_amber_rounded : Icons.help_outline_rounded;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDanger
                        ? const Color(0xFFFFEBEE) // Soft red
                        : const Color(0xFFE0F2F1), // Soft teal
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon ?? defaultIcon, color: activeColor, size: 32),
                ),
                const SizedBox(height: 20),

                // 2. Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // 4. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx, true);
                          onConfirm?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: activeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// แสดง Dialog กรอกข้อความ (เช่น สร้างโปรไฟล์ใหม่)
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? message,
    String hintText = '',
    String confirmText = 'บันทึก',
    String cancelText = 'ยกเลิก',
    IconData icon = Icons.add_circle_outline_rounded,
    String? initialValue,
  }) {
    final TextEditingController textController = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFF009688), size: 28),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // TextField
                  TextFormField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF009688), width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'กรุณากรอกข้อมูล';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            cancelText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              Navigator.pop(ctx, textController.text.trim());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF009688),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// แสดง Dialog ผลการวิเคราะห์รอยโรค (Scan Result) ในธีมของแอป
  static Future<void> showScanResult({
    required BuildContext context,
    required String resultName,
    required double confidence,
    required String? bodyPart,
    required bool isHighRisk,
    VoidCallback? onDetailsPressed,
  }) {
    final riskColor = isHighRisk ? const Color(0xFFE53935) : const Color(0xFF009688);
    final riskBgColor = isHighRisk ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1);
    final riskText = isHighRisk ? 'ความเสี่ยงสูง' : 'ความเสี่ยงต่ำ';

    final diseaseInfo = DiseaseData.getDiseaseInfo(resultName);
    final fullThaiName = diseaseInfo['thaiName'] as String? ?? resultName;

    final bool isNormalSkin = resultName.contains('ไม่พบโรค') ||
        resultName.contains('ปกติ') ||
        resultName.toLowerCase().contains('normal') ||
        fullThaiName.contains('ไม่พบโรค') ||
        fullThaiName.contains('ปกติ');

    String thaiTitle = fullThaiName;
    String subTitle = '';

    if (isNormalSkin) {
      thaiTitle = 'ไม่พบโรค';
      subTitle = 'ไม่พบความผิดปกติในกลุ่มโรค 8 ชนิด\nอาจเป็นเพียงภาวะผิวหนังทั่วไป';
    } else {
      if (fullThaiName.contains('(') && fullThaiName.contains(')')) {
        final openIndex = fullThaiName.lastIndexOf('(');
        final closeIndex = fullThaiName.lastIndexOf(')');
        thaiTitle = fullThaiName.substring(0, openIndex).trim();
        subTitle = fullThaiName.substring(openIndex + 1, closeIndex).trim();
      } else if (resultName.toLowerCase() != thaiTitle.toLowerCase()) {
        subTitle = resultName;
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'ผลการวิเคราะห์เบื้องต้น',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),

                // Result Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (bodyPart != null && bodyPart.isNotEmpty) ...[
                        Text(
                          'บริเวณ: $bodyPart',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // ชื่อโรคภาษาไทย (ตัวหลัก - ชัดเจน เข้าใจง่าย)
                      Text(
                        thaiTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          height: 1.25,
                        ),
                      ),
                      // ซับไตเติล: ข้อความอธิบายสำหรับไม่พบโรค หรือชื่อภาษาอังกฤษสำหรับคลาสอื่นๆ
                      if (subTitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isNormalSkin ? 13 : 14,
                            fontWeight: isNormalSkin ? FontWeight.normal : FontWeight.w500,
                            color: Colors.grey.shade600,
                            height: 1.35,
                            letterSpacing: isNormalSkin ? 0 : 0.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              riskText,
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ความแม่นยำ ${(confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFF009688),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Medical note
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'การประเมินนี้เป็นเพียงผลคัดกรองเบื้องต้นโดย AI แนะนำให้พบแพทย์ผิวหนังเพื่อการวินิจฉัยที่ถูกต้อง',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'ตกลง',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    if (onDetailsPressed != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDetailsPressed();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            backgroundColor: const Color(0xFF009688),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'รายละเอียดเพิ่มเติม',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
