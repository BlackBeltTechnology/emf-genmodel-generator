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
         * List EObject instances.
         */
        int list(FqnResolver resolver, String filter, «cliClassName».Format format);

        /**
         * Describe an EObject instance.
         */
         int describe(FqnResolver resolver, String identifier, «cliClassName».Format format);

        /**
         * Describe the schema (structural features) of the EObject type.
         */
         int describeSchema(«cliClassName».Format format);

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
    import org.eclipse.emf.ecore.EObject;
    import org.eclipse.emf.ecore.EReference;
    import org.eclipse.emf.ecore.EStructuralFeature;
    
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

        protected void render(List<Map<String, Object>> rows, «cliClassName».Format format) {
            if (rows.isEmpty()) {
                System.out.println("No " + getEObjectType() + " instances found.");
                return;
            }

            String payload;
            switch (format) {
                case JSON:
                    payload = toJson(rows);
                    break;
                case TABLE:
                default:
                    payload = toTable(rows);
                    break;
            }
            System.out.println(payload);
        }

        protected String toJson(List<Map<String, Object>> rows) {
            StringBuilder builder = new StringBuilder();
            builder.append("[\n");
            for (int i = 0; i < rows.size(); i++) {
                Map<String, Object> row = rows.get(i);
                builder.append("  {");
                int idx = 0;
                for (Map.Entry<String, Object> entry : row.entrySet()) {
                    builder.append('\"').append(entry.getKey()).append("\": ");
                    builder.append('\"').append(Objects.toString(entry.getValue(), "")).append('\"');
                    if (++idx < row.size()) {
                        builder.append(", ");
                    }
                }
                builder.append("}");
                if (i + 1 < rows.size()) {
                    builder.append(',');
                }
                builder.append("\n");
            }
            builder.append("]");
            return builder.toString();
        }

        protected String toTable(List<Map<String, Object>> rows) {
            StringBuilder builder = new StringBuilder();
            for (Map<String, Object> row : rows) {
                builder.append("- ").append(buildRowLabel(row)).append(System.lineSeparator());
                row.forEach((key, value) -> {
                    if (key.startsWith("_")) {
                        return;
                    }
                    builder.append("\t").append(key).append(": ").append(Objects.toString(value, ""))
                            .append(System.lineSeparator());
                });
            }
            return builder.toString();
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

        protected String buildRowLabel(Map<String, Object> row) {
            String name = Objects.toString(row.getOrDefault("name", row.getOrDefault("fqn", getEObjectType())), getEObjectType());
            return getEObjectType() + " " + name;
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

        protected boolean matchesFilter(EObject instance, String filter) {
            String[] tokens = filter.split("=", 2);
            if (tokens.length != 2) {
                return true;
            }
            String key = tokens[0].trim();
            String expected = tokens[1].trim();
            EStructuralFeature feature = instance.eClass().getEStructuralFeature(key);
            if (feature == null) {
                return false;
            }
            Object actual = instance.eGet(feature);
            if (feature.isMany() && actual instanceof List<?>) {
                return ((List<?>) actual).stream().anyMatch(value -> Objects.toString(value, "").equalsIgnoreCase(expected));
            }
            return Objects.toString(actual, "").equalsIgnoreCase(expected);
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
    import java.util.Collections;
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

        private EClass getEClass() {
            return «genPackage.packageFqName».«genPackage.packageInterfaceName».eINSTANCE.get«name»();
        }
        
        @Override
        public int describeSchema(«genModel.cliClassName».Format format) {
            EClass eClass = getEClass();
            List<Map<String, Object>> rows = new ArrayList<>();
            for (EStructuralFeature feature : eClass.getEAllStructuralFeatures()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("name", feature.getName());
                row.put("_type", feature.getName());
                if (feature instanceof EReference ref) {
                    row.put("kind", "reference");
                    row.put("type", ref.getEReferenceType() != null ? ref.getEReferenceType().getName() : "EObject");
                    row.put("containment", ref.isContainment());
                } else {
                    row.put("kind", "attribute");
                    row.put("type", feature.getEType() != null ? feature.getEType().getName() : "unknown");
                }
                row.put("many", feature.isMany());
                row.put("required", feature.isRequired());
                rows.add(row);
            }
            render(rows, format);
            return 0;
        }
        
        private boolean validateAttributes(java.util.Set<String> keys) {
            EClass eClass = getEClass();
            for (String key : keys) {
                if (eClass.getEStructuralFeature(key) == null) {
                    System.err.printf("Unknown attribute '%s' for %s. Valid attributes:%n", key, EOBJECT_TYPE);
                    describeSchema(«genModel.cliClassName».Format.TABLE);
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
        public int list(FqnResolver resolver, String filter, «genModel.cliClassName».Format format) {
            try {
                Stream<«modelJavaFqName»> stream = streamEObjects();
                if (filter != null && !filter.isBlank()) {
                    stream = stream.filter(eObject -> matchesFilter(eObject, filter));
                }
                List<Map<String, Object>> rows = stream
                        .map(eObject -> describe(resolver, eObject))
                        .collect(Collectors.toList());
                render(rows, format);
                return 0;
            } catch (Exception ex) {
                return fail("list", ex);
            }
        }

        @Override
        public int describe(FqnResolver resolver, String identifier, «genModel.cliClassName».Format format) {
            try {
                Optional<«modelJavaFqName»> eObject = resolveEObject(resolver, identifier);
                if (eObject.isEmpty()) {
                    System.err.printf("Could not find %s '%s'%n", EOBJECT_TYPE, identifier);
                    return 1;
                }
                render(Collections.singletonList(describe(resolver, eObject.get())), format);
                return 0;
            } catch (Exception ex) {
                return fail("describe", ex);
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
            return getModel().getEsmModelResourceSupport().getStreamOf(«modelJavaFqName».class);
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

