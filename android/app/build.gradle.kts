plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yoobbel.app"
    compileSdk = 36 // Updated to API 36
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ ADD THIS EXACT LINE
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Your unique Application ID for Firebase Console
        applicationId = "com.yoobbel.app"
        
        // Updated SDK levels for production stability and modern standards
        minSdk = 24
        targetSdk = 36 

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ ADD THIS ENTIRE BLOCK AT THE BOTTOM OF THE FILE
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // <-- Changed to 2.1.4
}