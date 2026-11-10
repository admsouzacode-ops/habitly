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


# Drift / sqlite3 (JNI do sqlite3_flutter_libs)
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-dontwarn org.sqlite.**
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications serializa notificações agendadas com Gson
# (SharedPreferences) para reagendar após reboot. Sem estas regras o R8 pode
# quebrar a desserialização no ScheduledNotificationBootReceiver.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# flutter_timezone
-keep class net.wolverinebeach.flutter_timezone.** { *; }
