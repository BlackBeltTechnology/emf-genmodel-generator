package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

import org.eclipse.emf.codegen.ecore.genmodel.GenClass
import org.eclipse.emf.codegen.ecore.genmodel.GenClassifier
import org.eclipse.emf.codegen.ecore.genmodel.GenDataType
import org.eclipse.emf.codegen.ecore.genmodel.GenFeature
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.codegen.util.CodeGenUtil

class ModelBuilderExtension {
			
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
    def modelJava(GenClassifier it) { 
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
		ecoreClass.instanceClassName === null && !abstract
	}
	
	// extensions to decide whether element is a (potentially abstract) builder type 
	def isBuilderType(GenDataType it) {
		false	
	} 
	
	def isBuilderType(GenClassifier it) {
		ecoreClassifier.instanceClassName === null	
	}

	def isBuilderType(GenClass it) {
		ecoreClass.instanceClassName === null	
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
    	val StringBuilder sb = new StringBuilder();
	    sb.append(genPackage.getFactoryName());
    	sb.append(".");
    	sb.append(genPackage.getFactoryInstanceName());
    	sb.toString();
  	}
  	
  	def effectiveType(GenFeature it) {
  		if (typeGenClass !== null){
  			typeGenClass
  		} else {
  			typeGenClassifier;
  		}
  	}
  
	/*
	def featureModifierMethodPrefix() {
		return "with";
	}

	// extensions to decide whether element is a non-abstract builder type
	def isNonAbstractBuilderType(EDataType it) {
		false;
	} 
    def isNonAbstractBuilderType(EClassifier it) {
    	false;
    }
    
    def isNonAbstractBuilderType(EClass it) {
    	instanceClassName === null && !abstract;
	}


	// extensions to decide whether element is a (potentially abstract) builder type 
    def isBuilderType(EDataType it) {
     	false; 	
 	} 
 	
    def isBuilderType(EClassifier it) {
    	false;
	}
    
    def isBuilderType(EClass it) { 
    	instanceClassName === null;
	}


    // extension with convinience string replacements
    def toJavaRef(String it) {
     	return replaceAll("\\$", ".").replaceAll("^boolean$", "Boolean").replaceAll("^int$", "Integer"); 	
 	}

    def fqBuilderJavaPackage(GenClass it) {
    	getContfqGenJavaPackage + ".util.builder";	
	}
	
    def fqBuilderJava(GenClass it) { 
    	fqBuilderJavaPackage + "." + builderName();
    	
	}

    // extensions for the generated builder java classes of an Ecore metamodel
    def fqBuilderFile(GenClass it) {
    	fqBuilderJava.replaceAll("\\.", "/") + ".java";
    	
    }
        
    def fqBuilderJavaPackage(GenPackage it)	{
    	packageFqName + ".util.builder";	
	}
	
	
    def builderName(GenClass it) { 
    	name + "Builder";	
	}

    // extensions for the generated builder facade java classes of an Ecore metamodel
    def fqFacadeFile(GenPackage it) { 
    	fqFacadeJava.replaceAll("\\.", "/") + ".java";	
	}
	
    def fqFacadeJava(GenPackage it) { 
    	fqFacadeJavaPackage + "." + facadeName;
    	
	}
    
    def fqFacadeJavaPackage(GenPackage it) { 
    	fqBuilderJavaPackage;    	
	}
    
    def facadeName(GenPackage it) { 
    	getEcorePackage.name.toFirstUpper() + "Builders";	
	}

    // extensions for the generated builder interface java class of an Ecore metamodel
    def fqInterfaceFile(GenPackage it) { 
    	fqInterfaceJava.replaceAll("\\.", "/") + ".java";	
	}

    def fqInterfaceJava(GenPackage it) { 
    	fqInterfaceJavaPackage + "." + interfaceName;
   	}
    
    def fqInterfaceJavaPackage(GenPackage it) { 
    	return fqBuilderJavaPackage();	
	}
     
    def interfaceName(GenPackage it) {
    	"I" + getEcorePackage.name.toFirstUpper() + "Builder";	
    }

    // extensions for the already generated java classes of an Ecore metamodel
    def fqGenJava(GenClass it) { 
    	fqGenJavaPackage + "." + name.toJavaRef;	
	}


    // extension to calculate the name of the feature access method
    //def featureAccessMethod(EStructuralFeature it) { 
    // 	(featureModifierMethodPrefix() === null || featureModifierMethodPrefix.trim().length == 0) ? safeName() : (featureModifierMethodPrefix() + p_sf.safeName().toFirstUpper());
    //}

*/	

/*
    def fqGenJavaPackage(EClassifier p_ec) {
    	return JAVA templates.JavaExtensions.fqGenJavaPackage(org.eclipse.emf.ecore.EClassifier);	
	}


     def fqGenJavaPackage(EPackage p_ep) : JAVA templates.JavaExtensions.fqGenJavaPackage(org.eclipse.emf.ecore.EPackage);
     def factoryInstance(EClassifier p_ec){ return JAVA templates.JavaExtensions.factoryInstance(org.eclipse.emf.ecore.EClassifier);

// an extension to filter the structural features of a EClass by derived or not changeable ones
     def structuralFeatures(EClass p_ec): p_ec.eAllStructuralFeatures.reject(e|e.derived || !e.changeable).sortBy(e|e.name);
     def unaryStructuralFeatures(EClass p_ec): p_ec.structuralFeatures().reject(sf|sf.isMulti());
     def multipleStructuralFeatures(EClass p_ec): p_ec.structuralFeatures().select(sf|sf.isMulti());

// an extension to decide whether the structural feature is a list
     def isMulti(EStructuralFeature p_sf): p_sf.upperBound > 1 || p_sf.upperBound == -1;

// an extension to get the name of a structural feature. If the name clashes with Java keyword like 'class', we append a '_' to the name
     def safeName(EStructuralFeature p_sf): JAVA templates.JavaExtensions.safeName(org.eclipse.emf.ecore.EStructuralFeature);
     def safeSetterName(EStructuralFeature p_sf): JAVA templates.JavaExtensions.safeSetterName(org.eclipse.emf.ecore.EStructuralFeature);
     def potentiallyPluralizedName(EStructuralFeature p_sf) : JAVA templates.JavaExtensions.potentiallyPluralizedName(org.eclipse.emf.ecore.EStructuralFeature);

// extension to calculate the name of the feature access method
     def featureAccessMethod(EStructuralFeature p_sf) : (featureModifierMethodPrefix() == null || featureModifierMethodPrefix().trim().length == 0) ?
  p_sf.safeName() 
  :(featureModifierMethodPrefix() + p_sf.safeName().toFirstUpper()); 

// option to control the prefix of the feature modifier method (i.e. "with"). Can be empty or null to skip the prefix.
String featureModifierMethodPrefix() : ((String)GLOBALVAR featureModifierMethodPrefix);

Void throwRuntimeException(String p_message): JAVA templates.JavaExtensions.throwRuntimeException(java.lang.String);
*/

}