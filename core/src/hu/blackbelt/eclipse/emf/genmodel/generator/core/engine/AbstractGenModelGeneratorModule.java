package hu.blackbelt.eclipse.emf.genmodel.generator.core.engine;

import org.eclipse.emf.ecore.EValidator;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.generator.IOutputConfigurationProvider;
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider;
import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.resource.IResourceFactory;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceRuntimeModule;
import org.eclipse.xtext.service.SingletonBinding;
import org.eclipse.xtext.validation.IResourceValidator;

import hu.blackbelt.eclipse.emf.genmodel.generator.core.validation.BasicConstraints;

public abstract class AbstractGenModelGeneratorModule extends AbstractGenericResourceRuntimeModule {
	public Class<? extends ResourceSet> bindResourceSet() {
		return ResourceSetImpl.class;
	}

	@Override
	public Class<? extends IQualifiedNameProvider> bindIQualifiedNameProvider() {
		return DefaultDeclarativeQualifiedNameProvider.class;
	}

	@Override
	protected String getFileExtensions() {
		return "genmodel";
	}

	@Override
	protected String getLanguageName() {
		return "hu.blackbelt.eclipse.emf.generator.genmodel";
	}

	public Class<? extends IResourceFactory> bindIResourceFactory() {
		return GenModelResourceFactory.class;
	}

	// suppress validation of profiles
	public Class<? extends IResourceValidator> bindIResourceValidator () {
		return ResourceValidatorImplExt.class;
	}

	public EValidator.Registry bindEValidatorRegistry() {
		return EValidator.Registry.INSTANCE;
	}
	
	@SingletonBinding(eager = true)
	public Class<? extends BasicConstraints> bindBasicConstraints() {
		return BasicConstraints.class;
	}
	
	public abstract Class<? extends IGenerator> bindIGenerator();

	@SingletonBinding
	public Class<? extends IOutputConfigurationProvider> bindIOutputConfigurationProvider() {
		return OutputConfigurationProvider.class;
	}

}
