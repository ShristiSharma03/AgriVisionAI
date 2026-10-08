# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }

# TensorFlow Lite GPU
-keep class org.tensorflow.lite.gpu.** { *; }

# Prevent warnings for TensorFlow Lite GPU classes
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options