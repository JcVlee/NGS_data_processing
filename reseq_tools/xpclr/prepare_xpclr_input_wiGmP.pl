#!/usr/bin/perl
use strict; 
use fileSunhh; 
use LogInforSunhh; 
use mathSunhh; 

!@ARGV and die "perl $0   out_pref   apple.snp_addGmP   idv_list_1_objPop   idv_list_2_refPop\n"; 

my $opref  = shift; 
my $fn_snp = shift; 
my $fn_lis1 = shift; 
my $fn_lis2 = shift;

my %glob; 
my $gmCn = 2; 

my %fho; 

my %indv_1 = &indv_list($fn_lis1); 
my %indv_2 = &indv_list($fn_lis2); 

my @h; 
my $fh_snp = &openFH( $fn_snp, '<' ); 
{ my $a=&wantLineC($fh_snp); @h=split(/\t/, $a); } 

{
	my %nn; 
	my @new_h; 
	for (my $i=0; $i<@h; $i++) {

		defined $indv_1{'has'}{$h[$i]} and push( @{$indv_1{'goodIdx'}}, $i ); 
		defined $indv_2{'has'}{$h[$i]} and push( @{$indv_2{'goodIdx'}}, $i ); 
		defined $indv_1{'has'}{$h[$i]} and defined $indv_2{'has'}{$h[$i]} and &stopErr("[Err] Indv [$h[$i]] exists in both groups.\n"); 
	}
	@{$indv_1{'goodSample'}} = @h[ @{$indv_1{'goodIdx'}} ]; 
	@{$indv_2{'goodSample'}} = @h[ @{$indv_2{'goodIdx'}} ]; 
}

my %cc = ( "cntN_base"=>0, "cntN_step"=>1e4 ); 

my %locs; 
my %sites; 
my %prev; 
while (&wantLineC($fh_snp)) { 
	&fileSunhh::log_section($. , \%cc) and &tsmsg("[Msg] $. line.\n"); 
	my @ta=split(/\t/, $_); 
#	defined $phy2gm_P{$ta[0]} or next; 
#	defined $phy2gm_P{$ta[0]}{$ta[1]} or next; 

	my @ta_1 = @ta[ @{$indv_1{'goodIdx'}} ]; 
	my @ta_2 = @ta[ @{$indv_2{'goodIdx'}} ]; 

	my ( %al, %al_1, %al_2 ); 
	my %geno; 
	my $is_bad = 0; 
	for (my $i=0; $i<@ta_1; $i++ ) { 
		if ($ta_1[$i] =~ m/^([ATGCN])$/) { 
			$al_1{$1} += 2; 
			$al{$1}   += 2; 
		} elsif ($ta_1[$i] =~ m/^([ATGC])([ATGC])$/) { 
			$al_1{$1} ++; $al_1{$2} ++; 
			$al{$1}   ++; $al{$2}   ++; 
		} elsif ( $ta_1[$i] =~ m/^[ATGC]{3,}$/ ) { 
			$is_bad = 1; 
			last; 
		} else { 
			if (!(defined $glob{'bad_geno'}{$ta_1[$i]})) {
				$glob{'bad_geno'}{$ta_1[$i]} = 1; 
				&tsmsg("[Wrn] Skip site with bad genotype [$ta_1[$i]]\n"); 
			}
			$is_bad = 1; 
			last; 
		}
	}
	delete $al_1{'N'}; 
	scalar(keys %al_1) > 0 or $is_bad = 1; 
	$is_bad == 1 and next; 
	for (my $i=0; $i<@ta_2; $i++ ) { 
		if ($ta_2[$i] =~ m/^([ATGCN])$/) { 
			$al_2{$1} += 2; 
			$al{$1}   += 2; 
		} elsif ($ta_2[$i] =~ m/^([ATGC])([ATGC])$/) { 
			$al_2{$2} ++; $al_2{$2} ++; 
			$al{$2}   ++; $al{$2}   ++; 
		} elsif ( $ta_2[$i] =~ m/^[ATGC]{3,}$/ ) { 
			$is_bad = 1; 
			last; 
		} else { 
			if ( !(defined $glob{'bad_geno'}{$ta_2[$i]}) ) {
				$glob{'bad_geno'}{$ta_2[$i]} = 1; 
				&tsmsg("[Wrn] Skip site with bad genotype [$ta_2[$i]]\n"); 
			}
			$is_bad = 1; 
			last; 
		}
	}
	delete $al_2{'N'}; 
	scalar(keys %al_2) > 0 or $is_bad = 1; 
	$is_bad == 1 and next; 
	delete $al{'N'}; 
	scalar( keys %al ) == 2 or next; 
	my @aa = sort { $al{$b} <=> $al{$a} || $a cmp $b } keys %al; 
	$geno{$aa[0]}         = '1 1'; 
	$geno{"$aa[0]$aa[0]"} = '1 1'; 
	$geno{$aa[1]}         = '0 0'; 
	$geno{"$aa[1]$aa[1]"} = '0 0'; 
	$geno{"$aa[0]$aa[1]"} = '1 0'; 
	$geno{"$aa[1]$aa[0]"} = '1 0'; 
	$geno{"N"}            = '9 9'; 

	my $chrN = $ta[0]; 
	$chrN =~ s!^(chr|WM97_Chr)!!i; 
	$chrN =~ s!^0+!!; 
	$chrN =~ m!^\d+$! or &stopErr("[Err] Bad chrID [$chrN] from [$ta[0]]\n"); 

	my $gmP = $ta[$gmCn]; 
	if (defined $prev{'gmID'} and $prev{'gmID'} eq $ta[0]) {
		$prev{'gmP'} < $gmP or next; 
	}
	$prev{'gmID'} = $ta[0]; 
	$prev{'gmP'}  = $gmP; 

	unless ( defined $fho{$ta[0]} ) {
		$fho{$ta[0]}{'geno1'} = &openFH( "${opref}.$ta[0]_g1.geno", '>' ); 
		$fho{$ta[0]}{'geno2'} = &openFH( "${opref}.$ta[0]_g2.geno", '>' ); 
		$fho{$ta[0]}{'SNP'}   = &openFH( "${opref}.$ta[0].snp",     '>' ); 
	}

	print {$fho{$ta[0]}{'geno1'}} join(' ', map { $geno{$_} } @ta_1)."\n"; 
	print {$fho{$ta[0]}{'geno2'}} join(' ', map { $geno{$_} } @ta_2)."\n"; 

	my $mrkID = "$ta[0]_$ta[1]"; 
#	print {$fho{$ta[0]}{'SNP'}} join( "\t", $mrkID, $chrN, $phy2gm_P{$ta[0]}{$ta[1]}, $ta[1], $aa[0], $aa[1] )."\n"; 
	print {$fho{$ta[0]}{'SNP'}} join( "\t", $mrkID, $chrN, $gmP                     , $ta[1], $aa[0], $aa[1] )."\n"; 

}
for my $chrID ( keys %fho ) {
	for my $k2 ( qw/geno1 geno2 SNP/ ) {
		close( $fho{$chrID}{$k2} ); 
	}
}

&tsmsg("[Rec] Done. $0\n"); 

#my $fh_oSite = &openFH("${opref}.sites", '>'); 
#my $fh_oLoci = &openFH("${opref}.locs",  '>'); 
sub indv_list {
	my $fn = shift; 
	my %back; 
	my $fh = &openFH($fn, '<'); 
	while (&wantLineC($fh)) {
		my @ta=&splitL("\t", $_); 
		defined $back{'has'}{$ta[0]} and next; 
		push(@{$back{'arr'}}, $ta[0]); 
		$back{'has'}{$ta[0]} = $#{$back{'arr'}}; 
	}
	close ($fh); 
	return(%back); 
}


sub load_gmP {
	my $fn = shift; 
	my %back; 
	my $fh = &openFH($fn, '<'); 
	while (&wantLineC($fh)) {
		# chr \\t pos \\t cM 
		my @ta = &splitL("\t", $_); 
		$ta[0] eq 'chr' and next; 
		$back{$ta[0]}{$ta[1]} = $ta[2]; 
	}
	close($fh); 
	return(%back); 
}

