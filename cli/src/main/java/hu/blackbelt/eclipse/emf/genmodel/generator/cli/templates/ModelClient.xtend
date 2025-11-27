package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine.CliConfig
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2

class ModelClient {
	@Inject extension CliExtension
    @Inject CliConfig cliConfig
    
	def doGenerate(GenModel genModel, IFileSystemAccess2 fsa){
        fsa.generateFile(genModel.clientFilePath, generateClient(genModel))
	}
	
    def generateClient(GenModel it) 
    '''
    package «cliPackageName»;
    
    import java.io.BufferedReader;
    import java.io.DataOutputStream;
    import java.io.File;
    import java.io.IOException;
    import java.io.InputStreamReader;
    import java.net.InetAddress;
    import java.net.ServerSocket;
    import java.net.Socket;
    import java.util.ArrayList;
    import java.util.List;
    
    /**
     * Client - Sends commands to the server.
     * 
     * @generated
     */
    public class «clientClassName» {
        
        public static void main(String[] args) {
            execute(args, «serverClassName».DEFAULT_PORT);
        }

        public static void execute(String[] args, int port) {
            if (args.length >= 1 && "start".equals(args[0])) {
                if (isServerRunning(port)) {
                    System.err.println("Error: Server is already running on port " + port + ".");
                    System.err.println("To stop it, run: «modelName.decapitalize»-api stop");
                    System.exit(1);
                }
                spawnServerProcess(port);
                System.out.println("Server started on port " + port);
                System.exit(0);
            }
            
            if (args.length >= 1 && "status".equals(args[0])) {
                if (isServerRunning(port)) {
                    System.out.println("Server is running on port " + port);
                    System.exit(0);
                } else {
                    System.out.println("Server is not running.");
                    System.out.println("To start it, run: «modelName.decapitalize»-api start");
                    System.exit(1);
                }
            }
            
            // For all other commands, require server to be running
            if (!isServerRunning(port)) {
                System.err.println("Error: Server is not running.");
                System.err.println("Start the server first with: «modelName.decapitalize»-api start");
                System.exit(1);
            }
            
            if (args.length == 0) {
                forwardToServer(new String[]{"--help"}, port);
                return;
            }
            
            forwardToServer(args, port);
        }
        
        private static void spawnServerProcess(int port) {
            try {
                String javaHome = System.getProperty("java.home");
                String javaBin = javaHome + File.separator + "bin" + File.separator + "java";
                String classpath = System.getProperty("java.class.path");
                String className = «serverClassName».class.getName();

                List<String> command = new ArrayList<>();
                command.add(javaBin);
                command.add("-cp");
                command.add(classpath);
                command.add(className);
                command.add("--port");
                command.add(String.valueOf(port));

                ProcessBuilder builder = new ProcessBuilder(command);
                
                builder.redirectOutput(ProcessBuilder.Redirect.DISCARD);
                builder.redirectError(ProcessBuilder.Redirect.INHERIT);
                
                File nullFile = new File(System.getProperty("os.name").toLowerCase().contains("win") ? "NUL" : "/dev/null");
                builder.redirectInput(ProcessBuilder.Redirect.from(nullFile));

                builder.start();
                
                for (int i = 0; i < 50; i++) {
                    if (isServerRunning(port)) break;
                    try { 
                        Thread.sleep(100); 
                    } catch (InterruptedException e) {}
                }
            } catch (Exception e) {
                e.printStackTrace();
                System.exit(1);
            }
        }
        
        private static boolean isServerRunning(int port) {
            try (ServerSocket ss = new ServerSocket(port, 0, InetAddress.getLoopbackAddress())) {
                ss.setReuseAddress(true);
                return false;
            } catch (IOException e) {
                return true;
            }
        }

        private static void forwardToServer(String[] args, int port) {
            try (Socket socket = new Socket("localhost", port);
                 DataOutputStream out = new DataOutputStream(socket.getOutputStream());
                 BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()))) {
                
                out.writeInt(args.length);
                for (String arg : args) {
                    out.writeUTF(arg);
                }
                out.flush();
                
                String line;
                int exitCode = 0;
                while ((line = in.readLine()) != null) {
                    if ("END_OF_RESPONSE".equals(line)) {
                        break;
                    }
                    if (line.startsWith("EXIT_CODE=")) {
                        try {
                            exitCode = Integer.parseInt(line.substring("EXIT_CODE=".length()));
                        } catch (NumberFormatException e) {}
                    } else {
                        System.out.println(line);
                    }
                }
                System.exit(exitCode);
            } catch (Exception e) {
                e.printStackTrace();
                System.exit(1);
            }
        }
    }
    '''
}
