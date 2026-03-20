import com.android.build.gradle.BaseExtension

plugins {
    id("com.android.application") version "8.11.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Настройка директории сборки (оставляем от Flutter)
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

// Задача clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ===================================================================
// ФИКС NAMESPACE ДЛЯ СТАРЫХ ПЛАГИНОВ (flutter_nearby_connections и т.п.)
// Используем withId вместо afterEvaluate для избежания ошибок жизненного цикла
// ===================================================================

subprojects {
    val subproject = this
    
    fun configureNamespace() {
        val androidExtension = subproject.extensions.findByType<BaseExtension>()
        androidExtension?.let { android ->
            if (android.namespace == null || android.namespace.toString().isEmpty()) {
                android.namespace = subproject.group.toString()
                    ?: "com.example.crisis_mesh_messenger"
            }
        }
    }

    plugins.withId("com.android.application") { configureNamespace() }
    plugins.withId("com.android.library") { configureNamespace() }
}

// ФИКС JVM TARGET COMPATIBILITY для всех подпроектов
subprojects {
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    
    plugins.withId("java-library") {
        tasks.withType<JavaCompile> {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
    
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}
