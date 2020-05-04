package hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates;

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import hu.blackbelt.eclipse.emf.genmodel.generator.helper.engine.HelperGeneratorConfig

class ModelResourceSupport implements IGenerator {
	@Inject extension Naming
	@Inject HelperGeneratorConfig config;
	
	override doGenerate(Resource input, IFileSystemAccess fsa) {		
		input.allContents.filter(GenModel).forEach[
			val content = generate
			fsa.generateFile(packagePath + "/support/" + modelName + "ModelResourceSupport.java", content)
		]
	}
	
	def generate (GenModel it) 
	'''
		package «packageName».support;

		import org.eclipse.emf.common.notify.Notifier;
		import org.eclipse.emf.common.util.BasicDiagnostic;
		import org.eclipse.emf.common.util.DelegatingResourceLocator;
		import org.eclipse.emf.common.util.Diagnostic;
		import org.eclipse.emf.common.util.EList;
		import org.eclipse.emf.common.util.URI;
		import org.eclipse.emf.ecore.EObject;
		import org.eclipse.emf.ecore.plugin.EcorePlugin;
		import org.eclipse.emf.ecore.resource.ContentHandler;
		import org.eclipse.emf.ecore.resource.Resource;
		import org.eclipse.emf.ecore.resource.ResourceSet;
		import org.eclipse.emf.ecore.resource.URIHandler;
		import org.eclipse.emf.ecore.resource.impl.ExtensibleURIConverterImpl;
		import org.eclipse.emf.ecore.resource.impl.ResourceFactoryRegistryImpl;
		import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
		import org.eclipse.emf.ecore.util.Diagnostician;
		import org.eclipse.emf.ecore.util.EObjectValidator;
		import org.eclipse.emf.ecore.xmi.XMLResource;
		import org.eclipse.emf.ecore.xmi.impl.URIHandlerImpl;
		
		import java.io.ByteArrayOutputStream;
		import java.io.File;
		import java.io.FileInputStream;
		import java.io.FileNotFoundException;
		import java.io.FileOutputStream;
		import java.io.IOException;
		import java.io.InputStream;
		import java.io.OutputStream;
		import java.lang.reflect.Field;
		import java.net.URL;
		import java.nio.charset.Charset;
		import java.util.Collections;
		import java.util.HashMap;
		import java.util.Iterator;
		import java.util.Map;
		import java.util.Optional;
		import java.util.Set;
		import java.util.concurrent.ConcurrentHashMap;
		import java.util.function.Function;
		import java.util.function.Predicate;
		import java.util.stream.Collectors;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;
		import static java.util.Objects.requireNonNull;
		import static java.util.Optional.ofNullable;
		
		«FOR p : genPackages»
			import «p.packageFqName».«moduleEmfName»Package;			
			import «p.packageFqName».util.«moduleEmfName»ResourceFactoryImpl;
			import «p.packageFqName».util.«moduleEmfName»ResourceImpl;			
		«ENDFOR»
		

		/**
		 * This class wraps EMF ResourceSet. This helps to manage URI handler and gives Java 8 stream api over it.
		 * It can help handle the model / load save using builder pattern for parameter construction.
		 *
		 * Examples:
		 *
		 * It can be used with an existing {@link ResourceSet}. On that case the the {@link ResourceSet}'s URI will be
		 * used for save.
		 * <pre>
		 *    «modelName»ModelResourceSupport «modelName.decapitalize»Model = «modelName»ModelResourceSupport.«modelName.decapitalize»ModelResourceSupportBuilder()
		 *                 .resourceSet(resourceSet)
		 *                 .build();
		 *    rdbmsModel.save();
		 * </pre>
		 *
		 *
		 * Load an model from file. The file URI is used as base URI.
		 * <pre>
		 *    «modelName»ModelResourceSupport «modelName.decapitalize»Model = «modelName»ModelResourceSupport.load«modelName»(
		 *    		«modelName»ModelResourceSupport.«modelName.decapitalize»LoadArgumentsBuilder()
		 *				.uri(URI.createFileURI(new File("src/test/model/test.«modelName.decapitalize»").getAbsolutePath())));
		 *
		 * </pre>
		 *
		 * More complex example, where model is loaded over an {@link URIHandler} in OSGi environment.
		 * The BundleURIHandler using the given path inside the bundle to resolve URI.
		 * <pre>
		 *
		 *    BundleURIHandler bundleURIHandler = new BundleURIHandler("urn", "", bundleContext.getBundle());
		 *
		 *    «modelName»ModelResourceSupport «modelName.decapitalize»Model = «modelName»ModelResourceSupport.load«modelName»(
		 *    		«modelName»ModelResourceSupport.«modelName.decapitalize»LoadArgumentsBuilder()
		 *                 .uri(URI.createURI("urn:test.«modelName.decapitalize»"))
		 *                 .uriHandler(bundleURIHandler)
		 *                 .build());
		 * </pre>
		 *
		 * When we want to use {@link URI} as logical reference, so not use it for the resource loading,
		 * the {@link File} or {@link InputStream} can be defined for load.
		 * <pre>
		 *
		 *    «modelName»ModelResourceSupport «modelName.decapitalize»Model = «modelName»ModelResourceSupport.load«modelName»(
		 *    		«modelName»ModelResourceSupport.«modelName.decapitalize»LoadArgumentsBuilder()
		 *                 .uri(URI.createURI("urn:test.«modelName.decapitalize»"))
		 *                 .file(new File("path_to_model"));
		 * </pre>
		 *
		 *
		 * Create an empty «modelName.decapitalize» model and load from {@link InputStream}. In that case when save called on model the
		 * file will be created on the given URI.
		 * <pre>
		 *    «modelName»ModelResourceSupport «modelName.decapitalize»Model = «modelName»ModelResourceSupport.«modelName.decapitalize»ModelResourceSupportBuilder()
		 *                 .uri(URI.createFileURI("test.model"))
		 *                 .build();
		 *
		 *    «modelName.decapitalize»Model.loadResource(«modelName»ModelResourceSupport.«modelName.decapitalize»LoadArgumentsBuilder()
		 *    			.inputStream(givenStream));
		 *
		 *    «modelName.decapitalize»Model.save();
		 * </pre>
		 *
		 */
		public class «modelName»ModelResourceSupport {
		
			private static Diagnostician diagnostician = new Diagnostician();

			private ResourceSet resourceSet;
			
			private URI uri;
		
			private static ReourceFactory factory = getResourceFactory();
			
			/**
			 * Create {@link Stream} from {@link Iterator}.
			 * @param sourceIterator the {@link Iterator} {@link Stream} made from
			 * @param <T> the generic type
			 * @return the {@link Stream} representation of {@link Iterator}
			 */
			public <T> Stream<T> asStream(Iterator<T> sourceIterator) {
			    return asStream(sourceIterator, false);
			}
		
			/**
			 * Create {@link Stream} from {@link Iterator}.
			 * @param sourceIterator the {@link Iterator} {@link Stream} made from
			 * @param parallel parallel execution
			 * @param <T> the generic type
			 * @return the {@link Stream} representation of {@link Iterator}
			 */
			@SuppressWarnings("WeakerAccess")
			public <T> Stream<T> asStream(Iterator<T> sourceIterator, boolean parallel) {
			    Iterable<T> iterable = () -> sourceIterator;
			    return StreamSupport.stream(iterable.spliterator(), parallel);
			}
		
			/**
			 * Get all content of the {@link ResourceSet}
			 * @param <T> the generic type
			 * @return the {@link Stream} representation of {@link ResourceSet} contents
			 */
			@SuppressWarnings("unchecked")
			public <T> Stream<T> all() {
				return asStream((Iterator<T>) resourceSet.getAllContents(), false);
			}
		
			/**
			 * Get the given class from {@link ResourceSet}
			 * @param clazz The {@link Class} which required
			 * @param <T> the generic type
			 * @return the {@link Stream} representation of {@link Class} type from {@link ResourceSet} contents
			 */
			@SuppressWarnings({"WeakerAccess", "NullableProblems", "unchecked"})
			public <T> Stream<T> getStreamOf(final Class<T> clazz) {
			    final Iterable<Notifier> contents = resourceSet::getAllContents;
			    return StreamSupport.stream(contents.spliterator(), false)
			            .filter(e -> clazz.isAssignableFrom(e.getClass())).map(e -> (T) e);
			}

			
			«FOR g : allGenPackagesWithConcreteClasses»
				«FOR s : g.genClasses.filter[ecoreClass.instanceClass === null && ecoreClass.interface === false]»
					public Stream<«s.genPackage.packageFqName».«s.name»> getStreamOf«s.genPackage.packageJavaName»«s.name»() {
						return getStreamOf(«s.genPackage.packageFqName».«s.name».class);
					}
				«ENDFOR»
			«ENDFOR»
			
			/**
			 * Set the relative {@link URI} to given {@link URI} and {@link ResourceSet}.
			 * Means there is no baseUri the rootUri is used.
			 * @param resourceSet {@link ResourceSet} is used
			 * @param rootUri {{@link URI}} which us used as root
			 */
			public static void setupRelativeUriRoot(ResourceSet resourceSet, URI rootUri) {
			    EList<URIHandler> uriHandlers = resourceSet.getURIConverter().getURIHandlers();
			    EList<ContentHandler> contentHandlers = resourceSet.getURIConverter().getContentHandlers();
			
			    // Set custom URI handler where URL without base part replaced with the base URI
			    resourceSet.setURIConverter(new ExtensibleURIConverterImpl() {
			        @Override
			        public URI normalize(URI uriPar) {
			
			            String fragment = uriPar.fragment();
			            String query = uriPar.query();
			            URI trimmedURI = uriPar.trimFragment().trimQuery();
			            URI result = getInternalURIMap().getURI(trimmedURI);
			            String scheme = result.scheme();
			            if (scheme == null) {
			                result = rootUri;
			            }
			
			            if (result == trimmedURI) {
			                return uriPar;
			            }
			
			            if (query != null) {
			                result = result.appendQuery(query);
			            }
			            if (fragment != null) {
			                result = result.appendFragment(fragment);
			            }
						if (result == null) {
							return uriPar;
						}
			            return normalize(result);
			        }
			    });
			
			    resourceSet.getURIConverter().getURIHandlers().clear();
			    resourceSet.getURIConverter().getURIHandlers().addAll(uriHandlers);
			    resourceSet.getURIConverter().getContentHandlers().clear();
			    resourceSet.getURIConverter().getContentHandlers().addAll(contentHandlers);
			}
		
			/**
			 * Set the relative {@link URI} to root {@link URI} in the {@link ResourceSet}.
			 * Means there is no baseUri the rootUri is used.
			 */
			public void setupRelativeUriRoot() {
				setupRelativeUriRoot(getResourceSet(), uri);
			}
		
			/**
			 * Setup the given {@link URIHandler} as the first {@link URIHandler} in the {@link ResourceSet}
			 * @param resourceSet {@link ResourceSet} which applied
			 * @param uriHandler {@link URIHandler} which is set as primary
			 */
			@SuppressWarnings("WeakerAccess")
			public static void setPrimaryUriHandler(ResourceSet resourceSet, URIHandler uriHandler) {
			    resourceSet.getURIConverter().getURIHandlers().add(0, uriHandler);
			}
		
		
			/**
			 * Create a {@link ResourceSet} and register all {@link Resource.Factory} belongs to «modelName» metamodel.
			 * @return the created {@link ResourceSet}
			 */
			public static ResourceSet create«modelName»ResourceSet() {
			    ResourceSet resourceSet = new ResourceSetImpl();
			    register«modelName»Metamodel(resourceSet);
			    resourceSet.getResourceFactoryRegistry()
						.getExtensionToFactoryMap()
						.put(ResourceFactoryRegistryImpl.DEFAULT_EXTENSION, factory);
			    return resourceSet;
			}
		
			/**
			 * Get sensibe default for model loading options.
			 * @return Map of options
			 */
			public static Map<Object, Object> get«modelName»ModelDefaultLoadOptions() {
				Map<Object, Object> loadOptions = new HashMap<>();
				
				«IF config.customResourceFactory === null || config.customResourceFactory.empty»
					//loadOptions.put(XMLResource.OPTION_RECORD_UNKNOWN_FEATURE, Boolean.TRUE);
					//loadOptions.put(XMLResource.OPTION_EXTENDED_META_DATA, Boolean.TRUE);
					loadOptions.put(XMLResource.OPTION_DEFER_IDREF_RESOLUTION, Boolean.TRUE);
					loadOptions.put(XMLResource.OPTION_LAX_FEATURE_PROCESSING, Boolean.TRUE);
					loadOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
				«ENDIF»
			    return loadOptions;
			}
		
			/**
			 * Get sensibe default for model saving options.
			 * @return Map of options
			 */
			public static Map<Object, Object> get«modelName»ModelDefaultSaveOptions() {
				Map<Object, Object> saveOptions = new HashMap<>();
				«IF config.customResourceFactory === null || config.customResourceFactory.empty»
					saveOptions.put(XMLResource.OPTION_DECLARE_XML, Boolean.TRUE);
					saveOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
					saveOptions.put(XMLResource.OPTION_URI_HANDLER, new URIHandlerImpl() {
						public URI deresolve(URI uri) {
							return uri.hasFragment()
									&& uri.hasOpaquePart()
									&& this.baseURI.hasOpaquePart()
									&& uri.opaquePart().equals(this.baseURI.opaquePart())
										? URI.createURI("#" + uri.fragment())
										: super.deresolve(uri);
						}
					});
					saveOptions.put(XMLResource.OPTION_SCHEMA_LOCATION, Boolean.TRUE);
					saveOptions.put(XMLResource.OPTION_DEFER_IDREF_RESOLUTION, Boolean.TRUE);
					saveOptions.put(XMLResource.OPTION_SKIP_ESCAPE_URI, Boolean.FALSE);
					saveOptions.put(XMLResource.OPTION_ENCODING, "UTF-8");
				«ENDIF»

				return saveOptions;
			}

			/**
			 * Create default {@link Resource.Factory} for the «modelName» model.
			 * @return the created {@link Resource.Factory}
			 */
			public static Resource.Factory get«modelName»Factory() {

				«IF config.customResourceFactory !== null && !config.customResourceFactory.empty »
					return new «config.customResourceFactory»();
			    «ELSE»
					return new «moduleEmfName»ResourceFactoryImpl() {
						@Override
						public Resource createResource(URI uri) {
							«IF config.generateUuid»
								Resource result = new «moduleEmfName»ResourceImpl(uri) {
									@Override
									protected boolean useUUIDs() {
										return true;
									}
								};
						    «ELSE»
								Resource result = new «moduleEmfName»ResourceImpl(uri);
							«ENDIF»
							Map<Object, Object> loadOptions = result.getDefaultLoadOptions();
							//loadOptions.put(XMLResource.OPTION_RECORD_UNKNOWN_FEATURE, Boolean.TRUE);
							//loadOptions.put(XMLResource.OPTION_EXTENDED_META_DATA, Boolean.TRUE);
							loadOptions.put(XMLResource.OPTION_DEFER_IDREF_RESOLUTION, Boolean.TRUE);
							loadOptions.put(XMLResource.OPTION_LAX_FEATURE_PROCESSING, Boolean.TRUE);
							loadOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
							
							Map<Object, Object> saveOptions = result.getDefaultLoadOptions();
							saveOptions.put(XMLResource.OPTION_DECLARE_XML, Boolean.TRUE);
							saveOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
							saveOptions.put(XMLResource.OPTION_URI_HANDLER, new URIHandlerImpl() {
								public URI deresolve(URI uri) {
									return uri.hasFragment()
											&& uri.hasOpaquePart()
											&& this.baseURI.hasOpaquePart()
											&& uri.opaquePart().equals(this.baseURI.opaquePart())
											? URI.createURI("#" + uri.fragment())
											: super.deresolve(uri);
								}
							});
							saveOptions.put(XMLResource.OPTION_SCHEMA_LOCATION, Boolean.TRUE);
							saveOptions.put(XMLResource.OPTION_DEFER_IDREF_RESOLUTION, Boolean.TRUE);
							saveOptions.put(XMLResource.OPTION_SKIP_ESCAPE_URI, Boolean.FALSE);
							saveOptions.put(XMLResource.OPTION_ENCODING, "UTF-8");
							return result;

						}
					};
			    «ENDIF»
			}

			/**
			 * Register namespaces for «modelName» metamodel.
			 * @param resourceSet Register «modelName» packages for the given {@link ResourceSet}
			 */
			public static void register«modelName»Metamodel(ResourceSet resourceSet) {
				«FOR p : genPackages»
					resourceSet.getPackageRegistry().put(«moduleEmfName»Package.eINSTANCE.getNsURI(), «moduleEmfName»Package.eINSTANCE);
				«ENDFOR»
			}

		    // Builder specific code
		    private static ResourceSet $default$resourceSet() {
		        return create«modelName»ResourceSet();
		    }
		
		    private static URIHandler $default$uriHandler() {
		        return null;
		    }
		
		    private «modelName»ModelResourceSupport(final ResourceSet resourceSet,
											final URIHandler uriHandler,
											final URI uri) {
		        this.resourceSet = resourceSet;
		        this.uri = uri;
		
				if (uri == null && resourceSet != null) {
			        if (resourceSet.getResources().size() == 0) {
			            throw new IllegalStateException("URI is not defined and the given ResourceSet is empty. " 
			            		+ "At least one resource can be presented.");
			        }			        
					this.uri = resourceSet.getResources().get(0).getURI();
				}

		        if (uriHandler != null) {
		        	setPrimaryUriHandler(resourceSet, uriHandler);
				}
		        setupRelativeUriRoot();

		        // If resource does not exists, create resource
				if (getResourceSet().getResource(this.uri, false) == null) {
					Resource resource = factory.createResource(this.uri);
					getResourceSet().getResources().add(resource);
				}
		    }
		
			/**
			 * Builder for {@link «modelName»ModelResourceSupport}
			 */
		    public static class «modelName»ModelResourceSupportBuilder {
		        private ResourceSet resourceSet;
		        private URIHandler uriHandler;
		        private URI uri;
		
		        «modelName»ModelResourceSupportBuilder() {
		        }
		
		        public «modelName»ModelResourceSupportBuilder resourceSet(final ResourceSet resourceSet) {
		            this.resourceSet = resourceSet;
		            return this;
		        }
		
				public «modelName»ModelResourceSupportBuilder uriHandler(final URIHandler uriHandler) {
					this.uriHandler = uriHandler;
					return this;
				}
		
		        public «modelName»ModelResourceSupportBuilder uri(final URI uri) {
		            this.uri = uri;
		            return this;
		        }
		
		        public «modelName»ModelResourceSupport build() {
					if (uri == null && resourceSet == null) {
						throw new NullPointerException("URI or ResourceSet have to be defined");
					}
					return new «modelName»ModelResourceSupport(
							resourceSet != null ? resourceSet : $default$resourceSet(),
		                    uriHandler != null ? uriHandler : $default$uriHandler(),
							uri);
		        }
		
		        @Override
		        public java.lang.String toString() {
		            return "«modelName»ModelResourceSupportBuilder(resourceSet=" + this.resourceSet
							+ ", uriHandler=" + this.uriHandler
							+ ", uri=" + this.uri + ")";
		        }
		    }
		
			/**
			 * Construct a {@link «modelName»ModelResourceSupportBuilder} to build {@link «modelName»ModelResourceSupport}.
			 * @return instance of {@link «modelName»ModelResourceSupportBuilder}
			 */
			public static «modelName»ModelResourceSupportBuilder «modelName.decapitalize»ModelResourceSupportBuilder() {
		        return new «modelName»ModelResourceSupportBuilder();
		    }
		
			/**
			 * Get the resourceSet this helper based on.
			 * @return instance of {@link ResourceSet}
			 */
		    public ResourceSet getResourceSet() {
		        return this.resourceSet;
		    }
		
			/**
			 * Get the model's root resource which represents the model's uri {@link URI} itself.
			 * If the given resource does not exists new one is created.
			 * @return instance of {@link Resource}
			 */
			public Resource getResource() {
				if (getResourceSet().getResource(uri, false) == null) {
					Resource resource = factory.createResource(this.uri);
					getResourceSet().getResources().add(resource);
				}
				return getResourceSet().getResource(uri, false);
			}
		
			/**
			 * Add content to the given model's root.
			 * @return this {@link «modelName»ModelResourceSupport}
			 */
			@SuppressWarnings("UnusedReturnValue")
			public «modelName»ModelResourceSupport addContent(EObject object) {
				getResource().getContents().add(object);
				return this;
			}
		
			/**
			 * Load an model into {@link «modelName»ModelResourceSupport} default {@link Resource}.
			 * The {@link URI}, {@link URIHandler} and {@link ResourceSet} arguments are not used here, because it has
			 * already set.
			 * @param loadArgumentsBuilder {@link LoadArguments.LoadArgumentsBuilder} used for load.
			 * @return this {@link «modelName»ModelResourceSupport}
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			public «modelName»ModelResourceSupport loadResource(«modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder
																loadArgumentsBuilder)
					throws IOException, «modelName»ValidationException {
				return loadResource(loadArgumentsBuilder.build());
			}
		
			/**
			 * Load an model into {@link «modelName»ModelResourceSupport} default {@link Resource}.
			 * The {@link URI}, {@link URIHandler} and {@link ResourceSet} arguments are not used here, because it has
			 * already set.
			 * @param loadArguments {@link LoadArguments} used for load.
			 * @return this {@link «modelName»ModelResourceSupport}
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			@SuppressWarnings("WeakerAccess")
			public «modelName»ModelResourceSupport loadResource(«modelName»ModelResourceSupport.LoadArguments
														loadArguments)
					throws IOException, «modelName»ValidationException {
		
				Resource resource = getResource();
				Map loadOptions = loadArguments.getLoadOptions()
						.orElseGet(HashMap::new);
		
				try {
					InputStream inputStream = loadArguments.getInputStream()
							.orElseGet(() -> loadArguments.getFile().map(f -> {
						try {
							return new FileInputStream(f);
						} catch (FileNotFoundException e) {
							throw new RuntimeException(e);
						}
					}).orElse(null));
		
					if (inputStream != null) {
						resource.load(inputStream, loadOptions);
					} else {
						resource.load(loadOptions);
					}
		
				} catch (RuntimeException e) {
					if (e.getCause() instanceof IOException) {
						throw (IOException) e.getCause();
					} else {
						throw e;
					}
				}
		
				if (loadArguments.isValidateModel() && !isValid()) {
					throw new «modelName»ModelResourceSupport.«modelName»ValidationException(this);
				}
				return this;
			}
		
		
			/**
			 * Load an model. {@link «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder} contains all parameter
			 * @param loadArgumentsBuilder {@link LoadArguments.LoadArgumentsBuilder} used for load.
			 * @return created instance of {@link «modelName»ModelResourceSupport}
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			public static «modelName»ModelResourceSupport load«modelName»(«modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder
																  loadArgumentsBuilder)
					throws IOException, «modelName»ModelResourceSupport.«modelName»ValidationException {
				return load«modelName»(loadArgumentsBuilder.build());
			}
		
			/**
			 * Load an model. {@link «modelName»ModelResourceSupport.LoadArguments} contains all parameter
			 * @param loadArguments {@link LoadArguments} used for load.
			 * @return created instance of {@link «modelName»ModelResourceSupport}
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			public static «modelName»ModelResourceSupport load«modelName»(«modelName»ModelResourceSupport.LoadArguments loadArguments)
					throws IOException, «modelName»ModelResourceSupport.«modelName»ValidationException {
		
				«modelName»ModelResourceSupport «modelName.decapitalize»ModelResourceSupport = «modelName.decapitalize»ModelResourceSupportBuilder()
								.resourceSet(loadArguments.getResourceSet()
										.orElseGet(«modelName»ModelResourceSupport::create«modelName»ResourceSet))
								.uri(loadArguments.getUri()
										.orElseThrow(() -> new IllegalArgumentException("URI must be set")))
								.uriHandler(loadArguments.getUriHandler()
										.orElse(null))
								.build();
		
				«modelName.decapitalize»ModelResourceSupport.loadResource(loadArguments);
				if (loadArguments.isValidateModel() && !«modelName.decapitalize»ModelResourceSupport.isValid()) {
					throw new «modelName»ModelResourceSupport.«modelName»ValidationException(«modelName.decapitalize»ModelResourceSupport);
				}
				return «modelName.decapitalize»ModelResourceSupport;
			}
		
			/**
			 * Save the model to the given URI.
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			public void save«modelName»() throws IOException, «modelName»ModelResourceSupport.«modelName»ValidationException {
				save«modelName»(«modelName»ModelResourceSupport.SaveArguments.«modelName.decapitalize»SaveArgumentsBuilder());
			}
		
			/**
			 * Save the model as the given {@link SaveArguments.SaveArgumentsBuilder} defines
			 * @param saveArgumentsBuilder {@link SaveArguments.SaveArgumentsBuilder} used for save
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			public void save«modelName»(«modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder saveArgumentsBuilder)
					throws IOException, «modelName»ModelResourceSupport.«modelName»ValidationException {
				save«modelName»(saveArgumentsBuilder.build());
			}
		
			/**
			 * Save the model as the given {@link «modelName»ModelResourceSupport.SaveArguments} defines
			 * @param saveArguments {@link SaveArguments} used for save
			 * @throws IOException when IO error occured
			 * @throws «modelName»ValidationException when model validation is true and the model is invalid.
			 */
			@SuppressWarnings("WeakerAccess")
			public void save«modelName»(«modelName»ModelResourceSupport.SaveArguments saveArguments)
					throws IOException, «modelName»ModelResourceSupport.«modelName»ValidationException {
				if (saveArguments.isValidateModel() && !isValid()) {
					throw new «modelName»ModelResourceSupport.«modelName»ValidationException(this);
				}
				Map saveOptions = saveArguments.getSaveOptions()
						.orElseGet(«modelName»ModelResourceSupport::get«modelName»ModelDefaultSaveOptions);
				try {
					OutputStream outputStream = saveArguments.getOutputStream()
							.orElseGet(() -> saveArguments.getFile().map(f -> {
								try {
									return new FileOutputStream(f);
								} catch (FileNotFoundException e) {
									throw new RuntimeException(e);
								}
							}).orElse(null));
					if (outputStream != null) {
						getResource().save(outputStream, saveOptions);
					} else {
						getResource().save(saveOptions);
					}
				} catch (RuntimeException e) {
					if (e.getCause() instanceof IOException) {
						throw (IOException) e.getCause();
					} else {
						throw e;
					}
				}
			}
		
			private Diagnostic getDiagnostic(EObject eObject) {
				// TODO: The hack is called here
				fixEcoreUri();
				BasicDiagnostic diagnostics = new BasicDiagnostic
						(EObjectValidator.DIAGNOSTIC_SOURCE,
								0,
								String.format("Diagnosis of %s\n", diagnostician.getObjectLabel(eObject)),
								new Object [] { eObject });
		
				diagnostician.validate(eObject, diagnostics, diagnostician.createDefaultContext());
				return diagnostics;
			}
		
			private static <T> Predicate<T> distinctByKey(
					Function<? super T, ?> keyExtractor) {
		
				Map<Object, Boolean> seen = new ConcurrentHashMap<>();
				return t -> seen.putIfAbsent(keyExtractor.apply(t), Boolean.TRUE) == null;
			}
		
			/**
			 * Get distinct diagnostics for model. Only  {@link Diagnostic}.WARN and {@link Diagnostic}.ERROR are returns.
			 * @return set of {@link Diagnostic}
			 */
			public Set<Diagnostic> getDiagnostics() {
				return all()
						.filter(EObject.class :: isInstance)
						.map(EObject.class :: cast)
						.map(this :: getDiagnostic)
						.filter(d -> d.getSeverity() > Diagnostic.INFO)
						.filter(d -> d.getChildren().size() > 0)
						.flatMap(d -> d.getChildren().stream())
						.filter(distinctByKey(Object::toString))
						.collect(Collectors.toSet());
			}
		
			/**
			 * Checks the model have any {@link Diagnostic}.ERROR diagnostics. When there is no any the model assumed as valid.
			 * @return true when model is valid
			 */
			public boolean isValid() {
				Set<Diagnostic> diagnostics = getDiagnostics();
				return diagnostics.stream().noneMatch(e -> e.getSeverity() >= Diagnostic.ERROR);
			}
		
			/**
			 * Print model as string
			 * @return model as XML string
			 */
			public String asString() {
				ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
				try {
					// Do not call save on model to bypass the validation
					getResource().save(byteArrayOutputStream, Collections.EMPTY_MAP);
				} catch (IOException ignored) {
				}
				return new String(byteArrayOutputStream.toByteArray(), Charset.defaultCharset());
			}
		
			/**
			 * Get diagnostics as a String
			 * @return diagnostic list as string. Every line represents one diagnostic.
			 */
			public String getDiagnosticsAsString() {
				return getDiagnostics().stream().map(Object::toString).collect(Collectors.joining("\n"));
			}
		
			/**
			 * Arguments for {@link «modelName»ModelResourceSupport#load«modelName»(«modelName»ModelResourceSupport.LoadArguments)}
			 * It can handle variance of the presented arguments.
			 */
			public static class LoadArguments {
				private URI uri;
				private URIHandler uriHandler;
				private ResourceSet resourceSet;
				private Map<Object, Object> loadOptions;
				private boolean validateModel;
				private InputStream inputStream;
				private File file;
		
				private static URIHandler $default$uriHandler() {
					return null;
				}
		
				private static ResourceSet $default$resourceSet() {
					return null;
				}
		
				private static File $default$file() {
					return null;
				}
		
				private static InputStream $default$inputStream() {
					return null;
				}
		
				private static Map<Object, Object> $default$loadOptions() {
					return «modelName»ModelResourceSupport.get«modelName»ModelDefaultLoadOptions();
				}
		
				Optional<URI> getUri() {
					return ofNullable(uri);
				}
		
				Optional<URIHandler> getUriHandler() {
					return ofNullable(uriHandler);
				}
		
				Optional<ResourceSet> getResourceSet() {
					return ofNullable(resourceSet);
				}
		
				Optional<Map<Object, Object>> getLoadOptions() {
					return ofNullable(loadOptions);
				}
		
				boolean isValidateModel() {
					return validateModel;
				}
		
				Optional<InputStream> getInputStream() {
					return ofNullable(inputStream);
				}
		
				Optional<File> getFile() {
					return ofNullable(file);
				}
		
		
		
				@java.lang.SuppressWarnings("all")
				/**
				 * Builder for {@link «modelName»ModelResourceSupport#load«modelName»Model(«modelName»ModelResourceSupport.LoadArguments)}.
				 */
				public static class LoadArgumentsBuilder {
					private URI uri;
					private boolean validateModel = true;
		
					private boolean uriHandler$set;
					private URIHandler uriHandler;
		
					private boolean resourceSet$set;
					private ResourceSet resourceSet;
		
					private boolean loadOptions$set;
					private Map<Object, Object> loadOptions;
		
					private boolean file$set;
					private File file;
		
					private boolean inputStream$set;
					private InputStream inputStream;
		
					LoadArgumentsBuilder() {
					}
		
					/**
					 * Defines the {@link URI} of the model.
					 * This is mandatory.
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder uri(final URI uri) {
						requireNonNull(uri);
						this.uri = uri;
						return this;
					}
		
					@java.lang.SuppressWarnings("all")
					/**
					 * Defines the {@link URIHandler} used for model IO. If not defined the default is EMF used.
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder uriHandler(
							final URIHandler uriHandler) {
						requireNonNull(uriHandler);
						this.uriHandler = uriHandler;
						uriHandler$set = true;
						return this;
					}
		
					@java.lang.SuppressWarnings("all")
					/**
					 * Defines the default {@link ResourceSet}. If it is not defined the factory based resourceSet is used.
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder resourceSet(
							final ResourceSet resourceSet) {
						requireNonNull(resourceSet);
						this.resourceSet = resourceSet;
						resourceSet$set = true;
						return this;
					}
		
					@java.lang.SuppressWarnings("all")
					/**
					 * Defines the load options for model. If not defined the
					 * {@link «modelName»ModelResourceSupport#get«modelName»ModelDefaultLoadOptions()} us used.
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder loadOptions(
							final Map<Object, Object> loadOptions) {
						requireNonNull(loadOptions);
						this.loadOptions = loadOptions;
						loadOptions$set = true;
						return this;
					}
		
					@java.lang.SuppressWarnings("all")
					/**
					 * Defines that model validation required or not on load. Default: true
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder validateModel(boolean validateModel) {
						this.validateModel = validateModel;
						return this;
					}
		
					@java.lang.SuppressWarnings("all")
					/**
					 * Defines the file if it is not loaded from URI. If not defined, URI is used. If inputStream is defined
					 * it is used.
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder file(final File file) {
						requireNonNull(file);
						this.file = file;
						file$set = true;
						return this;
					}
		
					@java.lang.SuppressWarnings("all")
					/**
					 * Defines the file if it is not loaded from  File or URI. If not defined, File or URI is used.
					 */
					public «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder inputStream(
							final InputStream inputStream) {
						requireNonNull(inputStream);
						this.inputStream = inputStream;
						inputStream$set = true;
						return this;
					}
		
		
					public «modelName»ModelResourceSupport.LoadArguments build() {
						URIHandler uriHandler = this.uriHandler;
						if (!uriHandler$set) uriHandler = «modelName»ModelResourceSupport.LoadArguments.$default$uriHandler();
						ResourceSet resourceSet = this.resourceSet;
						if (!resourceSet$set) resourceSet = «modelName»ModelResourceSupport.LoadArguments.$default$resourceSet();
						Map<Object, Object> loadOptions = this.loadOptions;
						if (!loadOptions$set) loadOptions = «modelName»ModelResourceSupport.LoadArguments.$default$loadOptions();
						File file = this.file;
						if (!file$set) file = «modelName»ModelResourceSupport.LoadArguments.$default$file();
						InputStream inputStream = this.inputStream;
						if (!inputStream$set) inputStream = «modelName»ModelResourceSupport.LoadArguments.$default$inputStream();
		
						return new «modelName»ModelResourceSupport.LoadArguments(uri, uriHandler, resourceSet,
								loadOptions, validateModel, file, inputStream);
					}
		
					@java.lang.Override
					public java.lang.String toString() {
						return "«modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder(uri=" + this.uri
								+ ", uri=" + this.uri
								+ ", uriHandler=" + this.uriHandler
								+ ", resourceSet=" + this.resourceSet
								+ ", loadOptions=" + this.loadOptions
								+ ", validateModel=" + this.validateModel
								+ ", file=" + this.file
								+ ", inputStream=" + this.inputStream
								+ ")";
					}
				}
		
				public static «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder «modelName.decapitalize»LoadArgumentsBuilder() {
					return new «modelName»ModelResourceSupport.LoadArguments.LoadArgumentsBuilder();
				}
		
				private LoadArguments(final URI uri,
									  final URIHandler uriHandler,
									  final ResourceSet resourceSet,
									  final Map<Object, Object> loadOptions,
									  final boolean validateModel,
									  final File file,
									  final InputStream inputStream) {
					this.uri = uri;
					this.uriHandler = uriHandler;
					this.resourceSet = resourceSet;
					this.loadOptions = loadOptions;
					this.validateModel = validateModel;
					this.file = file;
					this.inputStream = inputStream;
				}
			}
		
			/**
			 * Arguments for {@link «modelName»ModelResourceSupport#save«modelName»(«modelName»ModelResourceSupport.SaveArguments)}
			 * It can handle variance of the presented arguments.
			 */
			public static class SaveArguments {
				OutputStream outputStream;
				File file;
				Map<Object, Object> saveOptions;
				boolean validateModel;
		
				private static OutputStream $default$outputStream() {
					return null;
				}
		
				private static File $default$file() {
					return null;
				}
		
				private static Map<Object, Object> $default$saveOptions() {
					return null;
				}
		
				Optional<OutputStream> getOutputStream() {
					return ofNullable(outputStream);
				}
		
				Optional<File> getFile() {
					return ofNullable(file);
				}
		
				Optional<Map<Object, Object>> getSaveOptions() {
					return ofNullable(saveOptions);
				}
		
				boolean isValidateModel() {
					return validateModel;
				}
		
				@java.lang.SuppressWarnings("all")
				/**
				 * Builder for {@link «modelName»ModelResourceSupport#save«modelName»Model(«modelName»ModelResourceSupport.SaveArguments)}.
				 */
				public static class SaveArgumentsBuilder {
					private boolean outputStream$set;
					private OutputStream outputStream;
		
					private boolean file$set;
					private File file;
		
					private boolean saveOptions$set;
					private Map<Object, Object> saveOptions;
		
					private boolean validateModel = true;
		
					public Optional<OutputStream> getOutputStream() {
						return ofNullable(outputStream);
					}
		
					public Optional<File> getFile() {
						return ofNullable(file);
					}
		
					public Optional<Map<Object, Object>> getSaveOptions() {
						return ofNullable(saveOptions);
					}
		
					public boolean isValidateModel() {
						return validateModel;
					}
		
					SaveArgumentsBuilder() {
					}
		
					/**
					 * Defines {@link OutputStream} which is used by save. Whe it is not defined, file is used.
					 */
					public «modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder outputStream(
							final OutputStream outputStream) {
						requireNonNull(outputStream);
						this.outputStream = outputStream;
						outputStream$set = true;
						return this;
					}
		
					/**
					 * Defines {@link File} which is used by save. Whe it is not defined the model's
					 * {@link «modelName»ModelResourceSupport#uri is used}
					 */
					public «modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder file(File file) {
						requireNonNull(file);
						this.file = file;
						file$set = true;
						return this;
					}
		
					/**
					 * Defines save options. When it is not defined
					 * {@link «modelName»ModelResourceSupport#get«modelName»ModelDefaultSaveOptions()} is used.
					 * @param saveOptions
					 * @return
					 */
					public «modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder saveOptions(
							final Map<Object, Object> saveOptions) {
						requireNonNull(saveOptions);
						this.saveOptions = saveOptions;
						saveOptions$set = true;
						return this;
					}
		
					/**
					 * Defines that model validation required or not on save. Default: true
					 */
					public «modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder validateModel(boolean validateModel) {
						this.validateModel = validateModel;
						return this;
					}
		
					public «modelName»ModelResourceSupport.SaveArguments build() {
						OutputStream outputStream = this.outputStream;
						if (!outputStream$set) outputStream = «modelName»ModelResourceSupport.SaveArguments.$default$outputStream();
						File file = this.file;
						if (!file$set) file = «modelName»ModelResourceSupport.SaveArguments.$default$file();
						Map<Object, Object> saveOptions = this.saveOptions;
						if (!saveOptions$set) saveOptions = «modelName»ModelResourceSupport.SaveArguments.$default$saveOptions();
						return new «modelName»ModelResourceSupport.SaveArguments(outputStream, file, saveOptions, validateModel);
					}
		
					@java.lang.Override
					public java.lang.String toString() {
						return "«modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder(outputStream=" + this.outputStream
								+ ", file=" + this.file
								+ ", saveOptions=" + this.saveOptions + ")";
					}
				}
		
				public static «modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder «modelName.decapitalize»SaveArgumentsBuilder() {
					return new «modelName»ModelResourceSupport.SaveArguments.SaveArgumentsBuilder();
				}
		
				private SaveArguments(final OutputStream outputStream,
									  final File file,
									  final Map<Object, Object> saveOptions,
									  final boolean validateModel) {
					this.outputStream = outputStream;
					this.file = file;
					this.saveOptions = saveOptions;
					this.validateModel = validateModel;
				}
			}
		
			/**
			 * This exception is thrown when validateModel is true on load or save and the model is not conform with its
			 * defined metamodel.
			 */
			public static class «modelName»ValidationException extends Exception {
				«modelName»ModelResourceSupport «modelName.decapitalize»ModelResourceSupport;
		
				«modelName»ValidationException(«modelName»ModelResourceSupport «modelName.decapitalize»ModelResourceSupport) {
					super("Invalid model\n" +
							«modelName.decapitalize»ModelResourceSupport.getDiagnosticsAsString() + "\n" + «modelName.decapitalize»ModelResourceSupport.asString()
					);
					this.«modelName.decapitalize»ModelResourceSupport = «modelName.decapitalize»ModelResourceSupport;
				}
		
				«modelName»ModelResourceSupport get«modelName»ModelResourceSupport() {
					return «modelName.decapitalize»ModelResourceSupport;
				}
			}
		
			// TODO: Create ticket on Eclipse. The problem is that the DelegatingResourceLocator
			// creating a baseURL which ends with two trailing slash and the ResourceBundle cannot open the files.
			// This bug is came on Felix based OSGi container.
			private static void fixEcoreUri() {
				try {
					URL baseUrl = EcorePlugin.INSTANCE.getBaseURL();
					if (baseUrl.toString().startsWith("bundle:") && baseUrl.toString().endsWith("//")) {
						URL fixedUrl = new URL(baseUrl.toString().substring(0, baseUrl.toString().length() - 1));
						Field myField = getField(DelegatingResourceLocator.class, "baseURL");
						myField.setAccessible(true);
						myField.set(EcorePlugin.INSTANCE, fixedUrl);
					}
				} catch (Throwable t) {
					t.printStackTrace(System.out);
				}
		
			}
		
			private static Field getField(Class clazz, String fieldName)
					throws NoSuchFieldException {
				try {
					return clazz.getDeclaredField(fieldName);
				} catch (NoSuchFieldException e) {
					Class superClass = clazz.getSuperclass();
					if (superClass == null) {
						throw e;
					} else {
						return getField(superClass, fieldName);
					}
				}
			}
		}
	'''
}