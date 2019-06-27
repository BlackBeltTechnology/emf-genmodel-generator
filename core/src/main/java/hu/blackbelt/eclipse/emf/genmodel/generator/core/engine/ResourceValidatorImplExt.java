package hu.blackbelt.eclipse.emf.genmodel.generator.core.engine;

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
