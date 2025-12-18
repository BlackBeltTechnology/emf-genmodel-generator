package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates;

import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates.ModelBuilderExtension

/**
 * CLI-specific extensions.
 * Extends ModelBuilderExtension for common functionality and adds CLI-specific methods.
 */
class CliExtension extends ModelBuilderExtension {

    // ========== Model Type Checking ==========

    /**
     * Check if this GenModel is a JUDO metamodel (not a referenced external model like Ecore).
     * JUDO models have package names starting with "hu.blackbelt.judo.meta".
     */
    def isJudoModel(GenModel it) {
        val pkg = packageName
        return pkg !== null && pkg.startsWith("hu.blackbelt.judo.meta")
    }

    /**
     * Check if this GenPackage is a JUDO metamodel package.
     * JUDO packages have FQN starting with "hu.blackbelt.judo.meta".
     * Non-JUDO packages (like org.eclipse.emf.ecore for ASM) are skipped.
     */
    def isJudoPackage(GenPackage it) {
        val fqn = packageFqName
        return fqn !== null && fqn.startsWith("hu.blackbelt.judo.meta")
    }

    /**
     * Check if this GenModel is a primary model (not a sub-model like rdbms-datatypes).
     * Primary models have simple names like "Esm", "Psm", "Rdbms", "Ui".
     * Sub-models have compound names like "RdbmsDataTypes", "RdbmsNameMapping".
     */
    def isPrimaryModel(GenModel it) {
        val name = modelName
        if (name === null) {
            return false
        }
        // Primary models have simple names (Esm, Psm, Rdbms, Ui, etc.)
        // Sub-models have compound names with multiple capital letters
        // Check if name matches pattern: single word or ends with common metamodel suffixes
        val primaryPatterns = #["Esm", "Psm", "Asm", "Rdbms", "Ui", "Expression", "Jql", "Jcl", "Measure", "Query", "Script", "Keycloak", "Liquibase", "Openapi"]
        return primaryPatterns.exists[name.equals(it) || name.equalsIgnoreCase(it)]
    }

    // ========== CLI Package Helpers ==========

    def cliPackageName(GenModel it) {
        packageName + ".cli"
    }

    def cliRootPath(GenModel it) {
    	packagePath + "/cli/"
    }

    // ========== ModelSchema Helpers ==========

    def modelSchemaClassName(GenModel it) {
        modelName.capitalize + "ModelSchema"
    }

    def modelSchemaFilePath(GenModel it) {
        cliRootPath + modelSchemaClassName + ".java"
    }
}
