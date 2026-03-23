plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // leader ගේ project එකේ namespace එක හරියටම චෙක් කරන්න (සාමාන්‍යයෙන් මෙය වේ)
    namespace = "com.example.safeplus"

    // වැදගත්ම දේ: මෙය 35 සිට 36 දක්වා මම වැඩි කළා
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.safeplus"
        minSdk = flutter.minSdkVersion
        // targetSdk එකත් මම 36 දක්වා වැඩි කළා
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
