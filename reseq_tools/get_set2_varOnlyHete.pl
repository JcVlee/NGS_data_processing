#!/usr/bin/perl
use strict; 
use warnings; 
use LogInforSunhh; 
use Getopt::Long; 
my %opts; 
GetOptions(\%opts, 
	"help!", 
	"startColN:i", # 2 
); 

$opts{'startColN'} //= 2; 

my $geno_col = $opts{'startColN'}; 

sub usage {
	print STDERR <<HH; 

perl $0 in_snp.tbl > in_snp.tbl.set2_varOnlyHete

-help
-startColN       [$opts{'startColN'}]

Please note the geno_col=$geno_col

HH
	exit(1); 
}

-t and !@ARGV and &usage(); 
$opts{'help'} and &usage(); 

while (<>) {
	$. % 1e6 == 1 and &tsmsg("[Msg] Reading $. lines.\n"); 
	s/[^\S\t]+$//; 
	my @ta = split(/\t/, $_); 
	if ( $ta[0] eq 'chr' ) {
		print "$_\n"; 
		next; 
	}
	my $base = 'N'; 
	my $has_diff = 0; 
	for (my $i=$geno_col; $i<@ta; $i++) {
		$ta[$i] = uc($ta[$i]); 
		$ta[$i] =~ m/^[ATGC]$|\*|\+/ or $ta[$i] = 'N'; 
		$ta[$i] eq 'N' and next; 
		$base eq 'N' and $base = $ta[$i]; 
		$base ne $ta[$i] and do { $has_diff = 1; last; }; 
	}
	$has_diff == 0 and print "$_\n"; 
}
