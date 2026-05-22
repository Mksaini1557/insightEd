# Don't fail on warnings
-ignorewarnings

# CRITICAL: Keep the generated plugin registrant (registers all platform channels)
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class * extends io.flutter.plugin.common.PluginRegistry$Registrar { *; }
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Keep all plugin classes and their method channel handlers
-keep class com.josephcrowell.flutter_sound_record.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core (Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Sound Record
-keep class com.josephcrowell.flutter_sound_record.** { *; }
-keep class com.josephcrowell.flutter_sound_record_platform_interface.** { *; }
-dontwarn com.josephcrowell.**

# Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.**

# Audio players
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.**

# Speech to text
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Path provider
-keep class com.baseflow.permissionhandler.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
