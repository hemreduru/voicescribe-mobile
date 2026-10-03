# The record plugin's foreground recording service is referenced from the
# manifest by name; keep it from being renamed/removed.
-keep class com.llfbandit.record.service.AudioRecordingService { *; }
