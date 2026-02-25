# EMF GenModel Generator - Project Documentation

## Project Overview

**Repository:** BlackBeltTechnology/emf-genmodel-generator
**License:** Eclipse Public License 2.0 (EPL-2.0)
**Java Version:** 21
**Build System:** Maven 3.9.4+ with Tycho 4.0.13 (Eclipse plugin build tooling)

This is an Eclipse/Tycho-based code generation project that:
1. **Generates** utility code from EMF GenModels (`.genmodel` files derived from Ecore metamodels)
2. **Produces** Builder pattern classes for fluent EMF model construction
3. **Produces** Helper utilities (`ModelResourceSupport`) for stream-based model access
4. **Integrates** into MWE2 (Model Workflow Engine) workflows used by downstream metamodel projects
5. **Distributes** as Eclipse plugins via P2 update sites

## Directory Structure

```
emf-genmodel-generator/
├── core/                   # Base generation engine, validation, Guice DI
├── builder/                # Builder pattern code generator
├── helper/                 # Helper/ResourceSupport code generator
├── ecore/                  # Self-hosted: generates builders+helpers for Ecore itself
├── feature/                # Eclipse feature packaging (bundles all plugins)
├── site/                   # Eclipse P2 update site for distribution
├── .github/                # GitHub Actions CI/CD workflows
├── .mvn/                   # Maven wrapper config, JVM settings, extensions
└── pom.xml                 # Parent POM with Tycho configuration
```

## Core Modules

### Generation Engine Layer

| Module | Packaging | Purpose |
|--------|-----------|---------|
| `core/` | eclipse-plugin | Base code generation engine. Provides `AbstractGenModelGeneratorModule` (Guice DI config), `AbstractGenModelGeneratorStandaloneSetup` (injector creation), `GeneratorConfig` (base config), and validation framework. All generator modules extend these base classes. |
| `builder/` | eclipse-plugin | Generates Builder pattern classes from GenModels. For each concrete EClass, produces `{ClassName}Builder.java` (fluent builder), `{Package}Builders.java` (facade with factory methods), and `I{Package}Builder.java` (builder interface). |
| `helper/` | eclipse-plugin | Generates `{Model}ModelResourceSupport.java` with stream-based model element access, resource loading, factory methods, and optional UUID generation. |

### Self-Hosting Layer

| Module | Packaging | Purpose |
|--------|-----------|---------|
| `ecore/` | eclipse-plugin | Runs the builder and helper generators on the Ecore metamodel itself during `generate-sources` phase. Output goes to `src-gen/`. Provides `EcoreResourceImpl` and `EcoreResourceFactoryImpl` for Ecore resource handling. |

### Distribution Layer

| Module | Packaging | Purpose |
|--------|-----------|---------|
| `feature/` | eclipse-feature | Bundles `core`, `builder`, `helper`, and `ecore` plugins into an installable Eclipse feature |
| `site/` | eclipse-repository | P2 update site for Eclipse Marketplace distribution |

## Architecture

### Five-Layer Generator Pattern

Each generator module (`builder/`, `helper/`) follows an identical five-layer architecture:

1. **Config** (Xtend `@Data` class extending `GeneratorConfig`) — Module-specific configuration properties
2. **Module** (Java class extending `AbstractGenModelGeneratorModule`) — Guice bindings, most importantly binding `IGenerator2` to the main template class
3. **StandaloneSetup** (Java class extending `AbstractGenModelGeneratorStandaloneSetup`) — Creates Guice injector, registers EMF resource factories, binds config instances
4. **Workflow** (Xtend class extending `AbstractCompositeWorkflowComponent`) — MWE2 workflow component that wires Reader → GeneratorComponent
5. **Templates** (Xtend classes in `templates/` package) — The `IGenerator2` implementation and its delegate template classes that produce Java source

### Class Hierarchy

**Core base classes:**
- `AbstractGenModelGeneratorModule` → binds `IGenerator2` (abstract), `ResourceSet`, `IResourceFactory`, `IResourceValidator`, `IOutputConfigurationProvider`
- `AbstractGenModelGeneratorStandaloneSetup` → creates Guice injector, registers `.genmodel` extension
- `GeneratorConfig` → `javaGenPath: String`, `printXmlOnError: Boolean`

**Builder module:**
- `ModelBuilderGeneratorModule` extends `AbstractGenModelGeneratorModule` → binds `IGenerator2` to `ModelBuilder`
- `ModelBuilderGeneratorStandaloneSetup` extends `AbstractGenModelGeneratorStandaloneSetup` → binds `BuilderConfig`
- `BuilderConfig` extends `GeneratorConfig` → adds `featureModifierMethodPrefix` (default: `"with"`), `nullCheckByDefault`
- `BuilderGeneratorWorkflow` extends `AbstractCompositeWorkflowComponent`
- `ModelBuilder` implements `IGenerator2` → injects `ModelBuilderFacade`, `ModelBuilderInterface`
- `ModelBuilderFacade` → injects `ModelBuilderBuilder`, `ModelBuilderExtension`; generates facade classes
- `ModelBuilderBuilder` → generates individual builder classes per concrete EClass
- `ModelBuilderInterface` → generates builder interface per package
- `ModelBuilderExtension` → shared helper methods (naming, paths, feature filtering, type checking)

**Helper module:**
- `ModelHelperGeneratorModule` extends `AbstractGenModelGeneratorModule` → binds `IGenerator2` to `ModelHelper`
- `ModelHelperGeneratorStandaloneSetup` extends `AbstractGenModelGeneratorStandaloneSetup` → binds `HelperGeneratorConfig`
- `HelperGeneratorConfig` extends `GeneratorConfig` → adds `generateUuid: Boolean`
- `HelperGeneratorWorkflow` extends `AbstractCompositeWorkflowComponent`
- `ModelHelper` implements `IGenerator2` → injects `ModelResourceSupport`
- `ModelResourceSupport` → generates `{Model}ModelResourceSupport.java`; injects `Naming` extension

### Generation Flow

MWE2 workflows orchestrate the pipeline:

1. **Workflow component** receives `modelDir` and `javaGenPath` parameters
2. **StandaloneSetup** creates Guice injector with module-specific bindings
3. **Reader** component loads `.genmodel` files from `modelDir` into a resource slot
4. **GeneratorComponent** invokes `IGenerator2.doGenerate(resource, fsa, context)`
5. **IGenerator2 implementation** iterates over `GenModel` objects in the resource
6. **Template classes** use Xtend rich strings to produce Java source, written via `IFileSystemAccess2`

### How Consumer Projects Use This

Downstream metamodel projects (e.g., `judo-meta-esm`, `judo-meta-psm`, `judo-meta-rdbms`) define MWE2 workflows that invoke the generator:

```
component = hu.blackbelt.eclipse.emf.genmodel.generator.builder.BuilderGeneratorWorkflow {
    javaGenPath = "src-gen/java"
    modelDir = "model"
}
component = hu.blackbelt.eclipse.emf.genmodel.generator.helper.HelperGeneratorWorkflow {
    javaGenPath = "src-gen/java"
    modelDir = "model"
}
```

## Generated Code Overview

### Builder Generator Output

For each concrete EClass in a GenModel:
- `{ClassName}Builder.java` — Fluent builder with `with{Feature}()` setters, `build()` method, mandatory field validation
- `{Package}Builders.java` — Facade with static factory methods and decorator methods
- `I{Package}Builder.java` — Builder interface for polymorphic construction

```java
Customer customer = CustomerBuilder.create()
    .withName("John Doe")
    .withEmail("john@example.com")
    .build();
```

### Helper Generator Output

For each GenModel:
- `{Model}ModelResourceSupport.java` — Stream-based model element access, resource loading, factory methods, optional UUID generation

## Technology Stack

### Core Technologies
- **Eclipse Modeling Framework (EMF)** — Metamodel foundation (`org.eclipse.emf.codegen.ecore`)
- **Ecore** — Model definition language (`.ecore` files)
- **GenModel** — EMF code generation model (`.genmodel` files)
- **MWE2** (Model Workflow Engine 2) — Workflow orchestration (`org.eclipse.emf.mwe2.launch`)
- **Xtend** 2.39.0 — Template-based code generation language
- **Xtext** 2.39.0 — Language framework infrastructure (provides `IGenerator2`, `ISetup`, DI)
- **Tycho** 4.0.13 — Eclipse plugin Maven build

### Build & Quality
- **Maven** 3.9.4+ with wrapper (`./mvnw`)
- **GitHub Actions** — CI/CD pipeline on custom `judong` runner
- **JaCoCo** 0.8.12 — Code coverage
- **SonarQube** 3.9.1 — Code quality analysis
- **Lombok** 1.18.34 — Annotation processing
- **Logback** 1.5.12 — Logging (test config at root)

## Build Commands

```bash
# Standard build
./mvnw clean install

# Skip tests (no tests currently exist, but saves plugin overhead)
./mvnw clean install -DskipTests

# Build a single module
./mvnw clean install -pl builder

# Memory is configured in .mvn/jvm.config: -Xms1024m -Xmx2048m
```

### Maven Profiles

| Profile | Purpose |
|---------|---------|
| `modules` | Includes all 6 submodules (default, active when `skipModules` is not `true`) |
| `sign-artifacts` | GPG signing for release artifacts |
| `release-dummy` | Local file:// distribution (for testing) |
| `release-judong` | Deploy to BlackBelt Nexus (`nexus.judo.technology`) |
| `release-central` | Deploy to Maven Central via Sonatype OSSRH |
| `release-p2-judong` | Upload P2 site to BlackBelt Nexus |
| `generate-github-asciidoc-diagrams` | Generate diagram images from AsciiDoc |
| `update-source-code-license` | Update EPL-2.0 license headers in source files |

## Key Configuration Files

| File | Purpose |
|------|---------|
| `pom.xml` | Parent POM: module list, Tycho config, P2 repositories, all profiles |
| `.mvn/jvm.config` | JVM memory settings, `--add-opens` for Tycho, P2 mirror disable |
| `.mvn/extensions.xml` | Maven Wagon extensions (file, WebDAV/Jackrabbit) for deployment |
| `{module}/META-INF/MANIFEST.MF` | OSGi bundle metadata: dependencies, exported packages |
| `{module}/src/main/resources/workflow/*.mwe2` | MWE2 workflow definitions |
| `feature/feature.xml` | Eclipse feature definition (which plugins to bundle) |
| `site/category.xml` | P2 update site category definitions |
| `logback-test.xml` | Root-level test logging configuration |

## Development Environment

**Required:**
- Java 21 JDK (Zulu recommended, used by CI)
- Maven 3.9.4+ (or use `./mvnw`)

**Optional (for Xtend template editing):**
- Eclipse IDE with:
  - m2e (Maven integration)
  - Xtend/Xtext plugins from Eclipse Marketplace
  - EMF/Ecore modeling tools
  - MWE2 runtime

**Eclipse Setup:**
1. Import as "Existing Maven Projects"
2. Install Xtext/Xtend plugins from Eclipse Marketplace
3. Run MWE2 workflows with "Run As > MWE2 Workflow"

## Xtend Template Development

### Template Syntax

Xtend uses rich string syntax with guillemet characters:

```xtend
def generateClass(GenClass it) '''
package «genPackage.packageFqName»;

public class «name»Builder {
    «FOR feature : structuralFeatures»
    private «feature.type» «feature.name»;
    «ENDFOR»

    «FOR feature : structuralFeatures»
    public «name»Builder with«feature.name.capitalize»(«feature.type» «feature.name») {
        this.«feature.name» = «feature.name»;
        return this;
    }
    «ENDFOR»
}
'''
```

**Key patterns:**
- `'''...'''` — Multi-line template strings
- `«expression»` — Expression interpolation (guillemets, not angle brackets)
- `«FOR item : collection»...«ENDFOR»` — Template loops
- `«IF condition»...«ENDIF»` — Template conditionals
- `def methodName(Type it) '''...'''` — Extension methods (callable as `object.methodName()`)

### Template File Locations

| Module | Templates Directory | Key Files |
|--------|-------------------|-----------|
| `builder/` | `src/main/java/hu/blackbelt/eclipse/emf/genmodel/generator/builder/templates/` | `ModelBuilder.xtend` (entry point), `ModelBuilderBuilder.xtend`, `ModelBuilderFacade.xtend`, `ModelBuilderInterface.xtend`, `ModelBuilderExtension.xtend` |
| `helper/` | `src/main/java/hu/blackbelt/eclipse/emf/genmodel/generator/helper/templates/` | `ModelHelper.xtend` (entry point), `ModelResourceSupport.xtend`, `Naming.xtend` |

### Common Development Tasks

**Adding a new template:**
1. Create Xtend class in the appropriate module's `templates/` package
2. Add `@Inject extension` for helper methods
3. Implement generation logic using Xtend rich strings
4. Inject and call from the module's `IGenerator2` implementation (e.g., `ModelBuilder.xtend`)

**Modifying existing templates:**
1. Edit the `.xtend` file — Xtend compiles to Java in `xtend-gen/` (never edit those)
2. Rebuild: `./mvnw clean install -pl <module>`
3. Test by running the MWE2 workflow in a consumer metamodel project
4. Verify generated code in consumer's `src-gen/` compiles correctly

**Debugging:**
1. Check Xtend compiler output in Eclipse for compilation issues
2. Check generated Java in consumer project's `src-gen/` for runtime errors
3. Add `println()` in Xtend templates for debug output during generation
4. Enable MWE2 debug logging in the workflow file

## Git Workflow

- **Main Branch:** `develop`
- **Versioning:** CI-friendly with `${revision}` property (currently 1.1.1-SNAPSHOT)
- **Branch naming:** GitFlow-based — `feature/JNG-xxx`, `release/x.y.z`, `bugfix/JNG-xxx`, `hotfix/JNG-xxx`
- **Commit rule:** Every commit must reference a JIRA ticket (`JNG-xxx`)
- **CI/CD:** GitHub Actions on custom `judong` runner, triggered on push to `develop` and PRs
- **Release:** Automated via `release.yml` workflow — creates PRs to `master` and `develop`, signs and deploys artifacts

## Related Projects

- **judo-meta-esm** — Enterprise Service Model metamodel (uses this generator)
- **judo-meta-psm** — Platform Specific Model metamodel
- **judo-meta-asm** — Abstract Syntax Model metamodel
- **judo-meta-rdbms** — Relational Database metamodel
- **judo-meta-ui** — User Interface metamodel

## Related Documentation

- [README.md](README.md) — Project overview with architecture diagrams
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development setup and contribution guidelines
- [.github/CIFLOW.md](.github/CIFLOW.md) — CI/CD pipeline and branching documentation
- [EMF Documentation](https://www.eclipse.org/modeling/emf/docs/) — Eclipse Modeling Framework
- [Xtend Documentation](https://www.eclipse.org/xtend/documentation/) — Xtend language reference

## Troubleshooting

### Xtend Compilation Errors
**Issue:** "Xtend compiler not found"
**Solution:** Install Xtext/Xtend plugins in Eclipse, or ensure `xtend-maven-plugin` 2.39.0 is resolved

### Tycho Build Failures
**Issue:** "Cannot resolve P2 dependencies"
**Solution:** Check P2 repository URLs in `pom.xml` `<repositories>` section and `.mvn/extensions.xml`

### Generated Code Not Found
**Issue:** Generated classes missing after build
**Solution:** For the `ecore/` module, ensure the MWE2 workflow runs during `generate-sources`. For consumer projects, run MWE2 workflow first, then build. Check `src-gen/` directories.

### Memory Issues During Build
**Issue:** OutOfMemoryError
**Solution:** Increase heap in `.mvn/jvm.config` (currently `-Xms1024m -Xmx2048m`) or override with `MAVEN_OPTS="-Xmx3g" ./mvnw clean install`
