"""
=============================================================================
 สคริปต์เตรียมข้อมูลสำหรับเทรนโมเดลคัดกรองเบื้องต้น (Screening Model Data Prep)
 อัตราส่วน: โรค 60% : ผิวปกติ 40%
 สัดส่วนแบ่งชุดข้อมูล: Train 70% | Val 20% | Test 10%
 
 แหล่งข้อมูล:
 - ผิวปกติ: screening_experiment/Normaldata
 - รอยโรค: master_dataset (สุ่ม 8 คลาสเท่าๆ กัน)
 
 บันทึกรายชื่อ Path ของรูปรอยโรคที่สุ่มได้ไว้ที่:
 - screening_experiment/selected_disease_paths.txt
=============================================================================
"""

import os
import sys
import shutil
import random
from collections import defaultdict

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, ".."))

SOURCE_DISEASE_DIR = os.path.join(PROJECT_ROOT, "master_dataset")
SOURCE_NORMAL_DIR = os.path.join(CURRENT_DIR, "Normaldata")
OUTPUT_DIR = os.path.join(CURRENT_DIR, "dataset_screening")
PATHS_LOG_FILE = os.path.join(CURRENT_DIR, "selected_disease_paths.txt")

TRAIN_RATIO = 0.70
VAL_RATIO = 0.20
TEST_RATIO = 0.10

RANDOM_SEED = 42
random.seed(RANDOM_SEED)

def get_image_files(folder_path):
    valid_exts = ('.jpg', '.jpeg', '.png')
    if not os.path.exists(folder_path):
        return []
    return [
        os.path.join(folder_path, f)
        for f in os.listdir(folder_path)
        if f.lower().endswith(valid_exts)
    ]

def main():
    print("=" * 65)
    print("  กำลังเริ่มต้นเตรียมชุดข้อมูลสำหรับคัดกรอง (Screening Dataset)")
    print("=" * 65)

    if not os.path.exists(SOURCE_DISEASE_DIR):
        print(f"❌ ไม่พบโฟลเดอร์รอยโรค: {SOURCE_DISEASE_DIR}")
        return
    if not os.path.exists(SOURCE_NORMAL_DIR):
        print(f"❌ ไม่พบโฟลเดอร์ผิวปกติ: {SOURCE_NORMAL_DIR}")
        return

    # 1. รวบรวมภาพผิวปกติจาก Normaldata
    all_normal_files = get_image_files(SOURCE_NORMAL_DIR)
    random.shuffle(all_normal_files)
    normal_count = len(all_normal_files)
    print(f"📌 แหล่งข้อมูลผิวปกติ (Normaldata): พบ {normal_count:,} ภาพ")

    # 2. คำนวณจำนวนภาพโรคตามสัดส่วน 60:40 (โรค = ปกติ * 1.5)
    target_disease_total = int(normal_count * 1.5)
    
    disease_classes = sorted([
        d for d in os.listdir(SOURCE_DISEASE_DIR)
        if os.path.isdir(os.path.join(SOURCE_DISEASE_DIR, d))
    ])
    num_disease_classes = len(disease_classes)
    per_class_quota = target_disease_total // num_disease_classes

    print(f"📊 สัดส่วนเป้าหมาย (โรค 60% : ปกติ 40%):")
    print(f"   - ภาพผิวปกติ (40%): {normal_count:,} ภาพ")
    print(f"   - ภาพรอยโรค (60%): {target_disease_total:,} ภาพ (เฉลี่ยโรคละ {per_class_quota:,} ภาพ x {num_disease_classes} โรค)")
    print(f"   - รวมทั้งหมด: {normal_count + (per_class_quota * num_disease_classes):,} ภาพ")
    print("-" * 65)

    # 3. สุ่มคัดเลือกภาพจากแต่ละโรคใน master_dataset พร้อมบันทึก Path
    disease_pool = []
    class_to_paths = defaultdict(list)
    print("🔍 กำลังสุ่มดึงตัวแทนภาพรอยโรคทั้ง 8 คลาส:")
    for cls in disease_classes:
        cls_dir = os.path.join(SOURCE_DISEASE_DIR, cls)
        cls_files = get_image_files(cls_dir)
        random.shuffle(cls_files)
        
        selected = cls_files[:per_class_quota]
        disease_pool.extend(selected)
        class_to_paths[cls] = selected
        print(f"   ✓ {cls:<20}: มี {len(cls_files):>5} ภาพ -> สุ่มใช้ {len(selected):>4} ภาพ")

    random.shuffle(disease_pool)
    print(f"   รวมภาพรอยโรคที่สุ่มได้: {len(disease_pool):,} ภาพ")
    print("-" * 65)

    # 4. บันทึก Path ทั้งหมดลงในไฟล์ข้อความเพื่อให้ผู้ใช้ตรวจสอบ
    with open(PATHS_LOG_FILE, "w", encoding="utf-8") as f:
        f.write(f"=== รายชื่อ Path ภาพรอยโรคที่ถูกเลือกมาใช้เทรน (รวม {len(disease_pool):,} ภาพ) ===\n")
        f.write(f"สุ่มจาก master_dataset โรคละ {per_class_quota} ภาพ (Random Seed: {RANDOM_SEED})\n\n")
        for cls in disease_classes:
            f.write(f"----------------------------------------------------------------------\n")
            f.write(f"📁 คลาส: {cls} (จำนวน {len(class_to_paths[cls])} ภาพ)\n")
            f.write(f"----------------------------------------------------------------------\n")
            for p in sorted(class_to_paths[cls]):
                f.write(f"{p}\n")
            f.write("\n")
    print(f"📝 บันทึกรายชื่อ Path รูปรอยโรคทั้งหมดไว้ที่: {PATHS_LOG_FILE}")
    print("-" * 65)

    # 5. ล้างโฟลเดอร์ปลายทางเก่า แล้วสร้างใหม่
    if os.path.exists(OUTPUT_DIR):
        print(f"🧹 ล้างข้อมูลเดิมใน {OUTPUT_DIR}...")
        shutil.rmtree(OUTPUT_DIR)

    splits = ['train', 'val', 'test']
    for sp in splits:
        for cat in ['Normal', 'Disease']:
            os.makedirs(os.path.join(OUTPUT_DIR, sp, cat), exist_ok=True)

    # 6. ฟังก์ชันแบ่งข้อมูล 70 : 20 : 10
    def split_and_copy(file_list, category_name):
        n = len(file_list)
        n_train = int(n * TRAIN_RATIO)
        n_val = int(n * VAL_RATIO)
        n_test = n - n_train - n_val

        splits_map = {
            'train': file_list[:n_train],
            'val': file_list[n_train:n_train + n_val],
            'test': file_list[n_train + n_val:]
        }

        print(f"📦 กำลังคัดลอกคลาส {category_name:<8} -> Train: {n_train:>4} | Val: {n_val:>4} | Test: {n_test:>4}")
        for sp_name, items in splits_map.items():
            dst_folder = os.path.join(OUTPUT_DIR, sp_name, category_name)
            for src_path in items:
                fname = os.path.basename(src_path)
                # ป้องกันชื่อไฟล์ซ้ำระหว่างโรค
                if category_name == 'Disease':
                    parent_cls = os.path.basename(os.path.dirname(src_path))
                    fname = f"{parent_cls}_{fname}"
                dst_path = os.path.join(dst_folder, fname)
                shutil.copy2(src_path, dst_path)

    # 7. คัดลอกทั้งสองคลาส
    split_and_copy(all_normal_files, "Normal")
    split_and_copy(disease_pool, "Disease")

    print("=" * 65)
    print("✅ เตรียมชุดข้อมูล Screening จาก Normaldata สำเร็จเรียบร้อย 100%!")
    print(f"📁 บันทึกข้อมูลไว้ที่: {OUTPUT_DIR}")
    print(f"📄 ดูรายการ Path ของภาพรอยโรคทั้งหมดได้ที่: {PATHS_LOG_FILE}")
    print("=" * 65)

if __name__ == "__main__":
    main()
