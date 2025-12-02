package hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine

import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.GeneratorConfig
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors
class CliConfig extends GeneratorConfig {
	String resolverClass;
}