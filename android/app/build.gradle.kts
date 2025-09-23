plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project_radar_app"
    compileSdk = 36 // 🔹 Use a stable version (36 is preview, might break)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.project_radar_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // 🔹 Match stable compileSdk
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BOM keeps versions aligned
    implementation(platform("com.google.firebase:firebase-bom:32.2.2"))

    // Firebase core services
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // Firebase Messaging for push notifications
    implementation("com.google.firebase:firebase-messaging")

    // ✅ Use latest desugaring libs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Other dependencies...
}
flutter {
    source = "../.."
}
