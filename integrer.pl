#!/usr/bin/perl
use strict;
use warnings;
#use BasicMethods;
use ProcessOrbitrapData; #qw(compute_default_trheshold);

my $file = $ARGV[0];
my $bin_size = $ARGV[1];

my $final_tab = [];
my $sub_final_tab = [];
my $tmp_tab = [];

#scanCount_mzxml=1962, startTime_mzxml=0.3765, endTime_mzxml=2702.91
#
#<profile num=0 scan=1 time_mzxml=0.3765>
#200.000671386719	0
#200.001205444336	0
#200.001739501953	0
#200.00227355957	0
#200.125213623047	0

my $count= 0;
my $num = 0;

open (IN, $file) or die "cannot open file $file";
while(<IN>){ 
    my $line = chomp($_);
    if (/^<profile num=(\d+)/){
	$num = $1;
    }elsif(/^([\d.]+)\t([\d.]+)$/){
	push(@$tmp_tab, [$1, $2]);
    }elsif(/^<\/profile>/){
	my $default_threshold = compute_default_threshold($tmp_tab); 
	($sub_final_tab, $num)=ProcessOrbitrapData::process_profile($sub_final_tab, $tmp_tab, $num, $default_threshold);
	$tmp_tab = [];
	$count++;
	
	if ($count>=$bin_size){	
	    push(@$final_tab, $sub_final_tab);
	    $sub_final_tab = [];
	    $count=0;
	}
    }
}

close(IN);

### write $final_tab

open (FILE, "+>data_integre.txt") or die "can't create file: $!";
foreach my $i (0 .. scalar(@$final_tab)-1) {
    my $tab = $final_tab->[$i];
    print FILE "<profile num=" . $i . ">\n";
    print FILE join("\n", map {my $e = $_; join("\t", @$e)} @$tab) . "\n";
    print FILE "</profile>\n"
}

close (FILE);


print "Total number of scans: $num\n";
print "Number of integrated scans: " . scalar(@$final_tab) . "\n";
print "Number of scans in the last integrated scan: " . ($num % $bin_size) . "\n";
