package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.emf.codegen.ecore.genmodel.GenClass

class OperationsImpl {
    @Inject extension CliExtension    

    def doGenerate(GenModel genModel, IFileSystemAccess2 fsa) {
    	genModel.allGenPackagesWithConcreteClasses
        .forEach[
            genClasses
            .filter[isBuilderType]
            .forEach[
                fsa.generateFile(operationsImplFilePath, generateOperationsImpl(it))
            ]
        ]
    }

    def generateOperationsImpl(GenClass it)
    '''
    package «cliOperationsImplPackage»;
    
    import java.util.ArrayList;
    import java.util.LinkedHashMap;
    import java.util.List;
    import java.util.Map;
    import java.util.Optional;
    import java.util.stream.Collectors;
    import java.util.stream.Stream;
    
    import org.eclipse.emf.ecore.EClass;
    import org.eclipse.emf.ecore.EObject;
    import org.eclipse.emf.ecore.EReference;
    import org.eclipse.emf.ecore.EStructuralFeature;
    
    import «genModel.cliPackageName».FqnResolver;
    import «genModel.cliPackageName».Operations;
    import «genModel.cliPackageName».«genModel.cliClassName»;
    
    import «builderBuilderPackage».«builderBuilderName»;
    import «genModel.packageName».runtime.«genModel.modelName»Model;
    import «genModel.cliPackageName».AbstractOperations;

    /**
     * Operations implementation for «name».
     * Provides GraphQL query and mutation support backed by builders.
     *
     * @generated
     */
    public class «name.capitalize»Operations extends AbstractOperations implements Operations {

        private static final «name.capitalize»Operations INSTANCE = new «name.capitalize»Operations();
        private static final String EOBJECT_TYPE = "«eObjectTypeName»";

        private «name.capitalize»Operations() {}

        public static «name.capitalize»Operations getInstance() {
            return INSTANCE;
        }
        
        @Override
        protected String getEObjectType() {
            return EOBJECT_TYPE;
        }
        
        @Override
        protected «genModel.modelName»Model getModel() {
            return «genModel.cliClassName».sharedModel;
        }

        @Override
        public EClass getEClass() {
            return «genPackage.packageFqName».«genPackage.packageInterfaceName».eINSTANCE.get«name»();
        }

        @Override
        protected EObject doCreate(FqnResolver resolver, Map<String, Object> structuralFeatures) {
            try {
                Map<String, Object> working = new LinkedHashMap<>(structuralFeatures);
                Object containerObj = working.remove(CONTAINER_KEY);
                String containerFqn = containerObj != null ? containerObj.toString() : null;

                Map<String, Object> resolvedValues = resolveObjectValues(resolver, working, getEClass());

                «modelJavaFqName» instance = «builderBuilderName»
                    .create(true)
                    .withStructuralFeatures(resolvedValues)
                    .build();

                EObject container = resolveContainer(resolver, containerFqn);
                if (!attachToContainer(container, instance)) {
                    getModel().addContent(instance);
                }

                return instance;
            } catch (Exception ex) {
                fail("create", ex);
                return null;
            }
        }

        @Override
        protected boolean doUpdate(FqnResolver resolver, EObject instance, Map<String, Object> structuralFeatures) {
            try {
                Map<String, Object> working = new LinkedHashMap<>(structuralFeatures);
                working.remove(CONTAINER_KEY); // Container changes not supported in update

                Map<String, Object> resolvedValues = resolveObjectValues(resolver, working, getEClass());

                «builderBuilderName» builder = «builderBuilderName».use((«modelJavaFqName») instance, true);
                builder.withStructuralFeatures(resolvedValues);
                builder.build();

                return true;
            } catch (Exception ex) {
                fail("update", ex);
                return false;
            }
        }

        @Override
        protected Optional<? extends EObject> doResolve(FqnResolver resolver, String fqn) {
            if (fqn == null || fqn.isBlank()) {
                return Optional.empty();
            }
            return resolver.resolve(fqn)
                    .filter(«modelJavaFqName».class::isInstance)
                    .map(«modelJavaFqName».class::cast);
        }

        @Override
        public int create(FqnResolver resolver, Map<String, String> structuralFeatures) {
            try {
                Map<String, String> working = sanitize(structuralFeatures);
                String containerFqn = working.remove(CONTAINER_KEY);

                Map<String, Object> objectFeatures = new LinkedHashMap<>();
                working.forEach((k, v) -> objectFeatures.put(k, v));
                if (containerFqn != null) {
                    objectFeatures.put(CONTAINER_KEY, containerFqn);
                }

                EObject instance = doCreate(resolver, objectFeatures);
                if (instance == null) {
                    return 1;
                }
                resolver.bind(getModel().getResourceSet());
                
                System.out.printf("create " + EOBJECT_TYPE);
                working.forEach((key, value) -> System.out.printf(" --attr %s=%s", key, value));
                if (containerFqn != null) {
                    System.out.printf(" --attr container=" + containerFqn);
                }
                System.out.println();
                
                return 0;
            } catch (Exception ex) {
                return fail("create", ex);
            }
        }

        @Override
        public int execute(FqnResolver resolver, String graphqlQuery, Map<String, Object> variables) {
            try {
                List<Map<String, Object>> rows = streamEObjects()
                        .map(eObject -> describe(resolver, eObject))
                        .collect(Collectors.toList());

                return executeGraphQL(resolver, graphqlQuery, variables, rows);
            } catch (Exception ex) {
                return fail("execute", ex);
            }
        }

        @Override
        public int update(FqnResolver resolver, String identifier, Map<String, String> structuralFeaturesToSet, Map<String, String> structuralFeaturesToRemove) {
            try {
                Optional<? extends EObject> eObjectOpt = doResolve(resolver, identifier);
                if (eObjectOpt.isEmpty()) {
                    System.err.printf("Could not find %s '%s'%n", EOBJECT_TYPE, identifier);
                    return 1;
                }
                EObject instance = eObjectOpt.get();

                Map<String, String> toSet = sanitize(structuralFeaturesToSet);
                Map<String, String> toRemove = sanitize(structuralFeaturesToRemove);

                Map<String, Object> objectFeatures = new LinkedHashMap<>();
                toSet.forEach((k, v) -> objectFeatures.put(k, v));

                if (!doUpdate(resolver, instance, objectFeatures)) {
                    return 1;
                }
                removeStructuralFeatureValues(instance, toRemove);
                
                System.out.printf("update %s", identifier);
                if (structuralFeaturesToSet != null) {
                    structuralFeaturesToSet.forEach((key, value) -> System.out.printf(" --attr %s=%s", key, value));
                }
                if (structuralFeaturesToRemove != null) {
                    structuralFeaturesToRemove.forEach((key, value) -> System.out.printf(" --remove-attr %s=%s", key, value));
                }
                System.out.println();
                
                return 0;
            } catch (Exception ex) {
                return fail("update", ex);
            }
        }

        @Override
        public int delete(FqnResolver resolver, String identifier, boolean skipConfirm) {
            try {
                Optional<? extends EObject> eObjectOpt = doResolve(resolver, identifier);
                if (eObjectOpt.isEmpty()) {
                    System.err.printf("Could not find %s '%s'%n", EOBJECT_TYPE, identifier);
                    return 1;
                }
                if (!skipConfirm) {
                    System.out.println("Confirmation required. Re-run with --yes to delete.");
                    return 1;
                }

                removeFromContainer(eObjectOpt.get());
                System.out.printf("delete %s %s --yes%n", EOBJECT_TYPE, identifier);
                return 0;
            } catch (Exception ex) {
                return fail("delete", ex);
            }
        }

        private Stream<«modelJavaFqName»> streamEObjects() {
            return getModel().get«genModel.modelName»ModelResourceSupport().getStreamOf(«modelJavaFqName».class);
        }
    }
    '''
}
