allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    val setupProject = { p: Project ->
        if (p.hasProperty("android")) {
            val android = p.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                if (p.name != "app" && compileSdkVersion == "android-30") {
                    compileSdkVersion(34)
                }
                try {
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                } catch (e: Exception) {
                    // Ignore if already finalized
                }
            }
        }

        p.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }

        if (p.name == "isar_flutter_libs") {
            val libAndroid = p.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            libAndroid?.namespace = "dev.isar.isar_flutter_libs"
        }
    }

    if (project.state.executed) {
        setupProject(project)
    } else {
        project.afterEvaluate {
            setupProject(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
