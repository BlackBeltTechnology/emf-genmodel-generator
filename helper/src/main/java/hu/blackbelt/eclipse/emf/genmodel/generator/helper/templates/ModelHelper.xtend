package hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates;

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator

class ModelHelper implements IGenerator {
    @Inject ModelResourceSupport modelHelper
    // add more templates here

    override doGenerate(Resource input, IFileSystemAccess fsa) {
        modelHelper.doGenerate(input,fsa)
    }
}
