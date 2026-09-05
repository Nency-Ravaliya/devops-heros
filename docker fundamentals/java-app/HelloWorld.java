import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class HelloWorld {
    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(
            new InetSocketAddress("0.0.0.0", 8080),
            0
        );

        server.createContext("/", HelloWorld::handleRequest);
        server.setExecutor(null);

        System.out.println("Java application running on port 8080");

        server.start();
    }

    private static void handleRequest(HttpExchange exchange) throws IOException {
        String response = "<h1>Hello World from Java!</h1>";

        exchange.sendResponseHeaders(200, response.getBytes().length);

        try (OutputStream outputStream = exchange.getResponseBody()) {
            outputStream.write(response.getBytes());
        }
    }
}
