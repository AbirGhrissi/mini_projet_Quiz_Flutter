// Fichier android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.miniProjet.mini_projet"
    compileSdk = 35  // Mets à jour ici la version du SDK
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Activer le desugaring de la bibliothèque core
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.miniProjet.mini_projet"
        minSdkVersion(23)
        targetSdkVersion(33)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Ajoute la dépendance pour le desugaring des librairies Java 8
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Autres dépendances...
}
