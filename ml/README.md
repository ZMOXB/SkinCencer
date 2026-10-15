# Skin Disease Detection & Classification — AI/ML Pipeline 🔬🧠

เอกสารสรุปสถาปัตยกรรมโมเดล ขั้นตอนการเตรียมข้อมูล การเทรนโมเดล และการแปลงไฟล์สำหรับนำไปใช้งานร่วมกับแอปพลิเคชัน Flutter บนมือถือ

---

## 📌 สถาปัตยกรรมระบบ: Two-Stage Pipeline

ระบบคัดกรองและจำแนกโรคผิวหนังทำงานแบบ **2 ด่าน (Two-Stage Cascaded Pipeline)** เพื่อลด False Positive และเพิ่มความแม่นยำในการใช้งานจริง:

```
[ภาพถ่ายจากผู้ใช้ / กล้องมือถือ]
           │
           ▼
┌──────────────────────────────────────────────┐
│ ด่านที่ 1: Screening Model                   │
│ (screening_modelv2.tflite)                   │
│ - คัดกรองว่าเป็น "ผิวหนังปกติ" หรือ "มีรอยโรค" │
└──────────────────────┬───────────────────────┘
                       │
       ┌───────────────┴───────────────┐
       ▼                               ▼
 [ ผิวปกติ (Normal) ]        [ มีรอยโรค (Lesion) ]
   (แจ้งเตือนผู้ใช้)                    │
                                       ▼
                    ┌──────────────────────────────────────────────┐
                    │ ด่านที่ 2: Classification Model              │
                    │ (Modelv3.tflite + class_indices.json)        │
                    │ - จำแนกชนิดของโรคผิวหนัง 8 คลาส (ResNet50)    │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
                                 [ ผลการวินิจฉัย 8 โรค ]
```

### รายชื่อโรค 8 คลาส (Stage 2 Classes):
1. **Actinic Keratosis** — ระยะก่อนมะเร็งผิวหนัง
2. **BCC** (Basal Cell Carcinoma) — มะเร็งผิวหนังเบเซลเซลล์
3. **Keratosis** (Seborrheic Keratosis) — โรคกระเนื้อ
4. **Melanocytic Nevi** — ไฝ หรือ ปานธรรมดา
5. **Melanoma** — มะเร็งผิวหนังเมลาโนมา (อันตรายสูงสุด)
6. **Psoriasis** — โรคสะเก็ดเงิน
7. **SCC** (Squamous Cell Carcinoma) — มะเร็งผิวหนังชนิดสความัสเซลล์
8. **Tinea** — โรคเชื้อราที่ผิวหนัง / กลากเกลื้อน

---

## 📁 โครงสร้างโฟลเดอร์ `ml/`

```
ml/
├── README.md                          # เอกสารคู่มือนี้
├── requirements.txt                   # รายการ dependencies ที่ต้องใช้ (TensorFlow, scikit-learn, etc.)
│
├── stage1_screening/                  # 🔬 ด่านที่ 1: คัดกรองผิวหนังปกติ vs รอยโรค
│   ├── train_screening.py             # สคริปต์เทรน Binary Classification
│   ├── prepare_screening_data.py       # สคริปต์เตรียมและรวม Dataset สำหรับ Screening
│   ├── filter_strict_real_skin.py     # ตัวกรองข้อมูลผิวหนังจริงเพื่อความสะอาดของข้อมูล
│   ├── test_crop_and_background.py    # สคริปต์ทดสอบภาพตัดขอบและพื้นหลัง
│   ├── screening_configv2.json        # คอนฟิกค่า Threshold และพารามิเตอร์
│   └── selected_disease_paths.txt     # รายชื่อไฟล์รอยโรคที่เลือกใช้
│
├── stage2_classification/             # 🧠 ด่านที่ 2: จำแนก 8 โรคผิวหนัง (ResNet50 + Attention)
│   ├── train_classifier.py            # สคริปต์เทรนหลัก (Phase 1: Feature Extraction, Phase 2: Fine-Tuning)
│   ├── convert_tflite.py              # สคริปต์แปลงโมเดลจาก Keras (.keras) เป็น TFLite (.tflite)
│   ├── eval_model.py                  # สคริปต์ประเมินความแม่นยำ Classification Report & Confusion Matrix
│   ├── split_dataset.py               # สคริปต์แบ่งชุดข้อมูล Train (70%) / Val (20%) / Test (10%)
│   ├── create_sample_grid.py          # สคริปต์สร้างภาพ Grid ตัวอย่างโรค 8 คลาส
│   ├── class_indices.json             # ไฟล์จับคู่ Index (0-7) กับชื่อโรค
│   └── labels.txt                     # รายชื่อโรคเรียงตาม Index สำหรับแอป
│
├── pipeline_test/                     # 🧪 สคริปต์ทดสอบระบบและการทำเดโม
│   ├── test_two_stage_pipeline.py     # ทดสอบ End-to-End Two-Stage Pipeline
│   ├── app_gradio_demo.py             # เว็บแอป Gradio แบบ Interactive สำหรับเดโมบนคอมพิวเตอร์
│   ├── app_screening_gradio.py        # Gradio สำหรับทดสอบเฉพาะ Stage 1
│   └── test_screening_gradio.py
│
└── docs_and_diagrams/                 # 📊 แผนภาพและผลการทดลองสำหรับรายงาน/พรีเซนต์
    ├── graphs/                        # กราฟ Loss, Accuracy, Confusion Matrix, PR Curve
    ├── architecture_diagrams/         # ภาพไดอะแกรมโครงสร้างโมเดล ResNet50, Attention Block
    ├── test_reports/                  # ผลทดสอบรายโรคบันทึกเป็น Excel (.xlsx)
    └── generate_scripts/              # สคริปต์ Python ที่ใช้สร้างกราฟและไดอะแกรมทั้งหมด
```

---

## 🚀 ขั้นตอนการติดตั้งและรันสคริปต์ (How to Run)

### 1. ติดตั้ง Dependencies
```bash
cd ml
pip install -r requirements.txt
```

### 2. การเทรนโมเดล Stage 1 (Screening Model)
```bash
cd stage1_screening
python prepare_screening_data.py
python train_screening.py
```
*ไฟล์ที่ได้:* `screening_modelv2.tflite` สำหรับนำไปวางใน `../assets/`

### 3. การเทรนโมเดล Stage 2 (8-Class Classifier)
```bash
cd stage2_classification
python split_dataset.py
python train_classifier.py
```
* หมายเหตุ: สคริปต์จะทำการเทรน 2 เฟส:
  * **Phase 1:** Freeze Base Model (ResNet50) เทรนเฉพาะ Top Attention Layers ด้วย Adam (lr=1e-3)
  * **Phase 2:** Unfreeze เลเยอร์ช่วงท้าย (layer 120 เป็นต้นไป) ปรับ Fine-Tuning ด้วย Adam (lr=1e-5)

### 4. การแปลงโมเดลเป็น TensorFlow Lite (.tflite) สำหรับแอป Flutter
```bash
cd stage2_classification
python convert_tflite.py
```
*ผลลัพธ์:* จะได้ `Modelv3.tflite` และ `labels.txt` เพื่อนำไปอัปเดตในโฟลเดอร์ `assets/` ของโปรเจกต์ Flutter

### 5. การทดสอบเดโมผ่านเว็บ UI (Gradio)
```bash
cd pipeline_test
python test_two_stage_pipeline.py
# หรือเปิด Web UI
python app_gradio_demo.py
```
