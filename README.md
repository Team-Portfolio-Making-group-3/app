# 🌐 GuideWay: Smart Stick with Real-Time Alerts (YOLOv11n-Powered)

---

## 🧩 Problem

Traditional walking sticks are static tools that do not detect hazards in real time. Visually impaired individuals face daily risks from:

* 🧱 Obstacles (walls, poles, potholes)
* 🚗 Incoming vehicles and moving objects
* 🗺️ Poor route awareness and lack of caregiver visibility

These hazards limit their independence and safety during navigation.

---

## 💡 Solution — GuideWay

GuideWay is an AI-powered smart stick system that uses a **camera + YOLOv11n model** to detect hazards in real time and provide immediate **audio and vibration feedback** to the user.

The system integrates with a **Flutter mobile app** and **Firebase backend** for:

* Route tracking
* Community hazard reporting
* Caregiver monitoring

---

## ⚙️ Core Features

### 🧠 1. Real-Time Object Detection

* Detects obstacles, potholes, vehicles, and pedestrians.
* Uses a mounted mobile phone or small camera on the walking stick.
* On-device inference using YOLOv11n → TensorFlow Lite (INT8) for low-latency performance.

**Supported Classes:**
`obstacle`, `pothole`, `vehicle`, `pedestrian`, `stairs`, `curb`

### 🔊 2. Real-Time Alerts

* **Voice Feedback:** “Obstacle ahead, 2 meters.” (Text-to-speech)
* **Vibration Feedback:**

    * Short double buzz = obstacle
    * Long pulses = vehicle
    * Triple short buzz = pothole/stairs

### 🗺️ 3. Route & Hazard Logging

* Records walking routes via GPS.
* Logs detected hazards with timestamp, type, and approximate distance.
* Uploads anonymized hazard data to Firebase Firestore.

### 👨‍👩‍👧 4. Caregiver Integration

* View frequent hazard zones.
* Receive emergency alerts via Firebase Cloud Messaging (FCM).

---

## 🧠 Technology Stack

| Layer            | Technology                    | Description                          |
| ---------------- | ----------------------------- | ------------------------------------ |
| Model            | YOLOv11n                      | Lightweight object detection model   |
| Training         | Ultralytics (PyTorch)         | Train YOLOv11n using labeled dataset |
| Model Conversion | TensorFlow Lite               | Convert YOLOv11n to `.tflite` (INT8) |
| Frontend App     | Flutter                       | Camera, vibration, TTS integration   |
| Backend          | Firebase                      | Cloud database, auth, FCM, hosting   |
| Maps & Location  | Google Maps + GPS             | Navigation & route tracking          |
| Cloud Analytics  | Firebase Functions + BigQuery | Aggregate hazard & route data        |

---

## 🧰 YOLOv11n Model Implementation

### 📸 Dataset

* Custom dataset of real walking environments.
* 6–8 classes: obstacle, pothole, vehicle, pedestrian, stairs, curb.
* Augmented for varying lighting and weather conditions.
* Annotated in YOLO format (Roboflow / LabelImg).

### 🏋️ Training (Colab / Local)

```python
!pip install ultralytics

from ultralytics import YOLO

model = YOLO("yolov11n.pt")

model.train(
    data="guideway_data.yaml",
    epochs=150,
    imgsz=640,
    batch=16,
    name="guideway_yolov11n"
)
```

### 🔄 Export to TensorFlow Lite

```python
# Float32 export
model.export(format="tflite")

# INT8 quantized export
model.export(format="tflite", int8=True, representative_data="rep_dataset/")
```

### ⚡ On-Device Inference (Flutter + TFLite)

```dart
final interpreter = await Interpreter.fromAsset('guideway_yolov11n.tflite');
final input = preprocessCameraFrame(image);
final output = List.filled(outputSize, 0.0).reshape([1, outputSize]);
interpreter.run(input, output);
final detections = postProcess(output);
handleDetections(detections);
```

---

## 🔐 Firebase Integration

**Collections:**

* `/users` — user profiles, linked caregiver IDs
* `/hazards` — {type, lat, lon, timestamp, severity}
* `/routes` — route logs, polylines, timestamps
* `/emergencies` — SOS events

**Realtime Database:**

* Live GPS coordinates

**Cloud Functions:**

* Aggregate hazard data hourly
* Send FCM alerts to caregivers

---

## 🚨 Emergency Mode

* Shake stick or tap SOS button triggers immediate location sharing.
* Sends emergency alert to caregiver device.
* Optional call trigger (Twilio / phone intent).

---

## 📊 Dashboard Analytics Examples

| Metric                | Description                      | Visualization |
| --------------------- | -------------------------------- | ------------- |
| Hazard Frequency      | Number of hazards per day        | Bar chart     |
| Hotspots              | Common hazard locations          | Map heatmap   |
| Average Safe Distance | Avg distance before hazard alert | Line chart    |
| SOS Events            | Number of emergencies            | Pie chart     |
| User Routes           | Daily walking routes             | Map overlays  |

---

## 🧩 Extensions

* GPS-based safe route navigation
* Community hazard map (“Safe Paths” & “Danger Zones”)
* Voice assistant mode (“Describe ahead” commands)
* Offline mode with cached model & maps
* Edge TPU support for Raspberry Pi smart sticks

---

## ⚡ Performance Optimizations

* Skip frames for 10–15 FPS on low-end phones
* Crop camera feed to walking-level region
* Float16 quantization if INT8 fails
* Haptic + TTS feedback prioritization: vehicles > obstacles

---

## 🧭 Project Roadmap

| Phase   | Focus                      | Deliverable                  |
| ------- | -------------------------- | ---------------------------- |
| Phase 1 | Data Collection & Labeling | Dataset + annotations        |
| Phase 2 | Model Training & Export    | YOLOv11n + TFLite            |
| Phase 3 | Flutter App Integration    | Real-time detection + alerts |
| Phase 4 | Firebase Backend           | Logging + caregiver tracking |
| Phase 5 | Dashboard & Analytics      | Map heatmaps + insights      |
| Phase 6 | Field Testing              | Accuracy & latency tuning    |
| Phase 7 | Scale & Community Launch   | Deploy & crowdsource hazards |

---



## 💬 Example User Scenario

Maria, a visually impaired user, attaches her phone to the GuideWay stick and begins her morning walk:

* Detects a pothole 2 meters ahead → vibrates quickly
* Car approaches from left → “Vehicle incoming, step aside”
* Caregiver reviews route later → sees recurring hazard

---

## 🧠 Outcome & Impact

* Improves mobility independence for visually impaired users
* Builds crowdsourced safety map
* Empowers caregivers with insights for better route planning
* Demonstrates ethical AI through inclusive design and real-time assistance

---
