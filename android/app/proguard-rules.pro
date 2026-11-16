# ProGuard / R8 configuration rules for ONNX Runtime
# Prevents obfuscation/stripping of native JNI bindings used by flutter_onnxruntime.
-keep class ai.onnxruntime.** { *; }
