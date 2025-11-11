plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ocr_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs += listOf("-Xinline-classes")
    }

    defaultConfig {
        applicationId = "com.example.ocr_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("opencv/OpenCV-android-sdk/sdk/native/libs")
        }
    }

    packagingOptions {
        pickFirst("lib/arm64-v8a/libopencv_java4.so")
        pickFirst("lib/armeabi-v7a/libopencv_java4.so")
        pickFirst("lib/x86/libopencv_java4.so")
        pickFirst("lib/x86_64/libopencv_java4.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.opencv:opencv:4.10.0")
}
