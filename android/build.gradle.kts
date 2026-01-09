allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.buildDir = File(newBuildDir.asFile, project.name)
}
rootProject.buildDir = File(newBuildDir.asFile, "project")

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}