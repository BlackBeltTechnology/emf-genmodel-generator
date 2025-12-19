package hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine

import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.GeneratorConfig
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.List
import java.util.ArrayList

@Accessors
class CliConfig extends GeneratorConfig {
	String resolverClass;
	String validatorClass;
	List<String> genModelNames = new ArrayList();
}
