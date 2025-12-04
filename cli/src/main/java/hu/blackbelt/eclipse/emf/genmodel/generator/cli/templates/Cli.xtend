package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import com.google.inject.Inject

class Cli implements IGenerator2 {
	@Inject ModelClient modelClient
	@Inject ModelServer modelServer
	@Inject ModelCommand modelCommand
	@Inject OperationsImpl operations
	@Inject OperationsBase modelOperations

	override afterGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}

	override beforeGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}

	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		input.allContents.filter(GenModel).forEach[
			modelOperations.doGenerate(it,fsa)
			operations.doGenerate(it, fsa)
			modelClient.doGenerate(it, fsa)
			modelServer.doGenerate(it, fsa)
			modelCommand.doGenerate(it, input, fsa)
		]
	}
}
