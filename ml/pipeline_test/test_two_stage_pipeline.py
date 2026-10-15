"""
=============================================================================
 สคริปต์จำลองการทดสอบสถาปัตยกรรม 2 ด่าน (Two-Stage Pipeline Test)
 ด่านที่ 1: Screening Model (EfficientNet-B0) -> คัดกรอง ปกติ vs มีรอยโรค
 ด่านที่ 2: Diagnostic Model (Model3.keras เดิม) -> จำแนกละเอียด 8 โรคผิวหนัง
 
 ** สคริปต์นี้ทำงานแบบ Standalone ไม่กระทบ app.py หรือการทำงานของระบบเดิม **
=============================================================================
"""

import os
import sys
import json
import cv2
import numpy as np

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')
import tensorflow as tf
from tensorflow.keras.applications.efficientnet import preprocess_input as eff_preprocess
from tensorflow.keras.applications.resnet50 import preprocess_input as resnet_preprocess

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, ".."))

SCREENING_MODEL_PATH = os.path.join(CURRENT_DIR, "screening_model.keras")
SCREENING_CONFIG_PATH = os.path.join(CURRENT_DIR, "screening_config.json")

STAGE2_MODEL_PATH = os.path.join(PROJECT_ROOT, "Model3.keras")
STAGE2_INDICES_PATH = os.path.join(PROJECT_ROOT, "class_indices.json")

def load_pipelines():
    print("⏳ กำลังโหลดโมเดลทั้ง 2 ด่าน...")
    
    # 1. โหลด Stage 1: Screening Model
    if not os.path.exists(SCREENING_MODEL_PATH):
        raise FileNotFoundError(f"ไม่พบโมเดลคัดกรอง: {SCREENING_MODEL_PATH} (กรุณารัน train_screening.py ก่อน)")
    screening_model = tf.keras.models.load_model(SCREENING_MODEL_PATH)
    
    # อ่าน Threshold ความปลอดภัย
    threshold = 0.35
    if os.path.exists(SCREENING_CONFIG_PATH):
        with open(SCREENING_CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)
            threshold = cfg.get("suggested_safety_threshold", 0.35)
    print(f"✓ โหลด Stage 1 (Screening Model) สำเร็จ! [Safety Threshold = {threshold}]")

    # 2. โหลด Stage 2: Model3.keras เดิม
    if not os.path.exists(STAGE2_MODEL_PATH):
        raise FileNotFoundError(f"ไม่พบโมเดลเดิม: {STAGE2_MODEL_PATH}")
    stage2_model = tf.keras.models.load_model(STAGE2_MODEL_PATH, compile=False)
    
    stage2_labels = {}
    if os.path.exists(STAGE2_INDICES_PATH):
        with open(STAGE2_INDICES_PATH, "r", encoding="utf-8") as f:
            indices = json.load(f)
            stage2_labels = {v: k for k, v in indices.items()}
    print(f"✓ โหลด Stage 2 (Model3.keras 8 โรคเดิม) สำเร็จ!")

    return screening_model, stage2_model, threshold, stage2_labels

def predict_image(image_path, screening_model, stage2_model, threshold, stage2_labels):
    bgr = cv2.imread(image_path)
    if bgr is None:
        return {"error": "ไม่สามารถอ่านไฟล์ภาพได้"}
    
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    
    # -------------------------------------------------------------
    # ขั้นตอนที่ 1: เข้าด่าน Screening (EfficientNet-B0)
    # -------------------------------------------------------------
    img_screen = cv2.resize(rgb, (224, 224))
    img_screen_arr = np.expand_dims(img_screen, axis=0).astype(np.float32)
    img_screen_prep = eff_preprocess(img_screen_arr)
    
    prob_disease = float(screening_model.predict(img_screen_prep, verbose=0)[0][0])
    prob_normal = 1.0 - prob_disease

    # -------------------------------------------------------------
    # การตัดสินใจ (Decision Rule)
    # -------------------------------------------------------------
    if prob_disease < threshold:
        return {
            "stage1_result": "Normal (ผิวปกติ)",
            "normal_confidence": f"{prob_normal * 100:.2f}%",
            "disease_suspicion": f"{prob_disease * 100:.2f}%",
            "passed_to_stage2": False,
            "final_diagnosis": "ผิวหนังปกติ ไม่พบรอยโรคที่น่าสงสัย",
            "stage2_details": None
        }
    else:
        # ---------------------------------------------------------
        # ขั้นตอนที่ 2: มีรอยโรค -> ส่งต่อให้ Model3.keras เดิมวินิจฉัย
        # ---------------------------------------------------------
        img_stage2 = cv2.resize(rgb, (224, 224))
        img_stage2_arr = np.expand_dims(img_stage2, axis=0).astype(np.float32)
        img_stage2_prep = resnet_preprocess(img_stage2_arr)

        stage2_preds = stage2_model.predict(img_stage2_prep, verbose=0)[0]
        top_idx = int(np.argmax(stage2_preds))
        top_disease = stage2_labels.get(top_idx, f"Class {top_idx}")
        top_confidence = float(stage2_preds[top_idx])

        # สรุปอันดับความน่าจะเป็น 3 อันดับแรก
        top3_indices = np.argsort(stage2_preds)[::-1][:3]
        top3_results = [
            {"disease": stage2_labels.get(i, f"Class {i}"), "confidence": f"{stage2_preds[i]*100:.2f}%"}
            for i in top3_indices
        ]

        return {
            "stage1_result": "Abnormal (ตรวจพบรอยโรค/ผื่นผิดปกติ)",
            "normal_confidence": f"{prob_normal * 100:.2f}%",
            "disease_suspicion": f"{prob_disease * 100:.2f}%",
            "passed_to_stage2": True,
            "final_diagnosis": f"ผลวินิจฉัยละเอียด 8 โรค: {top_disease} (ความมั่นใจ {top_confidence*100:.2f}%)",
            "stage2_details": top3_results
        }

def print_result_card(img_path, res):
    print("\n" + "─" * 60)
    print(f"📷 ภาพทดสอบ: {os.path.basename(img_path)}")
    print("─" * 60)
    
    if "error" in res:
        print(f"❌ เกิดข้อผิดพลาด: {res['error']}")
        return

    # แสดงผลด่านที่ 1
    print(f"【ด่านที่ 1: Screening Model (EfficientNet-B0)】")
    print(f"  • สถานะ: {res['stage1_result']}")
    print(f"  • มั่นใจว่าเป็นผิวปกติ : {res['normal_confidence']}")
    print(f"  • ความน่าสงสัยว่ามีรอยโรค: {res['disease_suspicion']}")
    
    # แสดงผลด่านที่ 2
    print(f"\n【ด่านที่ 2: Diagnostic Model (Model3.keras 8 โรคเดิม)】")
    if not res['passed_to_stage2']:
        print("  • การทำงาน: 🛑 ไม่จำเป็นต้องตรวจต่อ (ดักจับเป็นผิวปกติเรียบร้อย)")
        print("  • สรุปผล   : ✅ ผิวหนังปกติ ไม่พบรอยโรคต้องสงสัย")
    else:
        print("  • การทำงาน: ➡️ ตรวจพบรอยโรค ส่งต่อให้ Model3.keras วินิจฉัยต่อ")
        print(f"  • สรุปผล   : ⚠️ {res['final_diagnosis']}")
        print("  • โอกาสเกิด 3 อันดับแรก:")
        for idx, item in enumerate(res['stage2_details'], 1):
            print(f"     {idx}. {item['disease']:<20} ({item['confidence']})")
    print("─" * 60)

def main():
    print("=" * 65)
    print("  🧪 ทดสอบระบบ 2 ด่าน (Screening Model -> Model3.keras)")
    print("=" * 65)
    
    try:
        screening_model, stage2_model, threshold, stage2_labels = load_pipelines()
    except Exception as e:
        print(f"❌ {e}")
        return

    # 1. ทดสอบตัวอย่างอัตโนมัติ 4 ภาพ (ผิวปกติ 2 ภาพ, รอยโรค 2 ภาพ)
    test_normal_dir = os.path.join(CURRENT_DIR, "dataset_screening", "test", "Normal")
    test_disease_dir = os.path.join(CURRENT_DIR, "dataset_screening", "test", "Disease")

    sample_tests = []
    if os.path.exists(test_normal_dir):
        normals = [os.path.join(test_normal_dir, f) for f in os.listdir(test_normal_dir)[:2]]
        sample_tests.extend(normals)
    if os.path.exists(test_disease_dir):
        diseases = [os.path.join(test_disease_dir, f) for f in os.listdir(test_disease_dir)[:2]]
        sample_tests.extend(diseases)

    print("\n🔍 กำลังรันตัวอย่างทดสอบจาก Test Set อัตโนมัติ 4 ภาพ:")
    for s_path in sample_tests:
        res = predict_image(s_path, screening_model, stage2_model, threshold, stage2_labels)
        print_result_card(s_path, res)

    # 2. เมนูป้อนรูปภาพทดสอบเองแบบ Interactive
    print("\n" + "=" * 65)
    print("  🎯 โหมดทดสอบรูปภาพของคุณเอง (Interactive Mode)")
    print("=" * 65)
    print("👉 วิธีใช้งาน: ลากไฟล์รูปภาพมาวางในหน้าต่างนี้ แล้วกด Enter (หรือพิมพ์ 'q' เพื่อออก)\n")

    while True:
        try:
            user_input = input("ป้อน Path รูปภาพ (หรือลากไฟล์มาวาง): ").strip()
            if not user_input:
                continue
            if user_input.lower() in ['q', 'exit', 'quit']:
                print("ปิดการทดสอบเรียบร้อยครับ")
                break
            
            # ลบเครื่องหมายคำพูดรอบ path (กรณีลากไฟล์มาวางใน Windows)
            clean_path = user_input.strip('"\'')
            if not os.path.exists(clean_path):
                print(f"❌ ไม่พบไฟล์รูปภาพที่: {clean_path} (กรุณาลองใหม่อีกครั้ง)")
                continue

            res = predict_image(clean_path, screening_model, stage2_model, threshold, stage2_labels)
            print_result_card(clean_path, res)
        except (KeyboardInterrupt, EOFError):
            print("\nปิดการทดสอบเรียบร้อยครับ")
            break

if __name__ == "__main__":
    main()
