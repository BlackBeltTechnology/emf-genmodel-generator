# Ecore Support Module Specification

## Purpose

The ecore module provides EMF resource utilities for Ecore model handling and self-hosts the builder and helper generators by running them on the Ecore metamodel itself during the build, producing builder and helper code for Ecore types in `src-gen/`.

## Architecture

The module has two roles:

**Runtime support classes (hand-written):**
- `EcoreResourceImpl` extends `XMIResourceImpl` — Wrapper for loading Ecore resources
- `EcoreResourceFactoryImpl` — Factory that creates `EcoreResourceImpl` instances

**Self-hosted generation (build-time):**
- `EcoreGenerator.mwe2` workflow runs during Maven `generate-sources` phase via `exec-maven-plugin`
- The workflow cleans `src-gen/`, then runs `HelperGeneratorWorkflow` and `BuilderGeneratorWorkflow` on the Ecore model files (`Ecore.ecore` / `Ecore.genmodel`)
- Output goes to `src-gen/` and is compiled as part of the module

**Model files:**
- `model/Ecore.ecore` — The Ecore metamodel definition
- `model/Ecore.genmodel` — GenModel for the Ecore metamodel
- `model/Ecore.aird` — Sirius diagram representation

**Exported packages:**
- `org.eclipse.emf.ecore.support`
- `org.eclipse.emf.ecore.util`
- `org.eclipse.emf.ecore.util.builder`

## Requirements

### Requirement: Ecore resource loading

`EcoreResourceImpl` SHALL provide XMI-based resource loading for Ecore models.

#### Scenario: Create Ecore resource with URI
- **GIVEN** a URI pointing to an `.ecore` file
- **WHEN** `EcoreResourceFactoryImpl.createResource(uri)` is called
- **THEN** an `EcoreResourceImpl` instance is returned that can load and parse the Ecore model

### Requirement: Self-hosted builder generation

The build SHALL run `BuilderGeneratorWorkflow` on the Ecore metamodel during `generate-sources` phase, producing builder classes for all concrete Ecore EClasses.

#### Scenario: Build generates Ecore builders
- **WHEN** `./mvnw clean install -pl ecore` is executed
- **THEN** builder classes (e.g., `EClassBuilder`, `EAttributeBuilder`, `EPackageBuilder`) are generated in `src-gen/` under `org.eclipse.emf.ecore.util.builder`

### Requirement: Self-hosted helper generation

The build SHALL run `HelperGeneratorWorkflow` on the Ecore metamodel during `generate-sources` phase, producing `ModelResourceSupport` for Ecore types.

#### Scenario: Build generates Ecore helpers
- **WHEN** `./mvnw clean install -pl ecore` is executed
- **THEN** `EcoreModelResourceSupport.java` (or equivalent) is generated in `src-gen/` with stream-based access to Ecore model elements

### Requirement: Clean regeneration

The MWE2 workflow SHALL clean the `src-gen/` directory before generating, ensuring no stale files remain.

#### Scenario: Stale files are removed
- **GIVEN** a previously generated file in `src-gen/` that no longer corresponds to any EClass
- **WHEN** the build runs
- **THEN** the stale file is removed and only current generated files exist

### Requirement: OSGi bundle exports

The module SHALL export `org.eclipse.emf.ecore.support`, `org.eclipse.emf.ecore.util`, and `org.eclipse.emf.ecore.util.builder` packages via its OSGi `MANIFEST.MF`, making the generated code available to dependent bundles.

#### Scenario: Bundle resolution
- **GIVEN** an Eclipse plugin that depends on `hu.blackbelt.eclipse.emf.genmodel.generator.ecore`
- **WHEN** the bundle is resolved
- **THEN** classes from `org.eclipse.emf.ecore.util.builder` are available on the classpath
