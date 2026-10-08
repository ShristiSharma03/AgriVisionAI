# AgriVision AI 🌱

### An Intelligent Crop Disease Detection and Prediction System for Smart Agriculture

AgriVision AI is a smart agriculture mobile application that uses deep learning-based image classification to help identify crop diseases from leaf images and provide supporting agricultural information.

## 📌 Project Overview

The system combines a lightweight machine learning model with a Flutter mobile application to provide farmers with disease detection and agricultural assistance.

The final machine learning model was developed using the PlantVillage dataset and trained using MobileNetV2 transfer learning.

## 🤖 Machine Learning

- Model: MobileNetV2
- Learning approach: Transfer Learning
- Dataset: PlantVillage
- Total images: 31,397
- Classes: 25
- Crops: 5
- Input size: 224 × 224 × 3
- Test accuracy: 95.3120%
- Macro F1 Score: 0.9585
- Weighted F1 Score: 0.9527

## 🌾 Supported Crops

- Apple
- Corn
- Grape
- Potato
- Tomato

## 🔬 Model Deployment

The trained model was converted from Keras to TensorFlow Lite for mobile deployment.

- Keras model size: 21.22 MB
- TensorFlow Lite model size: 8.58 MB
- TFLite input: [1, 224, 224, 3]
- TFLite output: [1, 25]
- TFLite validation: PASS

## ✨ Application Features

- Crop disease detection
- Disease treatment and prevention guidance
- AI agricultural assistant
- Weather information
- Crop information
- Disease scan history
- Community discussions
- Likes and comments
- Nearby agricultural suppliers
- User profile
- Multilingual support
- Voice-oriented assistance

## 🛠️ Technologies Used

### Frontend
- Flutter
- Dart

### Machine Learning
- Python
- TensorFlow
- MobileNetV2
- TensorFlow Lite

### Backend and Cloud Services
- FastAPI
- Firebase Authentication
- Firebase Firestore
- Supabase Storage

## 📂 Project Structure

```text
AgriVisionAI/
├── ai_model/
├── assets/
├── backend/
├── datasets/
├── docs/
├── documents/
├── frontend/
└── README.md