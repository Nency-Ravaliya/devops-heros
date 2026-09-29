import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class HelloWorld {

    public static void main(String[] args) throws IOException {

        HttpServer server = HttpServer.create(
                new InetSocketAddress(8080), 0);

        server.createContext("/", (HttpExchange exchange) -> {

            String response =
                    "<h1>Hello World from Java!</h1>";

            exchange.getResponseHeaders()
                    .set("Content-Type", "text/html");

            exchange.sendResponseHeaders(
                    200, response.getBytes().length);

            OutputStream output =
                    exchange.getResponseBody();

            output.write(response.getBytes());

            output.close();
        });

        server.start();

        System.out.println(
                "Java server running on port 8080"
        );
    }
}