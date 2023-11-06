package hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates;

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import com.google.inject.Inject

class ModelHelper implements IGenerator2 {
    @Inject ModelResourceSupport modelHelper
    // add more templates here

				
	override afterGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}
				
	override beforeGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
	}
				
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
        modelHelper.doGenerate(input, fsa)    		
	}
}
