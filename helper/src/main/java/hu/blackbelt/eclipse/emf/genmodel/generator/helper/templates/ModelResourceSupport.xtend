package hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates;

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.emf.codegen.ecore.genmodel.GenModel

class ModelResourceSupport implements IGenerator {
	@Inject extension Naming
	
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
		import org.eclipse.emf.common.util.EList;
		import org.eclipse.emf.common.util.URI;
		import org.eclipse.emf.ecore.resource.ContentHandler;
		import org.eclipse.emf.ecore.resource.Resource;
		import org.eclipse.emf.ecore.resource.ResourceSet;
		import org.eclipse.emf.ecore.resource.URIHandler;
		import org.eclipse.emf.ecore.resource.impl.ExtensibleURIConverterImpl;
		import org.eclipse.emf.ecore.resource.impl.ResourceFactoryRegistryImpl;
		import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
		import org.eclipse.emf.ecore.xmi.XMLResource;
		import org.eclipse.emf.ecore.xmi.impl.URIHandlerImpl;
		
		import java.util.HashMap;
		import java.util.Iterator;
		import java.util.Map;
		import java.util.Optional;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		«FOR p : genPackages»
			import «p.packageFqName».«moduleEmfName»Package;			
			import «p.packageFqName».util.«moduleEmfName»ResourceFactoryImpl;
			import «p.packageFqName».util.«moduleEmfName»ResourceImpl;			
		«ENDFOR»

		public class «modelName»ModelResourceSupport {

			ResourceSet resourceSet;
			
			Optional<URIHandler> uriHandler;
			
			Optional<URI> rootUri;
			
			public <T> Stream<T> asStream(Iterator<T> sourceIterator) {
			    return asStream(sourceIterator, false);
			}
			
			public <T> Stream<T> asStream(Iterator<T> sourceIterator, boolean parallel) {
			    Iterable<T> iterable = () -> sourceIterator;
			    return StreamSupport.stream(iterable.spliterator(), parallel);
			}
			
			@SuppressWarnings("unchecked")
			public <T> Stream<T> all() {
			    return asStream((Iterator<T>) resourceSet.getAllContents(), false);
			}
			
			@SuppressWarnings("unchecked")
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
			            return normalize(result);
			        }
			    });
			
			    resourceSet.getURIConverter().getURIHandlers().clear();
			    resourceSet.getURIConverter().getURIHandlers().addAll(uriHandlers);
			    resourceSet.getURIConverter().getContentHandlers().clear();
			    resourceSet.getURIConverter().getContentHandlers().addAll(contentHandlers);
			}


			public static void setupUriHandler(ResourceSet resourceSet, URIHandler uriHandler) {
			    resourceSet.getURIConverter().getURIHandlers().add(0, uriHandler);
			}


			public static ResourceSet create«modelName»ResourceSet() {
			    ResourceSet resourceSet = new ResourceSetImpl();
			    register«modelName»Metamodel(resourceSet);
			    resourceSet.getResourceFactoryRegistry().getExtensionToFactoryMap().put(ResourceFactoryRegistryImpl.DEFAULT_EXTENSION, get«modelName»Factory());
			    return resourceSet;
			}
			
			public static Map<Object, Object> get«modelName»ModelDefaultLoadOptions() {
			    Map<Object, Object> loadOptions = new HashMap<>();
			    //loadOptions.put(XMLResource.OPTION_RECORD_UNKNOWN_FEATURE, Boolean.TRUE);
			    //loadOptions.put(XMLResource.OPTION_EXTENDED_META_DATA, Boolean.TRUE);
			    loadOptions.put(XMLResource.OPTION_DEFER_IDREF_RESOLUTION, Boolean.TRUE);
			    loadOptions.put(XMLResource.OPTION_LAX_FEATURE_PROCESSING, Boolean.TRUE);
			    loadOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
			    return loadOptions;
			}
			
			public static Map<Object, Object> get«modelName»ModelDefaultSaveOptions() {
			    Map<Object, Object> saveOptions = new HashMap<>();
			    saveOptions.put(XMLResource.OPTION_DECLARE_XML, Boolean.TRUE);
			    saveOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
			    saveOptions.put(XMLResource.OPTION_URI_HANDLER, new URIHandlerImpl() {
			        public URI deresolve(URI uri) {
			            return uri.hasFragment() && uri.hasOpaquePart() && this.baseURI.hasOpaquePart() && uri.opaquePart().equals(this.baseURI.opaquePart()) ? URI.createURI("#" + uri.fragment()) : super.deresolve(uri);
			        }
			    });
			    saveOptions.put(XMLResource.OPTION_SCHEMA_LOCATION, Boolean.TRUE);
			    saveOptions.put(XMLResource.OPTION_DEFER_IDREF_RESOLUTION, Boolean.TRUE);
			    saveOptions.put(XMLResource.OPTION_SKIP_ESCAPE_URI, Boolean.FALSE);
			    saveOptions.put(XMLResource.OPTION_ENCODING, "UTF-8");
			    return saveOptions;
			}
			
			public static Resource.Factory get«modelName»Factory() {
			    return new «moduleEmfName»ResourceFactoryImpl() {
			        @Override
			        public Resource createResource(URI uri) {
			            Resource result = new «moduleEmfName»ResourceImpl(uri) {
			                @Override
			                protected boolean useUUIDs() {
			                    return true;
			                }
			            };
			            return result;
			        }
			    };
			}

			
			public static void register«modelName»Metamodel(ResourceSet resourceSet) {
				«FOR p : genPackages»
					resourceSet.getPackageRegistry().put(«moduleEmfName»Package.eINSTANCE.getNsURI(), «moduleEmfName»Package.eINSTANCE);
				«ENDFOR»
			}

		    // Builder specific code
		    @SuppressWarnings("all")
		    private static ResourceSet $default$resourceSet() {
		        return create«modelName»ResourceSet();
		    }
		
		    @SuppressWarnings("all")
		    private static Optional<URIHandler> $default$uriHandler() {
		        return Optional.empty();
		    }
		
		    @SuppressWarnings("all")
		    private static Optional<URI> $default$rootUri() {
		        return Optional.empty();
		    }
		
		    @SuppressWarnings("all")
		    «modelName»ModelResourceSupport(final ResourceSet resourceSet, final Optional<URIHandler> uriHandler, final Optional<URI> rootUri) {
		        this.resourceSet = resourceSet;
		        this.uriHandler = uriHandler;
		        this.rootUri = rootUri;
		
		        if (uriHandler.isPresent()) {
		            setupUriHandler(resourceSet, uriHandler.get());
		        }
		        if (rootUri.isPresent()) {
		            setupRelativeUriRoot(resourceSet, rootUri.get());
		        }
		    }
		
		    @SuppressWarnings("all")
		    public static class «modelName»ModelResourceSupportBuilder {
		        @SuppressWarnings("all")
		        private ResourceSet resourceSet;
		        @SuppressWarnings("all")
		        private Optional<URIHandler> uriHandler;
		        @SuppressWarnings("all")
		        private Optional<URI> rootUri;
		
		        @SuppressWarnings("all")
		        «modelName»ModelResourceSupportBuilder() {
		        }
		
		        @SuppressWarnings("all")
		        public «modelName»ModelResourceSupportBuilder resourceSet(final ResourceSet resourceSet) {
		            this.resourceSet = resourceSet;
		            return this;
		        }
		
		        @SuppressWarnings("all")
		        public «modelName»ModelResourceSupportBuilder uriHandler(final Optional<URIHandler> uriHandler) {
		            this.uriHandler = uriHandler;
		            return this;
		        }
		
		        @SuppressWarnings("all")
		        public «modelName»ModelResourceSupportBuilder rootUri(final Optional<URI> rootUri) {
		            this.rootUri = rootUri;
		            return this;
		        }
		
		        @SuppressWarnings("all")
		        public «modelName»ModelResourceSupport build() {
		            return new «modelName»ModelResourceSupport(resourceSet != null ? resourceSet : «modelName»ModelResourceSupport.$default$resourceSet(),
		                    uriHandler != null ? uriHandler : «modelName»ModelResourceSupport.$default$uriHandler(),
		                    rootUri != null ? rootUri : «modelName»ModelResourceSupport.$default$rootUri());
		        }

		        @Override
		        @SuppressWarnings("all")
		        public java.lang.String toString() {
		            return "«modelName»ModelResourceSupport.«modelName»ModelResourceSupportBuilder(resourceSet=" + this.resourceSet + ", uriHandler=" + this.uriHandler + ", rootUri=" + this.rootUri + ")";
		        }
		    }
		
		    @SuppressWarnings("all")
		    public static «modelName»ModelResourceSupportBuilder «modelName.decapitalize()»ModelResourceSupportBuilder() {
		        return new «modelName»ModelResourceSupportBuilder();
		    }
		
		    @SuppressWarnings("all")
		    public ResourceSet getResourceSet() {
		        return this.resourceSet;
		    }
		}
	'''
}