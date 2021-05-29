# Wayback Classic

A simple, CGI-based frontend for the Wayback Machine which works on old browsers without modern JavaScript or CSS support

## Why

The Wayback Machine contains a lot of websites from the turn of the century which are perfect for browsing on older machines, but the interface the Wayback Machine itself presents is completely incompatible with many such systems, making it very difficult to navigate.

Wayback Classic attempts to provide a fully-functional frontend for the Wayback Machine, providing these systems with access without the extra technological requirements.

## Notes

This is built on both the [CDX API](https://github.com/internetarchive/wayback/tree/master/wayback-cdx-server) (for retrieving lists of page snapshots), as well as the undocumented `__wb/search` API used by the Wayback Machine's own frontend to handle site search and determine if a site exists in the archive. More info about the site search can be found [in this blog post](http://blog.archive.org/2016/10/24/beta-wayback-machine-now-with-site-search/).

## Development

A basic, WEBrick-based development server script is included at `bin/dev-server`. It defaults to `localhost:8000`, but the port can be overridden by setting a `PORT` environment variable.
