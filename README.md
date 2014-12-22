# twitrrerr

A simple Twitter client.  You might not want this.

## Requirements

* Ruby 2.0+
* Bundler
* Qt 4.8

## Installation

First of all, install all dependencies and convert the UI files.

    # This may take forever depending on your computer and your installed gems, so be patient!
    $ bundle
    # Convert UI files
    $ rake build_ui

Finally, run Twitrrerr:

    $ bin/twitrrerr

### Windows builds

For some to me unknown reasons, Twitrrerr also works on Windows.  It might have some problems with
displaying profile pictures or handling unicode characters, but it seems to work quite well.

Builds are done with [Ocra](https://github.com/larsch/ocra), and the setup uses Inno Setup.  Take
a look at the `tools/` directory for the build script I'm using.

You can download Windows releases here: [twit.rrerr.net/windows](https://twit.rrerr.net/windows/)
