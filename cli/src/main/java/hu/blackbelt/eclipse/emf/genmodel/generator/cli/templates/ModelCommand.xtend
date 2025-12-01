package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine.CliConfig
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

class ModelCommand {
	@Inject extension CliExtension
    @Inject CliConfig cliConfig

	def doGenerate(GenModel genModel, Resource input, IFileSystemAccess2 fsa){
        fsa.generateFile(genModel.commandFilePath, generateCommand(genModel))
        fsa.generateFile(genModel.resolverFilePath, generateFqnResolver(genModel))
	}

	def generateFqnResolver(GenModel it) {
	'''
	package «cliPackageName»;
	import java.util.Optional;
	import java.util.stream.Stream;

	import org.eclipse.emf.ecore.EObject;
	import org.eclipse.emf.ecore.resource.ResourceSet;


	public interface FqnResolver {
	    /**
	     * Binds the resolver to a specific {@link ResourceSet} so it can traverse and cache
	     * model elements for later lookup.
	     *
	     * @param resourceSet the resource set backing the loaded runtime model
	     */
	    void bind(ResourceSet resourceSet);
	    /**
	     * Resolves an FQN string to a model element.
	     * @param fqn The FQN of the instance or type.
	     * @return An Optional containing the resolved EObject, or empty if not found.
	     */
	    Optional<EObject> resolve(String fqn);

	    /**
	     * Computes the FQN for a given EObject.
	     * This is the reverse of {@link #resolve(String)}.
	     * @param eObject The model element.
	     * @return An Optional containing the FQN string, or empty if not computable.
	     */
	    Optional<String> getFqn(EObject eObject);

	    /**
	     * @return A stream of fqns in the runtime model.
	     */
	    Stream<String> getFqnCollection();
	}
	'''
	}

    def generateCommand(GenModel it)
    '''
    package «cliPackageName»;

    import picocli.CommandLine;
    import picocli.CommandLine.Command;
    import picocli.CommandLine.Parameters;
    import picocli.CommandLine.Option;

    import java.util.Map;
    import java.util.HashMap;
    import java.util.Iterator;
    import java.util.List;
    import java.io.DataOutputStream;
    import java.io.File;
    import java.io.IOException;
    import java.nio.file.Files;
    import java.nio.file.Path;
    import java.util.stream.Stream;

    import «packageName».runtime.«modelName»Model;

    /**
     * Command logic for «modelName» model operations.
     * Contains all Picocli @Command annotations and business logic.
     *
     * @generated
     */
    @Command(
        name = "«modelName.decapitalize»-api",
        mixinStandardHelpOptions = true,
        description = "Command-line interface for working with «modelName» models.%n%n" +
                      "Lifecycle Commands:%n" +
                      "  start   Start the background server (must be called first)%n" +
                      "  status  Check if the server is running%n" +
                      "  stop    Stop the background server%n",
        subcommandsRepeatable = true
    )
    public class «cliClassName» implements Runnable {

        public enum Format { JSON, TABLE }

    	private static final FqnResolver RESOLVER = «IF cliConfig.resolverClass !== null»new «cliConfig.resolverClass»()«ELSE»throw new IllegalStateException("No FqnResolver configured for CLI generation.")«ENDIF»;

        public static «modelName»Model sharedModel;
        public static File sharedModelFile;
        public static boolean isDirty = false;

        static void bindResolver() {
            if (sharedModel == null) {
                throw new IllegalStateException("No model loaded. Use 'model --load' command first.");
            }
            RESOLVER.bind(sharedModel.getResourceSet());
        }

        private void markDirty() {
            isDirty = true;
        }

        private void clearDirty() {
            isDirty = false;
        }

    	private static final Map<String, Operations> OPERATIONS_MAP = new HashMap<>();
    	static {
            «FOR cls : allConcreteClasses»
            OPERATIONS_MAP.put("«cls.eObjectTypeName.toLowerCase»", «cls.cliOperationsImplPackage».«cls.operationsClassName».getInstance());
            «ENDFOR»
    	}

        @Override
        public void run() {
            // When called without subcommand, show help
            CommandLine.usage(this, System.out);
        }

        static class EObjectTypeCompletions implements Iterable<String> {
        	@Override
        	public Iterator<String> iterator() {
        		return OPERATIONS_MAP.keySet().iterator();
        	}
        }

        static class FqnCompletions implements Iterable<String> {
        	@Override
        	public Iterator<String> iterator() {
        		if (sharedModel == null) {
        		    return java.util.Collections.emptyIterator();
        		}
        		RESOLVER.bind(sharedModel.getResourceSet());
        		return RESOLVER.getFqnCollection().iterator();
        	}
        }

        @Command(name = "model", description = "Manage model file: load, create, or save.",
             mixinStandardHelpOptions = true)
        public int model(
            @Parameters(index = "0", arity = "0..1", description = "Path to the .model file. Defaults to ./model/*.model", paramLabel = "FILE")
            File modelFile,

            @Option(names = {"-l", "--load"}, description = "Load the model file into memory.")
            boolean load,

            @Option(names = {"-c", "--create"}, description = "Create a new model file if it doesn't exist.")
            boolean create,

            @Option(names = {"-s", "--save"}, description = "Save the current model state to disk.")
            boolean save,

            @Option(names = {"-y", "--yes", "--force"}, description = "Force operation even if current model has unsaved changes.")
            boolean force) {

            if (save) {
                if (sharedModel == null || sharedModelFile == null) {
                    System.err.println("No model is loaded. Nothing to save.");
                    return 1;
                }
                try {
                    System.out.println("Saving model to: " + sharedModelFile.getAbsolutePath());
                    sharedModel.save«modelName»Model();
                    System.out.println("Save complete.");
                    clearDirty();
                    return 0;
                } catch (IOException | «modelName»Model.«modelName»ValidationException e) {
                    System.err.println("Error: Failed to save model file.");
                    e.printStackTrace();
                    return 1;
                }
            }

            if (!load && !create) {
                // Default to load
                load = true;
            }

            if (isDirty && !force) {
                System.err.println("Error: Current model has unsaved changes.");
                System.err.println("Use 'model --save' to persist changes, or add '--force' to discard changes.");
                return 1;
            }

            try {
                File targetFile = modelFile != null ? modelFile : discoverModelFile();

                if (targetFile == null) {
                    System.err.println("Error: No model file specified and auto-discovery failed.");
                    System.err.println("Usage: model path/to/file.model --load");
                    return 1;
                }

                if (!targetFile.exists()) {
                    if (create) {
                        System.out.println("Creating new empty model at: " + targetFile.getAbsolutePath());
                        org.eclipse.emf.common.util.URI uri = org.eclipse.emf.common.util.URI.createFileURI(targetFile.getAbsolutePath());
                        sharedModel = «modelName»Model.build«modelName»Model().uri(uri).build();
                        sharedModel.save«modelName»Model();
                        sharedModelFile = targetFile;
                        clearDirty();
                        RESOLVER.bind(sharedModel.getResourceSet());
                        System.out.println("Empty model file created. Use 'create model --attr name=ModelName' to add model.");
                        return 0;
                    } else {
                        System.err.println("Error: Model file not found: " + targetFile.getAbsolutePath());
                        System.err.println("Use --create to create a new model.");
                        return 1;
                    }
                }

                System.out.println("Loading model from: " + targetFile.getAbsolutePath());
                sharedModel = «modelName»Model.load«modelName»Model(
                    «modelName»Model.LoadArguments.«modelName.decapitalize»LoadArgumentsBuilder()
                        .uri(org.eclipse.emf.common.util.URI.createFileURI(targetFile.getAbsolutePath()))
                        .validateModel(true)
                        .build()
                );
                sharedModelFile = targetFile;
                clearDirty();
                RESOLVER.bind(sharedModel.getResourceSet());
                System.out.println("Model loaded successfully.");
                System.out.println("FQN: " + sharedModel.getName());
                return 0;

            } catch (Exception e) {
                System.err.println("Error: " + e.getMessage());
                return 1;
            }
        }

        private File discoverModelFile() {
            Path startDir = Path.of(".");
            try (Stream<Path> stream = Files.walk(startDir, 3)) {
                List<Path> models = stream
                    .filter(Files::isRegularFile)
                    .filter(p -> p.toString().endsWith(".model"))
                    .collect(java.util.stream.Collectors.toList());
                if (models.size() == 1) {
                    return models.get(0).toFile();
                } else if (models.size() > 1) {
                    System.err.println("Multiple .model files found. Please specify one:");
                    models.forEach(p -> System.err.println(" " + p));
                }
            } catch (IOException e) {
                // Ignore
            }
            return null;
        }

        @Command(name = "create", description = "Create a new EObject.",
             mixinStandardHelpOptions = true)
        public int create(
                @Parameters(index = "0", description = "Type of EObject to create. Valid types: ${COMPLETION-CANDIDATES}", completionCandidates = EObjectTypeCompletions.class)
                String eObjectType,

                @Option(names = {"--attr"}, description = "Set attributes using key=value pairs.", split = ",")
                Map<String, String> attributes) {

            bindResolver();
            Operations operations = getOperations(eObjectType);
            int exitCode = operations.create(RESOLVER, attributes);

            if (exitCode == 0) {
                markDirty();
            }

            return exitCode;
        }

        @Command(name = "list", description = "List EObjects of a specific type.",
             mixinStandardHelpOptions = true)
        public int list(
            @Parameters(index = "0", description = "Type of EObject to list. Valid types: ${COMPLETION-CANDIDATES}", completionCandidates = EObjectTypeCompletions.class)
            String eObjectType,

            @Option(names = {"--filter"}, description = "Filter expression (e.g., 'name=John').")
            String filter,

            @Option(names = {"-f", "--format"}, description = "Output format: TABLE, JSON", defaultValue = "TABLE")
            Format format) {

            bindResolver();
            Operations operations = getOperations(eObjectType);
            return operations.list(RESOLVER, filter, format);
        }

        @Command(name = "describe", description = "Show detailed information for a specific EObject, or show the schema if no FQN is provided.",
             mixinStandardHelpOptions = true)
        public int describe(
            @Parameters(index = "0", description = "Type of EObject to describe. Valid types: ${COMPLETION-CANDIDATES}", completionCandidates = EObjectTypeCompletions.class)
            String eObjectType,

            @Parameters(index = "1", arity = "0..1", description = "FQN of the EObject. If omitted, shows the schema for the type.", completionCandidates = FqnCompletions.class)
            String identifier,

            @Option(names = {"-f", "--format"}, description = "Output format: TABLE, JSON", defaultValue = "TABLE")
            Format format) {

            Operations operations = getOperations(eObjectType);
            if (identifier == null || identifier.isBlank()) {
                return operations.describeSchema(format);
            }
            bindResolver();
            return operations.describe(RESOLVER, identifier, format);
        }

        @Command(name = "update", description = "Update attributes of an existing EObject.",
             mixinStandardHelpOptions = true)
        public int update(
            @Parameters(index = "0", description = "Type of EObject to update. Valid types: ${COMPLETION-CANDIDATES}", completionCandidates = EObjectTypeCompletions.class)
            String eObjectType,

            @Parameters(index = "1", description = "EObject FQN.", completionCandidates = FqnCompletions.class)
            String identifier,

            @Option(names = {"--attr"}, description = "Set or overwrite attributes (key=value).", split = ",")
            Map<String, String> attributesToSet,

            @Option(names = {"--remove-attr"}, description = "Remove value from a multi-valued attribute (key=value).", split = ",")
            Map<String, String> attributesToRemove) {

            bindResolver();
            Operations operations = getOperations(eObjectType);
            int exitCode = operations.update(RESOLVER, identifier, attributesToSet, attributesToRemove);

            if (exitCode == 0) {
                markDirty();
            }

            return exitCode;
        }

        @Command(name = "delete", description = "Delete an EObject from the model.",
             mixinStandardHelpOptions = true)
        public int delete(
            @Parameters(index = "0", description = "Type of EObject to delete. Valid types: ${COMPLETION-CANDIDATES}", completionCandidates = EObjectTypeCompletions.class)
            String eObjectType,

            @Parameters(index = "1", description = "Identifier of the EObject.", completionCandidates = FqnCompletions.class)
            String identifier,

            @Option(names = {"-y", "--yes"}, description = "Skip confirmation prompt.")
            boolean skipConfirm) {

            bindResolver();
            Operations operations = getOperations(eObjectType);
            int exitCode = operations.delete(RESOLVER, identifier, skipConfirm);

            if (exitCode == 0) {
                markDirty();
            }

            return exitCode;
        }

        private int readPortFromFile() {
            try {
                File userHome = new File(System.getProperty("user.home"));
                File judoDir = new File(userHome, ".judo");
                File portFile = new File(judoDir, ".«modelName».port");
                if (portFile.exists()) {
                    try (java.util.Scanner scanner = new java.util.Scanner(portFile)) {
                        if (scanner.hasNextInt()) {
                            return scanner.nextInt();
                        }
                    }
                }
            } catch (Exception e) {
                // ignore
            }
            return 0;
        }

        @Command(name = "stop", description = "Stop the background server process. Use --force to discard unsaved changes.",
             mixinStandardHelpOptions = true)
        public int stop(
            @Option(names = {"-p", "--port"}, description = "Port the server is running on.", defaultValue = "" + «serverClassName».DEFAULT_PORT)
            int port,

            @Option(names = {"-y", "--yes", "--force"}, description = "Force stop even if current model has unsaved changes.")
            boolean force) {

            if (port == 0) {
                port = readPortFromFile();
            }

            if (port == 0) {
                 System.err.println("Error: No port specified and could not read from file.");
                 return 1;
            }

            if (isDirty && !force) {
                System.err.println("Error: Current model has unsaved changes.");
                System.err.println("Use 'save' to persist changes, or 'stop --yes' to discard and load a new model.");
                return 1;
            }

            if (!isServerRunning(port)) {
                System.out.println("Server is not running on port " + port);
                return 1;
            }

            try (java.net.Socket socket = new java.net.Socket("localhost", port);
                 DataOutputStream out = new DataOutputStream(socket.getOutputStream());
                 java.io.BufferedReader in = new java.io.BufferedReader(new java.io.InputStreamReader(socket.getInputStream()))) {

                out.writeInt(1);
                out.writeUTF("shutdown");
                out.flush();

                String line;
                while ((line = in.readLine()) != null) {
                    if ("END_OF_RESPONSE".equals(line)) {
                        break;
                    }
                    if (!line.startsWith("EXIT_CODE=")) {
                        System.out.println(line);
                    }
                }
                return 0;
            } catch (Exception e) {
                System.err.println("Failed to stop server: " + e.getMessage());
                return 1;
            }
        }

        private static boolean isServerRunning(int port) {
            try (java.net.Socket s = new java.net.Socket("localhost", port)) {
                return true;
            } catch (Exception e) {
                return false;
            }
        }

        static Operations getOperations(String type) {
            String lowerCaseType = type.toLowerCase();
            if (!OPERATIONS_MAP.containsKey(lowerCaseType)) {
                throw new IllegalArgumentException(
                    "Unknown EObject type: '" + type + "'. Valid types are: " + OPERATIONS_MAP.keySet()
                );
            }
            return OPERATIONS_MAP.get(lowerCaseType);
        }

    }
    '''

}
