plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tao_app_fixed"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.martinjon.tao_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // This will work with both local development and CodeMagic
            if (System.getenv("CM_KEYSTORE") != null) {
                // CodeMagic environment - file will be created from base64
                storeFile = file("upload-keystore.jks")
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: ""
                keyAlias = System.getenv("CM_KEY_ALIAS") ?: ""
                keyPassword = System.getenv("CM_KEY_PASSWORD") ?: ""
            } else {
                // Local development
                storeFile = file("upload-keystore.jks")
                storePassword = "Tao_of_the_Day"
                keyAlias = "my-alias"
                keyPassword = "Tao_of_the_Day"
            }
        }

    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
