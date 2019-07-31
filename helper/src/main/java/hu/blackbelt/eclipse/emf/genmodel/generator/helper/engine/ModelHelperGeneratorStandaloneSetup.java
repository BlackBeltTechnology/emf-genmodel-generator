package hu.blackbelt.eclipse.emf.genmodel.generator.helper.engine;

import com.google.inject.AbstractModule;
import com.google.inject.Module;

import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorModule;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorStandaloneSetup;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.GeneratorConfig;

public class ModelHelperGeneratorStandaloneSetup extends AbstractGenModelGeneratorStandaloneSetup {

	private HelperGeneratorConfig helperConfig;
	
	public void setConfig(HelperGeneratorConfig helperConfig) {
		this.helperConfig = helperConfig;
	}
		
	@Override
	public Module getDynamicModule () {
		return new AbstractModule() {
			@Override
			protected void configure() {
				bind(GeneratorConfig.class).toInstance(helperConfig);
				bind(HelperGeneratorConfig.class).toInstance(helperConfig);
			}
		};
	}

	@Override
	public AbstractGenModelGeneratorModule getGenModelModule() {
		// TODO Auto-generated method stub
		return new ModelHelperGeneratorModule();
	}
}
