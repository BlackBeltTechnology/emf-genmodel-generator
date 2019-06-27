package hu.blackbelt.eclipse.emf.genmodel.generator.helper.engine;

import org.eclipse.xtext.generator.IGenerator;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorModule;
import hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates.ModelHelper;

public class ModelHelperGeneratorModule extends AbstractGenModelGeneratorModule {
	public Class<? extends IGenerator> bindIGenerator() {
		return ModelHelper.class;
	}
}
