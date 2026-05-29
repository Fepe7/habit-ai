# Reglas ProGuard/R8 para release de HabitAI

# Flutter — el motor usa JNI, no tocar
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase / Google Play services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Play Core (deferred components / split install que Flutter referencia)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Modelos serializados con Gson/JSON via reflexión — conservar nombres de campos
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# No quitar trazas de línea para que Crashlytics deobfusque bien
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
