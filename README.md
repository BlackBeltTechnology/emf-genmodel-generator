# EMF GenModel Generator

[![Build](https://github.com/BlackBeltTechnology/emf-genmodel-generator/actions/workflows/build.yml/badge.svg?branch=develop)](https://github.com/BlackBeltTechnology/emf-genmodel-generator/actions/workflows/build.yml)

The EMF GenModel Generator extends Eclipse Modeling Framework's standard code generation by automatically producing **Builder patterns** and **Helper utilities** from GenModel (`.genmodel`) files. It runs as a set of Eclipse plugins, distributed via a P2 update site, and integrates into MWE2 (Model Workflow Engine) workflows used by downstream metamodel projects.

## How It Works

Consumer projects (such as `judo-meta-esm`, `judo-meta-psm`, `judo-meta-rdbms`) define an Ecore metamodel and a corresponding GenModel. They invoke this generator's MWE2 workflow components to produce additional Java source code alongside EMF's standard output.

The generation pipeline follows this sequence:

```mermaid
sequenceDiagram
    participant Consumer as Consumer Project
    participant MWE2 as MWE2 Workflow
    participant Reader as Resource Reader
    participant Setup as StandaloneSetup
    participant Guice as Guice Injector
    participant Gen as IGenerator2 Impl
    participant Templates as Xtend Templates
    participant FS as IFileSystemAccess2

    Consumer->>MWE2: Run workflow (modelDir, javaGenPath)
    MWE2->>Setup: Create config & injector
    Setup->>Guice: Bind Module, Config, IGenerator2
    MWE2->>Reader: Load .genmodel resources
    Reader-->>MWE2: Resource with GenModel objects
    MWE2->>Gen: doGenerate(resource, fsa, context)
    Gen->>Templates: Iterate GenModels, delegate to templates
    Templates->>FS: Write generated .java files
    FS-->>Consumer: src-gen/{package}/{Class}.java
```

## Modules

This project is organized into six modules. The generator modules (`core`, `builder`, `helper`) form the generation engine, while the remaining modules handle packaging and self-hosting.

```mermaid
graph TD
    subgraph "Generation Engine"
        Core["core<br/><i>Base engine, validation,<br/>MWE2 integration</i>"]
        Builder["builder<br/><i>Builder pattern generator</i>"]
        Helper["helper<br/><i>Resource support generator</i>"]
    end

    subgraph "Self-Hosting"
        Ecore["ecore<br/><i>Runs generators on<br/>Ecore metamodel itself</i>"]
    end

    subgraph "Distribution"
        Feature["feature<br/><i>Eclipse feature bundle</i>"]
        Site["site<br/><i>P2 update site</i>"]
    end

    Builder --> Core
    Helper --> Core
    Ecore --> Builder
    Ecore --> Helper
    Feature --> Core
    Feature --> Builder
    Feature --> Helper
    Feature --> Ecore
    Site --> Feature
```

| Module | Packaging | What it produces |
|--------|-----------|-----------------|
| `core` | eclipse-plugin | Base classes: `AbstractGenModelGeneratorModule`, `AbstractGenModelGeneratorStandaloneSetup`, `GeneratorConfig`, validation framework |
| `builder` | eclipse-plugin | `{ClassName}Builder.java` (fluent builders), `{Package}Builders.java` (facade), `I{Package}Builder.java` (interface) |
| `helper` | eclipse-plugin | `{Model}ModelResourceSupport.java` with stream-based model access, resource loading, and factory methods |
| `ecore` | eclipse-plugin | Pre-generated builder and helper code for the Ecore metamodel itself |
| `feature` | eclipse-feature | Bundles all four plugins into an installable Eclipse feature |
| `site` | eclipse-repository | P2 update site for Eclipse Marketplace distribution |

## Generated Code Examples

### Builder Pattern

For each concrete EClass in a GenModel, the builder generator produces a fluent API:

```java
Customer customer = CustomerBuilder.create()
    .withName("John Doe")
    .withEmail("john@example.com")
    .withAddress(AddressBuilder.create()
        .withCity("New York")
        .build())
    .build();
```

### Helper / Resource Support

For each GenModel, the helper generator produces stream-based access utilities:

```java
ModelResourceSupport support = MyModelModelResourceSupport.myModelModelResourceSupportBuilder()
    .resourceSet(resourceSet)
    .build();

// Stream all instances of a type
support.getStreamOfMyModelCustomer()
    .filter(c -> c.getName() != null)
    .forEach(System.out::println);
```

## Class Architecture

Each generator module follows the same five-layer pattern, with core providing the abstract base:

```mermaid
classDiagram
    class AbstractGenModelGeneratorModule {
        <<abstract>>
        +bindResourceSet() ResourceSet
        +bindIGenerator2()* Class~IGenerator2~
        +bindIResourceValidator() ResourceValidatorImplExt
    }

    class AbstractGenModelGeneratorStandaloneSetup {
        <<abstract>>
        +createInjectorAndDoEMFRegistration() Injector
        +getGenModelModule()* Module
        #getDynamicModule() Module
    }

    class GeneratorConfig {
        +javaGenPath: String
        +printXmlOnError: Boolean
    }

    class ModelBuilderGeneratorModule {
        +bindIGenerator2() ModelBuilder
    }

    class ModelHelperGeneratorModule {
        +bindIGenerator2() ModelHelper
    }

    class ModelBuilder {
        -modelBuilderFacade: ModelBuilderFacade
        -modelBuilderInterface: ModelBuilderInterface
        +doGenerate(Resource, IFileSystemAccess2, IGeneratorContext)
    }

    class ModelHelper {
        -modelResourceSupport: ModelResourceSupport
        +doGenerate(Resource, IFileSystemAccess2, IGeneratorContext)
    }

    class BuilderConfig {
        +featureModifierMethodPrefix: String
        +nullCheckByDefault: boolean
    }

    class HelperGeneratorConfig {
        +generateUuid: Boolean
    }

    AbstractGenModelGeneratorModule <|-- ModelBuilderGeneratorModule
    AbstractGenModelGeneratorModule <|-- ModelHelperGeneratorModule
    GeneratorConfig <|-- BuilderConfig
    GeneratorConfig <|-- HelperGeneratorConfig
    ModelBuilderGeneratorModule ..> ModelBuilder : binds
    ModelHelperGeneratorModule ..> ModelHelper : binds
```

## Build

```bash
# Full build (requires Java 21, Maven 3.9.4+)
./mvnw clean install

# Skip tests (there are currently no unit tests)
./mvnw clean install -DskipTests

# Build a single module
./mvnw clean install -pl builder
```

> **Note:** JVM memory is pre-configured in `.mvn/jvm.config` (1-2 GB heap). The build uses Tycho 4.0.13 for Eclipse plugin packaging.

## External Dependencies

```mermaid
graph LR
    subgraph "Eclipse Platform"
        EMF["Eclipse EMF<br/><i>Metamodeling</i>"]
        Ecore2["Ecore<br/><i>Model definitions</i>"]
        GenModel["GenModel<br/><i>Code gen config</i>"]
        MWE2["MWE2<br/><i>Workflow engine</i>"]
    end

    subgraph "Xtext / Xtend"
        Xtend["Xtend 2.39.0<br/><i>Template language</i>"]
        Xtext["Xtext 2.39.0<br/><i>Language framework</i>"]
    end

    subgraph "Build"
        Tycho["Tycho 4.0.13<br/><i>Eclipse plugin build</i>"]
        Maven["Maven 3.9.4+<br/><i>Build orchestration</i>"]
    end

    Core2["Generator Core"] --> EMF
    Core2 --> MWE2
    Core2 --> Xtext
    Templates2["Xtend Templates"] --> Xtend
    Templates2 --> GenModel
    Build2["Build System"] --> Tycho
    Build2 --> Maven
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, submission guidelines, and CI workflow details.

## License

This project is licensed under the [Eclipse Public License 2.0](https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.txt).
