import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;

public class Hello {
  public static void main(String[] args) throws Exception {
    HttpServer server = HttpServer.create(new InetSocketAddress(8083), 0);
    server.createContext("/", exchange -> {
      byte[] body = "Hello from the Session 6 Java container.\n".getBytes();
      exchange.sendResponseHeaders(200, body.length);
      exchange.getResponseBody().write(body);
      exchange.close();
    });
    server.start();
  }
}
