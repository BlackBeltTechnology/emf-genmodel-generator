package hu.blackbelt.eclipse.emf.genmodel.generator.helper.engine

import org.eclipse.xtend.lib.annotations.Accessors
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.GeneratorConfig

@Accessors
class HelperGeneratorConfig extends GeneratorConfig {
	Boolean generateUuid = true;
}
