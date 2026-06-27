#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use Test::More;
use File::Basename;

my $dir   = dirname($0);
my $HL    = "$dir/../highlight";
my $debug = grep { /^--?debug$/ } @ARGV;

# Vanilla
is(
	highlight_output("cats and dogs", ['cats']),
    '[COLOR033]cats[RESET] and dogs',
    "simple word match"
);

is(
	highlight_output("two different words", ['two', 'words']),
    '[COLOR033]two[RESET] different [COLOR011]words[RESET]',
    "two different patterns"
);

# Case (in)sensitive
is(
	highlight_output("case INSENSITIVE", ['129,CASE','42,insensitive'], ['--case_insensitive']),
    '[COLOR129]case[RESET] [COLOR042]INSENSITIVE[RESET]',
    "ci via option"
);

is(
	highlight_output("CaSe InSeNsItIvE DEFAULT", ['36,insensitive']),
    'CaSe [COLOR036]InSeNsItIvE[RESET] DEFAULT',
    "smartcase (no upper = ci)"
);

is(
	highlight_output("Case sensitive case", ['177,Case']),
    '[COLOR177]Case[RESET] sensitive case',
    "smartcase (upper = cs)"
);

is(
	highlight_output("case sensitive Forced", ['55,Forced'], ['--case_sensitive']),
    'case sensitive [COLOR055]Forced[RESET]',
    "cs forced"
);

# Specific colors
is(
	highlight_output("Specific color", ['red,color']),
    'Specific [COLOR160]color[RESET]',
    "named color"
);

is(
	highlight_output("OMG three colors", ['green,OMG','yellow,three','orange,colors']),
    '[COLOR034]OMG[RESET] [COLOR226]three[RESET] [COLOR214]colors[RESET]',
    "three named colors"
);

# Regex
is(
	highlight_output("Match : Regexp", ['227,.+?: \w+']),
    '[COLOR227]Match : Regexp[RESET]',
    "regex match"
);

is(
	highlight_output("Only  : Paren", ['58,.+?: (\w+)']),
    'Only  : [COLOR058]Paren[RESET]',
    "capturing parens"
);

is(
	highlight_output("--Full: Matches", ['82,.+?: (\w+)'], ['--full_matches']),
    '[COLOR082]--Full: Matches[RESET]',
    "full matches with parens"
);

# Bold
is(
	highlight_output("Bolder", ['11,bold'], ['--bold']),
    '[BOLD][COLOR011]Bold[RESET]er',
    "bold"
);

done_testing();

exit 0;

###############################################################################

sub highlight_output {
	my ($text, $filters, $opts) = @_;

	my $filter_str = join(' ', map { "--filter '$_'" } @$filters);
	$opts //= [];
	my $opt_str = join(' ', @$opts);

	my $cmd   = "echo '$text' | $HL --force $opt_str $filter_str";
	my $after = `$cmd`;
	$after    = trim($after);

	diag("CMD: $cmd") if $debug;

	my $human = output_human($after);
	return bleach_text($human);
}

sub trim {
	my ($s) = (@_, $_);
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;
	return $s;
}

sub output_human {
	my @lines = @_;

	my $ret = '';
	foreach my $line (@lines) {
		$line =~ s/(\e\[.*?m)/dump_ansi($1)/eg;
		$ret .= $line;
	}
	return $ret;
}

sub dump_ansi {
	my $str = shift();
	if ($str !~ /^\e/) {
		return "";
	}

	my $raw = $str;
	$str =~ s/^\e\[//g;
	$str =~ s/m$//g;

	my $ret  = "\e[0m";
	$ret    .= "\e[38;5;15m";

	my @parts = split(";", $str);

	my @basic_mapping = qw(BLACK RED GREEN YELLW BLUE MAGNT CYAN WHITE);

	if (!@parts) {
		$ret .= "[RESET]";
	}

	for (my $count = 0; $count < @parts; $count++) {
		my $p = $parts[$count];
		if ($p eq "1") {
			$ret .= "[BOLD]";
		} elsif ($p eq "0" || $p eq "") {
			$ret .= "[RESET]";
		} elsif ($p eq "7") {
			$ret .= "[REVERSE]";
		} elsif ($p eq "27") {
			$ret .= "[NOTREV]";
		} elsif ($p eq "38") {
			my $next  = $parts[$count + 1];
			my $color = $parts[$count + 2];
			$count += 2;
			$ret .= sprintf("[COLOR%03d]",$color);
		} elsif ($p eq "48") {
			my $next  = $parts[++$count];
			my $color = $parts[++$count];
			$count += 2;
			$ret .= sprintf("[BACKG%03d]",$color);
		} elsif ($p >= 30 and $p <= 37) {
			my $color = $p - 30;
			$color = $basic_mapping[$color];
			$ret .= "[$color]";
		} else {
			$ret .= "[UKN: $p]";
		}
	}

	$ret .= $raw;

	return $ret;
}

sub bleach_text {
	my $str = shift();
	$str =~ s/\e\[\d*(;\d+)*m//g;
	return $str;
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
