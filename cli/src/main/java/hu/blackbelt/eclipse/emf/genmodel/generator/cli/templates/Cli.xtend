package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import com.google.inject.Inject
import hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine.CliConfig

/**
 * CLI generator orchestrator.
 *
 * Generates model-specific ModelSchema classes with EPackage access.
 * Static utilities (ModelClient, ModelServer, etc.) are provided by the model-cli module.
 *
 * @generated
 */
class Cli implements IGenerator2 {
	@Inject ModelSchemaGenerator modelSchemaGenerator
	@Inject CliConfig config

	override afterGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}

	override beforeGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}

	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		input.allContents.filter(GenModel).filter[e | config.genModelNames.size == 0 || config.genModelNames.contains(e.modelName)].forEach[
			modelSchemaGenerator.doGenerate(it, fsa)
		]
	}
}
