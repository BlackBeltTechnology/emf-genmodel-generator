package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2

/**
 * Generates ModelSchema implementation and SPI service file for each model.
 *
 * The generated ModelSchema implements hu.blackbelt.judo.cli.api.ModelSchema
 * and provides FQN resolution, validation, and EPackage access for
 * cross-model GraphQL querying.
 *
 * @generated
 */
class ModelSchemaGenerator {
    @Inject extension CliExtension

    def doGenerate(GenModel genModel, IFileSystemAccess2 fsa) {
        // Skip non-JUDO models (e.g., base Ecore model in ASM)
        // Only generate ModelSchema for JUDO metamodels
        if (!genModel.isJudoModel) {
            return
        }
        // Skip sub-models (e.g., rdbms-datatypes, rdbms-namemapping)
        // Only generate for primary models to avoid SPI file conflicts
        if (!genModel.isPrimaryModel) {
            return
        }
        fsa.generateFile(genModel.modelSchemaFilePath, generateModelSchema(genModel))
    }

    def generateModelSchema(GenModel it)
    '''
    package «cliPackageName»;

    import java.util.Optional;
    import java.util.stream.Stream;

    import org.eclipse.emf.ecore.EObject;
    import org.eclipse.emf.ecore.EPackage;
    import org.eclipse.emf.ecore.resource.ResourceSet;
    import org.slf4j.Logger;

    import hu.blackbelt.judo.cli.api.ModelSchema;
    import «packageName».runtime.«modelName»Model;
    «FOR pkg : getAllGenPackagesWithConcreteClasses().filter[isJudoPackage]»
    import «pkg.packageFqName».«pkg.getEcorePackage().name.capitalize»Package;
    «ENDFOR»

    /**
     * «modelName» model schema implementation.
     * <p>
     * Implements {@link ModelSchema} interface for cross-model GraphQL querying.
     * <p>
     * Provides:
     * <ul>
     *   <li>FQN resolution via {@link #resolve(String)}</li>
     *   <li>Model validation via {@link #validate(Logger)}</li>
     *   <li>EPackage access via {@link #getEPackages()}</li>
     * </ul>
     *
     * @generated
     */
    public class «modelSchemaClassName» implements ModelSchema {

        private static final «modelSchemaClassName» INSTANCE = new «modelSchemaClassName»();
        private static final String MODEL_TYPE = "«modelName.toLowerCase»";

        // Resolver and validator instances
        private «modelName»FqnResolverImpl fqnResolver;
        private «modelName»ValidatorImpl validator;

        // Reference to the loaded model
        private static «modelName»Model sharedModel;

        // Bound resource set
        private ResourceSet boundResourceSet;

        private «modelSchemaClassName»() {}

        public static «modelSchemaClassName» getInstance() {
            return INSTANCE;
        }

        /**
         * Sets the shared model instance.
         */
        public static void setSharedModel(«modelName»Model model) {
            sharedModel = model;
        }

        /**
         * Gets the shared model instance.
         */
        public static «modelName»Model getSharedModel() {
            return sharedModel;
        }

        // =========================================================================
        // ModelSchema interface implementation
        // =========================================================================

        @Override
        public String getModelType() {
            return MODEL_TYPE;
        }

        @Override
        public boolean isAvailable() {
            return sharedModel != null;
        }

        @Override
        public boolean supportsMutations() {
            return "esm".equals(MODEL_TYPE);
        }

        @Override
        public void bind(ResourceSet resourceSet) {
            this.boundResourceSet = resourceSet;
            if (fqnResolver == null) {
                fqnResolver = new «modelName»FqnResolverImpl();
            }
            fqnResolver.bind(resourceSet);
        }

        @Override
        public void unbind() {
            this.boundResourceSet = null;
            if (fqnResolver != null) {
                fqnResolver.unbind();
            }
        }

        @Override
        public boolean isBound() {
            return fqnResolver != null && fqnResolver.isBound();
        }

        @Override
        public ResourceSet getResourceSet() {
            return boundResourceSet;
        }

        @Override
        public Stream<EPackage> getEPackages() {
            return Stream.of(
                «FOR pkg : getAllGenPackagesWithConcreteClasses().filter[isJudoPackage] SEPARATOR ','»
                «pkg.getEcorePackage().name.capitalize»Package.eINSTANCE
                «ENDFOR»
            );
        }

        @Override
        public Optional<EObject> resolve(String fqn) {
            if (fqnResolver == null) {
                return Optional.empty();
            }
            return fqnResolver.resolve(fqn);
        }

        @Override
        public Optional<String> getFqn(EObject eObject) {
            if (fqnResolver == null) {
                return Optional.empty();
            }
            return fqnResolver.getFqn(eObject);
        }

        @Override
        public Stream<String> getFqnCollection() {
            if (fqnResolver == null) {
                return Stream.empty();
            }
            return fqnResolver.getFqnCollection();
        }

        @Override
        public ValidationResult validate(Logger logger) {
            if (validator == null) {
                validator = new «modelName»ValidatorImpl();
            }
            try {
                validator.validate(logger, sharedModel);
                return ValidationResult.success(MODEL_TYPE);
            } catch (Exception e) {
                return ValidationResult.failure(MODEL_TYPE, e.getMessage(), e);
            }
        }
    }
    '''
}
