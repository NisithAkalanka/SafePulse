plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.safeplus"
<<<<<<< Updated upstream
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
=======

    compileSdk = 36
>>>>>>> Stashed changes

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

<<<<<<< Updated upstream
    defaultConfig {
        applicationId = "com.example.safeplus"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
=======
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.safeplus"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
>>>>>>> Stashed changes
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

<<<<<<< Updated upstream
=======
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

>>>>>>> Stashed changes
flutter {
    source = "../.."
}

<<<<<<< Updated upstream
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
// Kotlin 2.x: use compilerOptions instead of deprecated android.kotlinOptions.jvmTarget
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
=======

>>>>>>> Stashed changes
