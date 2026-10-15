"""
=============================================================================
 เว็บแอป Gradio แบบง่าย สำหรับทดสอบระบบคัดกรอง 2 ด่าน (Two-Stage Screening UI)
 ด่านที่ 1: ตรวจว่า "ผิวปกติ" หรือ "มีรอยโรค" (EfficientNet-B0)
 ด่านที่ 2: ถ้ามีรอยโรค -> วินิจฉัยต่อว่า "เป็นโรคอะไรใน 8 โรค" (Model3.keras เดิม)
 
 ** ไฟล์นี้เป็นตัวทดสอบแยกใน screening_experiment/ ไม่กระทบ app.py เดิม **
=============================================================================
"""

import os
import sys
import json
import numpy as np
from PIL import Image
import gradio as gr
import tensorflow as tf

from tensorflow.keras.applications.efficientnet import preprocess_input as eff_preprocess
from tensorflow.keras.applications.resnet50 import preprocess_input as resnet_preprocess

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

# ---------------------------------------------------------------------------
# 1. กำหนด Path และโหลดโมเดล
# ---------------------------------------------------------------------------
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, ".."))

SCREENING_MODEL_PATH = os.path.join(CURRENT_DIR, "screening_model.keras")
SCREENING_CONFIG_PATH = os.path.join(CURRENT_DIR, "screening_config.json")

STAGE2_MODEL_PATH = os.path.join(PROJECT_ROOT, "Model3.keras")
STAGE2_INDICES_PATH = os.path.join(PROJECT_ROOT, "class_indices.json")

print("⏳ กำลังโหลดโมเดลทั้ง 2 ด่านเข้าสู่ระบบ...")
# โหลดโมเดลด่านที่ 1
screening_model = tf.keras.models.load_model(SCREENING_MODEL_PATH)

# โหลดเกณฑ์ความปลอดภัย
threshold = 0.45
if os.path.exists(SCREENING_CONFIG_PATH):
    with open(SCREENING_CONFIG_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)
        threshold = cfg.get("suggested_safety_threshold", 0.45)

# โหลดโมเดลด่านที่ 2 (Model3.keras เดิม)
stage2_model = tf.keras.models.load_model(STAGE2_MODEL_PATH, compile=False)

# โหลดชื่อ 8 โรค
with open(STAGE2_INDICES_PATH, "r", encoding="utf-8") as f:
    indices = json.load(f)
index_to_class = {int(v): k for k, v in indices.items()}

# คำแปลชื่อโรคภาษาไทย (จาก app.py เดิม)
disease_thai = {
    "Actinic Keratosis": "ระยะก่อนมะเร็งผิวหนัง (Actinic Keratosis)",
    "BCC": "มะเร็งผิวหนังเบเซลเซลล์ (BCC)",
    "Keratosis": "โรคกระเนื้อ (Keratosis)",
    "Melanocytic Nevi": "ไฝ หรือ ปานธรรมดา (Melanocytic Nevi)",
    "Melanoma": "มะเร็งผิวหนังเมลาโนมา (Melanoma)",
    "Psoriasis": "โรคสะเก็ดเงิน (Psoriasis)",
    "SCC": "มะเร็งผิวหนังชนิดสความัสเซลล์ (SCC)",
    "Tinea": "โรคเชื้อราที่ผิวหนัง / กลาก (Tinea)"
}

print(f"✓ โหลดโมเดลพร้อมทำงาน! [Threshold = {threshold}]")

# ---------------------------------------------------------------------------
# 2. ฟังก์ชันพยากรณ์ 2 ด่าน (Two-Stage Prediction)
# ---------------------------------------------------------------------------
def predict_pipeline(input_image):
    if input_image is None:
        return "กรุณาใส่รูปภาพก่อนตรวจ", {}, "กรุณาใส่รูปภาพ", None, "⚠️ กรุณาอัปโหลดรูปภาพ"

    # ตรวจสอบขนาดต้นฉบับ
    orig_w, orig_h = input_image.size

    # ปรับขนาดภาพตามขอบเขตโครงงาน (ไม่เกิน 224x224 พิกเซล)
    img_rgb = input_image.convert("RGB")
    img_resized = img_rgb.resize((224, 224), Image.Resampling.LANCZOS)
    img_arr = np.array(img_resized, dtype=np.float32)
    img_batch = np.expand_dims(img_arr, axis=0)

    scope_info = f"""
    📏 **การจัดการขนาดภาพตามขอบเขตโครงงาน (224x224 px):**
    • ขนาดภาพต้นฉบับที่อัปโหลด: **{orig_w:,} × {orig_h:,} พิกเซล**
    • ขนาดที่ปรับอัตโนมัติก่อนส่งเข้าโมเดล: **224 × 224 พิกเซล** *(ตรงตามขอบเขต)*
    """

    # -------------------------------------------------------------
    # ด่านที่ 1: ตรวจคัดกรอง (Screening Model)
    # -------------------------------------------------------------
    screen_prep = eff_preprocess(img_batch.copy())
    prob_disease = float(screening_model.predict(screen_prep, verbose=0)[0][0])
    prob_normal = 1.0 - prob_disease

    # -------------------------------------------------------------
    # แยกกรณี: ปกติ vs มีรอยโรค
    # -------------------------------------------------------------
    if prob_disease < threshold:
        # กรณีผิวปกติ
        stage1_html = f"""
        <div style="background-color: #e8f5e9; border: 2px solid #4caf50; border-radius: 10px; padding: 15px; margin-bottom: 15px;">
            <h3 style="color: #2e7d32; margin: 0 0 8px 0;">✅ ผลด่านที่ 1: ผิวหนังปกติ (Normal Skin)</h3>
            <p style="margin: 0; font-size: 15px; color: #1b5e20;">
                • ความมั่นใจว่าเป็นผิวปกติ: <b>{prob_normal * 100:.2f}%</b><br>
                • ความน่าสงสัยว่ามีรอยโรค: <b>{prob_disease * 100:.2f}%</b>
            </p>
        </div>
        """
        stage2_summary = "🛑 **สิ้นสุดการตรวจที่ด่านที่ 1**: ไม่พบรอยโรคผิดปกติ จึงไม่ต้องส่งต่อให้โมเดล 8 โรค (ป้องกันปัญหาการเดาสุ่มผิดพลาด)"
        stage2_probs = {"ผิวปกติ (Normal Skin)": prob_normal, "รอยโรคผิดปกติ": prob_disease}
        return stage1_html, stage2_probs, stage2_summary, img_resized, scope_info

    else:
        # กรณีตรวจพบรอยโรค -> ส่งต่อเข้าด่านที่ 2
        stage1_html = f"""
        <div style="background-color: #fff3e0; border: 2px solid #ff9800; border-radius: 10px; padding: 15px; margin-bottom: 15px;">
            <h3 style="color: #e65100; margin: 0 0 8px 0;">⚠️ ผลด่านที่ 1: ตรวจพบรอยโรค / ผื่นผิดปกติ (Disease Detected)</h3>
            <p style="margin: 0; font-size: 15px; color: #bf360c;">
                • ความน่าสงสัยว่ามีรอยโรค: <b>{prob_disease * 100:.2f}%</b> (เกินเกณฑ์ {threshold * 100:.1f}%)<br>
                • <b>ระบบกำลังส่งต่อภาพไปยัง Model3.keras เพื่อจำแนกโรคละเอียด...</b>
            </p>
        </div>
        """

        # ด่านที่ 2: วินิจฉัย 8 โรคด้วย Model3.keras เดิม
        stage2_prep = resnet_preprocess(img_batch.copy())
        stage2_preds = stage2_model.predict(stage2_prep, verbose=0)[0]

        top_idx = int(np.argmax(stage2_preds))
        top_name = index_to_class[top_idx]
        top_thai = disease_thai.get(top_name, top_name)
        top_conf = float(stage2_preds[top_idx])

        # แปลงเป็น dict สำหรับ gr.Label
        disease_scores = {}
        for i, score in enumerate(stage2_preds):
            d_name = index_to_class[i]
            label_text = f"{disease_thai.get(d_name, d_name)}"
            disease_scores[label_text] = float(score)

        stage2_summary = f"""
### 🩺 ผลวินิจฉัยละเอียด 8 โรค (จาก Model3.keras เดิม):
* **โรคที่พบมากที่สุด**: **{top_thai}**
* **ระดับความมั่นใจ**: **{top_conf * 100:.2f}%**
"""
        return stage1_html, disease_scores, stage2_summary, img_resized, scope_info

# ---------------------------------------------------------------------------
# 3. สร้างหน้ากากอินเทอร์เฟซ Gradio
# ---------------------------------------------------------------------------
# รวบรวมภาพตัวอย่างสำหรับให้ผู้ใช้คลิกทดสอบได้ทันที
examples_list = []
test_norm_dir = os.path.join(CURRENT_DIR, "dataset_screening", "test", "Normal")
test_dis_dir = os.path.join(CURRENT_DIR, "dataset_screening", "test", "Disease")

if os.path.exists(test_norm_dir):
    for f in os.listdir(test_norm_dir)[:3]:
        examples_list.append(os.path.join(test_norm_dir, f))
if os.path.exists(test_dis_dir):
    for f in os.listdir(test_dis_dir)[:3]:
        examples_list.append(os.path.join(test_dis_dir, f))

with gr.Blocks(title="Two-Stage Skin Screening Test", theme=gr.themes.Soft()) as demo:
    gr.Markdown("""
    # 🔬 ระบบทดสอบจำแนกผิวหนัง 2 ด่าน (Two-Stage Skin Screening)
    ### 🛡️ ด่านที่ 1: คัดกรองผิวปกติ vs รอยโรค $\\rightarrow$ 🩺 ด่านที่ 2: จำแนกละเอียด 8 โรค (Model3.keras เดิม)
    *(ระบบรองรับและปรับขนาดภาพอัตโนมัติตามขอบเขตโครงงาน: **224 × 224 พิกเซล**)*
    """)

    with gr.Row():
        # ฝั่งซ้าย: อัปโหลดภาพ
        with gr.Column(scale=1):
            input_img = gr.Image(type="pil", label="อัปโหลดภาพผิวหนัง (ขนาดใดก็ได้จากกล้อง/มือถือ)")
            btn_predict = gr.Button("🔍 เริ่มต้นการตรวจวิเคราะห์", variant="primary", size="lg")
            
            # กล่องแสดงผลขนาดภาพตามขอบเขต
            scope_box = gr.Markdown()
            processed_img_preview = gr.Image(type="pil", label="ภาพที่ย่อเหลือ 224x224 px ตามขอบเขตก่อนเข้าโมเดล", height=200)

            if examples_list:
                gr.Examples(
                    examples=examples_list,
                    inputs=input_img,
                    label="📌 ตัวอย่างภาพทดสอบ (คลิกเพื่อเลือกตรวจได้ทันที)"
                )

        # ฝั่งขวา: แสดงผล 2 ด่าน
        with gr.Column(scale=1):
            out_stage1 = gr.HTML(label="ผลด่านที่ 1 (Screening)")
            out_summary = gr.Markdown()
            out_probs = gr.Label(num_top_classes=5, label="สัดส่วนความน่าจะเป็น (Probability)")

    btn_predict.click(
        fn=predict_pipeline,
        inputs=input_img,
        outputs=[out_stage1, out_probs, out_summary, processed_img_preview, scope_box]
    )

if __name__ == "__main__":
    # รันบน Local Port 7865 เพื่อไม่ให้ชนกับพอร์ต 7860 ของแอปเดิม
    demo.launch(server_name="127.0.0.1", server_port=7865, inbrowser=True)
