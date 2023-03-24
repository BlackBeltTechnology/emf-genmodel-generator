package hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates;

import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage

class Naming {

    def packageName (GenModel it) {
        return genPackages.get(0).basePackage + "." + genPackages.get(0).packageName;
    }

    def packageFqName (GenPackage it) {
        return basePackage + "." + packageName;
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
        return name;
        //spackageFqName.replace('.','__')
    }

    def decapitalize (String string) {
        if (string === null || string.length() == 0) {
            return string;
        }
        val char[] c = string.toCharArray();
        c.set(0, Character.toLowerCase(c.get(0)));
        return new String(c);
    }


    def capitalize (String string) {
        if (string === null || string.length() == 0) {
            return string;
        }
        val char[] c = string.toCharArray();
        c.set(0, Character.toUpperCase(c.get(0)));
        return new String(c);
    }

    def moduleEmfName (GenModel it) {
        return genPackages.get(0).packageName.capitalize();
    }


}
