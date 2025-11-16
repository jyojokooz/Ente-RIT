# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Google Sign In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.android.gms.**

# Keep SLF4J classes that are found by reflection
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**