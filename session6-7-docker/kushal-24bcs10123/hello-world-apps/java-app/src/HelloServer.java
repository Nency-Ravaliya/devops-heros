import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

/** Hello World web server using only the JDK (no frameworks, no build tool). */
public class HelloServer {
    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        String host = InetAddress.getLocalHost().getHostName();
        String page = "<!doctype html><html><head><meta charset=\"utf-8\"><title>Java Hello World</title></head>"
                + "<body style=\"font-family:system-ui;text-align:center;margin-top:15vh\">"
                + "<h1>Hello World</h1>"
                + "<p>from <strong>Java " + Runtime.version().feature() + "</strong> running in a Docker container</p>"
                + "<p><small>container hostname: " + host + "</small></p></body></html>";

        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", port), 0);
        server.createContext("/", (HttpExchange ex) -> {
            byte[] body = page.getBytes(StandardCharsets.UTF_8);
            ex.getResponseHeaders().add("Content-Type", "text/html; charset=utf-8");
            ex.sendResponseHeaders(200, body.length);
            try (OutputStream os = ex.getResponseBody()) { os.write(body); }
        });
        server.start();
        System.out.println("java-app listening on " + port);
    }
}
