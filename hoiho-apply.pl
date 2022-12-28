#!/usr/bin/env perl
#
# This script takes a json file that contains rules for each domain as
# its first command line parameter, and then hostnames to interpret as
# follows.
# first, this script can read hostnames, one per line, from stdin.
# second this script can take a series of hostnames to interpret as
# optional command line parameters.
#
# Author: Matthew Luckie
# Copyright (C) 2021 The University of Waikato
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use warnings;
use JSON::XS;

if(scalar(@ARGV) < 1)
{
    print STDERR "hoiho-apply.pl \$json [\@hostnames]\n";
    exit -1;
}
my ($json, @hostnames) = @ARGV;

my %rulemap;
my %rules;
open(JSON, $json) or die "could not read $json";
while(<JSON>)
{
    my $obj = decode_json($_);
    my $domain = $obj->{domain};
    next if($obj->{score}{class} ne "good" &&
	    $obj->{score}{class} ne "promising");
    @{$rules{$domain}{re}} = @{$obj->{re}};
    @{$rules{$domain}{plan}} = @{$obj->{plan}};
    @{$rules{$domain}{geohints}} = @{$obj->{geohints}};

    foreach my $hint (@{$rules{$domain}{geohints}})
    {
	$hint->{str} = $hint->{code};
	$hint->{str} .= "|" . $hint->{st} if(defined($hint->{st}));
	$hint->{str} .= "|" . $hint->{cc} if(defined($hint->{cc}));

	if(defined($hint->{location}))
	{
	    $hint->{iso3166} = $hint->{location}{cc};
	    if(defined($hint->{location}{st})) {
		$hint->{iso3166} .= "-" . $hint->{location}{st};
	    }
	}
    }

    $rulemap{length($domain)}{$domain} = 1;
}
close JSON;
my @rulemap = sort {$b <=> $a} keys %rulemap;

sub apply($)
{
    my ($in) = @_;
    my $hostname = lc $in;
    my $len = length($hostname);

    foreach my $rulemap (@rulemap)
    {
	next if($rulemap >= $len);
	my $suffix = substr $hostname, 0-$rulemap;
	next if(!defined($rulemap{$rulemap}{$suffix}));

	my @re = @{$rules{$suffix}{re}};
	my $maphint;
	foreach my $i (0 .. $#re)
	{
	    my $re = $re[$i];
	    if($hostname =~ /$re/)
	    {
		my @plan = @{$rules{$suffix}{plan}[$i]};
		my %out;
		my @code;

		for(my $i = 1; $i < @+; $i++)
		{
		    my $str = substr $hostname, $-[$i], $+[$i] - $-[$i];
		    my $type = $plan[$i-1];
		    if($type eq "cc") { $out{cc} = $str; }
		    elsif($type eq "st") { $out{st} = $str; }
		    else { push @code, $str; $out{type} = $type; }
		}

		if(scalar(@code) == 1)
		{
		    $out{code} = join('', split(/[^a-z\d]+/, $code[0]));
		}
		else
		{
		    my $al = length $code[0];
		    my $bl = length $code[1];
		    my $code;
		    if($out{type} eq "locode")
		    {
			if($al == 2 && $bl == 3) {
			    $code = sprintf("%s%s",$code[0],$code[1]);
			} elsif($al == 3 && $bl == 2) {
			    $code = sprintf("%s%s",$code[1],$code[0]);
			}
		    }
		    elsif($out{type} eq "clli")
		    {
			if($al == 2 && $bl == 4) {
			    $code = sprintf("%s%s",$code[1],$code[0]);
			} elsif($al == 4 && $bl == 2) {
			    $code = sprintf("%s%s",$code[0],$code[1]);
			}
		    }
		    $out{code} = $code;
		    $out{str} = $code;
		    $out{str} .= "|" . $out{st} if(defined($out{st}));
		    $out{str} .= "|" . $out{cc} if(defined($out{cc}));
		}

		$maphint = \%out;
		last;
	    }
	}

	next if(!defined($maphint));
	my $match;

	foreach my $hint (@{$rules{$suffix}{geohints}})
	{
	    next if($maphint->{type} ne $hint->{type});
	    next if($maphint->{code} ne $hint->{code});
	    next if((defined($maphint->{cc}) && !defined($hint->{cc})) ||
		    (!defined($maphint->{cc}) && defined($hint->{cc})) ||
		    (defined($maphint->{cc}) && defined($hint->{cc}) &&
		     $maphint->{cc} ne $hint->{cc}));
	    next if((defined($maphint->{st}) && !defined($hint->{st})) ||
		    (!defined($maphint->{st}) && defined($hint->{st})) ||
		    (defined($maphint->{st}) && defined($hint->{st}) &&
		     $maphint->{st} ne $hint->{st}));

	    $match = $hint;
	    last;
	}

	if(defined($match))
	{
	    printf("%s %s", $in, $match->{str});
	    if(defined($match->{location}))
	    {
		printf(" %s %s %s \"%s\"",
		       $match->{iso3166}, $match->{lat}, $match->{lng},
		       $match->{location}{place});
		printf(" \"%s\"", $match->{location}{facname})
		    if(defined($match->{location}{facname}));
		printf(" \"%s\"", $match->{location}{street})
		    if(defined($match->{location}{street}));
	    }
	    print "\n";
	}
	else
	{
	    my $str = $maphint->{code};
	    $str .= "|" . $maphint->{st} if(defined($maphint->{st}));
	    $str .= "|" . $maphint->{cc} if(defined($maphint->{cc}));
	    printf("%s %s\n", $in, $str);
	}
    }
}

if(scalar(@hostnames) > 0)
{
    apply($_) foreach (@hostnames);
}
else
{
    while(<STDIN>)
    {
	chomp;
	apply($_);
    }
    close STDIN;
}

exit 0;
