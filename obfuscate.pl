#!/usr/bin/perl
##
## refpull - download remote files by hyperlinks from ASCII file
## Copyright (C) 2018, 2020 Daniel Haase
##
## This file is part of refpull.
##
## refpull is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## refpull is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with refpull. If not, see <http://www.gnu.org/licenses/gpl.txt>.
##

use strict;
use warnings;

my $name;
my $res;

sub apply
{
	my $val = shift;
	chomp $val;
	my $bck = $val;
	if($val =~ m/\?.*/) { return ""; }
	my $par = substr($val, 0, (rindex($val, '/') + 1));
	my $ext = substr($val, (rindex($val, '.') + 1));
	$val =~ s/.+\/(.+?)/$1/g;
	$val =~ s/(.+)\..+/$1/g;
	$val =~ s/%[0-9a-f]{2}/-/gi;
	$val =~ s/([a-z]{1})[a-z]*/$1/gi;
	$val =~ s/[-_.+\s]*([a-z]+)[-_.+\s]*/$1/gi;
	$val =~ tr/.()/-  /;
	$val =~ s/\s+//g;
	if(rindex($bck, '.') == -1) { $val = "${par}${val}"; }
	else { $val = "${par}${val}.${ext}"; }
	return $val;
}

if(@ARGV != 1)
{
	print "usage: " . __FILE__ . " <filename> | -\r\n";
	exit 1;
}
else { $name = shift; }

if($name eq "-")
{
	while(my $line = <STDIN>)
	{
		$res = apply($line);
		print "$res\n";
	}
}
else
{
	$res = apply($name);
	print "$res\n";
}

exit 0;
