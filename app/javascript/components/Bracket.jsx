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

  renderTeam(team) {
    return (
      <iframe src={team.embed_uri} allowtransparency="true" allow="encrypted-media" width="250" height="80" />
    )
  }

  render() {
    const { bracket } = this.state;

    return (
      <div className="">
        <div className="hero position-relative d-flex align-items-center justify-content-center">
          {bracket.image && (
            <img
              src={bracket.image.url}
              alt={`${bracket.name} image`}
              className="img-fluid position-absolute"
            />
          )}
          <div className="overlay bg-dark position-absolute" />
          <h1 className="display-4 position-relative text-white">
            {bracket.name}
          </h1>
        </div>
        <div className="container py-5">
          {bracket.nw && bracket.nw.map((ignored, idx) => (
            <div className="row" key={"n-" + idx}>
              <div className="col-sm-6 col-lg-6">
                <h5 className="mb-1 team1">
                  {this.renderTeam(bracket.nw[idx].team1)}
                </h5>
                <h5 className="mb-4 team2">
                  {this.renderTeam(bracket.nw[idx].team2)}
                </h5>
              </div>
              <div className="col-sm-6 col-lg-6">
                <h5 className="mb-1 team1">
                  {this.renderTeam(bracket.ne[idx].team1)}
                </h5>
                <h5 className="mb-4 team2">
                  {this.renderTeam(bracket.ne[idx].team2)}
                </h5>
              </div>
            </div>
          ))}
          {bracket.sw && bracket.sw.map((ignored, idx) => (
            <div className="row" key={"n-" + idx}>
              <div className="col-sm-6 col-lg-6">
                <h5 className="mb-1 team1">
                  {this.renderTeam(bracket.sw[idx].team1)}
                </h5>
                <h5 className="mb-4 team2">
                  {this.renderTeam(bracket.sw[idx].team2)}
                </h5>
              </div>
              <div className="col-sm-6 col-lg-6">
                <h5 className="mb-1 team1">
                  {this.renderTeam(bracket.se[idx].team1)}
                </h5>
                <h5 className="mb-4 team2">
                  {this.renderTeam(bracket.se[idx].team2)}
                </h5>
              </div>
            </div>
          ))}
          <Link to="/brackets" className="btn btn-link">
            Back to brackets
          </Link>
        </div>
      </div>
    );
  }
}

export default Bracket;