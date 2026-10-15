import os
import cv2
import numpy as np
from PIL import Image

def process_skin_techniques(image_path, target_size=(224, 224)):
    """
    ทดสอบ 2 วิธี:
    1. Center Crop & Zoom: ตัดขอบภาพให้เหลือเฉพาะผิวหนังตรงกลางตามขนาดที่โมเดลต้องการ (224x224)
    2. Background Removal (Skin Segmentation): ตัดฉากหลังที่ไม่ใช่ผิวหนังออกให้เหลือเฉพาะเนื่้อผิว
    """
    bgr = cv2.imread(image_path)
    if bgr is None:
        return None
    
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    h, w, _ = rgb.shape
    
    # -------------------------------------------------------------
    # 0. ภาพ Input (ย่อเพื่อแสดงผลคู่กัน)
    # -------------------------------------------------------------
    input_display = cv2.resize(rgb, target_size)
    
    # -------------------------------------------------------------
    # 1. เทคนิคที่ 1: Center Crop & Zoom (โฟกัสเฉพาะเนื้อผิวตรงกลาง)
    # -------------------------------------------------------------
    min_dim = min(h, w)
    # ซูมเข้า 1.25 เท่าเพื่อตัดขอบฉากหลังรอบนอกออก
    crop_size = int(min_dim * 0.8)
    cx, cy = w // 2, h // 2
    x1 = max(0, cx - crop_size // 2)
    y1 = max(0, cy - crop_size // 2)
    x2 = min(w, x1 + crop_size)
    y2 = min(h, y1 + crop_size)
    
    cropped = rgb[y1:y2, x1:x2]
    out_crop = cv2.resize(cropped, target_size)
    
    # -------------------------------------------------------------
    # 2. เทคนิคที่ 2: Background Removal (ตัดฉากหลังออกด้วย Skin Mask)
    # -------------------------------------------------------------
    # แปลงเป็นระบบสี YCrCb สำหรับสกัดผิวหนังมนุษย์
    ycrcb = cv2.cvtColor(rgb, cv2.COLOR_RGB2YCrCb)
    skin_mask = cv2.inRange(ycrcb, (0, 130, 75), (255, 180, 135))
    
    # กำจัด noise ด้วย Morphology (เปิด/ปิด)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_CLOSE, kernel, iterations=2)
    skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_OPEN, kernel, iterations=1)
    
    # Smooth ขอบหน้ากาก (Gaussian Blur)
    skin_mask_smooth = cv2.GaussianBlur(skin_mask, (5, 5), 0)
    
    # ตัดฉากหลัง: ส่วนที่เป็นผิวหนังเก็บไว้ ส่วนฉากหลังเปลี่ยนเป็นสีดำสนิท
    mask_3ch = cv2.cvtColor(skin_mask_smooth, cv2.COLOR_GRAY2RGB) / 255.0
    bg_removed = (rgb * mask_3ch).astype(np.uint8)
    
    # นำภาพที่ตัดฉากหลังแล้วมา Crop ตรงกลาง
    bg_removed_crop = bg_removed[y1:y2, x1:x2]
    out_bg_removed = cv2.resize(bg_removed_crop, target_size)
    
    # หน้ากากแสดงผล (Mask View)
    mask_display = cv2.resize(skin_mask, target_size)
    mask_display_3ch = cv2.cvtColor(mask_display, cv2.COLOR_GRAY2RGB)
    
    return {
        'input': input_display,
        'crop': out_crop,
        'bg_removed': out_bg_removed,
        'mask': mask_display_3ch
    }

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    normal_dir = os.path.join(base_dir, 'Normal_Skin')
    out_dir = os.path.join(base_dir, 'test_crop_output')
    os.makedirs(out_dir, exist_ok=True)
    
    # เลือกตัวอย่างภาพจากส่วนต่างๆ ของร่างกาย
    test_files = [
        ('Hand_Photo_0001.jpg', 'ผิวมือ (Hand)'),
        ('Arm_Photo_0001.jpg', 'ผิวแขน (Arm)'),
        ('Face_Photo_0001.jpg', 'ผิวหน้า (Face)'),
        ('Leg_Photo_0001.jpg', 'ผิวขา (Leg)'),
        ('Neck_Photo_0001.jpg', 'ผิวคอ (Neck)'),
        ('Torso_Photo_0001.jpg', 'ผิวลำตัว (Torso)'),
    ]
    
    print("=== กำลังทดสอบตัดภาพและลบแบล็กกราวด์ (Image Cropping & Background Removal) ===")
    
    comparison_cards = []
    
    for fname, label in test_files:
        fpath = os.path.join(normal_dir, fname)
        if not os.path.exists(fpath):
            continue
            
        res = process_skin_techniques(fpath)
        if res is None:
            continue
            
        # สร้างภาพแถบเปรียบเทียบ: [Input] | [Center Crop (224x224)] | [Background Removal] | [Skin Mask]
        # ใส่ตัวอักษรบรรยายในแต่ละภาพ
        def add_label(img, text):
            canvas = img.copy()
            cv2.rectangle(canvas, (0, 0), (224, 26), (20, 20, 20), -1)
            cv2.putText(canvas, text, (6, 18), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 255), 1, cv2.LINE_AA)
            return canvas

        p_input = add_label(res['input'], "1. Input Original")
        p_crop = add_label(res['crop'], "2. Output: Center Crop")
        p_bg = add_label(res['bg_removed'], "3. Output: Cut Background")
        p_mask = add_label(res['mask'], "4. Skin Mask Area")
        
        # ต่อภาพแนวนอน
        strip = np.hstack([p_input, p_crop, p_bg, p_mask])
        
        # บันทึกไฟล์เปรียบเทียบแต่ละรูป
        save_name = f"comparison_{fname}"
        save_path = os.path.join(out_dir, save_name)
        # แปลง RGB กลับเป็น BGR สำหรับ cv2.imwrite
        cv2.imwrite(save_path, cv2.cvtColor(strip, cv2.COLOR_RGB2BGR))
        print(f"[OK] Saved: {save_name} ({label})")
        comparison_cards.append(strip)
        
    # ต่อภาพทั้งหมดเป็นตารางสรุปใหญ่ 1 ใบ
    if comparison_cards:
        final_grid = np.vstack(comparison_cards)
        summary_path = os.path.join(out_dir, "ALL_BODY_PARTS_COMPARISON.jpg")
        cv2.imwrite(summary_path, cv2.cvtColor(final_grid, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 95])
        print(f"\n[DONE] Saved summary grid to:\n   {summary_path}")

if __name__ == '__main__':
    main()
