import React from "react";
import { Link } from "react-router-dom";

class Bracket extends React.Component {
  constructor(props) {
    super(props);
    this.state = { bracket: {} };
  }

  componentDidMount() {
    const {
      match: {
        params: { id }
      }
    } = this.props;

    const url = `/api/v1/brackets/${id}`;

    fetch(url)
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Network response was not ok.");
      })
      .then(response => this.setState({ bracket: response }))
      .catch(() => this.props.history.push("/brackets"));
  }

  render() {
    const { bracket } = this.state;

    return (
      <div className="">
        <div className="hero position-relative d-flex align-items-center justify-content-center">
          <img
            src={bracket.image}
            alt={`${bracket.name} image`}
            className="img-fluid position-absolute"
          />
          <div className="overlay bg-dark position-absolute" />
          <h1 className="display-4 position-relative text-white">
            {bracket.name}
          </h1>
        </div>
        <div className="container py-5">
          <div className="row">
            <div className="col-sm-12 col-lg-3">
              <ul className="list-group">
                <h5 className="mb-2">Ingredients</h5>
                None
              </ul>
            </div>
            <div className="col-sm-12 col-lg-7">
              <h5 className="mb-2">Preparation Instructions</h5>
              <div>None</div>
            </div>
          </div>
          <Link to="/brackets" className="btn btn-link">
            Back to brackets
          </Link>
        </div>
      </div>
    );
  }
}

export default Bracket;