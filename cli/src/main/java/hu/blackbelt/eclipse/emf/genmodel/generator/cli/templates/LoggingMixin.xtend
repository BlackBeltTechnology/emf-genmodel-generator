package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2

class LoggingMixin {
	@Inject extension CliExtension

	def doGenerate(GenModel genModel, IFileSystemAccess2 fsa) {
		fsa.generateFile(genModel.loggingMixinFilePath, generateLoggingMixin(genModel))
	}

	def generateLoggingMixin(GenModel it)
	'''
	package «cliMixinsPackage»;

	import org.slf4j.Logger;
	import org.slf4j.LoggerFactory;
	import picocli.CommandLine.Option;

	/**
	 * Mixin for verbose logging support.
	 * When --verbose is specified, the root logger level is set to DEBUG.
	 *
	 * @generated
	 */
	public class LoggingMixin {

		private static final Logger LOG = LoggerFactory.getLogger(LoggingMixin.class);

		@Option(names = {"-v", "--verbose"}, description = "Enable verbose (DEBUG) logging for the CLI")
		boolean verbose;

		public void configureLogging() {
			try {
				ch.qos.logback.classic.Logger rootLogger =
					(ch.qos.logback.classic.Logger) LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME);
				if (verbose) {
					rootLogger.setLevel(ch.qos.logback.classic.Level.DEBUG);
					LOG.debug("Verbose logging enabled");
				} else {
					rootLogger.setLevel(ch.qos.logback.classic.Level.INFO);
				}
			} catch (Exception e) {
				LOG.info("Verbose mode requested but could not configure logger: {}", e.getMessage());
			}
		}
	}
	'''
}
