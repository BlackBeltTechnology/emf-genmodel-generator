package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import javax.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.codegen.ecore.genmodel.GenClass
import org.eclipse.emf.ecore.resource.Resource

class ModelBuilderFacade {
	@Inject extension ModelBuilderExtension
	@Inject ModelBuilderBuilder modelBuilderBuilder
	
	def doGenerate(GenModel genModel, Resource input, IFileSystemAccess fsa) {		
		genModel.allGenPackagesWithConcreteClasses
		.forEach[
		    val facade = generateBuilderFacade
		    fsa.generateFile(builderFacadeFileName, facade)
		    genClasses
		    .filter[isNonAbstractBuilderType]
		    .forEach[
		    	modelBuilderBuilder.doGenerate(it, input, fsa)
		    ]			
		]
	}

	def generateBuilderFacade (GenPackage it) 
	'''
	package «builderFacadePackage»;

	/**
	 * <!-- begin-user-doc --> 
	 *   A facade for the builders for the EMF package ' <em><b>«getEcorePackage.nsURI»</b></em>'.
	 * <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	 
	 public class «builderFacadeName» {
		«FOR cl : genClasses.filter[isNonAbstractBuilderType]»
			«builderAccessMethod(cl)»
		«ENDFOR»
	}
    '''
    
   def builderAccessMethod(GenClass it)
   '''
    public static final «builderBuilderName» new«builderBuilderName»() {
      return «builderBuilderName».create();
    }
   '''


}