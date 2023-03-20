package hu.blackbelt.eclipse.emf.genmodel.generator.builder.templates;

/*-
 * #%L
 * hu.blackbelt.eclipse.emf.genmodel.generator.builder
 * %%
 * Copyright (C) 2018 - 2022 BlackBelt Technology
 * %%
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License, v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is
 * available at https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 * #L%
 */

import java.util.List;

import org.eclipse.emf.codegen.ecore.genmodel.GenModel;
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage;
import org.eclipse.emf.codegen.util.CodeGenUtil;
import org.eclipse.emf.common.util.BasicEList;
import org.eclipse.emf.ecore.EClassifier;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.util.EcoreUtil;

import com.google.common.collect.ImmutableList;

public class JavaExtensions {
  private List<GenModel> s_genModels;

  public JavaExtensions(List<GenModel> p_genModels) {
    s_genModels = ImmutableList.copyOf(p_genModels);
  }

  public String fqGenJavaPackage(final EClassifier p_eClassifier) {
    final GenPackage genPackage = findGenPackageFor(p_eClassifier);
    return fqGenJavaPackage(genPackage);
  }

  public String fqGenJavaPackage(final EPackage p_package) {
    final GenPackage genPackage = findGenPackageFor(p_package);
    return fqGenJavaPackage(genPackage);
  }

  private String fqGenJavaPackage(final GenPackage genPackage) {
    final StringBuilder sb = new StringBuilder();
    if (genPackage.getBasePackage() != null && genPackage.getBasePackage().trim().length() > 0) {
      sb.append(genPackage.getBasePackage());
      sb.append(".");
    }
    sb.append(genPackage.getEcorePackage().getName());
    return sb.toString();
  }

  public String factoryInstance(final EClassifier p_eClassifier) {
    final GenPackage genPackage = findGenPackageFor(p_eClassifier);
    final StringBuilder sb = new StringBuilder();
    sb.append(genPackage.getFactoryName());
    sb.append(".");
    sb.append(genPackage.getFactoryInstanceName());
    return sb.toString();
  }

  public final String safeName(final EStructuralFeature p_structuralFeature) {
    return CodeGenUtil.safeName(p_structuralFeature.getName());
  }

  public final String safeSetterName(final EStructuralFeature p_structuralFeature) {
    return p_structuralFeature.getName().equals("class") ? p_structuralFeature.getName() + "_" : p_structuralFeature.getName();
  }

  public String potentiallyPluralizedName(final EStructuralFeature p_structuralFeature) {
    return p_structuralFeature.getName();
  }

  public void throwRuntimeException(final String p_message) {
    throw new RuntimeException(p_message);
  }

  private final GenPackage findGenPackageFor(final EPackage p_package) {
    return findGenPackageFor(p_package, p_package);
  }

  private final GenPackage findGenPackageFor(final EClassifier p_classifier) {
    return findGenPackageFor(p_classifier, p_classifier.getEPackage());
  }

  private final GenPackage findGenPackageFor(final EObject p_element, final EPackage p_package) {
    final StringBuilder sb = new StringBuilder();
    for (final GenModel genModel : s_genModels) {

      List<GenPackage> listGenPkgs = getPackagesRecursively(genModel.getGenPackages());
      for (final GenPackage genPackage : listGenPkgs) {
        sb.append(genPackage.getNSURI()).append(",");
        if (p_element.eIsProxy()) {
          EcoreUtil.resolveAll(p_element);
          if (p_element.eIsProxy()) {
            throw new RuntimeException("Could not resolve proxy object " + p_element);
          }
        }
        if (ePackageEquals(p_package, genPackage.getEcorePackage())) {
          return genPackage;
        }
      }
    }
    throw new RuntimeException("Did not find genpackage for '" + p_element + " using genmodels " + sb.toString() + ".");
  }


  private final List<GenPackage> getPackagesRecursively(List<GenPackage> list) {
    List<GenPackage> resultList = new BasicEList<GenPackage>();
    resultList.addAll(list);

    for (final GenPackage genPackage : list) {
      resultList.addAll(getPackagesRecursively(genPackage.getNestedGenPackages()));
    }
    return resultList;
  }

  private boolean ePackageEquals(final EPackage p_this, final EPackage p_other) {
    return p_this.getName().equals(p_other.getName()) && p_this.getNsPrefix().equals(p_other.getNsPrefix()) && p_this.getNsURI().equals(p_other.getNsURI());
  }
}
