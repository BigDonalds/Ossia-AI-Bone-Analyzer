# ONNX Runtime reaches its Java classes through JNI, so R8 must not strip or
# rename them (flutter_onnxruntime, the on-device model).
-keep class ai.onnxruntime.** { *; }
