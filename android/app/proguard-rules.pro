-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Play Core classes
-keep class com.google.android.play.** { *; }
-keepclassmembers class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Keep Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep R8-required classes for deferred components
-keep class com.google.android.play.core.tasks.** { *; }
-keepclassmembers class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.tasks.**