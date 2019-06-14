package hu.blackbelt.eclipse.emf.genmodel.generator.helper.engine;

import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorModule;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorStandaloneSetup;

public class ModelHelperGeneratorStandaloneSetup extends AbstractGenModelGeneratorStandaloneSetup {

	@Override
	public AbstractGenModelGeneratorModule getGenModelModule() {
		// TODO Auto-generated method stub
		return new ModelHelperGeneratorModule();
	}
}
