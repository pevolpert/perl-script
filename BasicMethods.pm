#!/usr/bin/perl                                                                                                                                                      
package BasicMethods;
require Exporter;

use strict;
use warnings;#use DBI;          # Commentez pour "use Expasy"                                                                                                        
#use Expasy;            # Pour l'utilisation sur Expasy (commentez pour "use DBI")                                                                                   

our @ISA= qw(Exporter);
our @EXPORT=qw(first  min_i_first  mean  median  std_dev  log10  sqr  min  sum);
our @EXPORT_OK=qw();
our $VERSION=1.00;

sub first{
    if (scalar @_ == 0){return undef;}
    else {return shift;}
}

sub min_i_first {
    my @l=@_;
    my ($min, $ind)=(min(@l), 0);
    foreach (0.. scalar(@l)-1){
        if ($l[$_] == $min){$ind=$_;last;}
    }
    return $ind;
}

sub mean {
    my @l= grep{defined($_)} @_;
    my $n = scalar(@l);
    if ($n >0){
        my $tot=sum(@l);
        return $tot / $n;
    }else{
        return undef;
    }
}

sub median{
    my @l=sort{$a <=> $b} grep{defined($_)} @_;
    my $n=scalar(@l);
    if ($n >0){
    if ($n%2 == 0){
	return mean($l[($n/2)-1], $l[$n/2]);
    }else{
	return $l[int($n/2)];
    }
}else{
    return undef;
}
}
sub std_dev {
    my @l=grep{defined($_)} @_;
    my $n=scalar(@l);
    if ($n >0){
        my $mean=mean(@l);
        my $tot=0;
        map {$tot+=($_-$mean)**2} (@l);
        return ($tot / scalar(@l))**.5;
    }else{
        return undef;
    }
}

sub log10 {
    my $n = shift;
    return log($n)/log(10);
}


sub sqr {
    $_[0] * $_[0];
}


sub min {
    my @l= sort {$a <=> $b} grep {defined($_)} (@_);
    return shift @l;
}

sub sum {
    my @l= grep{defined($_)} @_;
    my $sum=0;
    map {$sum+=$_} @l;
    return $sum;
}
