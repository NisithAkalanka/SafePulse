plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // leader ගේ ප්‍රොජෙක්ට් එකට අනුව මෙය නිවැරදි දැයි බලන්න
    namespace = "com.example.safeplus"


    // වැදගත්ම දේ: මෙය 35 සිට 36 දක්වා මම වැඩි කළා
    compileSdk = 36
    compileSdk = 36 // අලුත්ම plugins සඳහා මෙය 36 තිබිය යුතුයි

    compileSdk = 36


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

        // targetSdk එකත් මම 36 දක්වා වැඩි කළා
        targetSdk = 36

        targetSdk = 36

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

// Kotlin 2.x: use compilerOptions instead of deprecated android.kotlinOptions.jvmTarget
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }


flutter {
    source = "../.."
}

}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}



tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

