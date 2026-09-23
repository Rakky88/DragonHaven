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

val rewardedAdsMode = havenBuildDefines["DRAGONHAVEN_REWARDED_ADS_MODE"] ?: "disabled"
val dragonHavenEnvironment = havenBuildDefines["DRAGONHAVEN_ENVIRONMENT"]?.trim()
val requestedGradleTasks = gradle.startParameter.taskNames.map { taskName ->
    taskName.substringAfterLast(':').lowercase()
}
val requestsReleaseBuild = requestedGradleTasks.any { taskName ->
    taskName.contains("release")
}
val requestsNonReleaseBuild = requestedGradleTasks.any { taskName ->
    taskName.contains("debug") || taskName.contains("profile")
}
val rewardedAdsTestAppId = "ca-app-pub-3940256099942544~3347511713"
val rewardedAdsTestUnitId = "ca-app-pub-3940256099942544/5224354917"
val admobAppId = havenBuildDefines["DRAGONHAVEN_ADMOB_ANDROID_APP_ID"] ?: rewardedAdsTestAppId
val admobGemsUnitId = havenBuildDefines["DRAGONHAVEN_ADMOB_REWARDED_GEMS_ID"] ?: rewardedAdsTestUnitId
val admobCoinsUnitId = havenBuildDefines["DRAGONHAVEN_ADMOB_REWARDED_COINS_ID"] ?: rewardedAdsTestUnitId
val admobAppIdPattern = Regex("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
val admobUnitIdPattern = Regex("^ca-app-pub-[0-9]{16}/[0-9]{10}$")
require(rewardedAdsMode in setOf("disabled", "test", "production")) {
    "DRAGONHAVEN_REWARDED_ADS_MODE must be disabled, test or production."
}
if (rewardedAdsMode == "test") {
    require(!dragonHavenEnvironment.isNullOrBlank() && dragonHavenEnvironment != "production") {
        "Google test ads require an explicit non-production DRAGONHAVEN_ENVIRONMENT."
    }
    require(requestsNonReleaseBuild && !requestsReleaseBuild) {
        "Google test ads are restricted to explicit debug or profile builds."
    }
    require(admobAppId == rewardedAdsTestAppId &&
        admobGemsUnitId == rewardedAdsTestUnitId && admobCoinsUnitId == rewardedAdsTestUnitId) {
        "Test builds must use Google's official sample ad identifiers."
    }
}
if (rewardedAdsMode == "production") {
    require(dragonHavenEnvironment == "production") {
        "Production ad units are restricted to the production environment."
    }
    require(requestsReleaseBuild && !requestsNonReleaseBuild) {
        "Production rewarded ads are restricted to explicit release builds."
    }
    require(admobAppIdPattern.matches(admobAppId) && admobAppId != rewardedAdsTestAppId) {
        "A real DragonHaven AdMob Android app ID is required."
    }
    require(admobUnitIdPattern.matches(admobGemsUnitId) && admobGemsUnitId != rewardedAdsTestUnitId &&
        admobUnitIdPattern.matches(admobCoinsUnitId) && admobCoinsUnitId != rewardedAdsTestUnitId &&
        admobGemsUnitId != admobCoinsUnitId) {
        "Two distinct real rewarded ad-unit IDs are required."
    }
    val appPublisher = admobAppId.substringAfter("ca-app-pub-").substringBefore('~')
    val gemsPublisher = admobGemsUnitId.substringAfter("ca-app-pub-").substringBefore('/')
    val coinsPublisher = admobCoinsUnitId.substringAfter("ca-app-pub-").substringBefore('/')
    require(appPublisher == gemsPublisher && appPublisher == coinsPublisher) {
        "The AdMob app ID and both rewarded ad-unit IDs must share one publisher account."
    }
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
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.jvmArgs(
                "--add-opens=java.base/java.lang=ALL-UNNAMED",
                "--add-opens=java.base/java.util=ALL-UNNAMED",
                "--add-opens=java.base/java.io=ALL-UNNAMED",
                "--add-opens=java.base/java.net=ALL-UNNAMED",
                "--add-opens=java.base/java.security=ALL-UNNAMED",
                "--add-opens=java.base/java.text=ALL-UNNAMED",
                "--add-opens=java.base/jdk.internal.access=ALL-UNNAMED",
                "--add-opens=java.desktop/java.awt.font=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
            )
        }
    }

    defaultConfig {
        applicationId = "nl.dragonhaven.app"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["dragonhavenAdmobAppId"] = admobAppId
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

// AGP's resource-backed unit-test package also consumes the Flutter assets.
tasks.configureEach {
    if (name.startsWith("package") && name.endsWith("UnitTestForUnitTest")) {
        val variant = name.removePrefix("package").removeSuffix("UnitTestForUnitTest")
        dependsOn("copyFlutterAssets$variant")
    }
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.17")
}
