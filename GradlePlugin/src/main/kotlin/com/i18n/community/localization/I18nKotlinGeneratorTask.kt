package com.i18n.community.localization

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction
import java.io.File

open class I18nKotlinGeneratorTask : DefaultTask() {

    @OutputDirectory
    lateinit var outputFolder: File

    @InputDirectory
    lateinit var langFolder: File

    @Input
    lateinit var packageName: String

    @TaskAction
    fun generateKotlinStrings() {

        val yamlFiles =
            langFolder.listFiles { _, fileName -> fileName.endsWith(".lyaml") && fileName != "en.lyaml" }
                .joinToString(separator = " ") { "$langFolder/it.name" }

        runCommand(
            command = "i18nGen $langFolder/en.lyaml $yamlFiles -kotlin $packageName",
            workingDirectory = File(outputFolder.absolutePath)
        )?.let(System.out::println)
    }

    private fun runCommand(command: String, workingDirectory: File? = null): String? {
        val process = Runtime.getRuntime()
            .exec(
                command,
                null,
                workingDirectory
            ).apply { waitFor() }

        return process.errorStream.bufferedReader().use { it.readText() }
            .trim().takeIf { it.isNotBlank() }
    }
}
