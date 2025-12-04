package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.emf.codegen.ecore.genmodel.GenClass

class Operations {
    @Inject extension CliExtension    

    def doGenerate(GenModel genModel, IFileSystemAccess2 fsa) {
    	fsa.generateFile(genModel.cliOperationsFilePath, generateOperations(genModel));
    	fsa.generateFile(genModel.abstractOperationsFilePath, generateAbstractOperations(genModel));
    	genModel.allGenPackagesWithConcreteClasses
        .forEach[
            genClasses
            .filter[isBuilderType]
            .forEach[
                fsa.generateFile(operationsImplFilePath, generateOperationsImpl(it))
            ]
        ]
    }
    
    def generateOperations(GenModel it) 
    '''
    package «cliPackageName»;
    
    import java.util.Map;

    /**
     * Common interface for all EObject operations.
     *
     * @generated
     */
    public interface Operations {
        /**
         * Create a new EObject instance.
         */
    	int create(FqnResolver resolver, Map<String, String> structuralFeatures);

        /**
         * Execute a GraphQL query against the EObject instances.
         * The query should follow GraphQL syntax. To 
         * { __schema { types { name } } } or { __type(name: "TypeName") { fields { name } } }
         * to explore the schema.
         *
         * @param resolver the FQN resolver for resolving references
         * @param graphqlQuery the GraphQL query string
         * @return exit code (0 for success)
         */
        int query(FqnResolver resolver, String graphqlQuery);

        /**
         * Update an EObject instance.
         */
        int update(FqnResolver resolver, String identifier, Map<String, String> structuralFeaturesToSet, Map<String, String> structuralFeaturesToRemove);
        
        /**
         * Delete an EObject instance.
         */
        int delete(FqnResolver resolver, String identifier, boolean skipConfirm);
    }
    '''
    
    def generateAbstractOperations(GenModel it)
    '''
    package «cliPackageName»;
    
    import java.util.Arrays;
    import java.util.Collections;
    import java.util.LinkedHashMap;
    import java.util.List;
    import java.util.Map;
    import java.util.Objects;
    import java.util.stream.Collectors;
    
    import org.eclipse.emf.common.util.EList;
    import org.eclipse.emf.ecore.EClass;
    import org.eclipse.emf.ecore.EObject;
    import org.eclipse.emf.ecore.EReference;
    import org.eclipse.emf.ecore.EStructuralFeature;
    
    import graphql.ExecutionInput;
    import graphql.ExecutionResult;
    import graphql.GraphQL;
    import graphql.Scalars;
    import graphql.schema.DataFetcher;
    import graphql.schema.FieldCoordinates;
    import graphql.schema.GraphQLCodeRegistry;
    import graphql.schema.GraphQLFieldDefinition;
    import graphql.schema.GraphQLList;
    import graphql.schema.GraphQLObjectType;
    import graphql.schema.GraphQLSchema;
    
    import com.fasterxml.jackson.databind.ObjectMapper;
    import com.fasterxml.jackson.databind.SerializationFeature;
    
    import «packageName».runtime.«modelName»Model;

    /**
     * Abstract base class for all Operations implementations.
     * Provides shared helper methods that don't require GenClass-specific information.
     *
     * @generated
     */
    public abstract class AbstractOperations {
    
        protected static final String CONTAINER_KEY = "container";
        
        protected abstract String getEObjectType();
        
        protected abstract «modelName»Model getModel();
        
        protected abstract EClass getEClass();

        protected Map<String, String> sanitize(Map<String, String> source) {
            return source == null ? new LinkedHashMap<>() : new LinkedHashMap<>(source);
        }

        protected EObject resolveContainer(FqnResolver resolver, String fqn) {
            if (fqn == null || fqn.isBlank()) {
                return null;
            }
            return resolver.resolve(fqn).orElse(null);
        }

        protected boolean attachToContainer(EObject container, EObject child) {
            if (container == null) {
                return false;
            }
            for (EStructuralFeature feature : container.eClass().getEAllStructuralFeatures()) {
                if (feature instanceof EReference reference && reference.isContainment()) {
                    if (reference.getEReferenceType() != null && reference.getEReferenceType().isSuperTypeOf(child.eClass())) {
                        if (reference.isMany()) {
                            @SuppressWarnings("unchecked")
                            List<EObject> list = (List<EObject>) container.eGet(reference);
                            list.add(child);
                        } else {
                            container.eSet(reference, child);
                        }
                        return true;
                    }
                }
            }
            return false;
        }

        protected GraphQLSchema buildGraphQLSchema(FqnResolver resolver, List<Map<String, Object>> rows) {
            EClass eClass = getEClass();
            String typeName = eClass.getName();
            
            GraphQLObjectType.Builder typeBuilder = GraphQLObjectType.newObject().name(typeName);
            
            // Add fqn field (always present in describe output)
            typeBuilder.field(GraphQLFieldDefinition.newFieldDefinition()
                .name("fqn")
                .type(Scalars.GraphQLString)
                .build());
            
            for (EStructuralFeature feature : eClass.getEAllStructuralFeatures()) {
                GraphQLFieldDefinition.Builder fieldBuilder = GraphQLFieldDefinition.newFieldDefinition()
                    .name(feature.getName());
                
                if (feature.isMany()) {
                    fieldBuilder.type(GraphQLList.list(Scalars.GraphQLString));
                } else {
                    fieldBuilder.type(Scalars.GraphQLString);
                }
                
                typeBuilder.field(fieldBuilder.build());
            }
            
            GraphQLObjectType entityType = typeBuilder.build();
            
            GraphQLObjectType queryType = GraphQLObjectType.newObject()
                .name("Query")
                .field(GraphQLFieldDefinition.newFieldDefinition()
                    .name("items")
                    .type(GraphQLList.list(entityType))
                    .argument(builder -> builder.name("filter").type(Scalars.GraphQLString))
                    .build())
                .field(GraphQLFieldDefinition.newFieldDefinition()
                    .name("item")
                    .type(entityType)
                    .argument(builder -> builder.name("fqn").type(Scalars.GraphQLString))
                    .build())
                .build();
            
            GraphQLCodeRegistry codeRegistry = GraphQLCodeRegistry.newCodeRegistry()
                .dataFetcher(FieldCoordinates.coordinates("Query", "items"), (DataFetcher<?>) env -> {
                    String filter = env.getArgument("filter");
                    if (filter == null || filter.isBlank()) {
                        return rows;
                    }
                    return rows.stream()
                        .filter(row -> matchesFilterMap(row, filter))
                        .collect(Collectors.toList());
                })
                .dataFetcher(FieldCoordinates.coordinates("Query", "item"), (DataFetcher<?>) env -> {
                    String fqn = env.getArgument("fqn");
                    if (fqn == null || fqn.isBlank()) {
                        return null;
                    }
                    return rows.stream()
                        .filter(row -> fqn.equals(row.get("fqn")))
                        .findFirst()
                        .orElse(null);
                })
                .build();
            
            return GraphQLSchema.newSchema()
                .query(queryType)
                .codeRegistry(codeRegistry)
                .build();
        }
        
        protected boolean matchesFilterMap(Map<String, Object> row, String filter) {
            String[] tokens = filter.split("=", 2);
            if (tokens.length != 2) {
                return true;
            }
            String key = tokens[0].trim();
            String expected = tokens[1].trim();
            Object actual = row.get(key);
            if (actual instanceof List<?>) {
                return ((List<?>) actual).stream()
                    .anyMatch(value -> Objects.toString(value, "").equalsIgnoreCase(expected));
            }
            return Objects.toString(actual, "").equalsIgnoreCase(expected);
        }

        private static final ObjectMapper JSON_MAPPER = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);

        protected int executeGraphQL(FqnResolver resolver, String graphqlQuery, List<Map<String, Object>> rows) {
            try {
                GraphQLSchema schema = buildGraphQLSchema(resolver, rows);
                GraphQL graphQL = GraphQL.newGraphQL(schema).build();
                
                ExecutionInput executionInput = ExecutionInput.newExecutionInput()
                    .query(graphqlQuery)
                    .build();
                
                ExecutionResult result = graphQL.execute(executionInput);
                
                if (!result.getErrors().isEmpty()) {
                    System.err.println("GraphQL errors:");
                    result.getErrors().forEach(error -> System.err.println("  - " + error.getMessage()));
                    return 1;
                }
                
                Object data = result.getData();
                String json = JSON_MAPPER.writeValueAsString(data);
                System.out.println(json);
                return 0;
                
            } catch (Exception ex) {
                System.err.printf("Failed to execute GraphQL query for %s: %s%n", getEObjectType(), ex.getMessage());
                ex.printStackTrace();
                return 1;
            }
        }

        protected String getDisplayName(EObject eObject) {
            EStructuralFeature nameFeature = eObject.eClass().getEStructuralFeature("name");
            if (nameFeature != null) {
                Object name = eObject.eGet(nameFeature);
                if (name instanceof String && !((String) name).isBlank()) {
                    return eObject.eClass().getName() + "(" + name + ")";
                }
            }
            return eObject.eClass().getName() + "@" + Integer.toHexString(System.identityHashCode(eObject));
        }

        protected List<String> splitValues(String raw) {
            if (raw == null || raw.isBlank()) {
                return Collections.emptyList();
            }
            return Arrays.stream(raw.split(","))
                    .map(String::trim)
                    .filter(token -> !token.isEmpty())
                    .collect(Collectors.toList());
        }

        protected void removeFromContainer(EObject instance) {
            EObject container = instance.eContainer();
            if (container == null) {
                getModel().getResource().getContents().remove(instance);
                return;
            }
            EStructuralFeature containingFeature = instance.eContainingFeature();
            if (containingFeature == null) {
                return;
            }
            if (containingFeature.isMany()) {
                @SuppressWarnings("unchecked")
                EList<EObject> list = (EList<EObject>) container.eGet(containingFeature);
                list.remove(instance);
            } else {
                container.eUnset(containingFeature);
            }
        }

        protected int fail(String action, Exception ex) {
            System.err.printf("Failed to %s %s: %s%n", action, getEObjectType(), ex.getMessage());
            ex.printStackTrace();
            return 1;
        }

        protected Map<String, Object> describe(FqnResolver resolver, EObject instance) {
            Map<String, Object> description = new LinkedHashMap<>();
            description.put("fqn", resolver.getFqn(instance).orElse("unknown"));
            description.put("_type", instance.eClass().getName());
            for (EStructuralFeature feature : instance.eClass().getEAllStructuralFeatures()) {
                Object value = instance.eGet(feature);
                if (value == null) {
                    continue;
                }
                if (feature.isMany() && value instanceof List<?>) {
                    List<?> list = (List<?>) value;
                    List<String> fqns = list.stream()
                            .map(item -> item instanceof EObject 
                                    ? resolver.getFqn((EObject) item).orElse(getDisplayName((EObject) item))
                                    : Objects.toString(item, ""))
                            .collect(Collectors.toList());
                    description.put(feature.getName(), fqns);
                } else if (value instanceof EObject) {
                    description.put(feature.getName(), resolver.getFqn((EObject) value).orElse(getDisplayName((EObject) value)));
                } else {
                    description.put(feature.getName(), value);
                }
            }
            return description;
        }

        protected void removeStructuralFeatureValues(EObject eObject, Map<String, String> structuralFeatures) {
            if (structuralFeatures.isEmpty()) {
                return;
            }
            structuralFeatures.forEach((name, value) -> {
                EStructuralFeature feature = eObject.eClass().getEStructuralFeature(name);
                if (feature == null) {
                    return;
                }
                if (feature.isMany()) {
                    @SuppressWarnings("unchecked")
                    List<Object> list = (List<Object>) eObject.eGet(feature);
                    splitValues(value).forEach(token -> list.removeIf(item -> Objects.toString(item, "").equals(token)));
                } else {
                    eObject.eUnset(feature);
                }
            });
        }
    }
    '''

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
     * Provisions CRUD helpers backed by builders.
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
        
        private boolean validateAttributes(java.util.Set<String> keys) {
            EClass eClass = getEClass();
            for (String key : keys) {
                if (eClass.getEStructuralFeature(key) == null) {
                    System.err.printf("Unknown attribute '%s' for %s.%n", key, EOBJECT_TYPE);
                    return false;
                }
            }
            return true;
        }

        @Override
        public int create(FqnResolver resolver, Map<String, String> structuralFeatures) {
            try {
                Map<String, String> working = sanitize(structuralFeatures);
                String containerFqn = working.remove(CONTAINER_KEY);
                
                if (!validateAttributes(working.keySet())) {
                    return 1;
                }
                
                «modelJavaFqName» instance  = «builderBuilderName»
                    .create(true)
                    .withStructuralFeatures(resolveValues(resolver, working))
                    .build();
                
                EObject container = resolveContainer(resolver, containerFqn);
                if (!attachToContainer(container, instance)) {
                    getModel().addContent(instance);
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
        public int query(FqnResolver resolver, String graphqlQuery) {
            try {
                List<Map<String, Object>> rows = streamEObjects()
                        .map(eObject -> describe(resolver, eObject))
                        .collect(Collectors.toList());
                
                if (rows.isEmpty()) {
                    System.out.println("No " + EOBJECT_TYPE + " instances found.");
                    return 0;
                }
                
                return executeGraphQL(resolver, graphqlQuery, rows);
            } catch (Exception ex) {
                return fail("query", ex);
            }
        }

        @Override
        public int update(FqnResolver resolver, String identifier, Map<String, String> structuralFeaturesToSet, Map<String, String> structuralFeaturesToRemove) {
            try {
                Optional<«modelJavaFqName»> eObject = resolveEObject(resolver, identifier);
                if (eObject.isEmpty()) {
                    System.err.printf("Could not find %s '%s'%n", EOBJECT_TYPE, identifier);
                    return 1;
                }
                «modelJavaFqName» instance = eObject.get();
                
                Map<String, String> toSet = sanitize(structuralFeaturesToSet);
                Map<String, String> toRemove = sanitize(structuralFeaturesToRemove);
                if (!validateAttributes(toSet.keySet()) || !validateAttributes(toRemove.keySet())) {
                    return 1;
                }
                
                «builderBuilderName» builder = «builderBuilderName».use(instance, true);
                builder.withStructuralFeatures(resolveValues(resolver, toSet));
                builder.build();
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
                Optional<«modelJavaFqName»> eObject = resolveEObject(resolver, identifier);
                if (eObject.isEmpty()) {
                    System.err.printf("Could not find %s '%s'%n", EOBJECT_TYPE, identifier);
                    return 1;
                }
                if (!skipConfirm) {
                    System.out.println("Confirmation required. Re-run with --yes to delete.");
                    return 1;
                }
                
                removeFromContainer(eObject.get());
                System.out.printf("delete %s %s --yes%n", EOBJECT_TYPE, identifier);
                return 0;
            } catch (Exception ex) {
                return fail("delete", ex);
            }
        }

        private Stream<«modelJavaFqName»> streamEObjects() {
            return getModel().get«genModel.modelName»ModelResourceSupport().getStreamOf(«modelJavaFqName».class);
        }

        private Map<String, Object> resolveValues(FqnResolver resolver, Map<String, String> attributes) {
            Map<String, Object> result = new LinkedHashMap<>();
            attributes.forEach((key, value) -> {
                EStructuralFeature feature = «genPackage.packageFqName».«genPackage.packageInterfaceName».eINSTANCE.get«name»().getEStructuralFeature(key);
                if (feature instanceof EReference) {
                    if (feature.isMany()) {
                        List<EObject> objects = new ArrayList<>();
                        splitValues(value).forEach(token -> resolver.resolve(token).ifPresent(objects::add));
                        result.put(key, objects);
                    } else {
                        resolver.resolve(value).ifPresent(obj -> result.put(key, obj));
                    }
                } else {
                    result.put(key, value);
                }
            });
            return result;
        }

        private Optional<«modelJavaFqName»> resolveEObject(FqnResolver resolver, String fqn) {
            if (fqn == null || fqn.isBlank()) {
                return Optional.empty();
            }
            return resolver.resolve(fqn)
                    .filter(«modelJavaFqName».class::isInstance)
                    .map(«modelJavaFqName».class::cast);
        }

    }
    '''
}

