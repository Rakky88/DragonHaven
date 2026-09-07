import java.util.Properties
import java.util.Base64
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional Firebase config is supplied by the owner/CI. Offline builds remain
// buildable without a fabricated project or any Google credentials.
val havenBuildDefines = (project.findProperty("dart-defines") as? String)
    ?.split(",")?.mapNotNull { encoded ->
        runCatching { String(Base64.getDecoder().decode(encoded)) }
            .getOrNull()
    }?.associate { value -> value.substringBefore("=") to value.substringAfter("=", "") }
    ?: emptyMap()
val firebaseBuildEnabled = havenBuildDefines["DRAGONHAVEN_FIREBASE_ENABLED"] == "true"
if (firebaseBuildEnabled) {
    require(file("google-services.json").exists()) {
        "Firebase-enabled builds require the owner's google-services.json."
    }
    val projects = JsonSlurper().parse(rootProject.file("../firebase-projects.json")) as Map<*, *>
    val environment = havenBuildDefines["DRAGONHAVEN_ENVIRONMENT"]
    val expected = havenBuildDefines["DRAGONHAVEN_FIREBASE_PROJECT_ID"]
    val config = JsonSlurper().parse(file("google-services.json")) as Map<*, *>
    val info = config["project_info"] as? Map<*, *>
    val clients = config["client"] as? List<*>
    require(environment != "production" || gradle.startParameter.taskNames.none {
        it.contains("debug", ignoreCase = true) || it.contains("profile", ignoreCase = true)
    }) { "Production Firebase collection is restricted to release builds." }
    require(expected != null && projects[environment] == expected && info?.get("project_id") == expected) {
        "Firebase project does not match the registered build environment."
    }
    require(clients?.any { value ->
        val client = value as? Map<*, *>
        val clientInfo = client?.get("client_info") as? Map<*, *>
        val androidInfo = clientInfo?.get("android_client_info") as? Map<*, *>
        androidInfo?.get("package_name") == "nl.dragonhaven.app"
    } == true) { "Firebase configuration does not contain the DragonHaven Android app." }
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
    apply(plugin = "com.google.firebase.firebase-perf")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use { stream ->
        keystoreProperties.load(stream)
    }
}

extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
    namespace = "nl.dragonhaven.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "nl.dragonhaven.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Public releases supply a stable private key through GitHub Secrets.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
