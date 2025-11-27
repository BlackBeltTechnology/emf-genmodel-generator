package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import com.google.inject.Inject
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
          *   A builder for the model object ' <em><b>«modelJavaFqName»</b></em>'.
          * <!-- end-user-doc -->
          *
          * @generated
          */
        public class «builderBuilderName()» implements «genPackage.builderInterfaceName»<«modelJavaFqName»> {
            private  «modelJavaFqName» $instance = null;

            // features and builders
             «FOR unary : unaryStructuralFeatures»
                 «unary.declaration»
             «ENDFOR»

             «FOR multi : multipleStructuralFeatures»
                 «multi.declarationMulti»
             «ENDFOR»

             // helper attributes
             private boolean m_nullCheck = «builderConfig.nullCheckByDefault»;
             «FOR struct : structuralFeatures»
                 «struct.assignmentHelperDeclaration»
             «ENDFOR»
            private static final org.eclipse.emf.ecore.EClass ECLASS = (org.eclipse.emf.ecore.EClass)
                    «genPackage.packageFqName».«genPackage.packageInterfaceName».eINSTANCE.getEClassifier("«name»");

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
             * This method constructs the final «modelJavaFqName» type.
             * @return new instance of the «modelJavaFqName» type
             */
            public «modelJavaFqName» build() {

                final «modelJavaFqName» _instance;

                if ($instance == null) {
                    _instance = «factoryInstanceFqName()».create«name»();
                } else {
                    _instance = $instance;
                }

                 «FOR unary : unaryStructuralFeatures»
                     «unary.assignFeature("_instance")»
                 «ENDFOR»
                 «FOR multi : multipleStructuralFeatures»
                     «multi.assignFeatureMulti("_instance")»
                 «ENDFOR»
                «FOR unary : unaryMandatoryStructuralFeatures»
                    «unary.checkMandatoryFeature(it, "_instance")»
                «ENDFOR»
                «FOR multi : multipleMandatoryStructuralFeatures»
                    «multi.checkMandatoryFeatureMulti(it, "_instance")»
                «ENDFOR»
                return _instance;
            }

            /**
             * Builder is not instantiated with a constructor.
             * @see «genPackage.builderFacadeName»#new«builderBuilderName()»()
             */
            private «builderBuilderName()»() {
            }


            /**
             * Builder is not instantiated with an instance.
             * @see  «genPackage.builderFacadeName»#use«builderBuilderName()»()
             */
            private «builderBuilderName»(«modelJavaFqName» instance) {
                $instance = instance;
            }

            /**
             * This method creates a new instance of the «builderBuilderName()».
             * @return new instance of the «builderBuilderName()»
             */
            public static «builderBuilderName()» create() {
                return new «builderBuilderName()»();
            }

            /**
             * This method creates a new instance of the «builderBuilderName()» with mandatory field check if nullCheck is true.
             * @return new instance of the «builderBuilderName()»
             */
            public static «builderBuilderName()» create(boolean p_nullCheck) {
                return new «builderBuilderName()»().withNullCheck(p_nullCheck);
            }

            /**
             * This method creates a new instance of the «builderBuilderName()» from the given instance of class.
             * @return new instance of the «builderBuilderName()»
             */
            public static «builderBuilderName()» use(«modelJavaFqName» instance) {
                return new «builderBuilderName()»(instance);
            }

            /**
             * This method creates a new instance of the «builderBuilderName()» from the given instance of class with mandatory field check if nullCheck is true.
             * @return new instance of the «builderBuilderName()»
             */
            public static «builderBuilderName()» use(«modelJavaFqName» instance, boolean p_nullCheck) {
                return new «builderBuilderName()»(instance).withNullCheck(p_nullCheck);
            }

            private «builderBuilderName()» withNullCheck(boolean p_nullCheck){
                m_nullCheck = p_nullCheck;
                return this;
            }

             «FOR unary : unaryStructuralFeatures»
                 «unary.method(it)»
             «ENDFOR»

             «FOR multi : multipleStructuralFeatures»
                 «multi.methodMulti(it)»
             «ENDFOR»
            
            public «builderBuilderName()» withStructuralFeatures(java.util.Map<String, Object> structuralFeatures) {
                if (structuralFeatures == null || structuralFeatures.isEmpty()) {
                    return this;
                }
                structuralFeatures.forEach(this::withStructuralFeature);
                return this;
            }

            public «builderBuilderName()» withStructuralFeature(String featureName, Object rawValue) {
                if (featureName == null) {
                    return this;
                }
                String normalized = featureName.trim();
                if (normalized.isEmpty()) {
                    return this;
                }
                «IF !structuralFeatures.empty»
                String key = normalized.toLowerCase(java.util.Locale.ROOT);
                switch (key) {	
                    «FOR feature : structuralFeatures»
                        case "«feature.ecoreFeature.name.toLowerCase»":
                            «IF feature.isMulti»
                                applyMany("«feature.ecoreFeature.name»", rawValue, this::«feature.featureAccessMethod»);
                            «ELSE»
                                applySingle("«feature.ecoreFeature.name»", rawValue, this::«feature.featureAccessMethod»);
                            «ENDIF»
                            break;
                    «ENDFOR»
                    default:
                        throw new IllegalArgumentException("Structural feature '" + featureName + "' is not supported for «modelJavaFqName».");
                }
                «ENDIF»
                return this;
            }
            «IF !structuralFeatures.empty»
            private void applySingle(String featureName, Object rawValue, java.util.function.Function<Object, «builderBuilderName()»> setter) {
                org.eclipse.emf.ecore.EStructuralFeature feature = structuralFeature(featureName);
                Object value = convertStructuralFeatureValue(feature, rawValue);
                setter.apply(value);
            }
            
            private org.eclipse.emf.ecore.EStructuralFeature structuralFeature(String featureName) {
                if (featureName == null || featureName.isEmpty()) {
                    throw new IllegalArgumentException("Feature name must be provided for «modelJavaFqName»." );
                }
                for (org.eclipse.emf.ecore.EStructuralFeature feature : ECLASS.getEAllStructuralFeatures()) {
                    if (feature.getName().equals(featureName)) {
                        return feature;
                    }
                }
                throw new IllegalArgumentException("Feature '" + featureName + "' is not a structural feature of " + ECLASS.getName());
            }
            private Object convertStructuralFeatureValue(org.eclipse.emf.ecore.EStructuralFeature feature, Object rawValue) {
                if (rawValue == null) {
                    return null;
                }
                if (feature instanceof org.eclipse.emf.ecore.EAttribute attribute) {
                    org.eclipse.emf.ecore.EDataType dataType = attribute.getEAttributeType();
                    if (dataType == null) {
                        return rawValue;
                    }
                    if (rawValue instanceof String stringValue) {
                        return org.eclipse.emf.ecore.util.EcoreUtil.createFromString(dataType, stringValue);
                    }
                    return rawValue;
                }
                return rawValue;
            }
            «ENDIF»
            «IF !multipleStructuralFeatures.empty»
            private void applyMany(String featureName, Object rawValue, java.util.function.Function<Object, «builderBuilderName()»> setter) {
                org.eclipse.emf.ecore.EStructuralFeature feature = structuralFeature(featureName);
                for (Object token : convertStructuralFeatureValues(feature, rawValue)) {
                    setter.apply(token);
                }
            }
            
            private java.util.List<Object> convertStructuralFeatureValues(org.eclipse.emf.ecore.EStructuralFeature feature, Object rawValue) {
                java.util.List<Object> values = new java.util.ArrayList<>();
                if (rawValue == null) {
                    return values;
                }
                if (rawValue instanceof java.util.Collection<?> collection) {
                    values.addAll(collection);
                    return values;
                }
                if (rawValue instanceof String stringValue) {
                    for (String token : stringValue.split(",")) {
                        String trimmed = token.trim();
                        if (!trimmed.isEmpty()) {
                            values.add(convertStructuralFeatureValue(feature, trimmed));
                    	}
                 	}
                    return values;
                }
                values.add(convertStructuralFeatureValue(feature, rawValue));
                return values;
             }
        «ENDIF»            
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
            modelJavaFqName
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
        «IF isBuilderType»
            private «typeGenClassifier.builderInterfaceFqName»<? extends «typeGenClassifier.modelJavaFqName»> m_feature«safeName().toFirstUpper()»Builder;
        «ENDIF»
        '''

    def declarationMulti(GenFeature it) '''
        private java.util.Collection<«typeDeclaration»> m_«safeName()» = new java.util.LinkedList<«typeDeclaration»>();
        «IF isBuilderType»
            private java.util.Collection<«typeGenClassifier.builderInterfaceFqName»<? extends «typeGenClassifier.modelJavaFqName»>> m_feature«safeName().toFirstUpper()»Builder = new java.util.LinkedList<«typeGenClassifier.builderInterfaceFqName»<? extends «typeGenClassifier.modelJavaFqName»>>();
        «ENDIF»
        '''

    def assignmentHelperDeclaration(GenFeature it) '''
        private boolean m_feature«safeName().toFirstUpper()»Set = false;
        '''

    def assignBuilderFeatures(GenFeature it, String p_var) '''
        «p_var».m_feature«safeName.toFirstUpper»Set = m_feature«safeName.toFirstUpper»Set;
        «p_var».m_«safeName» = m_«safeName»;
        «IF isBuilderType()»
            «p_var».m_feature«safeName().toFirstUpper()»Builder = m_feature«safeName().toFirstUpper()»Builder;
        «ENDIF»
           '''


    def assignFeature(GenFeature it, String p_var) '''
        if (m_feature«safeName().toFirstUpper()»Set) {
            «p_var».set«safeSetterName().toFirstUpper()»(m_«safeName()»);
        «IF isBuilderType()»
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
        «IF isBuilderType()»
            } else {
                if (!m_feature«safeName().toFirstUpper()»Builder.isEmpty()) {
                    for («typeGenClassifier.builderInterfaceFqName»<? extends «typeGenClassifier.modelJavaFqName()»> builder: m_feature«safeName().toFirstUpper()»Builder) {
                        «p_var».get«potentiallyPluralizedName().toFirstUpper()»().add(builder.build());
                    }
                }
            }
        «ELSE»
        }
        «ENDIF»
        '''

    def checkMandatoryFeature(GenFeature it, GenClass p_context, String p_var) '''
        if (m_nullCheck && «p_var».get«potentiallyPluralizedName().toFirstUpper()»() == null) {
            throw new IllegalArgumentException("Mandatory \"«safeName()»\" attribute is missing from «p_context.builderBuilderName()».");
        }
        '''

    def checkMandatoryFeatureMulti(GenFeature it, GenClass p_context, String p_var) '''
        if (m_nullCheck && «p_var».get«potentiallyPluralizedName().toFirstUpper()»().isEmpty()) {
            throw new IllegalArgumentException("Mandatory \"«safeName()»\" list cannot be empty in «p_context.builderBuilderName()».");
        }
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

        public «p_context.builderBuilderName» «featureAccessMethod»(Object p_«safeName()»){
            return «featureAccessMethod»((«typeDeclaration») p_«safeName()»);
        }

        «IF isBuilderType()»
            public «p_context.builderBuilderName()» «featureAccessMethod()»(«typeGenClassifier.builderInterfaceFqName»<? extends «typeGenClassifier.modelJavaFqName»> p_«p_context.builderBuilderName.toFirstLower()»){
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

        public «p_context.builderBuilderName» «featureAccessMethod»(Object p_«safeName()»){
            return «featureAccessMethod»((«typeDeclaration») p_«safeName()»);
        }

        public «p_context.builderBuilderName» «featureAccessMethod»(java.util.Collection<? extends «typeDeclaration»> p_«safeName()»){
            m_«safeName()».addAll(p_«safeName()»);
            m_feature«safeName().toFirstUpper()»Set = true;
            return this;
        }

        public «p_context.builderBuilderName» «featureAccessMethod»(«typeDeclaration»...p_«safeName()»){
            m_«safeName()».addAll(java.util.Arrays.asList(p_«safeName()»));
            m_feature«safeName().toFirstUpper()»Set = true;
            return this;
        }

        «IF isBuilderType()»
            public «p_context.builderBuilderName()» «featureAccessMethod()»(«typeGenClassifier.builderInterfaceFqName»<? extends «typeGenClassifier.modelJavaFqName»> p_«p_context.builderBuilderName.toFirstLower()»){
                m_feature«safeName().toFirstUpper()»Builder.add(p_«p_context.builderBuilderName().toFirstLower()»);
                return this;
            }
        «ENDIF»
        '''
}
