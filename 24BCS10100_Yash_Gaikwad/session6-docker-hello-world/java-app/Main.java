import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public class Main {
    public static void main(String[] args) throws IOException {
        int port = 8080;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/", exchange -> {
            String html = "<!DOCTYPE html><html><head><title>Java Hello World</title></head>"
                    + "<body style=\"font-family: sans-serif; text-align: center; margin-top: 60px;\">"
                    + "<h1>Hello World from Java in Docker!</h1>"
                    + "<p>Served by the JDK built-in HTTP server on port " + port + "</p>"
                    + "</body></html>";
            byte[] body = html.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, body.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(body);
            }
        });

        server.start();
        System.out.println("Server running on port " + port);
    }
}
