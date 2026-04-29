# TensorFlow Lite may reference optional GPU delegate options that are not
# packaged for all targets. Ignore this optional type during R8 shrink.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
