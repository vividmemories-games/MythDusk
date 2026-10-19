# Firebase / Play Services — release R8 was stripping Crashlytics component
# registration ("FirebaseCrashlytics component is not present").
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.** { *; }

# Component discovery registrars used by Firebase.init
-keep class com.google.firebase.**Registrar { *; }
-keep class com.google.firebase.components.** { *; }
-keepclassmembers class * {
  @com.google.firebase.components.ComponentRegistrar *;
}

-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.**
