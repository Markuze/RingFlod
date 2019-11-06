#!/usr/bin/perl -w

use strict;
use autodie;

my $__list = 0;
my $__arg = 1;
my $__func = 2;

my $file = '/homes/markuze/copy/drivers/nvme/host/fc.c';

my %callers = ();

sub collect_funcs {
	my $f = shift;
	open my $fh, '<', $f;

	while (<$fh>) {
		if (/^(\w[\s\w]+)\(\w+\**\s/) {
			#printf "$1\n";
			if (/([\w]+)\(\w+\**\s/) {
				$callers{$1} = undef;
			}
		}
	}
	close $fh;
}

sub build_map {
	my $f = shift;
	open my $fh, '<', $f;

	my $curr;

	while (<$fh>) {
		chomp;
		if (/^(\w[\s\w]+)\(\w+\**\s/) {
			if (/([\w]+)\(\w+\**\s/) {
				$curr = $1;
			}
			next;
		}
		if (/^}\s*&/) {
			$curr = undef;
		}
		next unless defined $curr;

		if (/(\w+)\(/) {
			my $func = $1;
			#print "$1 [$curr]\n";
			if  (exists $callers{$func}) {
				#print "$curr -> $1\n";
				push @{$callers{$func}[$__list]}, $curr;
			}
			if (/dma_map/) {
				my $arg;
				next if /mapping_error/;
				print ">$_\n";
				if (/dma_map\w+\([\w\->&]+,\s*([\w\->\.&]+)/) {
					$arg = $1;
				} else {
					my $line = <$fh>;
					#printf "$line";
					$line =~ /^\s+([&\w\->]+).*,/;
					$arg = $1;
				}
				print "$func : [$arg]\n";
				push @{$callers{$func}[$__arg]}, $arg;
			}
		}
	}
	close $fh;
}

sub show_call_list {
	my ($root, $idx) = @_;
	for (@{$callers{$root}[$__list]}) {
		#printf "$_\n";
		show_call_list($_, $idx++);
		printf "[$idx]$_,";
	}

}

collect_funcs $file;
#two steps cause we want only local funcs.
build_map $file;

for (@{$callers{'fc_dma_map_single'}[$__arg]}) {
	print "$_\n";
}

for (@{$callers{'fc_dma_map_single'}[$__list]}) {
	my $arg = shift @{$callers{'fc_dma_map_single'}[$__arg]};
	printf "Call list $_ [$arg]\n";
	show_call_list $_;
	printf "\n";
}
