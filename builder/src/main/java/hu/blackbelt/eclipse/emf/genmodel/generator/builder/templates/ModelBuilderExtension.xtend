package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import org.eclipse.emf.codegen.ecore.genmodel.GenClass
import org.eclipse.emf.codegen.ecore.genmodel.GenClassifier
import org.eclipse.emf.codegen.ecore.genmodel.GenDataType
import org.eclipse.emf.codegen.ecore.genmodel.GenFeature
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.codegen.util.CodeGenUtil
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.emf.ecore.EcorePackage

class ModelBuilderExtension {

    protected static final val String[] PRIMITIVES = #{
        "boolean",
        "byte",
        "char",
        "double",
        "float",
        "int",
        "long",
        "short"
    }

    def packageName (GenModel it) {
        genPackages.get(0).basePackage + "." + genPackages.get(0).packageName;
    }

    def packageFqName (GenPackage it) {
        val StringBuilder sb = new StringBuilder();
           if (basePackage !== null && basePackage.trim().length() > 0) {
               sb.append(basePackage);
               sb.append(".");
        }
        sb.append(getEcorePackage.getName);
        return sb.toString();
    }

    def packagePath (GenModel it) {
        packageName.replace('.','/')
    }

    def packagePath (GenPackage it) {
        packageFqName.replace('.','/')
    }

    def packageJavaName (GenPackage it) {
        var name = "";
        var p = it;
        while (p !== null) {
            name = p.getEcorePackage.name.capitalize + name
            if (p.eContainer instanceof GenPackage) {
                p = p.eContainer as GenPackage;
            } else {
                p = null;
            }
        }
        name;
        //spackageFqName.replace('.','__')
    }

    def decapitalize (String it) {
        if (it === null || length() == 0) {
            return it;
        }
        val char[] c = toCharArray();
        c.set(0, Character.toLowerCase(c.get(0)));
        new String(c);
    }


    def capitalize (String it) {
        if (it === null || length() == 0) {
            return it;
        }
        val char[] c = toCharArray();
        c.set(0, Character.toUpperCase(c.get(0)));
        new String(c);
    }

    def moduleEmfName (GenModel it) {
        genPackages.get(0).packageName.capitalize();
    }


    // extension with convinience string replacements
    def toJavaRef(String it) {
         return replaceAll("\\$", ".")
         .replaceAll("^boolean$", "Boolean")
         .replaceAll("^long$", "Long")
         .replaceAll("^int$", "Integer");
     }

    // extensions for the already generated java classes of an Ecore metamodel
    def modelJavaFqName(GenClassifier it) {
        genPackage.packageFqName + "." + ecoreClassifier.name.toJavaRef;
    }

    /* Facade helpers  */
    def builderFacadeDirectory(GenPackage it) {
        packagePath + "/util/builder";
    }

    def builderFacadeName(GenPackage it) {
        getEcorePackage.name.capitalize + "Builders"
    }

    def builderFacadeFileName(GenPackage it) {
        builderFacadeDirectory + "/" + builderFacadeName + ".java"
    }

    def builderFacadePackage(GenPackage it) {
        packageFqName + ".util.builder"
    }

    /* Interface helpers  */
    def builderInterfaceDirectory(GenPackage it) {
        packagePath + "/util/builder";
    }

    def builderInterfaceName(GenPackage it) {
        "I" + getEcorePackage.name.capitalize + "Builder"
    }

    def builderInterfaceFileName(GenPackage it) {
        builderInterfaceDirectory + "/" + builderInterfaceName + ".java"
    }

    def builderInterfacePackage(GenPackage it) {
        packageFqName + ".util.builder"
    }

    def builderInterfaceFqName(GenClassifier it) {
        genPackage.builderInterfacePackage + "." + genPackage.builderInterfaceName
    }

    /* Builder helpers  */
    def builderBuilderDirectory(GenClass it) {
        genPackage.packagePath + "/util/builder";
    }

    def builderBuilderFileName(GenClass it) {
        builderBuilderDirectory + "/" + builderBuilderName + ".java"
    }

    def builderBuilderPackage(GenClass it) {
        genPackage.packageFqName + ".util.builder"
    }

    def builderBuilderName(GenClass it) {
        name + "Builder"
    }


    def throwRuntimeException(String it) {
        throw new RuntimeException(it);
    }

    // extensions to decide whether element is a non-abstract builder type
    def isNonAbstractBuilderType(GenDataType it) {
        false
    }

    def isNonAbstractBuilderType(GenClassifier it) {
        false
    }

    def isNonAbstractBuilderType(GenClass it) {
        //ecoreClass.instanceClassName === null && !abstract
        ecoreClassifier.isBuilderType
    }


    def isBuilderType(GenClassifier it) {
        ecoreClassifier.isBuilderType
    }

    def isBuilderType(GenFeature it) {
        typeGenClassifier.isBuilderType
    }

    def isBuilderType(EClassifier it) {
        if (it instanceof EClass) {
            return (it as EClass).isBuilderType
        }
        false
    }

    def isBuilderType(EClass it) {
        instanceClassName === null && !abstract
    }

    def isBuilderType(GenClass it) {
        ecoreClass.isBuilderType
    }

    // an extension to filter the structural features of a EClass by derived or not changeable ones
    def structuralFeatures(GenClass it) {
        it.allGenFeatures.reject[derived || !changeable].sortBy[name];
    }

    def unaryStructuralFeatures(GenClass it) {
        structuralFeatures.reject[isMulti]
    }

    def multipleStructuralFeatures(GenClass it) {
        structuralFeatures.filter[isMulti]
    }

    def unaryMandatoryStructuralFeatures(GenClass it) {
        structuralFeatures.filter[isMandatory && !isMulti]
    }

    def multipleMandatoryStructuralFeatures(GenClass it) {
        structuralFeatures.filter[isMandatory && isMulti]
    }

    // an extension to decide whether the structural feature is a list
    def isMulti(GenFeature it) {
        ecoreFeature.upperBound > 1 || ecoreFeature.upperBound == -1
    }

    // an extension to get the name of a structural feature. If the name clashes with Java keyword like 'class', we append a '_' to the name
    def safeName(GenFeature it) {
        CodeGenUtil.safeName(name)
      }

    def safeSetterName(GenFeature it) {
        if (name === "class")
            "class_"
        else name;
    }

    def potentiallyPluralizedName(GenFeature it) {
        return it.name;
    }

      def factoryInstance(GenClass it) {
        genPackage.getFactoryName() + "." + genPackage.getFactoryInstanceName()
      }

      def factoryInstanceFqName(GenClass it) {
        genPackage.packageFqName + "." + factoryInstance
      }

      def isMandatory(GenFeature it) {
        !isPrimitive && ecoreFeature.lowerBound > 0 && (ecoreFeature.defaultValueLiteral.isNullOrEmpty && ecoreFeature.defaultValue == null)
      }

      def isNullCheck(GenClass it) {
        structuralFeatures.findFirst[isMandatory] != null
      }

      def isPrimitive(GenFeature it) {
          PRIMITIVES.contains(ecoreFeature.EType.instanceClassName)
      }

}