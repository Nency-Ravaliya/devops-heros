import com.sun.net.httpserver.HttpServer;

import java.io.OutputStream;
import java.net.InetSocketAddress;

public class Main {

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);

        server.createContext("/", exchange -> {
            String message = "<h1>Hello World from Java + Docker!</h1>";
            exchange.getResponseHeaders().set("Content-Type", "text/html");
            exchange.sendResponseHeaders(200, message.getBytes().length);
            OutputStream out = exchange.getResponseBody();
            out.write(message.getBytes());
            out.close();
        });

        server.start();
        System.out.println("Server running on port 8080");
    }
}
