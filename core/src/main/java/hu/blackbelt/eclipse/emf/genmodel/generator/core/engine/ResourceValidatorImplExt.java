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

import java.util.Collections;
import java.util.List;

import org.eclipse.emf.codegen.ecore.genmodel.GenModel;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.service.OperationCanceledError;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.Issue;
import org.eclipse.xtext.validation.ResourceValidatorImpl;

public class ResourceValidatorImplExt extends ResourceValidatorImpl {
    @Override
    public List<Issue> validate(Resource resource, CheckMode mode, CancelIndicator mon)
            throws OperationCanceledError {
        if (resource.getContents().get(0) instanceof GenModel) {
            return Collections.emptyList();
        }
        return super.validate(resource, mode, mon);
    }
}
