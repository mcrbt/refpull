# refpull

## Description

This basic Bash script is capable of downloading remote files by hyperlinks
stored in an ASCII file. Lines not starting with "`http`" (including empty
lines) are ignored. Each of the hyperlinks should point to an accessible remote
file. For generating such an hyperlink file from open browser tabs a browser
plugin (e.g. "*Export Tabs URLs*" for Mozilla Firefox) can be used.

Downloaded files can be "renamed" on the fly by either naming the files with
consecutive numbers, or by *obfuscating* their original name.

Optionally, downloaded files can be packed as *tar* archive and additionally
encrypted symmetrically using the *AES256* algorithm of *GnuPG*.

See usage details for additional reference.


### File name obfuscation

It is searched for a program named "`obfuscate`", used to obfuscate filenames in
the current directory and in locations of the system `PATH` variable. If there
is such a program in the current working directory it is supposed to be a Perl
script. System commands (accessible via `$PATH`) can also be symbolic links to
any kind of executable.

A basic filename obfuscation script `obfuscate.pl` is provided, but any other
tool could alternatively be used, as well.


#### obfuscate.pl

The provided obfuscation script works the following way.
In general, digits in the original name remain present while consecutive
alphabetic characters are replaced by the first character of such "word". For
instance, the filename "`hello-obfuscation2018perl.script97.pl`" would be
obfuscated to "`ho2018ps97.pl`". That way, a little information is kept, but
any plain text contained in the original filename is no longer guessable.


## Usage

```

refpull version 0.2.1
copyright (c) 2018, 2020 Daniel Haase

usage:  refpull.sh [-d <dir>] [-r | -o] [-t] [-e] [-c] [-v | -s | -q] <filename>
        refpull.sh [-h | -V | -L | -D]

  -d <directory>
    download files to directory <dir> (default is a date string)

  -r
    rename files to consecutive numbers (e.g. "1.jpg", "2.jpg", ...)

  -o
    rename files to an obfuscation of their original name
    (requires program "obfuscate")

  -t
    use tar command to archive files after download

  -e
    encrypt generated tar archive (implies -t)

  -c
    remove downloaded files after archiving and tar archive after encrypting

  -v
    be verbose (the default)

  -s
    be silent and only print success message with number of
    downloaded files when finished

  -q
    like -s but also suppress success message

  -h
    print this help message and exit

  -V
    print version information

  -L
    print GPL license disclaimer

  -D
    print list of dependencies

note:  - long options are not supported
       - flags (without positional arguments) can be combined
         (e.g. "-oes" is allowed instead of "-o -e -s")
       - the order of options is not relevant
       - if conflicting arguments are given the latter ones take effect
       - files/directories are never overridden

```


## Copyright

Copyright &copy; 2018, 2020 Daniel Haase

`refpull` is licensed under the **GNU General Public License** version 3.


## License disclaimer

```
refpull - download remote files by hyperlinks from ASCII file
Copyright (C) 2018, 2020 Daniel Haase

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see
<https://www.gnu.org/licenses/gpl-3.0.txt>.
```

[GPL](https://www.gnu.org/licenses/gpl-3.0.txt)
