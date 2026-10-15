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

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, ".."))

SCREENING_MODEL_PATH = os.path.join(CURRENT_DIR, "screening_model.keras")
SCREENING_CONFIG_PATH = os.path.join(CURRENT_DIR, "screening_config.json")
STAGE2_MODEL_PATH = os.path.join(PROJECT_ROOT, "Model3.keras")
STAGE2_INDICES_PATH = os.path.join(PROJECT_ROOT, "class_indices.json")

print("⏳ 1. กำลังโหลดโมเดลคัดกรอง (Stage 1: Screening Model - EfficientNet-B0)...")
screening_model = tf.keras.models.load_model(SCREENING_MODEL_PATH)

threshold = 0.45
if os.path.exists(SCREENING_CONFIG_PATH):
    with open(SCREENING_CONFIG_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)
        threshold = cfg.get("suggested_safety_threshold", 0.45)
print(f"✓ โหลด Stage 1 สำเร็จ! [เกณฑ์ความปลอดภัย Threshold = {threshold}]")

print("⏳ 2. กำลังโหลดโมเดลวินิจฉัย 8 โรค (Stage 2: Model3.keras - ResNet50+Attention)...")
stage2_model = tf.keras.models.load_model(STAGE2_MODEL_PATH, compile=False)

with open(STAGE2_INDICES_PATH, "r", encoding="utf-8") as f:
    indices = json.load(f)
index_to_class = {int(v): k for k, v in indices.items()}

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
print("✓ โหลด Stage 2 (Model3.keras) และชื่อ 8 โรคสำเร็จแล้วพร้อมทดสอบ!")

def predict_two_stage(img, custom_threshold, force_stage2):
    if img is None:
        return "กรุณาอัปโหลดรูปภาพ", {}, ""
    
    img_rgb = img.convert("RGB")
    img_resized = img_rgb.resize((224, 224))
    img_arr = np.array(img_resized, dtype=np.float32)
    img_batch = np.expand_dims(img_arr, axis=0)
    
    # ---------------------------------------------------------
    # ด่านที่ 1: Screening Model (EfficientNet-B0)
    # ---------------------------------------------------------
    screen_prep = eff_preprocess(img_batch.copy())
    prob_disease = float(screening_model.predict(screen_prep, verbose=0)[0][0])
    prob_normal = 1.0 - prob_disease
    cutoff = custom_threshold if custom_threshold is not None else threshold
    
    is_abnormal = prob_disease >= cutoff or force_stage2
    
    # ด่าน 1: สร้างการ์ดผลลัพธ์
    if prob_disease < cutoff:
        stage1_html = f"""
        <div style="background-color: #e8f5e9; border: 2px solid #4caf50; border-radius: 12px; padding: 15px; margin-bottom: 12px;">
            <h3 style="color: #2e7d32; margin: 0 0 6px 0;">🛡️ ด่านที่ 1: ผิวปกติ (Normal / Benign)</h3>
            <p style="margin: 0; font-size: 15px; color: #1b5e20;">
                • มั่นใจว่าเป็นผิวปกติ/สิว/แผลเป็น: <b>{prob_normal * 100:.2f}%</b><br>
                • ความน่าสงสัยว่ามีรอยโรค: <b>{prob_disease * 100:.2f}%</b> (ต่ำกว่าเกณฑ์ตัด {cutoff * 100:.0f}%)
            </p>
        </div>
        """
    else:
        stage1_html = f"""
        <div style="background-color: #fff3e0; border: 2px solid #ff9800; border-radius: 12px; padding: 15px; margin-bottom: 12px;">
            <h3 style="color: #e65100; margin: 0 0 6px 0;">⚠️ ด่านที่ 1: ตรวจพบรอยโรคผิดปกติ (Abnormal / Lesion Detected)</h3>
            <p style="margin: 0; font-size: 15px; color: #bf360c;">
                • ความน่าสงสัยว่ามีรอยโรค: <b>{prob_disease * 100:.2f}%</b> (เกินเกณฑ์ตัด {cutoff * 100:.0f}%)<br>
                • <b>ระบบกำลังส่งภาพไปยังด่านที่ 2 (Model3.keras) เพื่อจำแนกชื่อโรค...</b>
            </p>
        </div>
        """

    # ---------------------------------------------------------
    # ด่านที่ 2: วินิจฉัย 8 โรคด้วย Model3.keras
    # ---------------------------------------------------------
    if is_abnormal:
        stage2_prep = resnet_preprocess(img_batch.copy())
        stage2_preds = stage2_model.predict(stage2_prep, verbose=0)[0]
        
        top_idx = int(np.argmax(stage2_preds))
        top_name = index_to_class[top_idx]
        top_thai = disease_thai.get(top_name, top_name)
        top_conf = float(stage2_preds[top_idx])
        
        disease_scores = {}
        for i, score in enumerate(stage2_preds):
            d_name = index_to_class[i]
            label_text = f"{disease_thai.get(d_name, d_name)}"
            disease_scores[label_text] = float(score)
            
        badge_title = "🩺 ผลวินิจฉัยละเอียด 8 โรค (Stage 2 - Model3.keras)"
        if force_stage2 and prob_disease < cutoff:
            badge_title += " [โหมดบังคับตรวจ]"
            
        stage2_html = f"""
        <div style="background-color: #ffebee; border: 2px solid #e53935; border-radius: 12px; padding: 18px; margin-top: 10px;">
            <h3 style="color: #c62828; margin: 0 0 10px 0;">{badge_title}</h3>
            <div style="font-size: 22px; font-weight: bold; color: #b71c1c;">
                👉 {top_thai}
            </div>
            <div style="font-size: 18px; color: #333; margin-top: 6px;">
                ระดับความมั่นใจสูงสุด: <b style="color: #c62828;">{top_conf * 100:.2f}%</b>
            </div>
        </div>
        """
        return stage1_html, stage2_html, disease_scores
    else:
        # กรณีผิวปกติ และไม่ได้ติ๊กบังคับตรวจ
        stage2_html = """
        <div style="background-color: #f5f5f5; border: 2px dashed #9e9e9e; border-radius: 12px; padding: 18px; margin-top: 10px; text-align: center;">
            <h3 style="color: #616161; margin: 0 0 6px 0;">🛑 สิ้นสุดการทำงานที่ด่านที่ 1 (ไม่ต้องตรวจ 8 โรค)</h3>
            <p style="color: #757575; font-size: 15px; margin: 0;">
                เนื่องจากภาพนี้ผ่านการคัดกรองว่าเป็น <b>ผิวปกติ / สิวหรือรอยทั่วไป</b><br>
                ระบบจึงไม่ส่งต่อให้โมเดล 8 โรค เพื่อป้องกันปัญหาการเดาสุ่มมั่วว่าเป็นมะเร็งผิวหนัง
            </p>
            <p style="color: #9e9e9e; font-size: 12px; margin-top: 8px;">
                (หากต้องการลองดูว่าโมเดล 8 โรคจะทายว่าอะไร ให้ติ๊กถูกที่ช่อง <i>'บังคับตรวจด่านที่ 2 เสมอ'</i> ด้านซ้าย)
            </p>
        </div>
        """
        binary_scores = {
            "ผิวปกติ / สิว / แผลเป็น (Normal)": prob_normal,
            "ความน่าสงสัยว่ามีรอยโรค (Disease)": prob_disease
        }
        return stage1_html, stage2_html, binary_scores

# ตัวอย่างภาพทดสอบ
examples = []
test_norm = os.path.join(CURRENT_DIR, "dataset_screening", "test", "Normal")
test_dis = os.path.join(CURRENT_DIR, "dataset_screening", "test", "Disease")

if os.path.exists(test_norm):
    for f in os.listdir(test_norm)[:3]:
        examples.append([os.path.join(test_norm, f), 0.45, False])
if os.path.exists(test_dis):
    for f in os.listdir(test_dis)[:3]:
        examples.append([os.path.join(test_dis, f), 0.45, False])

with gr.Blocks(title="Two-Stage Skin AI", theme=gr.themes.Soft()) as demo:
    gr.Markdown("""
    # 🔬 ระบบทดสอบจำแนกผิวหนัง 2 ด่าน (Two-Stage Skin Classification)
    ### 🛡️ **ด่าน 1:** คัดกรองผิวปกติ/สิว/แผลเป็น $\\rightarrow$ 🩺 **ด่าน 2:** วินิจฉัยละเอียด 8 โรค (`Model3.keras`)
    """)
    
    with gr.Row():
        with gr.Column(scale=1):
            input_img = gr.Image(type="pil", label="อัปโหลดภาพผิวหนังที่ต้องการทดสอบ")
            
            with gr.Row():
                thresh_slider = gr.Slider(
                    minimum=0.10, maximum=0.90, value=threshold, step=0.05,
                    label="เกณฑ์ตัดสินใจด่านที่ 1 (Threshold)",
                    info="ค่าแนะนำ 0.45 (สงสัยเกิน 45% ส่งต่อ 8 โรค)"
                )
            force_stage2_chk = gr.Checkbox(
                value=False,
                label="⚡ บังคับส่งไปตรวจโมเดล 8 โรคเสมอ (Force Stage 2)",
                info="ติ๊กช่องนี้เพื่อดูว่าแม้จะเป็นสิวหรือผิวปกติ โมเดล 8 โรคจะทายว่าอะไร"
            )
            btn_predict = gr.Button("🔍 เริ่มต้นการตรวจวิเคราะห์", variant="primary", size="lg")
            
            if examples:
                gr.Examples(
                    examples=examples,
                    inputs=[input_img, thresh_slider, force_stage2_chk],
                    label="📌 ตัวอย่างภาพทดสอบ (คลิกเพื่อเลือกภาพ)"
                )
                
        with gr.Column(scale=1):
            out_stage1 = gr.HTML(label="ผลลัพธ์ด่านที่ 1 (Screening)")
            out_stage2 = gr.HTML(label="ผลลัพธ์ด่านที่ 2 (8 โรคผิวหนัง)")
            out_probs = gr.Label(num_top_classes=8, label="สัดส่วนความน่าจะเป็น (Probability)")

    btn_predict.click(
        fn=predict_two_stage,
        inputs=[input_img, thresh_slider, force_stage2_chk],
        outputs=[out_stage1, out_stage2, out_probs]
    )

if __name__ == "__main__":
    demo.launch(server_name="127.0.0.1", server_port=7866, inbrowser=True)
