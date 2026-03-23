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
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.safeplus"
        minSdk = flutter.minSdkVersion
<<<<<<< Updated upstream
        targetSdk = flutter.targetSdkVersion
=======
        targetSdk = 36
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

dependencies {
    // Required for flutter_local_notifications (desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
<<<<<<< Updated upstream

flutter {
    source = "../.."
<<<<<<< Updated upstream
}
=======
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
>>>>>>> Stashed changes
