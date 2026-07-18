# ProGuard / R8 keep rules for the M4 Family release build.
# Conservative on purpose: the plugins below use reflection / JNI, so we keep
# their packages wholesale rather than risk a runtime ClassNotFound in release.

# ---- Flutter engine & embedding ----
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Keep annotations, signatures, native methods, enums, Parcelables ----
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ---- webview_flutter ----
-keep class io.flutter.plugins.webviewflutter.** { *; }

# ---- video_player / ExoPlayer (via chewie) ----
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ---- image_picker / file_picker ----
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ---- flutter_secure_storage (androidx.security crypto / Tink) ----
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ---- OkHttp / okio (used transitively by several plugins) ----
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**

# ---- Play Core (referenced by Flutter's deferred-components stubs) ----
-dontwarn com.google.android.play.core.**

# ---- Keep any JSON model that relies on reflection (json_serializable output
#      is pure Dart, so this is only a safety net for Java/Kotlin side) ----
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keep @androidx.annotation.Keep class * { *; }
