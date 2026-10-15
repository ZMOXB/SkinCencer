import os
import sys
import json
import numpy as np

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')
import matplotlib.pyplot as plt
import seaborn as sns

import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from sklearn.utils.class_weight import compute_class_weight
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc

# ---------------------------------------------------------------------------
# 1. การตั้งค่าระบบ (Configuration)
# ---------------------------------------------------------------------------
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(CURRENT_DIR, "dataset_screening")

TRAIN_DIR = os.path.join(DATA_DIR, "train")
VAL_DIR = os.path.join(DATA_DIR, "val")
TEST_DIR = os.path.join(DATA_DIR, "test")

MODEL_SAVE_PATH = os.path.join(CURRENT_DIR, "screening_modelv2.keras")
TFLITE_SAVE_PATH = os.path.join(CURRENT_DIR, "screening_modelv2.tflite")
CONFIG_SAVE_PATH = os.path.join(CURRENT_DIR, "screening_configv2.json")

IMG_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 25
LEARNING_RATE = 1e-4

def check_environment():
    print("=" * 65)
    print("ตรวจสอบสภาพแวดล้อมการเทรน (System Information)")
    print("=" * 65)
    print(f"TensorFlow Version: {tf.__version__}")
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        print(f"✓ ตรวจพบ GPU: {gpus}")
    else:
        print("รันบน CPU (EfficientNet-B0 ถูกปรับแต่งให้ประมวลผลเร็วบน CPU)")
    print("-" * 65)

def build_model(input_shape=(224, 224, 3)):
    """
    สร้างโมเดล EfficientNet-B0 สำหรับ Binary Classification
    """
    base_model = EfficientNetB0(
        weights="imagenet",
        include_top=False,
        input_shape=input_shape
    )
    # Freeze โครงข่ายหลักเพื่อความเร็วและความเสถียร
    base_model.trainable = False

    inputs = layers.Input(shape=input_shape)
    x = base_model(inputs, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    # Output: Sigmoid สำหรับ 0 (Normal) หรือ 1 (Disease)
    outputs = layers.Dense(1, activation="sigmoid")(x)

    model = models.Model(inputs, outputs, name="Screening_EfficientNetB0")
    return model

def main():
    check_environment()

    if not os.path.exists(TRAIN_DIR):
        print("ไม่พบข้อมูลใน dataset_screening/")
        print("กรุณารัน 'python screening_experiment/prepare_screening_data.py' ก่อนเป็นอันดับแรก!")
        return

    # -----------------------------------------------------------------------
    # 2. Data Generators & Augmentation
    # -----------------------------------------------------------------------
    print("\nกำลังโหลดชุดข้อมูล...")
    train_datagen = ImageDataGenerator(
        preprocessing_function=preprocess_input,
        rotation_range=20,
        zoom_range=0.15,
        horizontal_flip=True,
        vertical_flip=True,
        fill_mode="nearest"
    )

    val_datagen = ImageDataGenerator(preprocessing_function=preprocess_input)
    test_datagen = ImageDataGenerator(preprocessing_function=preprocess_input)

    train_gen = train_datagen.flow_from_directory(
        TRAIN_DIR,
        classes=["Normal", "Disease"],
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode="binary"
    )

    val_gen = val_datagen.flow_from_directory(
        VAL_DIR,
        classes=["Normal", "Disease"],
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode="binary"
    )

    test_gen = test_datagen.flow_from_directory(
        TEST_DIR,
        classes=["Normal", "Disease"],
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode="binary",
        shuffle=False
    )

    class_indices = train_gen.class_indices
    print(f"✓ ผังคลาส (Class Indices): {class_indices}")

    # -----------------------------------------------------------------------
    # 3. คำนวณ Class Weights (ปรับสมดุล 60:40)
    # -----------------------------------------------------------------------
    train_labels = train_gen.classes
    classes_unique = np.unique(train_labels)
    class_weights_arr = compute_class_weight(
        class_weight="balanced",
        classes=classes_unique,
        y=train_labels
    )
    class_weights_dict = {i: float(w) for i, w in zip(classes_unique, class_weights_arr)}
    print(f"Class Weights ถ่วงน้ำหนัก: {class_weights_dict}")

    # -----------------------------------------------------------------------
    # 4. ประกอบโมเดลและคอมไพล์
    # -----------------------------------------------------------------------
    print("\nกำลังประกอบโมเดล EfficientNet-B0...")
    model = build_model(input_shape=(IMG_SIZE, IMG_SIZE, 3))

    model.compile(
        optimizer=Adam(learning_rate=LEARNING_RATE),
        loss="binary_crossentropy",
        metrics=[
            "accuracy",
            tf.keras.metrics.Precision(name="precision"),
            tf.keras.metrics.Recall(name="recall"),
            tf.keras.metrics.AUC(name="auc")
        ]
    )
    model.summary()

    # -----------------------------------------------------------------------
    # 5. Callbacks
    # -----------------------------------------------------------------------
    callbacks = [
        ModelCheckpoint(
            filepath=MODEL_SAVE_PATH,
            monitor="val_auc",
            mode="max",
            save_best_only=True,
            verbose=1
        ),
        EarlyStopping(
            monitor="val_auc",
            mode="max",
            patience=5,
            restore_best_weights=True,
            verbose=1
        ),
        ReduceLROnPlateau(
            monitor="val_auc",
            mode="max",
            factor=0.5,
            patience=2,
            min_lr=1e-6,
            verbose=1
        )
    ]

    # -----------------------------------------------------------------------
    # 6. เริ่มการฝึกสอนโมเดล (Training)
    # -----------------------------------------------------------------------
    print("\n" + "=" * 65)
    print("เริ่มกระบวนการเทรนโมเดล (Training in Progress)")
    print("=" * 65)
    history = model.fit(
        train_gen,
        epochs=EPOCHS,
        validation_data=val_gen,
        class_weight=class_weights_dict,
        callbacks=callbacks
    )

    # -----------------------------------------------------------------------
    # 7. ประเมินผลข้อสอบจริง (Evaluation on Test Set)
    # -----------------------------------------------------------------------
    print("\n" + "=" * 65)
    print("ประเมินผลลัพธ์บนข้อสอบจริง (Evaluating Test Set)")
    print("=" * 65)

    test_gen.reset()
    test_preds_prob = model.predict(test_gen, verbose=1).ravel()
    test_true = test_gen.classes

    # คำนวณ ROC Curve & หาจุด Safety Threshold
    fpr, tpr, thresholds = roc_curve(test_true, test_preds_prob)
    roc_auc = auc(fpr, tpr)
    print(f"ผลลัพธ์ Area Under Curve (ROC-AUC): {roc_auc:.4f}")

    # คำนวณเกณฑ์ความปลอดภัยทางการแพทย์ (Safety Threshold):
    # เลื่อนจุดตัดลงมาเพื่อให้ Recall ฝั่งโรคสูงที่สุด (Sensitivity > 97%)
    disease_class_idx = class_indices.get("Disease", 1)
    high_recall_idx = np.where(tpr >= 0.97)[0]
    if len(high_recall_idx) > 0:
        suggested_threshold = float(thresholds[high_recall_idx[0]])
    else:
        suggested_threshold = 0.35

    # จำกัดให้อยู่ระหว่าง 0.20 - 0.45 เพื่อความเสถียร
    suggested_threshold = round(max(0.20, min(0.45, suggested_threshold)), 3)
    print(f"★ เกณฑ์ตัดสินใจความปลอดภัยที่แนะนำ (Safety Threshold): {suggested_threshold} (ค่าปกติทั่วไปคือ 0.50)")

    # -----------------------------------------------------------------------
    # 8. บันทึกกราฟผลการทดสอบ (Plots)
    # -----------------------------------------------------------------------
    # 8.1 กราฟ Loss & Accuracy
    plt.figure(figsize=(14, 5))
    plt.subplot(1, 2, 1)
    plt.plot(history.history['loss'], label='Train Loss', color='blue')
    plt.plot(history.history['val_loss'], label='Val Loss', color='orange')
    plt.title('Loss Curve')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.subplot(1, 2, 2)
    plt.plot(history.history['accuracy'], label='Train Acc', color='blue')
    plt.plot(history.history['val_accuracy'], label='Val Acc', color='orange')
    plt.title('Accuracy Curve')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(CURRENT_DIR, "screening_loss_acc.png"), dpi=200)
    plt.close()

    # 8.2 Confusion Matrix (แบบปกติ 0.50 vs แบบ Safety Threshold)
    preds_standard = (test_preds_prob >= 0.50).astype(int)
    preds_safety = (test_preds_prob >= suggested_threshold).astype(int)

    cm_standard = confusion_matrix(test_true, preds_standard)
    cm_safety = confusion_matrix(test_true, preds_safety)
    target_names = ["Normal", "Disease"]

    plt.figure(figsize=(12, 5))
    plt.subplot(1, 2, 1)
    sns.heatmap(cm_standard, annot=True, fmt='d', cmap='Blues', xticklabels=target_names, yticklabels=target_names)
    plt.title(f'Standard Confusion Matrix (Cutoff=0.50)')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')

    plt.subplot(1, 2, 2)
    sns.heatmap(cm_safety, annot=True, fmt='d', cmap='Greens', xticklabels=target_names, yticklabels=target_names)
    plt.title(f'Medical Safety Matrix (Cutoff={suggested_threshold})')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.tight_layout()
    plt.savefig(os.path.join(CURRENT_DIR, "screening_confusion_matrix.png"), dpi=200)
    plt.close()

    # -----------------------------------------------------------------------
    # 9. แปลงโมเดลเป็น TFLite เพื่อความเร็วและใช้ในอนาคต
    # -----------------------------------------------------------------------
    print("\nกำลังแปลงโมเดลเป็น TFLite...")
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        with open(TFLITE_SAVE_PATH, "wb") as f:
            f.write(tflite_model)
        print(f"บันทึกโมเดล TFLite เรียบร้อย: {TFLITE_SAVE_PATH}")
    except Exception as e:
        print(f"แปลง TFLite ข้ามไปก่อน: {e}")

    # -----------------------------------------------------------------------
    # 10. บันทึกค่า Config เพื่อให้โค้ดอื่นเรียกใช้ได้ทันที
    # -----------------------------------------------------------------------
    config = {
        "model_architecture": "EfficientNet-B0",
        "input_shape": [IMG_SIZE, IMG_SIZE, 3],
        "class_indices": class_indices,
        "standard_threshold": 0.50,
        "suggested_safety_threshold": suggested_threshold,
        "test_auc": float(roc_auc)
    }
    with open(CONFIG_SAVE_PATH, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=4, ensure_ascii=False)

    print("\n" + "=" * 65)
    print("ฝึกสอนโมเดลคัดกรองสำเร็จเรียบร้อยแล้ว!")
    print(f"ไฟล์โมเดล: {MODEL_SAVE_PATH}")
    print(f"กราฟสรุปผล: {os.path.join(CURRENT_DIR, 'screening_loss_acc.png')}")
    print(f"Confusion Matrix: {os.path.join(CURRENT_DIR, 'screening_confusion_matrix.png')}")
    print("=" * 65)

if __name__ == "__main__":
    main()
