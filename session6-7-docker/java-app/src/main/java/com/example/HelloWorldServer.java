package com.example;

import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

/**
 * Minimal Hello World web server built on the JDK's built-in HttpServer,
 * so the image needs no external web framework or servlet container.
 */
public class HelloWorldServer {

    private static final int PORT = 8080;

    private static final String PAGE = """
            <!DOCTYPE html>
            <html>
              <head><title>Java Hello World</title></head>
              <body style="font-family: sans-serif; text-align: center; padding-top: 4rem;">
                <h1>Hello World</h1>
                <p>Served by Java inside Docker</p>
              </body>
            </html>
            """;

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", PORT), 0);

        server.createContext("/", exchange -> {
            byte[] body = PAGE.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, body.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(body);
            }
        });

        server.start();
        System.out.println("Java app listening on port " + PORT);
    }
}
