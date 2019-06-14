package hu.blackbelt.eclipse.emf.genmodel.generator.core.engine;

import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.ISetup;

import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;

public abstract class AbstractGenModelGeneratorStandaloneSetup implements ISetup {
	private Injector injector;
	private GeneratorConfig config;
	
	public abstract AbstractGenModelGeneratorModule getGenModelModule();
	
	public void setConfig(GeneratorConfig config) {
		this.config = config;
	}
	
	public void setDoInit (boolean init) {
		createInjectorAndDoEMFRegistration();
	}
	

	public AbstractGenModelGeneratorStandaloneSetup () {
	}
	
	private Module getDynamicModule () {
		return new AbstractModule() {
			@Override
			protected void configure() {
				bind(GeneratorConfig.class).toInstance(config);
			}
		};
	}

	@Override
	public Injector createInjectorAndDoEMFRegistration() {
		if (injector == null) {
			injector = Guice.createInjector(getGenModelModule(), getDynamicModule());
			register(injector);
		}
		return injector;
	}

	public void register(Injector injector) {
		org.eclipse.xtext.resource.IResourceFactory resourceFactory = injector.getInstance(org.eclipse.xtext.resource.IResourceFactory.class);
		org.eclipse.xtext.resource.IResourceServiceProvider serviceProvider = injector.getInstance(org.eclipse.xtext.resource.IResourceServiceProvider.class);
		Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("genmodel", resourceFactory);
		org.eclipse.xtext.resource.IResourceServiceProvider.Registry.INSTANCE.getExtensionToFactoryMap().put("genmodel", serviceProvider);
	}

}
