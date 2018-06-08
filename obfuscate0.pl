#!/usr/bin/perl

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
	#elsif($val =~ m/tumblr_.*/) { $val =~ s/tumblr_(.+)/$1/gi; return $val; }
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

if($name eq "-") { while(my $line = <STDIN>) { $res = apply($line); print "$res\n"; } }
else { $res = apply($name); print "$res\n"; }
exit 0;
