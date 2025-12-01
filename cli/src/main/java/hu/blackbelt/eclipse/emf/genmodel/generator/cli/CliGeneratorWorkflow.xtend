package hu.blackbelt.eclipse.emf.genmodel.generator.cli

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.generator.GeneratorComponent.Outlet
import org.eclipse.xtext.mwe.ResourceLoadingSlotEntry
import org.eclipse.emf.mwe2.runtime.workflow.AbstractCompositeWorkflowComponent
import hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine.CliGeneratorStandaloneSetup
import hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine.CliConfig

@Accessors
class CliGeneratorWorkflow extends AbstractCompositeWorkflowComponent {

    String javaGenPath
    String modelDir
    String resolverClass
    String slot = "cliGenerator"
    Boolean printXmlOnError = false;

    override preInvoke() {
        val slotEntry = new ResourceLoadingSlotEntry() => [
            setSlot(slot)
        ]
        
        val config = new CliConfig() => [
            setJavaGenPath(javaGenPath)
            setPrintXmlOnError(printXmlOnError)
            setResolverClass(resolverClass)
        ]

        val setup = new CliGeneratorStandaloneSetup() => [
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
