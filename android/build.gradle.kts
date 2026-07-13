plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

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
}

subprojects {
    project.pluginManager.withPlugin("com.android.library") {
        try {
            project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                if (namespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val packageMatch = """package="([^"]+)"""".toRegex().find(content)
                        if (packageMatch != null) {
                            namespace = packageMatch.groupValues[1]
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore if it's not a library
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}