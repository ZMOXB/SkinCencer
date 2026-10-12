// scan.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'scan_detail.dart';
import 'widgets/app_dialogs.dart';

// คลาสสำหรับส่งข้อมูล Tensor ที่คำนวณเสร็จแล้วจาก Isolate กลับมายัง Main Thread
class _ScanTensors {
  final Float32List screeningInput;
  final Float32List classifierInput;

  _ScanTensors({
    required this.screeningInput,
    required this.classifierInput,
  });
}

// ฟังก์ชันประมวลผลรูปภาพแบบ Pure Background Isolate (ไม่บล็อก UI และเร็วกว่าเดิมหลายเท่า)
_ScanTensors _preprocessScanImageInIsolate(Uint8List imageBytes) {
  final img.Image? originalImage = img.decodeImage(imageBytes);
  if (originalImage == null) throw Exception("ไม่สามารถอ่านรูปภาพได้");
  final img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

  final screeningInput = Float32List(224 * 224 * 3);
  final classifierInput = Float32List(224 * 224 * 3);
  int sIndex = 0;
  int cIndex = 0;

  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = resizedImage.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      // ด่านที่ 1 (Screening Model): RGB
      screeningInput[sIndex++] = r;
      screeningInput[sIndex++] = g;
      screeningInput[sIndex++] = b;

      // ด่านที่ 2 (Classifier Model): BGR และลบค่า Mean
      classifierInput[cIndex++] = b - 103.939;
      classifierInput[cIndex++] = g - 116.779;
      classifierInput[cIndex++] = r - 123.68;
    }
  }

  return _ScanTensors(
    screeningInput: screeningInput,
    classifierInput: classifierInput,
  );
}

class ScanScreen extends StatefulWidget {
  final String profileId;

  const ScanScreen({super.key, this.profileId = 'main'});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String? selectedBodyPart;
  final List<String> bodyParts = ['คอ', 'แขน', 'ขา', 'หน้า', 'หลัง'];

  File? _selectedImage;
  String? _originalImagePath;
  final ImagePicker _picker = ImagePicker();

  Interpreter? _screeningInterpreter;
  Interpreter? _classifierInterpreter;
  Map<String, dynamic>? _classIndices;
  bool _isModelLoaded = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      debugPrint('🔄 กำลังโหลดโมเดลคัดกรอง screening_modelv2.tflite...');
      _screeningInterpreter = await Interpreter.fromAsset('assets/screening_modelv2.tflite');
      debugPrint('✅ โหลด screening_modelv2.tflite สำเร็จ!');
    } catch (e) {
      debugPrint('❌ ไม่สามารถโหลด screening_modelv2.tflite: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          '❌ โหลด screening_modelv2.tflite ไม่สำเร็จ: ($e)',
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    try {
      debugPrint('🔄 กำลังโหลดโมเดลจำแนกโรค Modelv3.tflite...');
      _classifierInterpreter = await Interpreter.fromAsset('assets/Modelv3.tflite');
      debugPrint('✅ โหลด Modelv3.tflite สำเร็จ!');
    } catch (e) {
      debugPrint('❌ ไม่สามารถโหลด Modelv3.tflite: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          '❌ โหลด Modelv3.tflite ไม่สำเร็จ: ($e)',
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    try {
      debugPrint('🔄 กำลังโหลด class_indices.json...');
      String jsonString = await rootBundle.loadString('assets/class_indices.json');
      _classIndices = jsonDecode(jsonString);
      debugPrint('✅ โหลด class_indices.json สำเร็จ!');
    } catch (e) {
      debugPrint('❌ ไม่สามารถโหลด class_indices.json: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          '❌ โหลด class_indices.json ไม่สำเร็จ: ($e)',
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isModelLoaded = true;
      });
    }
    debugPrint('🎉 โหลดโมเดล Two-Stage Pipeline และ Labels สำเร็จครบถ้วน!');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePickerPlatform imagePickerImplementation = ImagePickerPlatform.instance;
      if (imagePickerImplementation is ImagePickerAndroid) {
        imagePickerImplementation.useAndroidPhotoPicker = true;
      }
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        _originalImagePath = pickedFile.path;
        _cropImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'ครอบตัดรูปภาพ',
            toolbarColor: const Color(0xFF009688),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF009688),
            cropFrameColor: const Color(0xFF009688),
            cropGridColor: Colors.white.withValues(alpha: 0.8),
            cropFrameStrokeWidth: 3,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'ครอบตัดรูปภาพ',
            aspectRatioLockEnabled: true,
            resetButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการ Crop: $e');
    }
  }

  Future<Map<String, dynamic>?> _saveScanHistory(String diseaseName, double confidenceScore, String? bodyPart) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        String? imageUrl;
        if (_selectedImage != null) {
          final fileExtension = _selectedImage!.path.split('.').last;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          final filePath = '${user.id}/$fileName'; 

          await Supabase.instance.client.storage
              .from('scan_images')
              .upload(filePath, _selectedImage!);

          imageUrl = Supabase.instance.client.storage
              .from('scan_images')
              .getPublicUrl(filePath);
        }

        final inserted = await Supabase.instance.client.from('scan_history').insert({
          'user_id': user.id,
          'profile_id': widget.profileId, 
          'result_name': diseaseName,
          'confidence': confidenceScore,
          'body_part': bodyPart ?? 'ไม่ระบุ',
          'image_url': imageUrl, 
        }).select().single();
        debugPrint('✅ บันทึกประวัติและอัปโหลดรูปภาพสำเร็จ!');
        return inserted;
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการบันทึกประวัติ/รูปภาพ: $e');
      return null;
    }
    return null;
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      AppSnackBar.showWarning(context, 'กรุณาอัปโหลดหรือถ่ายรูปภาพก่อน');
      return;
    }
    if (selectedBodyPart == null) {
      AppSnackBar.showWarning(context, 'กรุณาเลือกบริเวณที่เป็นรอยโรค');
      return;
    }
    if (!_isModelLoaded || _screeningInterpreter == null || _classifierInterpreter == null || _classIndices == null) {
      AppSnackBar.showError(context, 'ระบบกำลังเตรียมโมเดล หรือโหลดโมเดลไม่สำเร็จ กรุณาลอง Rebuild แอป');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      // ประมวลผลรูปภาพล่วงหน้าใน Isolate (background thread) เพื่อให้ UI ทำงานลื่นไหล 100%
      final tensors = await compute(_preprocessScanImageInIsolate, imageBytes);

      // ==========================================
      // ด่านที่ 1 (โมเดล: screening_modelv2.tflite)
      // คัดกรองเบื้องต้นว่าภาพเป็น "ผิวหนังปกติ" หรือ "มีรอยโรค"
      // รับ Input ขนาด 224x224 (float32) และได้ Output เป็นค่าความน่าจะเป็นของโรค [1, 1]
      // ==========================================
      var sInputTensor = _screeningInterpreter!.getInputTensor(0);
      var sOutputTensor = _screeningInterpreter!.getOutputTensor(0);

      var sInput = tensors.screeningInput.reshape(sInputTensor.shape);
      var sOutputBuffer = Float32List(sOutputTensor.shape.reduce((a, b) => a * b));
      var sOutput = sOutputBuffer.reshape(sOutputTensor.shape);

      _screeningInterpreter!.run(sInput, sOutput);

      double diseaseProbability = 0.0;
      if (sOutputTensor.shape.length == 2) {
        diseaseProbability = (sOutput[0][0] as num).toDouble();
      } else {
        diseaseProbability = (sOutput[0] as num).toDouble();
      }

      debugPrint('🔍 ด่านที่ 1 - ความน่าจะเป็นของรอยโรค (Disease Probability): $diseaseProbability');

      // เงื่อนไข: ถ้าค่าน้อยกว่า 0.45 (< 0.45) ถือว่าเป็น "ผิวหนังปกติ" แล้วจบการทำงานทันที
      if (diseaseProbability < 0.45) {
        debugPrint('✅ ด่านที่ 1: ผลประเมิน < 0.45 ถือว่าเป็น "ผิวหนังปกติ" สิ้นสุดการทำงาน');
        const predictedClass = 'ผิวหนังปกติ';
        final normalConfidence = 1.0 - diseaseProbability;

        final savedData = await _saveScanHistory(predictedClass, normalConfidence * 100, selectedBodyPart);
        if (mounted) {
          _showResultDialog(predictedClass, normalConfidence, savedData);
        }
        return; // จบการทำงานทันที ไม่ต้องรันด่านที่ 2 ต่อ
      }

      // ==========================================
      // ด่านที่ 2 (โมเดลเดิม: Modelv3.tflite + class_indices.json)
      // ทำงานเมื่อค่าจากด่านแรก >= 0.45 แสดงว่า "ตรวจพบรอยโรค"
      // นำภาพส่งต่อไปให้โมเดลเดิมเพื่อจำแนกละเอียด 8 โรค
      // ==========================================
      debugPrint('🚨 ด่านที่ 1: ผลประเมิน >= 0.45 ตรวจพบรอยโรค -> ส่งต่อด่านที่ 2 จำแนก 8 โรค');

      var cInputTensor = _classifierInterpreter!.getInputTensor(0);
      var cOutputTensor = _classifierInterpreter!.getOutputTensor(0);

      var cInput = tensors.classifierInput.reshape(cInputTensor.shape);
      var cOutputBuffer = Float32List(cOutputTensor.shape.reduce((a, b) => a * b));
      var cOutput = cOutputBuffer.reshape(cOutputTensor.shape);

      _classifierInterpreter!.run(cInput, cOutput);

      List<double> predictions = [];
      if (cOutputTensor.shape.length == 2) {
        predictions = List<double>.from(cOutput[0]);
      } else {
        predictions = List<double>.from(cOutput);
      }

      double maxScore = 0;
      int maxIndex = 0;
      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxScore) {
          maxScore = predictions[i];
          maxIndex = i;
        }
      }

      String predictedClass = "ไม่ทราบผลลัพธ์ (Index $maxIndex)";
      _classIndices!.forEach((key, value) {
        if (value.toString() == maxIndex.toString() || key == maxIndex.toString()) {
          predictedClass = value is String ? value : key;
        }
      });

      final savedData = await _saveScanHistory(predictedClass, maxScore * 100, selectedBodyPart);
      if (mounted) {
        _showResultDialog(predictedClass, maxScore, savedData);
      }
      
    } catch (e) {
      debugPrint("❌ Error ตอนรันโมเดล: $e");
      if (mounted) {
        AppSnackBar.showError(context, "ระบบประมวลผลล้มเหลว: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Map<String, dynamic> _getRiskLevelInfo(String diseaseName) {
    String nameLower = diseaseName.toLowerCase();
    if (nameLower.contains("ปกติ") || nameLower.contains("normal")) {
      return {'text': 'ผิวปกติ', 'color': const Color(0xFF009688), 'bgColor': const Color(0xFFE0F2F1)};
    }
    bool isHighRisk = nameLower.contains("melanoma") ||
        nameLower.contains("มะเร็ง") ||
        nameLower.contains("basal") ||
        nameLower.contains("bcc") ||
        nameLower.contains("squamous") ||
        nameLower.contains("scc") ||
        nameLower.contains("actinic") ||
        nameLower.contains("เมลาโนมา");

    if (isHighRisk) {
      return {'text': 'ความเสี่ยงสูง', 'color': Colors.red, 'bgColor': Colors.red.shade50};
    } else {
      return {'text': 'ความเสี่ยงต่ำ', 'color': const Color(0xFF009688), 'bgColor': const Color(0xFFE0F2F1)};
    }
  }

  void _showResultDialog(String result, double score, Map<String, dynamic>? savedData) {
    final riskInfo = _getRiskLevelInfo(result);
    final bool isHighRisk = riskInfo['text'] == 'ความเสี่ยงสูง';

    AppDialog.showScanResult(
      context: context,
      resultName: result,
      confidence: score,
      bodyPart: selectedBodyPart,
      isHighRisk: isHighRisk,
      onDetailsPressed: savedData != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanDetailScreen(historyItem: savedData, riskInfo: riskInfo),
                ),
              );
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('สแกนรอยโรค',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('อัปโหลดรูปภาพ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
              const SizedBox(height: 8),
              const Text(
                  'ถ่ายรูปรอยโรคที่ต้องการประเมินให้ชัดเจน\nเพื่อผลลัพธ์ที่แม่นยำ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.teal.shade100, width: 2)),
                child: _selectedImage != null
                    ? Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final path = _originalImagePath ?? _selectedImage!.path;
                              _cropImage(path);
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_selectedImage!,
                                      height: 250, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.crop, color: Colors.white, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'แตะเพื่อแก้ไขครอ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  final path = _originalImagePath ?? _selectedImage!.path;
                                  _cropImage(path);
                                },
                                icon: const Icon(Icons.crop, color: Color(0xFF009688)),
                                label: const Text('ครอปใหม่',
                                    style: TextStyle(
                                        color: Color(0xFF009688),
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _selectedImage = null;
                                  _originalImagePath = null;
                                }),
                                icon: const Icon(Icons.refresh, color: Colors.red),
                                label: const Text('เปลี่ยนรูปภาพ',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildUploadOption(
                              icon: Icons.camera_alt_outlined,
                              label: 'ถ่ายรูปใหม่',
                              onTap: () => _pickImage(ImageSource.camera)),
                          const SizedBox(height: 16),
                          _buildUploadOption(
                              icon: Icons.image_outlined,
                              label: 'เลือกจากคลังภาพ',
                              onTap: () => _pickImage(ImageSource.gallery)),
                        ],
                      ),
              ),
              const SizedBox(height: 32),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('บริเวณที่เป็น (Body Part)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal)),
                ),
                hint: const Text('เลือกบริเวณที่เป็น', style: TextStyle(color: Colors.grey)),
                initialValue: selectedBodyPart,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: bodyParts
                    .map((String part) => DropdownMenuItem<String>(value: part, child: Text(part)))
                    .toList(),
                onChanged: (String? newValue) => setState(() => selectedBodyPart = newValue),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.teal, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            '* คำแนะนำ: ซูมหรือปรับตำแหน่งรูปให้เห็นรอยโรคชัดเจน หากเห็นรอยโรคชัดเจนอยู่แล้วไม่จำเป็นต้องซูมเพิ่ม',
                            style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white))
                  : const Text('เริ่มวิเคราะห์',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF009688)),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF009688))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _screeningInterpreter?.close();
    _classifierInterpreter?.close();
    super.dispose();
  }
}