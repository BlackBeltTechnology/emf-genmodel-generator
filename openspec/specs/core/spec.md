# Core Generation Engine Specification

## Purpose

The core module provides the base infrastructure for all EMF GenModel code generators, including Guice dependency injection configuration, MWE2 workflow integration, resource loading, validation, and output configuration.

## Architecture

The core module defines abstract base classes that all generator modules extend:

- `AbstractGenModelGeneratorModule` — Guice module that binds core services (`ResourceSet`, `IResourceFactory`, `IResourceValidator`, `IOutputConfigurationProvider`) and declares an abstract `bindIGenerator2()` method for subclasses
- `AbstractGenModelGeneratorStandaloneSetup` — Implements `ISetup` to create a Guice injector, register EMF resource factories for `.genmodel` files, and bind `GeneratorConfig` instances
- `GeneratorConfig` — Base configuration with `javaGenPath` (output directory) and `printXmlOnError` (debug flag)
- `GenModelResourceFactory` — EMF resource factory for loading `.genmodel` files
- `OutputConfigurationProvider` — Configures the output directory for generated code
- `ResourceValidatorImplExt` — Extended Xtext resource validator
- `BasicConstraints` — Declarative validation constraints for GenModel resources

## Requirements

### Requirement: Guice dependency injection configuration

The `AbstractGenModelGeneratorModule` SHALL provide default bindings for all services required by the generation pipeline, while allowing subclasses to override `bindIGenerator2()` to specify their concrete generator.

#### Scenario: Builder module extends core module
- **GIVEN** a `ModelBuilderGeneratorModule` that extends `AbstractGenModelGeneratorModule`
- **WHEN** the module is loaded by the Guice injector
- **THEN** `IGenerator2` is bound to `ModelBuilder`, and all other bindings (ResourceSet, IResourceFactory, etc.) use the core defaults

#### Scenario: Helper module extends core module
- **GIVEN** a `ModelHelperGeneratorModule` that extends `AbstractGenModelGeneratorModule`
- **WHEN** the module is loaded by the Guice injector
- **THEN** `IGenerator2` is bound to `ModelHelper`, and all other bindings use the core defaults

### Requirement: Standalone setup and injector creation

`AbstractGenModelGeneratorStandaloneSetup` SHALL create a fully configured Guice injector that registers EMF resource factories for `.genmodel` files and binds both the generator module and dynamic configuration module.

#### Scenario: Injector creation with config binding
- **GIVEN** a `GeneratorConfig` instance with `javaGenPath = "src-gen/java"`
- **WHEN** `createInjectorAndDoEMFRegistration()` is called
- **THEN** the returned injector resolves `GeneratorConfig` to the provided instance and the `.genmodel` extension is registered with `GenModelResourceFactory`

### Requirement: GenModel resource loading

`GenModelResourceFactory` SHALL create EMF resources capable of loading and parsing `.genmodel` files.

#### Scenario: Load a valid GenModel file
- **GIVEN** a `.genmodel` file exists at a given URI
- **WHEN** the resource factory creates a resource for that URI
- **THEN** the resource can be loaded and contains `GenModel` EObjects

### Requirement: Output configuration

`OutputConfigurationProvider` SHALL provide output configurations that direct generated code to the path specified in `GeneratorConfig.javaGenPath`.

#### Scenario: Custom output path
- **GIVEN** a `GeneratorConfig` with `javaGenPath = "src-gen/custom"`
- **WHEN** the output configuration is queried
- **THEN** generated files are written to the `src-gen/custom` directory

### Requirement: Resource validation

`ResourceValidatorImplExt` and `BasicConstraints` SHALL validate GenModel resources before generation proceeds.

#### Scenario: Valid GenModel passes validation
- **GIVEN** a well-formed `.genmodel` resource
- **WHEN** validation is performed
- **THEN** no errors are reported and generation proceeds

#### Scenario: Invalid GenModel fails validation
- **GIVEN** a malformed `.genmodel` resource
- **WHEN** validation is performed
- **THEN** validation errors are reported
