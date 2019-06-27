package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.emf.codegen.ecore.genmodel.GenModel

class ModelBuilder implements IGenerator {
	@Inject ModelBuilderFacade modelBuilderFacade
	@Inject ModelBuilderInterface modelBuilderInterface

	// add more templates here
	
	override doGenerate(Resource input, IFileSystemAccess fsa) {
		
		input.allContents.filter(GenModel).forEach[
			modelBuilderFacade.doGenerate(it, input, fsa)
			modelBuilderInterface.doGenerate(it, input, fsa)
		]

	}	
}