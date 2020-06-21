import App from "../components/App";
import React from "react";
import { render } from "react-dom";
import 'bootstrap/dist/js/bootstrap.bundle.min';

document.addEventListener("DOMContentLoaded", () => {
  render(
    <App />,
    document.body.appendChild(document.createElement("div"))
  );
});
