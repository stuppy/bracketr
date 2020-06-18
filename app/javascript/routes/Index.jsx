import React from "react";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import Bracket from "../components/Bracket";
import Brackets from "../components/Brackets";
import Home from "../components/Home";
import NewBracket from "../components/NewBracket";

export default (
  <Router>
    <Switch>
      <Route path="/" exact component={Home} />
      <Route path="/brackets" exact component={Brackets} />
      <Route path="/bracket/:id" exact component={Bracket} />
      <Route path="/new" exact component={NewBracket} />
    </Switch>
  </Router>
);
