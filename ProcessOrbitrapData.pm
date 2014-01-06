#!/usr/bin/perl                                                                                              

package ProcessOrbitrapData;
require Exporter;

use strict;
use warnings;
use BasicMethods;
#use DBI;          # Commentez pour "use Expasy"                                                
#use Expasy;            # Pour l'utilisation sur Expasy (commentez pour "use DBI")                           

our @ISA= qw(Exporter);
our @EXPORT=qw(process_profile compute_default_threshold print_final_results);
our @EXPORT_OK=qw();
our $VERSION=1.00;

sub compute_default_threshold{
    my ($tmp_t) = @_;
    my $default_threshold= BasicMethods::median(
						map {
						    if (!defined($tmp_t->[$_+1]->[0]) || !defined($tmp_t->[$_]->[0])){
							print STDERR "Error $tmp_t->[$_+1]->[0]-$tmp_t->[$_]->[0]\n";
						    }
						    $tmp_t->[$_+1]->[0]-$tmp_t->[$_]->[0]}
						grep {$_ >= 0 && $_ < scalar(@$tmp_t)-1}
						(0 .. 20)
						);
    
    return  $default_threshold-$default_threshold/10;

    }


sub print_final_results{
    my ($t,$nber_scans, $txt_file, $error_file)=@_;
    
    open (OUT, ">$txt_file") or die "Cannot open file $txt_file";
    open (ERR, ">$error_file") or die "Cannot open file $error_file";
    
    for( my $i=0;$i<scalar(@$t); $i++){
	my $e=$t->[$i];
	my $inten = $e->[1]/$nber_scans;
	if ($i>0 && $i < scalar(@$t)-2 #&& $t->[$i-1]->[1] > $e->[1] && $t->[$i+1]->[1] > $e->[1] && $t->[$i+1]->[1] > $t->[$i+2]->[1]                                                                          
	    && $inten > 100 && ($e->[1] - $t->[$i-1]->[1])/$nber_scans > 100 && ($e->[1] - $t->[$i+1]->[1])/$nber_scans > 100 && ($t->[$i+2]->[1]- $t->[$i+1]->[1])/$nber_scans > 100){
	    my $diff1 = $e->[0] - $t->[$i-1]->[0];
	    my $diff2 = $t->[$i+1]->[0]- $e->[0];
	    my $diff3 = $t->[$i+2]->[0]-$t->[$i+1]->[0];
	    print ERR "WARNING: $i - Something possibly went wrong for mass $e->[0]: $diff1, $diff2, $diff3, $t->[$i+1]->[1] > $e->[1] && $t->[$i-1]->[1] > $e->[1]!\n";
	}
	print OUT join("\t", ($e->[0], $inten)) . "\n";
    }
    
    close OUT;
    close ERR;
    
}

sub process_profile{
    my ($t, $tmp_t, $num, $default_threshold) = @_;

#    print scalar(@$t) . " - $num!!\n";
    if (scalar(@$t) == 0){
	
        for(my $i = 0; $i< scalar(@$tmp_t)-1; $i++){
            my $d = $tmp_t->[$i];
            my $last_i=scalar(@$t)-1;
            my $min_interval=BasicMethods::median(
					       map {
						   if (!defined($tmp_t->[$_+1]->[0]) || !defined($tmp_t->[$_]->[0])){
						       print STDERR "Error $tmp_t->[$_+1]->[0]-$tmp_t->[$_]->[0]\n";
						   }
						   $tmp_t->[$_+1]->[0]-$tmp_t->[$_]->[0]}
					       grep {$_ >= 0 && $_ < scalar(@$tmp_t)-1}
					       ($i-10 .. $i+10)
					       );
            my $threshold = $min_interval-$min_interval/10
                || $default_threshold;

            $threshold=$default_threshold if ($threshold < $default_threshold);
#	    $threshold= $median_interval_start if ($threshold <  $median_interval_start);  
            if ($i > 0 && $tmp_t->[$i]->[0]-$tmp_t->[$i-1]->[0] < $threshold){
		my $diff = $tmp_t->[$i]->[0]-$tmp_t->[$i-1]->[0] ;
#		print "$threshold, $diff, $tmp_t->[$i]->[0] $tmp_t->[$i-1]->[0] $tmp_t->[$i+1]->[0], $tmp_t->[$i]->[1]\n";
                $t->[$last_i]->[1]+=$d->[1];
            }else{
                push(@$t, [$d->[0], $d->[1]]);
            }
        }
    }else{
        $t= process($tmp_t, $t, $num, $default_threshold);
    }
#    exit 0;

    return ($t, $num);
}


sub process{
    my ($tmp_t, $t, $num, $default_threshold) = @_;
    my $tmp_t_to_insert=[];
    my $i=0;

    foreach my $d (@$tmp_t){

	my ($mass, $inten)=(@$d);
	my $tmp_local_vals=[];
	
	my $last_i=scalar(@$t)-1;
	
	while ($last_i > $i && $t->[$i+1]->[0] < $mass){
	    $i++;
	}
	
	if ($i < $last_i && $t->[$i+1]->[0] == $mass){
	    ($t, $i, $tmp_t_to_insert)=splice_tmp_tab($t, $i, $tmp_t_to_insert) if (scalar(@$tmp_t_to_insert)>0);
	    $t->[$i+1]->[1]+=$inten;
	}else{
	    my $diff1 =($i >= 0) ? $mass - $t->[$i]->[0] : undef;
    my $diff2 = ($i < $last_i) ? $t->[$i+1]->[0] - $mass : undef;
            my $min_interval = BasicMethods::median(
                                   map {
                                       print STDERR "Error $_, $t->[$_+1]->[0]-$t->[$_]->[0]\n" if (!defined($t->[$_+1]->[0]) || !defined($t->[$_]->[0]));
                                       $t->[$_+1]->[0]-$t->[$_]->[0]}
                                   grep {$_ >= 0 && $_ < $last_i}
				   ($i-10 .. $i+10)
                                   );
            my $threshold = $min_interval-$min_interval/10
                || $default_threshold;
	    $threshold=$default_threshold if ($threshold < $default_threshold);
	    
            if ((!$diff1 || $diff1 > $threshold)
                && (!$diff2 || $diff2 > $threshold)){
                splice(@$t, $i+1, 0, ([$mass, $inten]));
            }else{
                if ($diff2 && (!$diff1 || ($diff1 && $diff1 > $diff2))){
                    ($t, $i, $tmp_t_to_insert)=splice_tmp_tab($t, $i, $tmp_t_to_insert) if (scalar(@$tmp_t_to_insert)>0);
                    $t->[$i+1]->[1]+=$inten;
                }elsif($diff1){
                    ($t, $i, $tmp_t_to_insert)=splice_tmp_tab($t, $i, $tmp_t_to_insert) if (scalar(@$tmp_t_to_insert)>0);
                    $t->[$i]->[1]+=$inten;
                }
            }
	}
    }
    return $t;
}


sub splice_tmp_tab{
    my ($t, $i, $tmp_tab) = @_;

    splice(@$t, $i, 0, @$tmp_tab);
    $i+=scalar(@$tmp_tab);
    $tmp_tab =[];

    return ($t, $i, $tmp_tab);
}
