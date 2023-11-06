package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import com.google.inject.Inject

class ModelBuilder implements IGenerator2 {
    @Inject ModelBuilderFacade modelBuilderFacade
    @Inject ModelBuilderInterface modelBuilderInterface

    // add more templates here
				
	override afterGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}
	
	override beforeGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}
	
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
        input.allContents.filter(GenModel).forEach[
            modelBuilderFacade.doGenerate(it, input, fsa)
            modelBuilderInterface.doGenerate(it, input, fsa)
        ]
	}
}
