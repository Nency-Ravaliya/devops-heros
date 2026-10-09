import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public class HelloServer {

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", port), 0);

        server.createContext("/", exchange -> {
            String host = InetAddress.getLocalHost().getHostName();
            String body = "<!doctype html>\n"
                    + "<html>\n"
                    + "  <head><title>Java on Docker</title></head>\n"
                    + "  <body>\n"
                    + "    <h1>Hello World from Java!</h1>\n"
                    + "    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>\n"
                    + "    <p>Served by Java " + System.getProperty("java.version")
                    + " in container " + host + "</p>\n"
                    + "  </body>\n"
                    + "</html>";

            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });

        server.start();
        System.out.println("Java app listening on port " + port);
    }
}
