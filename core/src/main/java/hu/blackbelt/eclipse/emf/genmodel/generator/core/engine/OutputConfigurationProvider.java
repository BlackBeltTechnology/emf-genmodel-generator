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

import static org.eclipse.xtext.xbase.lib.CollectionLiterals.newHashSet;
import java.util.Set;
import org.eclipse.xtext.generator.IFileSystemAccess;
import org.eclipse.xtext.generator.IOutputConfigurationProvider;
import org.eclipse.xtext.generator.OutputConfiguration;

public class OutputConfigurationProvider implements IOutputConfigurationProvider {

	public static final String GEN_ONCE_OUTPUT = "gen-once";

	/**
	 * @return a set of {@link OutputConfiguration} available for the generator
	 */
	public Set<OutputConfiguration> getOutputConfigurations() {
		OutputConfiguration defaultOutput = new OutputConfiguration(IFileSystemAccess.DEFAULT_OUTPUT);
		defaultOutput.setDescription("Output folder");
		defaultOutput.setOutputDirectory("./src-gen");
		defaultOutput.setOverrideExistingResources(true);
		defaultOutput.setCreateOutputDirectory(true);
		defaultOutput.setCleanUpDerivedResources(true);
		defaultOutput.setSetDerivedProperty(true);

		OutputConfiguration readonlyOutput = new OutputConfiguration(GEN_ONCE_OUTPUT);
		readonlyOutput.setDescription("Generate once output folder");
		readonlyOutput.setOutputDirectory("./src");
		readonlyOutput.setOverrideExistingResources(false);
		readonlyOutput.setCreateOutputDirectory(true);
		readonlyOutput.setCleanUpDerivedResources(false);
		readonlyOutput.setSetDerivedProperty(false);
		return newHashSet(defaultOutput, readonlyOutput);
	}
	
}
