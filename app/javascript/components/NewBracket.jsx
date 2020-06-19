import React from "react";
import { Link } from "react-router-dom";

class NewBracket extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      query: "",
      page: "SEARCH"
    };

    this.onChange = this.onChange.bind(this);
    this.onAlbumCheckChange = this.onAlbumCheckChange.bind(this);
    this.onAlbumsSelect = this.onAlbumsSelect.bind(this);
    this.onArtistSelect = this.onArtistSelect.bind(this);
    this.onSearchSubmit = this.onSearchSubmit.bind(this);
    this.onTracksSelect = this.onTracksSelect.bind(this);
    this.onTrackCheckChange = this.onTrackCheckChange.bind(this);
  }

  onChange(event) {
    this.setState({ [event.target.name]: event.target.value });
  }

  onSearchSubmit(event) {
    event.preventDefault();
    const { query } = this.state;

    if (query.length == 0) {
      return;
    }

    const url = `/api/v1/song_bracket_setup/search?query=${encodeURIComponent(query)}`;

    fetch(url)
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Network response was not ok.");
      })
      .then(response => this.setState({ searchResults: response.results || [] }))
      .catch(error => console.log(error.message));
  }

  onArtistSelect(event) {
    event.preventDefault();
    const ref = event.currentTarget.getAttribute("data-ref");

    const url = "/api/v1/song_bracket_setup/submit";
    const body = {
      ref
    };
    const token = document.querySelector('meta[name="csrf-token"]').content;
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Network response was not ok.");
      })
      // TODO(stuppy): I think setState(response) would work, but probably isn't Reacty?
      .then(response => this.setState({ page: response.page, albums: response.albums, token: response.token }))
      .catch(error => console.log(error.message));
  }

  onAlbumsSelect(event) {
    event.preventDefault();

    const { albums, token } = this.state;

    const selectedRefs = albums.filter(album => album.selected).map(album => album.ref);

    const url = "/api/v1/song_bracket_setup/submit";
    const body = {
      refs: selectedRefs,
      token
    };
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Network response was not ok.");
      })
      // TODO(stuppy): I think setState(response) would work, but probably isn't Reacty?
      .then(response => this.setState({ page: response.page, albums: response.albums, token: response.token }))
      .catch(error => console.log(error.message));
  }

  onTracksSelect(event) {
    event.preventDefault();

    const { albums, token } = this.state;

    const selectedRefs = albums.map(a => a.tracks.filter(t => t.selected).map(t => t.ref)).flat(1 /* array of arrays */);

    const url = "/api/v1/song_bracket_setup/submit";
    const body = {
      refs: selectedRefs,
      token
    };
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Network response was not ok.");
      })
      .then(response => this.props.history.push("/bracket/" + response.bracket_id))
      .catch(error => console.error("Could not save bracket!", error));
  }

  renderSearch() {
    const { searchResults } = this.state;
    return (
      <>
        <h1 className="font-weight-normal mb-5">Find an artist to create a new bracket!</h1>
        <form onSubmit={this.onSearchSubmit}>
          <div className="form-group">
            <input
              type="text"
              name="query"
              id="query"
              className="form-control"
              required
              onChange={this.onChange}
              placeholder="Artist"
            />
          </div>
          <button type="submit" className="btn custom-button mt-3">Search</button>
        </form>
        {searchResults && (
          <>
            {searchResults.map((result) =>
              <div key={result.ref} data-ref={result.ref} onClick={this.onArtistSelect}>
                {result.image && (<img src={result.image.url} height={50} width={50} />)}
                {result.name}
              </div>
            )}
          </>
        )}
      </>
    );
  }

  onAlbumCheckChange(event) {
    const { checked } = event.target;
    const { albums } = this.state;
    const ref = event.target.getAttribute("data-ref");
    const album = albums.filter(a => a.ref == ref)[0]
    if (!album) {
      console.error(`Could not find album with ref "${ref}"`)
      return;
    }
    album.selected = checked;
    this.setState({ albums: albums.concat() });
  }

  renderAlbums() {
    const { albums } = this.state;
    return (
      <>
        <h1 className="font-weight-normal mb-5">Select albums to consider for the bracket!</h1>
        <form onSubmit={this.onAlbumsSelect}>
          {albums && albums.map((album) => (
            <div key={album.ref} className="form-group">
              <input
                type="checkbox"
                name={album.ref}
                data-ref={album.ref}
                id={"album-" + album.ref}
                onChange={this.onAlbumCheckChange}
                checked={album.selected}
              />
              <label htmlFor={"album-" + album.ref}>
                {album.artwork && (<img src={album.artwork.url} height={50} width={50} />)}
                {album.name}
              </label>
            </div>
          ))}
          <button type="submit" className="btn custom-button mt-3">Select</button>
        </form>
      </>
    );
  }

  onTrackCheckChange(event) {
    const { checked } = event.target;
    const { albums } = this.state;
    const albumRef = event.target.getAttribute("data-album-ref");
    const trackRef = event.target.getAttribute("data-track-ref");
    const album = albums.filter(a => a.ref == albumRef)[0]
    if (!album) {
      console.error(`Could not find album with ref "${albumRef}"`)
      return;
    }
    const track = album.tracks.filter(t => t.ref == trackRef)[0]
    if (!track) {
      console.error(`Could not find track on album ${album.name} with ref "${trackRef}"`)
      return;
    }
    track.selected = checked;
    this.setState({ albums: albums.concat() });
  }

  renderAlbumTracks() {
    const { albums } = this.state;
    const numChecked = albums.map(a => a.tracks.filter(t => t.selected).length).reduce((a, b) => a + b, 0);
    const errorMessage = `Must select 4, 8, 16, 32, 64 or 128 tracks; currently at ${numChecked}`;
    let ready = false;
    if (numChecked >= 4 && numChecked <= 128) {
      const log2 = Math.log2(numChecked);
      ready = Number.isInteger(log2);
    }
    return (
      <>
        <h1 className="font-weight-normal mb-5">Select tracks to include in the bracket!</h1>
        <form onSubmit={this.onTracksSelect}>
          {albums && albums.map((album) => (
            <div key={album.ref}>
              {album.artwork && (<img src={album.artwork.url} height={50} width={50} />)}
              <div>{album.name}</div>
              {album.tracks && album.tracks.map((track) =>
                <div key={track.ref} className="form-group">
                  <input
                    type="checkbox"
                    name={track.ref}
                    data-album-ref={album.ref}
                    data-track-ref={track.ref}
                    id={"track-" + track.ref}
                    onChange={this.onTrackCheckChange}
                    checked={track.selected}
                  />
                  <label htmlFor={"track-" + track.ref}>
                    {track.track_number}. {track.name}
                  </label>
                </div>
              )}
            </div>
          ))}
          { errorMessage && (
            <div>{errorMessage}</div>
          )}
          <button type="submit" disabled={!ready} className="btn custom-button mt-3">Select</button>
        </form>
      </>
    );
  }

  render() {
    const { page } = this.state;
    return (
      <div className="container mt-5">
        <div className="row">
          <div className="col-sm-12 col-lg-6 offset-lg-3">
            {page === "SEARCH" && this.renderSearch()}
            {page === "ALBUMS" && this.renderAlbums()}
            {page === "TRACKS" && this.renderAlbumTracks()}
          </div>
        </div>
      </div>
    );
  }
}

export default NewBracket;