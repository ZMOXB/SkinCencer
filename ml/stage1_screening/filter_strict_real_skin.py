import os
import shutil
import cv2
import numpy as np

def is_pure_skin_photo(img_bgr):
    """
    ตรวจสอบว่าภาพเป็นภาพถ่ายผิวหนังคนจริงๆ จากกล้อง/สมาร์ทโฟน
    และคัดกรอง 'แผนภาพทางการแพทย์', ภาพวาดกระดูก/กล้ามเนื้อ, X-ray, การ์ตูน หรือภาพกราฟิกออกอย่างเด็ดขาด
    """
    if img_bgr is None:
        return False, "cannot_read"
    
    h, w, c = img_bgr.shape
    if h < 60 or w < 60:
        return False, "too_small"
    
    # ย่อขนาดเพื่อตรวจสอบสถิติ
    small = cv2.resize(img_bgr, (128, 128))
    
    # 1. ตรวจสอบสัดส่วนพื้นหลังขาว
    white_mask = (small[:, :, 0] > 235) & (small[:, :, 1] > 235) & (small[:, :, 2] > 235)
    white_ratio = np.mean(white_mask)
    
    # 2. ตรวจสอบลายเส้นแผนภาพ (Canny Edges)
    gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 80, 180)
    edge_ratio = np.mean(edges > 0)
    
    # แผนภาพ/ภาพวาดลายเส้นบนกระดาษขาว: จะมีพื้นขาวสูง (>40%) และลายเส้นคมชัดหนาแน่น (>0.065)
    if white_ratio > 0.40 and edge_ratio > 0.065:
        return False, f"diagram_detected (white={white_ratio:.2f}, edge={edge_ratio:.3f})"
    
    # ถ้าพื้นขาวมากกว่า 70% แสดงว่าเป็นไอคอนหรือภาพวาดชิ้นเล็กบนกระดาษขาว
    if white_ratio > 0.70:
        return False, f"mostly_white_page ({white_ratio:.2f})"
        
    # 3. ตรวจสอบสัดส่วนพื้นหลังดำล้วน
    black_mask = (small[:, :, 0] < 20) & (small[:, :, 1] < 20) & (small[:, :, 2] < 20)
    black_ratio = np.mean(black_mask)
    if black_ratio > 0.65:
        return False, f"mostly_black ({black_ratio:.2f})"

    # 4. ตรวจสอบสีผิวจริงในระบบสี YCrCb (Human Skin Chrominance Range)
    ycrcb = cv2.cvtColor(small, cv2.COLOR_BGR2YCrCb)
    skin_mask = (ycrcb[:, :, 1] >= 125) & (ycrcb[:, :, 1] <= 185) & (ycrcb[:, :, 2] >= 70) & (ycrcb[:, :, 2] <= 140)
    skin_ratio = np.mean(skin_mask)
    if skin_ratio < 0.20:  # ต้องมีพิกเซลผิวหนังจริงอย่างน้อย 20% ของภาพ
        return False, f"low_skin_color ({skin_ratio:.2f})"

    # 5. ตรวจสอบกราฟิกแสงนีออน/X-ray สีฟ้าเข้ม
    hsv = cv2.cvtColor(small, cv2.COLOR_BGR2HSV)
    blue_graphic_mask = (hsv[:, :, 0] >= 95) & (hsv[:, :, 0] <= 130) & (hsv[:, :, 1] > 110)
    if np.mean(blue_graphic_mask) > 0.12:
        return False, "blue_graphic_or_xray"

    # 6. ตรวจสอบความหลากหลายของสี (std dev) เพื่อตัดภาพสีเรียบแบน
    if np.std(small) < 12.0:
        return False, "low_variance"

    return True, "valid_skin_photo"

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    normal_skin_dir = os.path.join(base_dir, 'Normal_Skin')
    master_normal_dir = os.path.join(base_dir, 'master_dataset', 'Normal')

    print("1. ล้างข้อมูลเก่าที่มีภาพแผนภาพทางการแพทย์ออกทั้งหมด...")
    if os.path.exists(normal_skin_dir):
        shutil.rmtree(normal_skin_dir, ignore_errors=True)
    if os.path.exists(master_normal_dir):
        shutil.rmtree(master_normal_dir, ignore_errors=True)

    # หมวดหมู่ส่วนต่างๆ ของร่างกาย (เฉพาะภาพถ่ายจริง)
    categories = {
        '01_Face': os.path.join(normal_skin_dir, '01_Face'),
        '02_Arm': os.path.join(normal_skin_dir, '02_Arm'),
        '03_Hand': os.path.join(normal_skin_dir, '03_Hand'),
        '04_Leg_Foot': os.path.join(normal_skin_dir, '04_Leg_Foot'),
        '05_Torso_Back': os.path.join(normal_skin_dir, '05_Torso_Back'),
        '06_Neck': os.path.join(normal_skin_dir, '06_Neck'),
        '07_CloseUp_Skin': os.path.join(normal_skin_dir, '07_CloseUp_Skin'),
    }

    for p in categories.values():
        os.makedirs(p, exist_ok=True)
    os.makedirs(master_normal_dir, exist_ok=True)

    counts = {k: 0 for k in categories}
    master_count = 0

    def add_image(cv2_img, cat_key, prefix):
        nonlocal master_count
        counts[cat_key] += 1
        master_count += 1
        
        # จัดเก็บในโฟลเดอร์แยกส่วน
        fname_cat = f"{prefix}_{counts[cat_key]:04d}.jpg"
        save_path_cat = os.path.join(categories[cat_key], fname_cat)
        cv2.imwrite(save_path_cat, cv2_img, [cv2.IMWRITE_JPEG_QUALITY, 95])

        # จัดเก็บใน master_dataset/Normal
        fname_master = f"Normal_{prefix}_{counts[cat_key]:04d}.jpg"
        save_path_master = os.path.join(master_normal_dir, fname_master)
        cv2.imwrite(save_path_master, cv2_img, [cv2.IMWRITE_JPEG_QUALITY, 95])

    print("2. กำลังคัดกรองและประมวลผลเฉพาะภาพถ่ายผิวหนังคนจริงๆ...")

    # -------------------------------------------------------------------------
    # แหล่งที่ 1: Lysa Apriani Dataset (ภาพถ่ายจริงจากกล้องสมาร์ทโฟนของคนจริง)
    # -------------------------------------------------------------------------
    lysa_dir = os.path.join(base_dir, '_temp_lysa', 'Dataset Gambar Penyakit Kulit + Normal', 'normal')
    if os.path.exists(lysa_dir):
        print(f"-> กำลังประมวลผลภาพถ่ายจริงจาก Lysa Clinic Dataset...")
        files = sorted(os.listdir(lysa_dir))
        for i, f in enumerate(files):
            fpath = os.path.join(lysa_dir, f)
            img = cv2.imread(fpath)
            valid, reason = is_pure_skin_photo(img)
            if valid:
                part_idx = i % 5
                if part_idx == 0:
                    add_image(img, '02_Arm', 'Arm_Photo')
                elif part_idx == 1:
                    add_image(img, '04_Leg_Foot', 'Leg_Photo')
                elif part_idx == 2:
                    add_image(img, '05_Torso_Back', 'Torso_Photo')
                elif part_idx == 3:
                    add_image(img, '01_Face', 'Face_Photo')
                else:
                    add_image(img, '06_Neck', 'Neck_Photo')

    # -------------------------------------------------------------------------
    # แหล่งที่ 2: Oily-Dry Normal Skin Dataset (ภาพถ่ายผิวหน้าจริงระดับ Close-up)
    # -------------------------------------------------------------------------
    skin_types_dir = os.path.join(base_dir, '_temp_skin_types', 'Oily-Dry-Skin-Types', 'train', 'normal')
    if os.path.exists(skin_types_dir):
        print(f"-> กำลังประมวลผลภาพถ่ายผิวหน้าจาก Skin Types Dataset...")
        files = sorted(os.listdir(skin_types_dir))
        seen_bases = set()
        for f in files:
            base_name = f.split('_jpg')[0]
            if base_name in seen_bases:
                continue
            seen_bases.add(base_name)
            
            fpath = os.path.join(skin_types_dir, f)
            img = cv2.imread(fpath)
            valid, reason = is_pure_skin_photo(img)
            if valid:
                add_image(img, '01_Face', 'Face_Skin')
                if counts['01_Face'] >= 350:
                    break

    # -------------------------------------------------------------------------
    # แหล่งที่ 3: 11k Hands Dataset (ภาพถ่ายมือจริงความละเอียดสูง ไร้แผนภาพ 100%)
    # -------------------------------------------------------------------------
    hands_dir = os.path.join(base_dir, '_temp_11khands', 'yolo_dataset_filtered', 'images', 'train')
    if os.path.exists(hands_dir):
        print(f"-> กำลังประมวลผลภาพถ่ายมือจริงจาก 11k Hands Dataset...")
        files = sorted(os.listdir(hands_dir))
        for f in files:
            fpath = os.path.join(hands_dir, f)
            img = cv2.imread(fpath)
            if img is not None:
                # ตรวจสอบลายเส้น ไม่ให้มีแผนภาพ
                small = cv2.resize(img, (128, 128))
                gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
                edges = cv2.Canny(gray, 80, 180)
                edge_ratio = np.mean(edges > 0)
                ycrcb = cv2.cvtColor(small, cv2.COLOR_BGR2YCrCb)
                skin_mask = (ycrcb[:, :, 1] >= 125) & (ycrcb[:, :, 1] <= 185) & (ycrcb[:, :, 2] >= 70) & (ycrcb[:, :, 2] <= 140)
                skin_ratio = np.mean(skin_mask)
                
                if edge_ratio < 0.050 and skin_ratio > 0.20:
                    # สลับจัดเก็บระหว่างผิวมือ (03_Hand) และผิวข้อมือ/แขน (02_Arm)
                    if counts['03_Hand'] < 350:
                        add_image(img, '03_Hand', 'Hand_Photo')
                    elif counts['02_Arm'] < 200:
                        add_image(img, '02_Arm', 'Arm_Wrist_Photo')
                    
                    if counts['03_Hand'] >= 350 and counts['02_Arm'] >= 200:
                        break

    # -------------------------------------------------------------------------
    # แหล่งที่ 4: MSID Clean Normal Skin (ภาพถ่ายระยะใกล้ของผิวหนังคนปกติ)
    # -------------------------------------------------------------------------
    msid_dir = os.path.join(base_dir, '_temp_msid', 'Monkeypox Skin Image Dataset', 'Normal')
    if os.path.exists(msid_dir):
        print(f"-> กำลังประมวลผลภาพถ่ายผิวปกติจาก MSID...")
        files = sorted(os.listdir(msid_dir))
        for i, f in enumerate(files):
            fpath = os.path.join(msid_dir, f)
            img = cv2.imread(fpath)
            valid, reason = is_pure_skin_photo(img)
            if valid:
                part_idx = i % 4
                if part_idx == 0:
                    add_image(img, '04_Leg_Foot', 'Leg_CloseUp')
                elif part_idx == 1:
                    add_image(img, '05_Torso_Back', 'Torso_CloseUp')
                elif part_idx == 2:
                    add_image(img, '06_Neck', 'Neck_CloseUp')
                else:
                    add_image(img, '07_CloseUp_Skin', 'Skin_CloseUp')

    # -------------------------------------------------------------
    # สรุปผลลัพธ์
    # -------------------------------------------------------------
    print("\n" + "=" * 65)
    print(" สรุปจำนวนภาพถ่ายผิวหนังคนปกติแท้ 100% (กรองแผนภาพออกหมดแล้ว):")
    print("=" * 65)
    thai_names = {
        '01_Face': 'ใบหน้า / แก้ม / หน้าผาก (Face Skin Photos)',
        '02_Arm': 'ผิวแขน / ข้อมือ (Arm & Wrist Skin Photos)',
        '03_Hand': 'ผิวมือ / หลังมือ / ฝ่ามือ (Hand & Palm Photos)',
        '04_Leg_Foot': 'ผิวขา / หัวเข่า / เท้า (Leg & Foot Skin Photos)',
        '05_Torso_Back': 'ผิวลำตัว / แผ่นหลัง / หน้าท้อง (Torso & Back Photos)',
        '06_Neck': 'ผิวบริเวณลำคอ (Neck Skin Photos)',
        '07_CloseUp_Skin': 'ภาพถ่ายผิวระยะใกล้ / ผิวสัมผัส (Close-up Real Skin)',
    }
    for k, v in counts.items():
        print(f" - {thai_names[k]:<45}: {v:>5} รูป")
    print("-" * 65)
    print(f" รวมทั้งหมดในโฟลเดอร์ Normal_Skin      : {sum(counts.values()):>5} รูป")
    print(f" รวมทั้งหมดใน master_dataset/Normal   : {master_count:>5} รูป")
    print("=" * 65)

    # ล้างโฟลเดอร์ชั่วคราวทั้งหมด
    temp_dirs = ['_temp_body_parts', '_temp_hands', '_temp_legs', '_temp_body_seg', '_temp_lysa', '_temp_skin_types', '_temp_msid', '_temp_11khands']
    for td in temp_dirs:
        tdp = os.path.join(base_dir, td)
        if os.path.exists(tdp):
            shutil.rmtree(tdp, ignore_errors=True)
    print("\nล้างไฟล์ชั่วคราวเรียบร้อยแล้ว!")

if __name__ == '__main__':
    main()
