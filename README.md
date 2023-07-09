# Wayback Classic

[![Ruby](https://github.com/ticky/wayback-classic/actions/workflows/ruby.yml/badge.svg)](https://github.com/ticky/wayback-classic/actions/workflows/ruby.yml) [![Deploy](https://github.com/ticky/wayback-classic/actions/workflows/main.yml/badge.svg)](https://github.com/ticky/wayback-classic/actions/workflows/main.yml)

A simple, CGI-based frontend for the Wayback Machine which works on old browsers without modern JavaScript or CSS support

The main instance of Wayback Classic is available at [wayback-classic.net](http://wayback-classic.net). It supports both HTTP and HTTPS.

## Why

The Wayback Machine contains a lot of websites from the turn of the century which are perfect for browsing on older machines, but the interface the Wayback Machine itself presents is completely incompatible with many such systems, making it very difficult to navigate.

Wayback Classic attempts to provide a fully-functional frontend for the Wayback Machine, providing these systems with access without the extra technological requirements.

## Notes

This is built on both the [CDX API](https://github.com/internetarchive/wayback/tree/master/wayback-cdx-server) (for retrieving lists of page snapshots), as well as the undocumented `__wb/search` API used by the Wayback Machine's own frontend to handle site search and determine if a site exists in the archive. More info about the site search can be found [in this blog post](http://blog.archive.org/2016/10/24/beta-wayback-machine-now-with-site-search/).

## Development

A basic, WEBrick-based development server script is included at `bin/dev-server`. It defaults to `localhost:8000`, but the port can be overridden by setting a `PORT` environment variable.

You can run this with either of:

```
./bin/dev-server
```

or

```
bundle exec bin/dev-server
```

## Deployment

For your convenience, there are some scripts under the contrib/ folder: 

- a script to install a recent version of ruby
- a systemctl service file to run this server on startup
- nginx site file that serve this to an external domain. 

these should allow you to run a version of this tool on your site, but will require tweaking. For example, take care to configure the port correctly.

To enable https, you could start with the http nginx file, then run `sudo certbot --nginx -d wayback.yourdomain.com`. Then re-run the server with the `HTTPS='on'` environment variable, either manually or in the systemctl service.

## Testing

While the root directory of this repository is intended to map directly to the root htdocs directory of a server, with no dependencies other than the Ruby standard library, a `Gemfile` is provided under the `tests` directory which contains dependencies for testing.

For testing purposes, the CGI scripts are loaded as Ruby modules instead of normal scripts, and their lifecycle is exercised by a minimal Rack application to facilitate the use of Capybara.

To run the test suite, open a terminal within the `tests` directory, and run `bundle && bundle exec rake`.
