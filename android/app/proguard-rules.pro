# Keep Google Sign-In classes
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.auth.** { *; }

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep annotations
-keepattributes *Annotation*

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}