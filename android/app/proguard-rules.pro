# TensorFlow Lite may reference optional GPU delegate options that are not
# packaged for all targets. Ignore this optional type during R8 shrink.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep native (JNI) method bindings used by whisper.cpp so R8 doesn't strip
# the methods the native library resolves by name at runtime.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# The record plugin's foreground recording service is referenced from the
# manifest by name; keep it from being renamed/removed.
-keep class com.llfbandit.record.service.AudioRecordingService { *; }
