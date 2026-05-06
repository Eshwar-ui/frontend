import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
val keyAliasValue = (keystoreProperties["keyAlias"] as String?) ?: System.getenv("ANDROID_KEY_ALIAS")
val keyPasswordValue = (keystoreProperties["keyPassword"] as String?) ?: System.getenv("ANDROID_KEY_PASSWORD")
val storePasswordValue = (keystoreProperties["storePassword"] as String?) ?: System.getenv("ANDROID_STORE_PASSWORD")
val storeFilePathValue = (keystoreProperties["storeFile"] as String?) ?: System.getenv("ANDROID_KEYSTORE_PATH")
val hasReleaseSigning = !keyAliasValue.isNullOrBlank() &&
        !keyPasswordValue.isNullOrBlank() &&
        !storePasswordValue.isNullOrBlank() &&
        !storeFilePathValue.isNullOrBlank()

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

android {
    namespace = "com.quantumdashboard.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.quantumdashboard.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                storeFile = rootProject.file(storeFilePathValue!!)
                storePassword = storePasswordValue
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
