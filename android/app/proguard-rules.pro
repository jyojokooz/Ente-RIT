# Fix for SLF4J missing class during R8 minify
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**

# Optional: Prevent R8 from removing logging classes
-keep class * extends org.slf4j.Logger { *; }
