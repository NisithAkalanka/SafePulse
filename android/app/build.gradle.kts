plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // leader ගේ ප්‍රොජෙක්ට් එකට අනුව මෙය නිවැරදි දැයි බලන්න
    namespace = "com.example.safeplus"
    compileSdk = 36 // අලුත්ම plugins සඳහා මෙය 36 තිබිය යුතුයි

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Deprecation warning එක අයින් කිරීමට මෙසේ ලබා දෙන්න
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.safeplus"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
} // <--- Android block එක මෙතනින් අවසන් විය යුතුයි

// සගල වරහනෙන් පිටත මෙලෙස dependencies දාන්න
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
