package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import javax.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.emf.codegen.ecore.genmodel.GenClass
import org.eclipse.emf.codegen.ecore.genmodel.GenClassifier
import org.eclipse.emf.codegen.ecore.genmodel.GenFeature
import org.eclipse.emf.codegen.ecore.genmodel.GenTypedElement
import org.eclipse.emf.codegen.ecore.genmodel.GenTypeParameter
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import hu.blackbelt.eclipse.emf.genmodel.generator.builder.engine.BuilderConfig

class ModelBuilderBuilder {
	@Inject extension ModelBuilderExtension

	Resource resource
	JavaExtensions javaExtension

	@Inject 
	BuilderConfig builderConfig;

//	String featureModifierMethodPrefix = "with"
	
	def doGenerate(GenClass genClass, Resource input, IFileSystemAccess fsa) {		
	    val builder = genClass.generateBuilder
	    this.resource = input;
	    javaExtension = new JavaExtensions(resource.allContents.filter(x | x instanceof GenModel).map(x | x as GenModel).toList)
	    fsa.generateFile(genClass.builderBuilderFileName, builder)	    
	}
    
    def generateBuilder(GenClass it) '''
		package «builderBuilderPackage»;
		
		/**
		  * <!-- begin-user-doc --> 
		  *   A builder for the model object ' <em><b>«modelJava»</b></em>'.
		  * <!-- end-user-doc -->
		  * 
		  * @generated
		  */
		public class «builderBuilderName()» implements «genPackage.builderInterfaceName»<«modelJava»> {
		 
		    // features and builders
		 	«FOR unary : unaryStructuralFeatures»
		 		«unary.declaration»
		 	«ENDFOR»
		
		 	«FOR multi : multipleStructuralFeatures»
		 		«multi.declarationMulti»
		 	«ENDFOR»
		
		 	// helper attributes
		 	«FOR struct : structuralFeatures»
		 		«struct.assignmentHelperDeclaration»
		 	«ENDFOR»
		
		    /**
		     * This method can be used to override attributes of the builder. It constructs a new builder and copies the current values to it.
		     */
		    public «builderBuilderName()» but() {
			   	«builderBuilderName()» _builder = create();
			  	«FOR struct : structuralFeatures»
			  		«assignBuilderFeatures(struct,"_builder")»
			  	«ENDFOR»
			  	return _builder;
		  	}
		
		    /**
		     * This method constructs the final «modelJava» type.
		     * @return new instance of the «modelJava» type
		     */
		    public «modelJava» build() {
		    	final «modelJava» _newInstance = «genPackage.packageFqName».«factoryInstance()».create«name.toFirstUpper()»();
			 	«FOR unary : unaryStructuralFeatures»
			 		«unary.assignFeature("_newInstance")»
			 	«ENDFOR»		
			 	«FOR multi : multipleStructuralFeatures»
			 		«multi.assignFeatureMulti("_newInstance")»
			 	«ENDFOR»
		    	return _newInstance;
			}

		    /**
		     * Builder is not instantiated with a constructor.
		     * @see #new«builderBuilderName()»()
		     */ 
		    private «builderBuilderName()»() {
		    }
		   
		    /**
		     * This method creates a new instance of the «builderBuilderName()».
		     * @return new instance of the «builderBuilderName()»
		     */
		    public static «builderBuilderName()» create() {
		        return new «builderBuilderName()»();
		    }

		 	«FOR unary : unaryStructuralFeatures»
		 		«unary.method(it)»
		 	«ENDFOR»
		
		 	«FOR multi : multipleStructuralFeatures»
		 		«multi.methodMulti(it)»
		 	«ENDFOR»

		}
	 	'''

	def typeDeclaration(GenFeature it) {
		if (typeGenClass !== null)
			typeDeclaration(typeGenClass)
		else 
			typeDeclaration(typeGenClassifier)
	}
	
	def typeDeclaration(GenClassifier it) {
		if (ecoreClassifier.instanceClassName !== null) {
			ecoreClassifier.typeWithGeneric
		} else {
			modelJava
		}
	}

	def typeDeclaration(EClassifier it) {
		if (instanceClassName !== null) {
			typeWithGeneric
		} else {
			javaExtension.fqGenJavaPackage(it) + "." + name.toJavaRef
		}
	}

    def String typeWithGeneric(EClassifier it) {
		if (instanceClassName == "java.util.Map$Entry") {
	    	instanceClassName.toJavaRef + "<" + (it as EClass).EAllStructuralFeatures.map[EType as EClassifier].map[typeDeclaration].join(", ") + ">"		
		} else {
			instanceClassName.toJavaRef
		}
	}
 
	def typeDeclaration(GenTypedElement it) {
		("Unmapped Element '" + it + "' in typeDeclaration").throwRuntimeException;
	}

	def typeDeclaration(GenTypeParameter it) {
		("Unmapped Element '" + it + "' in typeDeclaration").throwRuntimeException;
	}


	def declaration(GenFeature it) '''
		private «typeDeclaration» m_«safeName()»;
		«IF effectiveType.isBuilderType»
			private «effectiveType.genPackage.builderInterfaceName»<? extends «effectiveType.modelJava»> m_feature«safeName().toFirstUpper()»Builder;   
		«ENDIF»
		'''

	def declarationMulti(GenFeature it) '''
		private java.util.Collection<«typeDeclaration»> m_«safeName()»;
		«IF effectiveType.isBuilderType»
			private java.util.Collection<«effectiveType.genPackage.builderInterfaceName»<? extends «effectiveType.modelJava»>> m_feature«safeName().toFirstUpper()»Builder = new java.util.LinkedList<«effectiveType.genPackage.builderInterfaceName»<? extends «effectiveType.modelJava»>>();   
		«ENDIF»
		'''

	def assignmentHelperDeclaration(GenFeature it) '''
		private boolean m_feature«safeName().toFirstUpper()»Set = false;
		'''

	def assignBuilderFeatures(GenFeature it, String p_var) '''
		«p_var».m_feature«safeName.toFirstUpper»Set = m_feature«safeName.toFirstUpper»Set;
		«IF effectiveType.isBuilderType()»
			«p_var».m_feature«safeName().toFirstUpper()»Builder = m_feature«safeName().toFirstUpper()»Builder;
	    «ENDIF»
   		'''


	def assignFeature(GenFeature it, String p_var) '''
		if (m_feature«safeName().toFirstUpper()»Set) {
			«p_var».set«safeSetterName().toFirstUpper()»(m_«safeName()»);
		«IF effectiveType.isBuilderType()»
			} else {
					if (m_feature«safeName().toFirstUpper()»Builder != null) {
						«p_var».set«safeSetterName().toFirstUpper()»(m_feature«safeName().toFirstUpper()»Builder.build());
					}
				}
		«ELSE»
		}
		«ENDIF»
		''' 

	def assignFeatureMulti(GenFeature it, String p_var) '''
		if(m_feature«safeName().toFirstUpper()»Set) {
			«p_var».get«potentiallyPluralizedName().toFirstUpper()»().addAll(m_«safeName()»);
		«IF effectiveType.isBuilderType()»
			} else {
				if (!m_feature«safeName().toFirstUpper()»Builder.isEmpty()) {
					for («genPackage.builderInterfaceName»<? extends «effectiveType.modelJava()»> builder: m_feature«safeName().toFirstUpper()»Builder) {
						«p_var».get«potentiallyPluralizedName().toFirstUpper()»().add(builder.build());
					}
				}
			}
		«ELSE»
		}
		«ENDIF»
		''' 

	// extension to calculate the name of the feature access method
	def featureAccessMethod(GenFeature it) {
		if (builderConfig.featureModifierMethodPrefix === null || builderConfig.featureModifierMethodPrefix.trim().length === 0)
			safeName() 
		else
		  builderConfig.featureModifierMethodPrefix + safeName().toFirstUpper; 
	    }

    def method(GenFeature it, GenClass p_context) '''
		public «p_context.builderBuilderName» «featureAccessMethod»(«typeDeclaration» p_«safeName()»){
			m_«safeName()» = p_«safeName()»;
			m_feature«safeName().toFirstUpper()»Set = true;
			return this;
		}
		«IF it.typeGenClassifier.isBuilderType()»
			public «p_context.builderBuilderName()» «featureAccessMethod()»(«effectiveType.genPackage.builderInterfaceName»<? extends «effectiveType.modelJava»> p_«p_context.builderBuilderName.toFirstLower()»){
				m_feature«safeName().toFirstUpper()»Builder = p_«p_context.builderBuilderName().toFirstLower()»;
				return this;
			} 
		«ENDIF» 
		'''

    def methodMulti(GenFeature it, GenClass p_context) '''
		public «p_context.builderBuilderName» «featureAccessMethod»(«typeDeclaration» p_«safeName()»){
			m_«safeName()».add(p_«safeName()»);
			m_feature«safeName().toFirstUpper()»Set = true;
			return this;
		}

		public «p_context.builderBuilderName» «featureAccessMethod»(java.util.Collection<? extends «typeDeclaration»> p_«safeName()»){
			m_«safeName()».addAll(p_«safeName()»);
			m_feature«safeName().toFirstUpper()»Set = true;
			return this;
		}

		«IF it.typeGenClassifier.isBuilderType()»
			public «p_context.builderBuilderName()» «featureAccessMethod()»(«effectiveType.genPackage.builderInterfaceName»<? extends «effectiveType.modelJava»> p_«p_context.builderBuilderName.toFirstLower()»){
				m_feature«safeName().toFirstUpper()»Builder.add(p_«p_context.builderBuilderName().toFirstLower()»);
				return this;
			} 
		«ENDIF» 
		'''
}

//«DEFINE builderImplementation FOR EClass»
//  «IF isNonAbstractBuilderType()»
//    «FILE fqBuilderFile()»
//      package «fqBuilderJavaPackage()»;
//      
//      /**
//       * <!-- begin-user-doc --> 
//       *   A builder for the model object ' <em><b>«fqGenJava()»</b></em>'.
//       * <!-- end-user-doc -->
//       * 
//       * @generated
//       */
//      public class «builderName()» implements «ePackage.fqInterfaceJava()»<«fqGenJava()»> {
//      
//        // features and builders
//        «EXPAND declaration FOREACH unaryStructuralFeatures()»
//        «EXPAND declarationMulti FOREACH multipleStructuralFeatures()»
//        
//        // helper attributes
//        «EXPAND assignmentHelperDeclaration FOREACH structuralFeatures()»        
//      
//        /**
//         * Builder is not instantiated with a constructor.
//         * @see #new«builderName()»()
//         */ 
//        private «builderName()»() {
//        }
//        
//        /**
//         * This method creates a new instance of the «builderName()».
//         * @return new instance of the «builderName()»
//         */
//        public static «builderName()» create() {
//          return new «builderName()»();
//        }
//        
//        /**
//         * This method can be used to override attributes of the builder. It constructs a new builder and copies the current values to it.
//         */
//        public «builderName()» but() {
//          «LET "_builder" AS var»
//            «builderName()» «var» = create();        
//            «EXPAND assignBuilderFeatures(var) FOREACH structuralFeatures()»           
//            return «var»;
//          «ENDLET»            
//        }
//        
//        /**
//         * This method constructs the final «fqGenJava()» type.
//         * @return new instance of the «fqGenJava()» type
//         */
//        public «fqGenJava()» build() {
//          «LET "_newInstance" AS var»
//            final «fqGenJava()» «var» = «fqGenJavaPackage()».«factoryInstance()».create«name.toFirstUpper()»();            
//            «EXPAND assignFeatures(var) FOREACH unaryStructuralFeatures()»
//            «EXPAND assignFeaturesMulti(var) FOREACH multipleStructuralFeatures()»            
//            return «var»;
//          «ENDLET»
//        }    
//        
//        «EXPAND method(this) FOREACH unaryStructuralFeatures()»
//        «EXPAND methodMulti(this) FOREACH multipleStructuralFeatures()»
//      }
//    «ENDFILE»
//  «ENDIF»
//«ENDDEFINE»
//
//
//«DEFINE assignFeatures(String p_var) FOR EStructuralFeature»
//  if(m_feature«safeName().toFirstUpper()»Set) {
//    «p_var».set«safeSetterName().toFirstUpper()»(m_«safeName()»);     
//  «IF eType.isBuilderType()»
//  } else {
//    if (m_feature«safeName().toFirstUpper()»Builder != null) {
//      «p_var».set«safeSetterName().toFirstUpper()»(m_feature«safeName().toFirstUpper()»Builder.build());
//    }    
//  }
//  «ELSE»
//  }
//  «ENDIF»
//«ENDDEFINE»
//
//«DEFINE assignFeaturesMulti(String p_var) FOR EStructuralFeature»
//  if(m_feature«safeName().toFirstUpper()»Set) {    
//    «p_var».get«potentiallyPluralizedName().toFirstUpper()»().addAll(m_«safeName()»);        
//  «IF eType.isBuilderType()»
//  } else {
//    if (!m_feature«safeName().toFirstUpper()»Builder.isEmpty()) {
//      for («eType.ePackage.fqInterfaceJava()»<? extends «eType.fqGenJava()»> builder: m_feature«safeName().toFirstUpper()»Builder) {
//         «p_var».get«potentiallyPluralizedName().toFirstUpper()»().add(builder.build());          
//      }
//    } 
//  }
//  «ELSE»
//  }
//  «ENDIF»
//«ENDDEFINE»
//
//«DEFINE method(EClass p_context) FOR EStructuralFeature»  
//  public «p_context.builderName()» «featureAccessMethod()»(«EXPAND typeDeclaration FOR eType» p_«safeName()»){
//    m_«safeName()» = p_«safeName()»;
//    m_feature«safeName().toFirstUpper()»Set = true;
//    return this;
//  }
//
//  «IF eType.isBuilderType()»
//    public «p_context.builderName()» «featureAccessMethod()»(«eType.ePackage.fqInterfaceJava()»<? extends «eType.fqGenJava()»> p_«eType.builderName().toFirstLower()»){
//      m_feature«safeName().toFirstUpper()»Builder = p_«eType.builderName().toFirstLower()»;
//      return this;
//    }
//  «ENDIF»  
//«ENDDEFINE»
//
//«DEFINE methodMulti(EClass p_context) FOR EStructuralFeature» 
//  public «p_context.builderName()» «featureAccessMethod()»(«EXPAND typeDeclaration FOR eType» p_«safeName()»){
//    m_«safeName()».add(p_«safeName()»);
//    m_feature«safeName().toFirstUpper()»Set = true;
//    return this;
//  }    
//
//  public «p_context.builderName()» «featureAccessMethod()»(java.util.Collection<? extends «EXPAND typeDeclaration FOR eType»> p_«safeName()»){
//    m_«safeName()».addAll(p_«safeName()»);
//    m_feature«safeName().toFirstUpper()»Set = true;
//    return this;
//  }
//
//  «IF eType.isBuilderType()»
//    public «p_context.builderName()» «featureAccessMethod()»(«eType.ePackage.fqInterfaceJava()»<? extends «eType.fqGenJava()»> p_«eType.builderName().toFirstLower()»){
//      m_feature«safeName().toFirstUpper()»Builder.add(p_«eType.builderName().toFirstLower()»);
//      return this;
//    }            
//  «ENDIF»  
//«ENDDEFINE»
