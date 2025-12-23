# EMF GenModel Generator - Project Documentation

## Project Overview

**Repository:** BlackBeltTechnology/emf-genmodel-generator
**License:** Eclipse Public License 2.0 (EPL-2.0)
**Java Version:** 21
**Build System:** Maven 3.9.4+ with Tycho 4.0.13 (Eclipse build tooling)

This is an Eclipse/Tycho-based code generation project that:
1. **Generates** utility code from EMF GenModels (Ecore metamodels)
2. **Produces** Builder patterns, Helper utilities, and CLI integration code
3. **Supports** MWE2 (Model Workflow Engine) based generation workflows
4. **Provides** Xtend-based templates for flexible code generation
5. **Distributes** via Eclipse P2 update sites for Eclipse plugin integration

## What This Project Does

The EMF GenModel Generator extends EMF's standard code generation capabilities by automatically creating:
- **Builder patterns** for fluent API construction of EMF model instances
- **Helper utilities** for common model operations (validation, navigation, transformation)
- **CLI integration** generating ModelSchema implementations for GraphQL querying via JUDO Model CLI
- **Runtime support** for model instantiation, resource management, and validation

## Directory Structure

```
emf-genmodel-generator/
├── core/                   # Core engine and validation
├── builder/                # Builder pattern generator
├── helper/                 # Helper utilities generator
├── cli/                    # CLI/GraphQL integration generator
├── ecore/                  # Ecore support utilities
├── feature/                # Eclipse feature packaging
├── site/                   # Eclipse P2 update site
└── .github/                # CI/CD workflows (GitHub Actions)
```

## Core Modules

### Generation Engine Layer

| Module | Type | Purpose |
|--------|------|---------|
| `core/` | eclipse-plugin | Core code generation engine using MWE2 workflows. Provides base templates, validation framework, and workflow orchestration. |
| `ecore/` | eclipse-plugin | Ecore support utilities - EMF utilities for model instantiation, resource loading, and builder patterns. |

### Code Generator Modules

| Module | Type | Purpose |
|--------|------|---------|
| `builder/` | eclipse-plugin | Generates Builder pattern classes for fluent EMF model construction. Creates `*Builder` classes with chainable setters and validation. |
| `helper/` | eclipse-plugin | Generates Helper utilities including `ModelResourceSupport` for streaming model elements, factory methods, and model navigation. |
| `cli/` | eclipse-plugin | Generates CLI integration code: `ModelSchema` implementations, FQN resolvers, validators, and Operations classes for GraphQL querying. |

### Distribution Layer

| Module | Type | Purpose |
|--------|------|---------|
| `feature/` | eclipse-feature | Eclipse feature bundling all generator plugins |
| `site/` | eclipse-repository | P2 update site for Eclipse distribution |

## Generated Code Overview

### Builder Generator (`builder/`)

**Input:** GenModel (`*.genmodel` file)
**Output:** For each concrete EClass:
- `{ClassName}Builder.java` - Fluent builder with setters, validation, and build() method
- `{Package}Builders.java` - Facade providing static factory methods
- `I{Package}Builder.java` - Builder interface for polymorphism

**Example:**
```java
// Generated code usage
Customer customer = CustomerBuilder.create()
    .withName("John Doe")
    .withEmail("john@example.com")
    .withAddress(AddressBuilder.create()
        .withCity("New York")
        .build())
    .build();
```

**Templates:** Located in `builder/src/main/java/.../builder/templates/`
- `ModelBuilderBuilder.xtend` - Individual builder classes
- `ModelBuilderFacade.xtend` - Facade factory
- `ModelBuilderInterface.xtend` - Builder interfaces
- `ModelBuilderExtension.xtend` - Common helper methods

### Helper Generator (`helper/`)

**Input:** GenModel
**Output:**
- `{Model}ModelResourceSupport.java` - Stream-based model element access
- Helper methods for model validation, navigation, and transformation

**Key Features:**
- Stream API integration: `model.getStreamOf(Customer.class)`
- Resource management and loading
- Model validation hooks
- Factory method generation

**Templates:** Located in `helper/src/main/java/.../helper/templates/`
- `ModelResourceSupport.xtend` - Main resource support class
- `HelperExtension.xtend` - Helper utilities

### CLI Generator (`cli/`)

**Input:** GenModel
**Output:** For JUDO metamodels (packages starting with `hu.blackbelt.judo.meta`):
- `{Model}ModelSchema.java` - ModelSchema implementation
- `{Model}FqnResolverImpl.java` - FQN resolution
- `{Model}ValidatorImpl.java` - Validation integration
- `{Class}Operations.java` - Per-class operations for GraphQL

**CLI Integration:** The generated classes integrate with [judo-model-cli](https://github.com/BlackBeltTechnology/judo-model-cli) to provide:
- **GraphQL Queries:** `{ esm { count(type: "EntityType") } }`
- **Mutations:** `create`, `update`, `delete` operations (ESM only)
- **Validation:** `validate` command integration
- **FQN Resolution:** Resolve elements by fully qualified names

**Templates:** Located in `cli/src/main/java/.../cli/templates/`
- `ModelSchemaGenerator.xtend` - ModelSchema implementation
- `OperationsImpl.xtend` - Per-class operations
- `CliExtension.xtend` - CLI-specific utilities

## Technology Stack

### Core Technologies
- **Eclipse Modeling Framework (EMF)** - Metamodel foundation
- **Ecore** - Model definition language (`.ecore` files)
- **GenModel** - EMF code generation model (`.genmodel` files)
- **MWE2** (Model Workflow Engine) 2.13.0 - Workflow orchestration
- **Xtend** 2.39.0 - Template-based code generation language
- **Xtext** 2.39.0 - Language framework infrastructure
- **Tycho** 4.0.13 - Eclipse plugin build

### Build & Quality
- **Maven** 3.9.4+ with wrapper
- **GitHub Actions** - CI/CD pipeline
- **JaCoCo** 0.8.12 - Code coverage
- **SonarQube** 3.9.1 - Code quality analysis
- **Lombok** 1.18.34 - Annotation processing

## Build Commands

```bash
# Standard build
mvn clean install
# or with wrapper
./mvnw clean install

# Memory requirements (configured in .mvn/jvm.config)
# -Xms1024m -Xmx2048m

# Skip tests for faster builds
mvn clean install -DskipTests
```

### Maven Profiles

| Profile | Purpose |
|---------|---------|
| `modules` | Includes all 8 submodules (default) |
| `sign-artifacts` | GPG signing for Maven Central release |
| `release-central` | Deploy to Maven Central (sonatype) |
| `release-judong` | Deploy to BlackBelt internal repository |

## Code Generation Workflow

### Integration with Metamodel Projects

This project is used by metamodel projects like `judo-meta-esm`, `judo-meta-psm`, `judo-meta-rdbms`, etc.

**Typical MWE2 Workflow** (in metamodel projects):
```
model/
├── model/
│   ├── {model}.ecore        # Metamodel definition
│   └── {model}.genmodel     # EMF code generation config
└── src/
    └── workflow/
        └── generateModel.mwe2  # MWE2 workflow
```

**Example MWE2 Configuration:**
```xtend
module generateModel

import org.eclipse.emf.mwe.utils.*

var modelDir = "model"
var javaGenPath = "src-gen/java"

Workflow {
    // Load GenModel
    component = org.eclipse.emf.mwe.utils.Reader {
        uri = "${modelDir}/${model}.genmodel"
        slot = "genModel"
    }

    // Generate standard EMF code
    component = org.eclipse.emf.codegen.ecore.genmodel.generator.GenModelGeneratorAdapter {
        genModel = slot:genModel
    }

    // Generate Builders
    component = hu.blackbelt.eclipse.emf.genmodel.generator.builder.BuilderGeneratorWorkflow {
        javaGenPath = javaGenPath
        modelDir = modelDir
    }

    // Generate Helpers
    component = hu.blackbelt.eclipse.emf.genmodel.generator.helper.HelperGeneratorWorkflow {
        javaGenPath = javaGenPath
        modelDir = modelDir
    }

    // Generate CLI integration
    component = hu.blackbelt.eclipse.emf.genmodel.generator.cli.CliGeneratorWorkflow {
        javaGenPath = javaGenPath
        modelDir = modelDir
    }
}
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `pom.xml` | Parent POM with module definitions, Tycho configuration |
| `.mvn/jvm.config` | JVM memory settings for Maven builds |
| `{module}/META-INF/MANIFEST.MF` | OSGi bundle metadata |
| `feature/feature.xml` | Eclipse feature definition |
| `site/category.xml` | P2 update site categories |

## Development Environment

**Required:**
- Java 21 JDK
- Maven 3.9.4+
- Eclipse IDE with:
  - m2e (Maven integration)
  - Xtend/Xtext plugins
  - EMF/Ecore modeling tools
  - MWE2 runtime

**Eclipse Setup:**
1. Import as "Existing Maven Projects"
2. Install Xtext/Xtend plugins from Eclipse Marketplace
3. Run MWE2 workflows with "Run As > MWE2 Workflow"

## Git Workflow

- **Main Branch:** `develop`
- **Versioning:** SNAPSHOT-based (currently 1.1.1-SNAPSHOT)
- **CI/CD:** GitHub Actions builds on every commit
- **Release Process:** Automated via CI to Maven Central and P2 site

## Xtend Template Development

### Understanding Xtend Templates

Xtend is a Java-based language with enhanced template syntax. Key features used in this project:

**Template Syntax:**
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

**Extension Methods:**
- `def methodName(Type it)` - Define method on type
- Can be called as: `object.methodName()` or `methodName(object)`
- Used for reusable helper methods

**Key Patterns:**
- `'''...'''` - Multi-line template strings
- `«expression»` - Expression interpolation in templates
- `«FOR item : collection»...«ENDFOR»` - Template loops
- `«IF condition»...«ENDIF»` - Template conditionals

### Common Extension Classes

| Class | Module | Purpose |
|-------|--------|---------|
| `ModelBuilderExtension` | builder | Common helpers for builder generation (packageName, capitalize, etc.) |
| `CliExtension` | cli | CLI-specific helpers (isJudoModel, isPrimaryModel, path helpers) |
| `HelperExtension` | helper | Helper generation utilities |

## CLI Integration Details

### Generated CLI Components

For JUDO metamodels (packages starting with `hu.blackbelt.judo.meta`):

**ModelSchema (`{Model}ModelSchema.java`):**
- Implements `hu.blackbelt.judo.cli.api.ModelSchema`
- Provides model type identification
- Binds/unbinds to ResourceSets for FQN resolution
- Returns Operations providers for GraphQL querying
- Supports validation and mutations (ESM only)

**FQN Resolver (`{Model}FqnResolverImpl.java`):**
- Resolves Fully Qualified Names to EObjects
- Format: `package::subpackage::ElementName.feature`
- Example: `demo::entities::Customer.name`

**Validator (`{Model}ValidatorImpl.java`):**
- Integrates EVL (Epsilon) or Java validation
- Called by CLI `validate` command

**Operations (`{Class}Operations.java`):**
- Per-class streaming and description generation
- Used by GraphQL queries
- Provides EClass, type name, and streaming methods

### CLI Usage Example

```bash
# Query model via GraphQL
judo-cli graphql "{ esm { count(type: \"EntityType\") } }"

# List all entities
judo-cli graphql "{ entities { fqn name } }"

# Validate model
judo-cli validate

# Create new element (ESM only - mutations enabled)
judo-cli graphql 'mutation { create(type: "EntityType", data: {...}) }'
```

**See Also:** [judo-model-cli documentation](https://github.com/BlackBeltTechnology/judo-model-cli) for complete CLI capabilities.

## Important Notes

1. **Xtend Compilation:** Xtend templates must be compiled before Java compilation
2. **EMF GenModel Understanding:** Familiarize yourself with EMF's GenModel concepts before modifying templates
3. **JUDO-Specific Generation:** CLI code is only generated for JUDO metamodels (`hu.blackbelt.judo.meta.*` packages)
4. **Builder Pattern:** Generated builders validate mandatory features and provide type-safe construction
5. **Extension Inheritance:** CLI and Helper generators extend `ModelBuilderExtension` for shared utilities
6. **Template Testing:** Test template changes by regenerating code in metamodel projects (esm, psm, rdbms, etc.)

## Common Development Tasks

### Adding a New Template

1. Create Xtend class in appropriate module's `templates/` package
2. Add `@Inject extension` for helper methods
3. Implement `doGenerate(GenModel, IFileSystemAccess2)` method
4. Register in module's main generator class (e.g., `Cli.xtend`)
5. Update workflow class to invoke the template

### Modifying Existing Templates

1. Locate template in `{module}/src/main/java/.../templates/`
2. Edit Xtend code - remember template syntax: `'''...'''` and `«...»`
3. Rebuild module: `mvn clean install`
4. Test in metamodel project by running MWE2 workflow
5. Verify generated code compiles and behaves correctly

### Debugging Generated Code

1. **Xtend Compilation Issues:** Check Xtend compiler output in Eclipse
2. **Runtime Errors:** Check generated Java code in `src-gen/` of metamodel projects
3. **MWE2 Workflow Issues:** Enable MWE2 debug logging in workflow file
4. **Template Logic:** Add `println()` statements in Xtend templates for debugging

## Related Projects

- **judo-meta-esm** - Enterprise Service Model metamodel (uses this generator)
- **judo-meta-psm** - Platform Specific Model metamodel
- **judo-meta-asm** - Abstract Syntax Model metamodel
- **judo-meta-rdbms** - Relational Database metamodel
- **judo-meta-ui** - User Interface metamodel
- **judo-model-cli** - CLI tool for GraphQL querying and mutations

## Related Documentation

- `README.adoc` - Basic project information
- `CONTRIBUTING.adoc` - Contribution guidelines
- [EMF Documentation](https://www.eclipse.org/modeling/emf/docs/) - Eclipse Modeling Framework
- [Xtend Documentation](https://www.eclipse.org/xtend/documentation/) - Xtend language reference
- [judo-model-cli/AGENTS.md](https://github.com/BlackBeltTechnology/judo-model-cli) - JUDO Model CLI documentation

## CI/CD Pipeline

**GitHub Actions Workflow** (`.github/workflows/build.yml`):
- Triggered on push to `develop` and `feature/*` branches
- Runs: `mvn clean install`
- Uploads build artifacts
- Runs code quality checks (JaCoCo, SonarQube)

**Release Process:**
1. Update version in `pom.xml` (remove `-SNAPSHOT`)
2. Commit and tag: `git tag v1.1.1`
3. CI builds and deploys to Maven Central
4. Update site deployed to P2 repository
5. Increment version to next SNAPSHOT

## Troubleshooting

### Xtend Compilation Errors
**Issue:** "Xtend compiler not found"
**Solution:** Install Xtext/Xtend plugins in Eclipse

### Tycho Build Failures
**Issue:** "Cannot resolve P2 dependencies"
**Solution:** Check `.mvn/extensions.xml` and P2 repository URLs in `pom.xml`

### Generated Code Not Found
**Issue:** Generated classes missing after build
**Solution:** Run MWE2 workflow first, then Maven build. Check `src-gen/` directories.

### Memory Issues During Build
**Issue:** OutOfMemoryError
**Solution:** Increase heap in `.mvn/jvm.config` or use: `MAVEN_OPTS="-Xmx2g" mvn clean install`

## Contact & Support

- **GitHub Issues:** https://github.com/BlackBeltTechnology/emf-genmodel-generator/issues
- **Organization:** BlackBelt Technology
- **License:** EPL-2.0
