#!/usr/bin/perl -CS
# muffet.pl: commandline driver for Spider::Muffet

use Spider::Muffet;


my $spider = Spider::Muffet->new_with_options();
$spider->start;
exit(0);
