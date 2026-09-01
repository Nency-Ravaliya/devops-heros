import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.jsx";
import { BrowserRouter } from "react-router-dom";
import reduxstore from "./redux/reduxstore.js";
import { Provider } from "react-redux";

createRoot(document.getElementById("root")).render(
  <BrowserRouter>
    <Provider store={reduxstore}>
      <App />
    </Provider>
  </BrowserRouter>
);
