plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "it.guidomarangoni.el_troso"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "it.guidomarangoni.el_troso"
        // minSdk esplicito a 26 (Android 8.0): flutter_gemma + MediaPipe GenAI
        // non garantiscono compatibilità su API più basse. Cfr. README
        // https://github.com/DenisovAV/flutter_gemma .
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Multidex abilitato a partire dalla build 18 (Fase 4.5.h+).
        // Aggiunto url_launcher per le GameInfoSheet ha spinto il method
        // count complessivo oltre il limite 64K del singolo DEX e Gradle
        // si schianta su DexMergingTaskDelegate. Su minSdk=26 (>=21) il
        // multidex e' nativo Android, basta il flag senza aggiungere
        // dependency androidx.multidex.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing con le chiavi debug per ora - sostituire in Fase 5 prima
            // della submission Kaggle se l'APK va pubblicato firmato.
            signingConfig = signingConfigs.getByName("debug")

            // === Fase 3.1 (2026-04-19) ===
            // R8/shrink temporaneamente disabilitati per evitare l'errore:
            //   Missing class com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
            //   Missing class com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
            // Le classi esistono a runtime nei proto MediaPipe ma non sono
            // esposte come symbol visibili a R8 in fase di static analysis.
            // Piano: in Fase 4 riabilitare isMinifyEnabled=true aggiungendo
            // keep rules ProGuard da build/app/outputs/mapping/release/missing_rules.txt
            // nel file android/app/proguard-rules.pro.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
