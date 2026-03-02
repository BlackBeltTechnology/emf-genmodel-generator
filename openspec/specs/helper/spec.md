# Helper Generator Specification

## Purpose

The helper module generates `ModelResourceSupport` utility classes from EMF GenModel files, providing stream-based access to model elements, resource loading, and factory method generation.

## Architecture

The helper generator follows the core five-layer pattern:

- `HelperGeneratorConfig` extends `GeneratorConfig` — adds `generateUuid: Boolean` (default: `true`)
- `ModelHelperGeneratorModule` extends `AbstractGenModelGeneratorModule` — binds `IGenerator2` to `ModelHelper`
- `ModelHelperGeneratorStandaloneSetup` extends `AbstractGenModelGeneratorStandaloneSetup` — creates injector with `HelperGeneratorConfig`
- `HelperGeneratorWorkflow` extends `AbstractCompositeWorkflowComponent` — MWE2 workflow with `modelDir`, `javaGenPath`, `generateUuid`, `slot` parameters

Template classes:
- `ModelHelper` (IGenerator2) — entry point; delegates to `ModelResourceSupport`
- `ModelResourceSupport` — generates `{Model}ModelResourceSupport.java` with stream APIs, resource management, and factory methods
- `Naming` — extension class for naming conventions

## Requirements

### Requirement: ModelResourceSupport class generation

The generator SHALL produce a `{Model}ModelResourceSupport.java` class for each GenModel.

#### Scenario: Standard model
- **GIVEN** a GenModel named `MyModel` with packages containing EClasses `Customer`, `Order`, and `Product`
- **WHEN** the helper generator runs
- **THEN** a `MyModelModelResourceSupport.java` file is generated

### Requirement: Stream-based model element access

The generated `ModelResourceSupport` class SHALL provide typed stream accessor methods for each concrete EClass in the model.

#### Scenario: Stream accessor for EClass
- **GIVEN** a GenModel containing EClass `Customer`
- **WHEN** `ModelResourceSupport` is generated
- **THEN** a method `getStreamOfCustomer()` (or similar) is available that returns a `Stream<Customer>` of all Customer instances in the resource set

### Requirement: Resource loading and management

The generated class SHALL provide methods for loading and managing EMF resources.

#### Scenario: Resource set integration
- **GIVEN** a `ModelResourceSupport` instance
- **WHEN** a resource set is provided
- **THEN** the support class can stream elements from all resources in the set

### Requirement: Factory method generation

The generated class SHALL include factory methods for creating instances of model elements.

#### Scenario: Create model element
- **GIVEN** a `ModelResourceSupport` for a model with EClass `Customer`
- **WHEN** the factory method for `Customer` is called
- **THEN** a new `Customer` instance is created using the appropriate EMF factory

### Requirement: UUID generation support

When `generateUuid` is `true` (the default), the generated class SHALL include UUID-based identification support.

#### Scenario: UUID generation enabled
- **GIVEN** `HelperGeneratorConfig.generateUuid = true`
- **WHEN** the helper generator runs
- **THEN** the generated `ModelResourceSupport` includes UUID generation for new model elements

#### Scenario: UUID generation disabled
- **GIVEN** `HelperGeneratorConfig.generateUuid = false`
- **WHEN** the helper generator runs
- **THEN** the generated `ModelResourceSupport` does not include UUID generation logic

### Requirement: Builder-style API for ModelResourceSupport

The generated `ModelResourceSupport` class SHALL provide a builder for its own construction.

#### Scenario: Build ModelResourceSupport instance
- **GIVEN** a resource set
- **WHEN** `MyModelModelResourceSupport.myModelModelResourceSupportBuilder().resourceSet(resourceSet).build()` is called
- **THEN** a fully configured `ModelResourceSupport` instance is returned

### Requirement: MWE2 workflow integration

`HelperGeneratorWorkflow` SHALL be invocable as an MWE2 workflow component with configurable `modelDir`, `javaGenPath`, and `generateUuid` parameters.

#### Scenario: Workflow invocation from consumer project
- **GIVEN** a consumer project's MWE2 workflow referencing `HelperGeneratorWorkflow`
- **WHEN** the workflow runs with `modelDir = "model"` and `javaGenPath = "src-gen/java"`
- **THEN** `ModelResourceSupport` classes are generated in `src-gen/java/{package}/` for all GenModels in `model/`
