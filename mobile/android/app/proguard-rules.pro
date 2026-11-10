# Habitly release R8 rules.
# Flutter 3.47 enables minify + shrink on release by default. The 1.0.0+2
# crash was Room InstantiationException: R8 kept WorkDatabase_Impl but
# stripped its no-arg constructor, so Room.getGeneratedImplementation()
# failed with "Failed to create an instance of androidx.work.impl.WorkDatabase"
# during WorkManagerInitializer / InitializationProvider.

# Room's consumer rule only keeps the class, not members/constructors.
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.room.** { *; }
-keep class **.*_Impl { *; }
-keepclassmembers class **.*_Impl { <init>(...); *; }

# WorkManager + generated Room DAOs / SQLite
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.model.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class androidx.startup.** { *; }

# AdMob / Play Services (avoid another InitializationProvider crash)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
