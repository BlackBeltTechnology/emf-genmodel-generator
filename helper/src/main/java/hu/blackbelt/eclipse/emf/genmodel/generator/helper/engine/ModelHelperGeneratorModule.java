package hu.blackbelt.eclipse.emf.genmodel.generator.helper.engine;

/*-
 * #%L
 * hu.blackbelt.eclipse.emf.genmodel.generator.helper
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

import org.eclipse.xtext.generator.IGenerator;
import hu.blackbelt.eclipse.emf.genmodel.generator.core.engine.AbstractGenModelGeneratorModule;
import hu.blackbelt.eclipse.emf.genmodel.generator.helper.templates.ModelHelper;

public class ModelHelperGeneratorModule extends AbstractGenModelGeneratorModule {
	public Class<? extends IGenerator> bindIGenerator() {
		return ModelHelper.class;
	}
}
