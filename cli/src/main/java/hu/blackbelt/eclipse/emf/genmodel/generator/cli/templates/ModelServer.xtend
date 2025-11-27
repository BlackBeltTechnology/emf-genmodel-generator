package hu.blackbelt.eclipse.emf.genmodel.generator.cli.templates

import com.google.inject.Inject
import hu.blackbelt.eclipse.emf.genmodel.generator.cli.engine.CliConfig
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.xtext.generator.IFileSystemAccess2

class ModelServer {
	@Inject extension CliExtension
    @Inject CliConfig cliConfig
    
	def doGenerate(GenModel genModel, IFileSystemAccess2 fsa){
        fsa.generateFile(genModel.serverFilePath, generateServer(genModel))
	}
	
    def generateServer(GenModel it) 
    '''
    package «cliPackageName»;
    
    import picocli.CommandLine;
    
    import java.io.DataInputStream;
    import java.io.IOException;
    import java.io.PrintWriter;
    import java.io.StringWriter;
    import java.net.InetAddress;
    import java.net.ServerSocket;
    import java.net.Socket;
    import java.util.concurrent.ExecutorService;
    import java.util.concurrent.Executors;
    
    /**
     * Server - the listener that receives commands and executes them.
     * 
     * @generated
     */
    public class «serverClassName» {
        
        public static final int DEFAULT_PORT = 44444;

        public static void main(String[] args) {
            int port = DEFAULT_PORT;
            if (args.length > 0 && "--port".equals(args[0])) {
                if (args.length > 1) {
                    try {
                        port = Integer.parseInt(args[1]);
                    } catch (NumberFormatException e) {
                        System.err.println("Invalid port number: " + args[1]);
                        System.exit(1);
                    }
                } else {
                    System.err.println("No port number given for option " + args[0]);
                }
            }
            new «serverClassName»().start(port);
        }

        public void start(int port) {
            try (ServerSocket serverSocket = new ServerSocket(port, 50, InetAddress.getLoopbackAddress())) {
                ExecutorService pool = Executors.newCachedThreadPool();
                System.out.println("Server listening on port " + port);

                while (true) {
                    Socket clientSocket = serverSocket.accept();
                    pool.submit(() -> handleClient(clientSocket));
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        private void handleClient(Socket clientSocket) {
            java.io.PrintStream originalOut = System.out;
            java.io.PrintStream originalErr = System.err;
            
            try (clientSocket;
                 DataInputStream in = new DataInputStream(clientSocket.getInputStream());
                 PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true)) {

                clientSocket.setSoTimeout(100);
                int argCount;
                try {
                    argCount = in.readInt();
                } catch (java.io.EOFException | java.net.SocketTimeoutException e) {
                    return;
                }
                clientSocket.setSoTimeout(0);
                String[] args = new String[argCount];
                for (int i = 0; i < argCount; i++) {
                    args[i] = in.readUTF();
                }

                if (args.length == 1 && "shutdown".equals(args[0])) {
                    out.println("Server shutting down...");
                    out.println("EXIT_CODE=0");
                    out.println("END_OF_RESPONSE");
                    out.flush();
                    System.exit(0);
                    return;
                }

                // Redirect System.out/err BEFORE any command processing
                java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
                java.io.PrintStream redirectedStream = new java.io.PrintStream(baos, true);
                java.io.PrintWriter capturedWriter = new java.io.PrintWriter(redirectedStream, true);
                
                System.setOut(redirectedStream);
                System.setErr(redirectedStream);
                
                try {
                    int exitCode = new CommandLine(new «cliClassName»())
                        .setOut(capturedWriter)
                        .setErr(capturedWriter)
                        .execute(args);

                    capturedWriter.flush();
                    redirectedStream.flush();
                    
                    String output = baos.toString();
                    if (!output.isEmpty()) {
                        out.print(output);
                        if (!output.endsWith("\n")) {
                            out.println();
                        }
                    }
                    
                    out.println("EXIT_CODE=" + exitCode);
                    out.println("END_OF_RESPONSE");
                    out.flush();
                } finally {
                    System.setOut(originalOut);
                    System.setErr(originalErr);
                }

            } catch (Exception e) {
                System.setOut(originalOut);
                System.setErr(originalErr);
                e.printStackTrace();
            }
        }
    }
    '''
}
