# Builder Generator Specification

## Purpose

The builder module generates fluent Builder pattern classes from EMF GenModel files, producing type-safe, chainable APIs for constructing EMF model instances.

## Architecture

The builder generator follows the core five-layer pattern:

- `BuilderConfig` extends `GeneratorConfig` — adds `featureModifierMethodPrefix` (default: `"with"`) and `nullCheckByDefault` (default: `false`)
- `ModelBuilderGeneratorModule` extends `AbstractGenModelGeneratorModule` — binds `IGenerator2` to `ModelBuilder`
- `ModelBuilderGeneratorStandaloneSetup` extends `AbstractGenModelGeneratorStandaloneSetup` — creates injector with `BuilderConfig`
- `BuilderGeneratorWorkflow` extends `AbstractCompositeWorkflowComponent` — MWE2 workflow with `modelDir`, `javaGenPath`, `featureModifierMethodPrefix`, `nullCheckByDefault`, `slot` parameters

Template classes:
- `ModelBuilder` (IGenerator2) — entry point; delegates to `ModelBuilderFacade` and `ModelBuilderInterface`
- `ModelBuilderFacade` — generates `{Package}Builders.java` facade; delegates per-class generation to `ModelBuilderBuilder`
- `ModelBuilderBuilder` — generates `{ClassName}Builder.java` for each concrete EClass
- `ModelBuilderInterface` — generates `I{Package}Builder.java` interface
- `ModelBuilderExtension` — shared helper methods for naming, path computation, feature filtering, type checking
- `JavaExtensions` — Java-specific utility methods

## Requirements

### Requirement: Builder class generation for concrete EClasses

The generator SHALL produce a `{ClassName}Builder.java` file for each concrete (non-abstract) EClass in the GenModel.

#### Scenario: Simple EClass with structural features
- **GIVEN** a GenModel containing a concrete EClass `Customer` with features `name: String` and `email: String`
- **WHEN** the builder generator runs
- **THEN** a `CustomerBuilder.java` file is generated with `withName(String)` and `withEmail(String)` setter methods that return the builder, and a `build()` method that returns a `Customer` instance

#### Scenario: Abstract EClass is skipped
- **GIVEN** a GenModel containing an abstract EClass `BaseEntity`
- **WHEN** the builder generator runs
- **THEN** no `BaseEntityBuilder.java` file is generated

### Requirement: Fluent setter method naming

Builder setter methods SHALL use the configured `featureModifierMethodPrefix` (default: `"with"`) followed by the capitalized feature name.

#### Scenario: Default prefix
- **GIVEN** `featureModifierMethodPrefix = "with"` and a feature named `firstName`
- **WHEN** the builder is generated
- **THEN** the setter method is named `withFirstName`

#### Scenario: Custom prefix
- **GIVEN** `featureModifierMethodPrefix = "set"` and a feature named `firstName`
- **WHEN** the builder is generated
- **THEN** the setter method is named `setFirstName`

### Requirement: Mandatory feature validation

The `build()` method SHALL validate that all mandatory (required, lower bound >= 1) features have been set.

#### Scenario: Missing mandatory feature
- **GIVEN** a builder for an EClass with mandatory feature `name`
- **WHEN** `build()` is called without calling `withName()`
- **THEN** an exception is thrown indicating that the mandatory feature `name` was not set

#### Scenario: All mandatory features provided
- **GIVEN** a builder for an EClass with mandatory feature `name`
- **WHEN** `withName("John")` is called before `build()`
- **THEN** the `build()` method succeeds and returns a valid instance

### Requirement: Facade class generation

The generator SHALL produce a `{Package}Builders.java` facade class for each GenPackage containing concrete EClasses, providing static factory methods.

#### Scenario: Package with multiple concrete classes
- **GIVEN** a GenPackage `model` containing concrete EClasses `Customer` and `Order`
- **WHEN** the builder generator runs
- **THEN** a `ModelBuilders.java` facade is generated with `createCustomerBuilder()` and `createOrderBuilder()` factory methods, plus decorator methods for existing instances

### Requirement: Builder interface generation

The generator SHALL produce an `I{Package}Builder.java` interface for each GenPackage, enabling polymorphic builder usage.

#### Scenario: Package builder interface
- **GIVEN** a GenPackage `model` with concrete EClasses
- **WHEN** the builder generator runs
- **THEN** an `IModelBuilder.java` interface is generated

### Requirement: Multi-valued feature handling

For multi-valued features (upper bound > 1 or -1), the builder SHALL generate appropriate collection-based setter methods.

#### Scenario: List feature
- **GIVEN** a feature `orders` with type `Order` and upper bound `-1` (unbounded)
- **WHEN** the builder is generated
- **THEN** the builder provides a setter that accepts a collection of `Order` instances

### Requirement: Feature filtering

The generator SHALL only generate setters for non-derived, changeable structural features, as determined by `ModelBuilderExtension.structuralFeatures()`.

#### Scenario: Derived feature excluded
- **GIVEN** an EClass with a derived feature `fullName`
- **WHEN** the builder is generated
- **THEN** no `withFullName()` setter method is generated

### Requirement: MWE2 workflow integration

`BuilderGeneratorWorkflow` SHALL be invocable as an MWE2 workflow component with configurable `modelDir`, `javaGenPath`, `featureModifierMethodPrefix`, and `nullCheckByDefault` parameters.

#### Scenario: Workflow invocation from consumer project
- **GIVEN** a consumer project's MWE2 workflow file referencing `BuilderGeneratorWorkflow`
- **WHEN** the workflow runs with `modelDir = "model"` and `javaGenPath = "src-gen/java"`
- **THEN** builder classes are generated in `src-gen/java/{package}/` for all GenModels in `model/`
