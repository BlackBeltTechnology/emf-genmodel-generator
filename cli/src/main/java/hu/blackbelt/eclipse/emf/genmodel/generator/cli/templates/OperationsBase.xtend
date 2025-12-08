package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2

class OperationsBase {
	@Inject extension CliExtension    

	def doGenerate(GenModel genModel, IFileSystemAccess2 fsa) {
		fsa.generateFile(genModel.cliOperationsFilePath, generateOperations(genModel));
		fsa.generateFile(genModel.abstractOperationsFilePath, generateAbstractOperations(genModel));
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
         * Execute a GraphQL query or mutation against the EObject instances.
         * The query should follow GraphQL syntax.
         *
         * For queries:
         * - { items { fqn name } } - list all items
         * - { items(filter: "name=value") { fqn name } } - filter items
         * - { item(fqn: "some.fqn") { fqn name } } - get single item
         * - { __schema { types { name } } } - introspect schema
         *
         * For mutations:
         * - mutation { create(input: {name: "value", container: "parent.fqn"}) { fqn name } }
         * - mutation { update(fqn: "item.fqn", input: {name: "newValue"}) { fqn name } }
         * - mutation { delete(fqn: "item.fqn") { fqn name success } }
         *
         * @param resolver the FQN resolver for resolving references
         * @param graphqlQuery the GraphQL query or mutation string
         * @param variables optional variables map for the GraphQL operation
         * @return exit code (0 for success)
         */
        int execute(FqnResolver resolver, String graphqlQuery, Map<String, Object> variables);

        /**
         * Execute a GraphQL query or mutation without variables.
         */
        default int execute(FqnResolver resolver, String graphqlQuery) {
            return execute(resolver, graphqlQuery, null);
        }

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
    import java.util.ArrayList;
    import java.util.Arrays;
    import java.util.Collections;
    import java.util.LinkedHashMap;
    import java.util.List;
    import java.util.Map;
    import java.util.Objects;
    import java.util.Optional;
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
    import graphql.schema.DataFetchingEnvironment;
    import graphql.schema.FieldCoordinates;
    import graphql.schema.GraphQLArgument;
    import graphql.schema.GraphQLCodeRegistry;
    import graphql.schema.GraphQLFieldDefinition;
    import graphql.schema.GraphQLInputObjectField;
    import graphql.schema.GraphQLInputObjectType;
    import graphql.schema.GraphQLList;
    import graphql.schema.GraphQLNonNull;
    import graphql.schema.GraphQLObjectType;
    import graphql.schema.GraphQLSchema;
    
    import com.fasterxml.jackson.databind.ObjectMapper;
    import com.fasterxml.jackson.databind.SerializationFeature;
    
    import «packageName».runtime.«modelName»Model;

    /**
     * Abstract base class for all Operations implementations.
     * Provides shared helper methods and GraphQL schema building with mutation support.
     *
     * @generated
     */
    public abstract class AbstractOperations {
    
        protected static final String CONTAINER_KEY = "container";
        
        protected abstract String getEObjectType();
        
        protected abstract «modelName»Model getModel();
        
        protected abstract EClass getEClass();

        /**
         * Creates a new instance with the given structural features.
         * Must be implemented by subclasses to use the appropriate builder.
         *
         * @param resolver the FQN resolver
         * @param structuralFeatures map of feature names to values
         * @return the created EObject, or null if creation failed
         */
        protected abstract EObject doCreate(FqnResolver resolver, Map<String, Object> structuralFeatures);

        /**
         * Updates an existing instance with the given structural features.
         * Must be implemented by subclasses to use the appropriate builder.
         *
         * @param resolver the FQN resolver
         * @param instance the instance to update
         * @param structuralFeatures map of feature names to values
         * @return true if update succeeded
         */
        protected abstract boolean doUpdate(FqnResolver resolver, EObject instance, Map<String, Object> structuralFeatures);

        /**
         * Resolves an EObject by its FQN.
         * Must be implemented by subclasses to filter by the correct type.
         *
         * @param resolver the FQN resolver
         * @param fqn the fully qualified name
         * @return Optional containing the EObject if found
         */
        protected abstract Optional<? extends EObject> doResolve(FqnResolver resolver, String fqn);

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
                if (feature instanceof EReference) {
                    EReference reference = (EReference) feature;
                    if (reference.isContainment() && reference.getEReferenceType() != null && reference.getEReferenceType().isSuperTypeOf(child.eClass())) {
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

        /**
         * Builds the GraphQL input type for create/update mutations.
         */
        protected GraphQLInputObjectType buildInputType() {
            EClass eClass = getEClass();
            String inputTypeName = eClass.getName() + "Input";

            GraphQLInputObjectType.Builder inputBuilder = GraphQLInputObjectType.newInputObject()
                .name(inputTypeName);

            inputBuilder.field(GraphQLInputObjectField.newInputObjectField()
                .name(CONTAINER_KEY)
                .type(Scalars.GraphQLString)
                .build());

            for (EStructuralFeature feature : eClass.getEAllStructuralFeatures()) {
                GraphQLInputObjectField.Builder fieldBuilder = GraphQLInputObjectField.newInputObjectField()
                    .name(feature.getName());

                if (feature.isMany()) {
                    fieldBuilder.type(GraphQLList.list(Scalars.GraphQLString));
                } else {
                    fieldBuilder.type(Scalars.GraphQLString);
                }

                inputBuilder.field(fieldBuilder.build());
            }

            return inputBuilder.build();
        }

        /**
         * Creates the DataFetcher for create mutations.
         */
        protected DataFetcher<Map<String, Object>> createMutationDataFetcher(FqnResolver resolver) {
            return new DataFetcher<Map<String, Object>>() {
                @Override
                public Map<String, Object> get(DataFetchingEnvironment environment) throws Exception {
                    Map<String, Object> input = environment.getArgument("input");
                    if (input == null) {
                        input = new LinkedHashMap<>();
                    }

                    EObject created = doCreate(resolver, new LinkedHashMap<>(input));
                    if (created == null) {
                        throw new RuntimeException("Failed to create " + getEObjectType());
                    }

                    resolver.bind(getModel().getResourceSet());
                    return describe(resolver, created);
                }
            };
        }

        /**
         * Creates the DataFetcher for update mutations.
         */
        protected DataFetcher<Map<String, Object>> updateMutationDataFetcher(FqnResolver resolver) {
            return new DataFetcher<Map<String, Object>>() {
                @Override
                public Map<String, Object> get(DataFetchingEnvironment environment) throws Exception {
                    String fqn = environment.getArgument("fqn");
                    if (fqn == null || fqn.isBlank()) {
                        throw new IllegalArgumentException("fqn argument is required for update mutation");
                    }

                    Map<String, Object> input = environment.getArgument("input");
                    if (input == null) {
                        input = new LinkedHashMap<>();
                    }

                    Optional<? extends EObject> eObjectOpt = doResolve(resolver, fqn);
                    if (eObjectOpt.isEmpty()) {
                        throw new IllegalArgumentException("Could not find " + getEObjectType() + " with fqn: " + fqn);
                    }

                    EObject instance = eObjectOpt.get();
                    if (!doUpdate(resolver, instance, new LinkedHashMap<>(input))) {
                        throw new RuntimeException("Failed to update " + getEObjectType());
                    }

                    resolver.bind(getModel().getResourceSet());
                    return describe(resolver, instance);
                }
            };
        }

        /**
         * Creates the DataFetcher for delete mutations.
         */
        protected DataFetcher<Map<String, Object>> deleteMutationDataFetcher(FqnResolver resolver) {
            return new DataFetcher<Map<String, Object>>() {
                @Override
                public Map<String, Object> get(DataFetchingEnvironment environment) throws Exception {
                    String fqn = environment.getArgument("fqn");
                    if (fqn == null || fqn.isBlank()) {
                        throw new IllegalArgumentException("fqn argument is required for delete mutation");
                    }

                    Optional<? extends EObject> eObjectOpt = doResolve(resolver, fqn);
                    if (eObjectOpt.isEmpty()) {
                        throw new IllegalArgumentException("Could not find " + getEObjectType() + " with fqn: " + fqn);
                    }

                    EObject eObject = eObjectOpt.get();
                    Map<String, Object> deletedDescription = describe(resolver, eObject);
                    deletedDescription.put("success", true);

                    removeFromContainer(eObject);
                    resolver.bind(getModel().getResourceSet());

                    return deletedDescription;
                }
            };
        }

        protected GraphQLSchema buildGraphQLSchema(FqnResolver resolver, List<Map<String, Object>> rows) {
            EClass eClass = getEClass();
            String typeName = eClass.getName();
            
            // Build entity type for query results
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

            // Build mutation result type (includes success field)
            GraphQLObjectType.Builder mutationResultBuilder = GraphQLObjectType.newObject()
                .name(typeName + "MutationResult");

            mutationResultBuilder.field(GraphQLFieldDefinition.newFieldDefinition()
                .name("fqn")
                .type(Scalars.GraphQLString)
                .build());

            mutationResultBuilder.field(GraphQLFieldDefinition.newFieldDefinition()
                .name("success")
                .type(Scalars.GraphQLBoolean)
                .build());

            for (EStructuralFeature feature : eClass.getEAllStructuralFeatures()) {
                GraphQLFieldDefinition.Builder fieldBuilder = GraphQLFieldDefinition.newFieldDefinition()
                    .name(feature.getName());

                if (feature.isMany()) {
                    fieldBuilder.type(GraphQLList.list(Scalars.GraphQLString));
                } else {
                    fieldBuilder.type(Scalars.GraphQLString);
                }

                mutationResultBuilder.field(fieldBuilder.build());
            }

            GraphQLObjectType mutationResultType = mutationResultBuilder.build();

            // Mutations
            GraphQLInputObjectType inputType = buildInputType();

            // Query
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

            // Mutation type
            GraphQLObjectType mutationType = GraphQLObjectType.newObject()
                .name("Mutation")
                .field(GraphQLFieldDefinition.newFieldDefinition()
                    .name("create")
                    .type(entityType)
                    .argument(GraphQLArgument.newArgument()
                        .name("input")
                        .type(GraphQLNonNull.nonNull(inputType))
                        .build())
                    .build())
                .field(GraphQLFieldDefinition.newFieldDefinition()
                    .name("update")
                    .type(entityType)
                    .argument(GraphQLArgument.newArgument()
                        .name("fqn")
                        .type(GraphQLNonNull.nonNull(Scalars.GraphQLString))
                        .build())
                    .argument(GraphQLArgument.newArgument()
                        .name("input")
                        .type(GraphQLNonNull.nonNull(inputType))
                        .build())
                    .build())
                .field(GraphQLFieldDefinition.newFieldDefinition()
                    .name("delete")
                    .type(mutationResultType)
                    .argument(GraphQLArgument.newArgument()
                        .name("fqn")
                        .type(GraphQLNonNull.nonNull(Scalars.GraphQLString))
                        .build())
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
                .dataFetcher(FieldCoordinates.coordinates("Mutation", "create"), createMutationDataFetcher(resolver))
                .dataFetcher(FieldCoordinates.coordinates("Mutation", "update"), updateMutationDataFetcher(resolver))
                .dataFetcher(FieldCoordinates.coordinates("Mutation", "delete"), deleteMutationDataFetcher(resolver))
                .build();
            
            return GraphQLSchema.newSchema()
                .query(queryType)
                .mutation(mutationType)
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

        protected int executeGraphQL(FqnResolver resolver, String graphqlQuery, Map<String, Object> variables, List<Map<String, Object>> rows) {
            try {
                GraphQLSchema schema = buildGraphQLSchema(resolver, rows);
                GraphQL graphQL = GraphQL.newGraphQL(schema).build();

                ExecutionInput.Builder executionInputBuilder = ExecutionInput.newExecutionInput()
                    .query(graphqlQuery);

                if (variables != null && !variables.isEmpty()) {
                    executionInputBuilder.variables(variables);
                }

                ExecutionResult result = graphQL.execute(executionInputBuilder.build());

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
                System.err.printf("Failed to execute GraphQL for %s: %s%n", getEObjectType(), ex.getMessage());
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

        /**
         * Resolves values from a Map<String, Object> (from GraphQL input).
         * Handles both single values and lists, resolving references as needed.
         */
        protected Map<String, Object> resolveObjectValues(FqnResolver resolver, Map<String, Object> input, EClass eClass) {
            Map<String, Object> result = new LinkedHashMap<>();
            input.forEach((key, value) -> {
                if (value == null) {
                    return;
                }
                EStructuralFeature feature = eClass.getEStructuralFeature(key);
                if (feature == null) {
                    // Skip unknown features (like container which is handled separately)
                    if (!CONTAINER_KEY.equals(key)) {
                        result.put(key, value);
                    }
                    return;
                }
                if (feature instanceof EReference) {
                    if (feature.isMany()) {
                        List<EObject> objects = new ArrayList<>();
                        if (value instanceof List<?>) {
                            ((List<?>) value).forEach(token ->
                                resolver.resolve(token.toString()).ifPresent(objects::add));
                        } else {
                            splitValues(value.toString()).forEach(token ->
                                resolver.resolve(token).ifPresent(objects::add));
                        }
                        result.put(key, objects);
                    } else {
                        resolver.resolve(value.toString()).ifPresent(obj -> result.put(key, obj));
                    }
                } else {
                    result.put(key, value);
                }
            });
            return result;
        }
    }
    '''
	    
}