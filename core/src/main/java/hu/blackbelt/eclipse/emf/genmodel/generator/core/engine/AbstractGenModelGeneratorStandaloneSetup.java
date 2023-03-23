package hu.blackbelt.eclipse.emf.genmodel.generator.core.engine;

/*-
 * #%L
 * hu.blackbelt.eclipse.emf.genmodel.generator.core
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

import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.ISetup;

import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;

public abstract class AbstractGenModelGeneratorStandaloneSetup implements ISetup {
    private Injector injector;
    private GeneratorConfig config;

    public abstract AbstractGenModelGeneratorModule getGenModelModule();

    public void setConfig(GeneratorConfig config) {
        this.config = config;
    }

    public void setDoInit (boolean init) {
        createInjectorAndDoEMFRegistration();
    }


    public AbstractGenModelGeneratorStandaloneSetup () {
    }

    public Module getDynamicModule () {
        return new AbstractModule() {
            @Override
            protected void configure() {
                bind(GeneratorConfig.class).toInstance(config);
            }
        };
    }

    @Override
    public Injector createInjectorAndDoEMFRegistration() {
        if (injector == null) {
            injector = Guice.createInjector(getGenModelModule(), getDynamicModule());
            register(injector);
        }
        return injector;
    }

    public void register(Injector injector) {
        org.eclipse.xtext.resource.IResourceFactory resourceFactory = injector.getInstance(org.eclipse.xtext.resource.IResourceFactory.class);
        org.eclipse.xtext.resource.IResourceServiceProvider serviceProvider = injector.getInstance(org.eclipse.xtext.resource.IResourceServiceProvider.class);
        Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("genmodel", resourceFactory);
        org.eclipse.xtext.resource.IResourceServiceProvider.Registry.INSTANCE.getExtensionToFactoryMap().put("genmodel", serviceProvider);
    }

}
