package hu.blackbelt.eclipse.emf.genmodel.generator.builder

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.generator.GeneratorComponent.Outlet
import org.eclipse.xtext.mwe.ResourceLoadingSlotEntry
import hu.blackbelt.eclipse.emf.genmodel.generator.builder.engine.ModelBuilderGeneratorStandaloneSetup
import hu.blackbelt.eclipse.emf.genmodel.generator.builder.engine.BuilderConfig
import java.util.logging.Logger
import org.eclipse.emf.mwe2.runtime.workflow.AbstractCompositeWorkflowComponent

@Accessors
class BuilderGeneratorWorkflow extends AbstractCompositeWorkflowComponent {
	
	Logger logger = Logger.getLogger("BuilderGeneratorWorkflow.class"); 

	String javaGenPath
	String modelDir
	String featureModifierMethodPrefix = "with"
	String slot = "builderGenerator"
	boolean nullCheckByDefault = false
	
	override preInvoke() {
		val slotEntry = new ResourceLoadingSlotEntry() => [
			setSlot(slot)
		]
		
		val config = new BuilderConfig() => [
			setJavaGenPath(javaGenPath)
			setFeatureModifierMethodPrefix(featureModifierMethodPrefix)
			setNullCheckByDefault(nullCheckByDefault)
		]
		
		val setup = new ModelBuilderGeneratorStandaloneSetup() => [
			setConfig(config)
			setDoInit(true)
		]

		val readerComponent = new org.eclipse.xtext.mwe.Reader() => [
			addRegister(setup)
			addPath(modelDir)
			addLoadResource(slotEntry)
		]
		
		val outlet = new Outlet() => [
            setPath(javaGenPath)
        ]
		
		val generatorComponent = new org.eclipse.xtext.generator.GeneratorComponent() => [
			setRegister(setup)
			addSlot(slot)
			addOutlet(outlet)
		]

		addComponent(readerComponent)
		addComponent(generatorComponent)
		super.preInvoke
	}
}
