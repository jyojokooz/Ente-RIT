# ── Firebase Auth ──────────────────────────────────────────
-keep class com.google.firebase.auth.** { *; }

# ── Google Sign In ─────────────────────────────────────────
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.android.gms.**

# ── SLF4J ──────────────────────────────────────────────────
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**

# ── OkHttp / uCrop ─────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Firebase Core ──────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
-keepnames class com.google.firebase.** { *; }

# ── Google Play Services ───────────────────────────────────
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.android.gms.** { *; }

# ── Firestore ──────────────────────────────────────────────
-keep class com.google.firebase.firestore.** { *; }

# ── Firebase Messaging ─────────────────────────────────────
-keep class com.google.firebase.messaging.** { *; }

# ── Firebase Storage ───────────────────────────────────────
-keep class com.google.firebase.storage.** { *; }

# ── Flutter Firebase Plugins ───────────────────────────────
-keep class io.flutter.plugins.firebase.** { *; }

# ── Flutter core ───────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ── Keep all plugin registrants ────────────────────────────
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# ── Kotlin ─────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# ── Keep enums ─────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Keep Parcelables ───────────────────────────────────────
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ── Keep Serializable ──────────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}