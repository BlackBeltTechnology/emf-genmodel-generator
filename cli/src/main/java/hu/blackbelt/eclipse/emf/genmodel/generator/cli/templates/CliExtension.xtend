package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates;

import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.codegen.ecore.genmodel.GenClass
import hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates.ModelBuilderExtension

/**
 * CLI-specific extensions.
 * Extends GenModelExtensions for common functionality and adds CLI-specific methods.
 */
class CliExtension extends ModelBuilderExtension {

    def packageName(GenPackage it) {
        interfacePackageName
    }

    // ========== CLI-Specific: CLI Package Helpers ==========

    def cliPackageName(GenModel it) {
        packageName + ".cli"
    }

    def cliRootPath(GenModel it) {
    	packagePath + "/cli/"
    }

    def cliOperationsFilePath(GenModel it) {
		cliRootPath + "Operations.java"
    }

    def abstractOperationsFilePath(GenModel it) {
    	cliRootPath + "AbstractOperations.java"
    }

    def cliOperationsImplPackage(GenClass it) {
    	genPackage.packageFqName + ".util.operations"
    }

    def cliMixinsPackage(GenModel it) {
        cliPackageName + ".mixins"
    }

    def cliMixinsRootPath(GenModel it) {
        cliRootPath + "mixins/"
    }

    def loggingMixinFilePath(GenModel it) {
        cliMixinsRootPath + "LoggingMixin.java"
    }

    def cliClassName(GenModel it) {
    	modelName.capitalize +"Command"
    }

    def commandFilePath(GenModel it) {
        cliRootPath + cliClassName + ".java"
    }

	// ========== RuntimeModel-Specific: Model Package Helpers ==========

    def modelClass(GenModel it) {
    	modelName + "Model"
    }

    def modelValidationException(GenModel it) {
    	modelClass + "." + modelName + "ValidationException"
    }

	// ========== FqnResolver-Specific: FqnResovler Package Helpers ==========

    def resolverFilePath(GenModel it) {
        cliRootPath  + "FqnResolver.java"
    }

    def resolverPackage(GenModel it) {
        cliPackageName +".FqnResolver"
    }

    // ========== Validator-Specific: Validator Package Helpers ==========

    def validatorFilePath(GenModel it) {
        cliRootPath  + "Validator.java"
    }

    def validatorPackage(GenModel it) {
        cliPackageName +".Validator"
    }

	// ========== Operations-Specific: Operations Package Helpers ==========

    def operationsClassName(GenClass it) {
    	name.capitalize + "Operations"
    }

    def operationsImplFilePath(GenClass it) {
        genPackage.packagePath + "/util/operations/" + operationsClassName +".java"
    }

    def operationsImplFilePath(GenModel it) {
		packagePath + "/util/operations/AbstractOperations.java"
    }

    def eObjectTypeName(GenClass it) {
        name.toLowerCase
    }

    def allConcreteClasses(GenModel it) {
	    getAllGenPackagesWithConcreteClasses().flatMap[ genClasses ].filter[ isBuilderType ]
    }


    def eObjectTypeNames(GenModel it) {
        allConcreteClasses.map[eObjectTypeName].toList
    }


    def allReferences(GenClass it) {
        allGenFeatures.filter[isReferenceType]
    }

    // ========== Server-Specific: Server Package Helpers ==========

    def serverClassName(GenModel it) {
        modelName.capitalize + "Server"
    }

    def serverFilePath(GenModel it) {
        cliRootPath + serverClassName + ".java"
    }

	// ========== Client-Specific: Server Package Helpers ==========

    def clientClassName(GenModel it) {
        modelName.capitalize + "Client"
    }

    def clientFilePath(GenModel it) {
        cliRootPath + clientClassName + ".java"
    }
}
