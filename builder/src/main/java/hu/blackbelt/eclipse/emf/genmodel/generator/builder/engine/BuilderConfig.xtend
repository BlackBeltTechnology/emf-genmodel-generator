package hu.blackbelt.eclipse.emf.genmodel.generator.builder.engine;

import org.eclipse.xtend.lib.annotations.Accessors
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.GeneratorConfig

@Accessors
class BuilderConfig extends GeneratorConfig {
    String featureModifierMethodPrefix = "with"
    boolean nullCheckByDefault = false
}
