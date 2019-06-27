package hu.blackbelt.eclipse.emf.genmodel.generator.builder.engine;

import com.google.inject.AbstractModule;
import com.google.inject.Module;

import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorModule;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorStandaloneSetup;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.GeneratorConfig;

public class ModelBuilderGeneratorStandaloneSetup extends AbstractGenModelGeneratorStandaloneSetup {

	private BuilderConfig builderConfig;
	
	public void setConfig(BuilderConfig builderConfig) {
		this.builderConfig = builderConfig;
	}
		
	@Override
	public Module getDynamicModule () {
		return new AbstractModule() {
			@Override
			protected void configure() {
				bind(GeneratorConfig.class).toInstance(builderConfig);
				bind(BuilderConfig.class).toInstance(builderConfig);
			}
		};
	}

	@Override
	public AbstractGenModelGeneratorModule getGenModelModule() {
		return new ModelBuilderGeneratorModule();
	}
}
