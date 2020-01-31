package hu.blackbelt.eclipse.emf.genmodel.generator.builder.engine;

import org.eclipse.xtext.generator.IGenerator;

import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorModule;
import hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates.ModelBuilder;

public class ModelBuilderGeneratorModule extends AbstractGenModelGeneratorModule {

	public Class<? extends IGenerator> bindIGenerator() {
		return ModelBuilder.class;
	}
}
