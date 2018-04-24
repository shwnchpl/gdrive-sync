gdrive-sync
===========

1. [About](#about)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Usage](#usage)
5. [Examples](#examples)
6. [License](#license)

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

For best results, google-drive-ocamlfuse should be configured to convert
Google Docs, Sheets, and Slides into a plain-text format that git can keep
track of without the added overhead of a binary format.

(TODO) (How to do this).

Presumably any images or other large binary files you have on Google Drive
will not be changing often enough to bog your local git repo down.

For more information on google-drive-ocamlfuse configuration, see this
[Wiki page](https://github.com/astrada/google-drive-ocamlfuse/wiki/Configuration).

#### gdrive-sync configuration

(TODO)

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

