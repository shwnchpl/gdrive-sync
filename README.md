gdrive-sync
===========

1. [About](#about)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Usage](#usage)
5. [License](#license)

## About

gdrive-sync is a script that glues together
[google-drive-ocamlfuse](https://github.com/astrada/google-drive-ocamlfuse),
[rsync](https://rsync.samba.org/), and [git](https://git-scm.com/) into a utility for version controlled local Google Drive backups.

gdrive-sync can be called manually, or used with a job scheduler like
[cron](https://www.gnu.org/software/mcron/) for regular offline backups.

## Installation

#### Requirements

* [google-drive-ocamlfuse](https://github.com/astrada/google-drive-ocamlfuse) and all associated requirements
* [rsync](https://rsync.samba.org/)
* [git](https://git-scm.com/)
* [pod2man](https://perldoc.perl.org/pod2man.html), which comes with most [Perl](https://www.perl.org) distributions
* [findmnt(8)](http://man7.org/linux/man-pages/man8/findmnt.8.html), which comes with [util-linux](https://github.com/karelzak/util-linux)

#### Building

Building requires [GNU Autotools](https://www.gnu.org/software/automake/faq/autotools-faq.html#Where-can-I-get-the-latest-versions-of-these-tools_003f).  To build and install the script and documentation, clone this repository and from the root directory run:

```
$ ./bootstrap
$ ./configure
$ make
```

Then, as root, run:

```
# make install
```

## Configuration

#### google-drive-ocamlfuse configuration

For information on installing and configuring google-drive-ocamlfuse, see the
[google-drive-ocamlfuse wiki](https://github.com/astrada/google-drive-ocamlfuse/wiki).
If you plan to use gdrive-sync on a headless system (such as a home server or
VPS), be sure to see the
[Headless Usage & Authorization](https://github.com/astrada/google-drive-ocamlfuse/wiki/Headless-Usage-&-Authorization)
page.  If you want to use gdrive-sync (and by extension google-drive-ocamlfuse)
with multiple Google accounts, you'll have to use google-drive-ocamlfuse labels
to differentiate the accounts.  This is explained on the
[Usage](https://github.com/astrada/google-drive-ocamlfuse/wiki/Usage) wiki
page.

google-drive-ocamlfuse supports a variety of
[exportable formats](https://github.com/astrada/google-drive-ocamlfuse/wiki/Exportable-formats).
For best results with git, I recommend configuring google-drive-ocamlfuse
to export Docs, Sheets, Slides, and Drawings into a plain-text formats so that
they can be track them without the added overhead associated with binary
formats.

To do this, edit ``GDFUSE_CONFIG_DIR/default/config`` or
``GDFUSE_CONFIG_DIR/gdfuse/label/config`` where ``GDFUSE_CONFIG_DIR`` is the
location of your google-drive-ocamlfuse configuration (this may be
``~/.config/gdfuse`` or ``~/.gdfuse``).  There should already be default
entries for each file type in the configuration file.  Change them to read as
follows:

```
document_format=rtf
drawing_format=svg
presentation_format=txt
spreadsheet_format=csv
```

Please note that this is entirely optional and may result in some loss of
information.  A ``csv`` file, for instance, does not contain the same formatting
as an ``xlsx`` or ``ods`` file.  The git repo size/performance advantages may be
outweighed by the need to preserve files more accurately, depending on your
use case.  It is also worth noting that any images or other large binary files
you have stored on Google Drive will be exported and tracked in their binary
state.  The way I use Google Drive, these sorts of files do not change often
enough to create a serious issue, but it is worth being aware that git will
more or less keep a copy of every state your binary file has ever been in, and
from a storage standpoint this could become expensive.

As a safety measure, I also recommend setting ``read_only=true`` to prevent
any of the Google Drive files from being deleted by the mounted
google-drive-ocamlfuse file system.

For more information on google-drive-ocamlfuse configuration file options and
examples, see the [Configuration](https://github.com/astrada/google-drive-ocamlfuse/wiki/Configuration)
page on the google-drive-ocamlfuse wiki.

#### gdrive-sync configuration

Unless an alternate configuration file is explicitly specified with the
``--config`` option, gdrive-sync uses the file called ``.gdsconfig`` in the
current user's home directory if it exists.  This configuration file is run as
a Bash script, which allows for a somewhat dynamic configuration process.
Once gdrive-sync has been installed, an example configuration file named
``gdsconfig`` can be found in your system configuration directory (which may
be ``/etc`` or ``/usr/local/etc``).

A configuration file can to set default options for gdrive-sync.  These options
can always be overridden by command line arguments, but they may come in
handy if you'd like to avoid having to type the same thing over and over
again and/or having a huge command in your crontab.  Most all configuration
that can be done with command line arguments can be done with a configuration
file.

For instance, adding the following lines to a configuration file

```
src_dir=~/foo
dest_dir=~/bar
verbose_mode=yes
```

would result in the default source directory (and/or google-drive-ocamlfuse
mount point) being set to ``~/foo``, the default destination directory being
set to ``~/bar``, and verbose mode being enabled by default.

## Usage

Invoke gdrive-sync with the flag -h or --help to print usage information.

```
$ gdrive-sync --help
Usage: gdrive-sync --option="value" --option

gdrive-sync is a simple script for version controlled local Google Drive backups
using google-drive-ocamlfuse, rsync, and git.

Options:
-c=[FILE], --config=[FILE]        Use [FILE] as the configuration file.
-s=[DIR], --src=[DIR]             Use [DIR] as the source directory.
-d=[DEST], --dest=[DEST]          Use [DIR] as the dest directory.
--sync-dir-name=[DIR]             Use [DIR] as the sync directory. Sync
                                  directory is the directory within the
                                  destination directory to which files are
                                  actually synced.
--sync-commit-message=[MESSAGE]   Append [MESSAGE] to each automatically
                                  generated commit, following the timestamp.
                                  Defaults to "gdrive-sync".
--mount-label=[LABEL]             Call google-drive-ocamlfuse with [LABEL]
                                  as account label.

--no-delete                       Do not delete any files on sync.
-q, --quiet                       Suppress all output.
-v, --verbose                     Issue the most output.
--no-mount                        Assume the source directory is not a
                                  mount point and/or that it already
                                  contains the files we want to sync.
--no-colors                       No colored output. This shouldn't be
                                  necessary on terminals that do not
                                  support color.
--no-create                       Do not create any new directories.
-h, --help                        Print this message.

Please report bugs to https://github.com/shwnchpl/gdrive-sync or shwnchpl@gmail.com.
```

To use gdrive-sync with
[cron(8)](http://man7.org/linux/man-pages/man8/cron.8.html), make an entry in
your [crontab(5)](http://man7.org/linux/man-pages/man5/crontab.5.html). This is
generally done using the
[crontab(1)](http://man7.org/linux/man-pages/man1/crontab.1.html) command.

For example, to run gdrive-sync every Tuesday at 3:00AM with the
default/configured parameters, run `crontab -e` and make the following
entry.

```
0 3 * * Tue gdrive-sync
```

If you want to be extra sure that your crontab entry will do what you think, I
recommend using a tool like [crontab.guru](https://crontab.guru/) to check it.

## License

Copyright (C) 2018 Shawn M. Chapla.

License GPLv2+: GNU GPL version 2 or later <https://www.gnu.org/licenses/gpl.html>.  This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

