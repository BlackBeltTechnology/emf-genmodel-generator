package hu.blackbelt.eclipse.emf.genmodel.generator.core.engine;

import org.eclipse.xtend.lib.annotations.Accessors

@Accessors
class GeneratorConfig {
    String javaGenPath
    Boolean printXmlOnError = false;
}
