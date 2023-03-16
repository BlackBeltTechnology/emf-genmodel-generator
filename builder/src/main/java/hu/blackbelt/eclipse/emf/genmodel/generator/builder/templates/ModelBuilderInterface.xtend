package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import javax.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.ecore.resource.Resource

class ModelBuilderInterface {
    @Inject extension ModelBuilderExtension

    def doGenerate(GenModel genModel, Resource input, IFileSystemAccess fsa) {
        genModel.allGenPackagesWithConcreteClasses.forEach[
            val facade = generateBuilderInterface
            fsa.generateFile(builderInterfaceFileName, facade)
        ]
    }

    def generateBuilderInterface (GenPackage it)
    '''
    package «builderInterfacePackage»;
    /**
     * <!-- begin-user-doc -->
     *   A marker interface for the builders of the EMF package ' <em><b>«getEcorePackage.nsURI»</b></em>'.
     * <!-- end-user-doc -->
     *
     * @generated
     */
    public interface «builderInterfaceName()»<T extends org.eclipse.emf.ecore.EObject> {
        public T build();
    }
    '''
}