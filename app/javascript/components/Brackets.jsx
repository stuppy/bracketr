import React from "react";
import { Link } from "react-router-dom";

class Brackets extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      brackets: []
    };
  }

  componentDidMount() {
    const url = "/api/v1/brackets";
    fetch(url)
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Network response was not ok.");
      })
      .then(response => this.setState({ brackets: response.brackets }))
      .catch(() => this.props.history.push("/"));
  }

  render() {
    const { brackets } = this.state;
    const allBrackets = brackets.map((bracket, index) => (
      <div key={index} className="col-md-6 col-lg-4">
        <div className="card mb-4">
          <img
            src={bracket.image}
            className="card-img-top"
            alt={`${bracket.name} image`}
          />
          <div className="card-body">
            <h5 className="card-title">{bracket.name}</h5>
            <Link to={`/bracket/${bracket.id}`} className="btn custom-button">
              View Bracket
            </Link>
          </div>
        </div>
      </div>
    ));
    const noBrackets = (
      <div className="vw-100 vh-50 d-flex align-items-center justify-content-center">
        <h4>
          No brackets yet. Why not <Link to="/new">create one</Link>
        </h4>
      </div>
    );

    return (
      <>
        <section className="jumbotron jumbotron-fluid text-center">
          <div className="container py-5">
            <h1 className="display-4">Brackets for every occasion</h1>
            <p className="lead text-muted">
              We’ve pulled together our most popular brackets, our latest
              additions, and our editor’s picks, so there’s sure to be something
              tempting for you to try.
            </p>
          </div>
        </section>
        <div className="py-5">
          <main className="container">
            <div className="text-right mb-3">
              <Link to="/new" className="btn custom-button">
                Create New Bracket
              </Link>
            </div>
            <div className="row">
              {brackets.length > 0 ? allBrackets : noBrackets}
            </div>
            <Link to="/" className="btn btn-link">
              Home
            </Link>
          </main>
        </div>
      </>
    );
  }
}
export default Brackets;