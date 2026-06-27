#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use Test::More;
use File::Basename;
use File::Temp;

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

###############################################################################
# --file option
###############################################################################

{
	my $tmp = File::Temp->new(UNLINK => 1);
	print $tmp "red\thello";
	close $tmp;
	is(
		bleached_output("echo 'hello world' | $HL --force --file '$tmp'"),
		'[COLOR160]hello[RESET] world',
		"--file with tab-separated pattern"
	);
}

{
	my $tmp = File::Temp->new(UNLINK => 1);
	print $tmp "hello";
	close $tmp;
	is(
		bleached_output("echo 'hello world' | $HL --force --file '$tmp'"),
		'[COLOR033]hello[RESET] world',
		"--file with plain pattern"
	);
}

{
	my $tmp = File::Temp->new(UNLINK => 1);
	print $tmp "# comment\nred\thello";
	close $tmp;
	is(
		bleached_output("echo 'hello world' | $HL --force --file '$tmp'"),
		'[COLOR160]hello[RESET] world',
		"--file ignores comment lines"
	);
}

###############################################################################
# HIGHLIGHT_COLORS env var
###############################################################################

is(
	bleached_output("echo 'cat dog' | HIGHLIGHT_COLORS=160,27 $HL --force cat dog"),
	'[COLOR160]cat[RESET] [COLOR027]dog[RESET]',
	"HIGHLIGHT_COLORS overrides default color cycle"
);

###############################################################################
# NO_COLOR env var
###############################################################################

is(
	bleached_output("echo 'hello world' | NO_COLOR=1 $HL hello"),
	'hello world',
	"NO_COLOR disables color without --force"
);

is(
	bleached_output("echo 'hello world' | NO_COLOR=1 $HL --force hello"),
	'[COLOR033]hello[RESET] world',
	"--force takes precedence over NO_COLOR"
);

###############################################################################
# Multi-line input
###############################################################################

is(
	bleached_output("printf 'cat\\ndog\\n' | $HL --force --filter 33,cat --filter 11,dog"),
	"[COLOR033]cat[RESET]\n[COLOR011]dog[RESET]",
	"multi-line input with two filters"
);

###############################################################################
# Multiple matches per line
###############################################################################

is(
	bleached_output("echo 'cat cat cat' | $HL --force cat"),
	'[COLOR033]cat[RESET] [COLOR033]cat[RESET] [COLOR033]cat[RESET]',
	"multiple matches on one line"
);

###############################################################################
# Dash-leading patterns
###############################################################################

is(
	bleached_output("echo '-foo bar' | $HL --force --filter '196,-foo'"),
	'[COLOR196]-foo[RESET] bar',
	"dash-leading pattern via --filter"
);

###############################################################################
# _bold color suffix
###############################################################################

is(
	bleached_output("echo 'word' | $HL --force --filter '165_bold,word'"),
	'[COLOR165][BOLD]word[RESET]',
	"_bold color suffix combines color and bold in one code"
);

###############################################################################
# on_ background suffix
###############################################################################

is(
	bleached_output("echo 'word' | $HL --force --filter '10_on_140,word'"),
	'[COLOR010][BACKG140]word[RESET]',
	"on_ background suffix sets foreground and background"
);

###############################################################################
# Bareword patterns
###############################################################################

is(
	bleached_output("echo 'hello' | $HL --force hello"),
	'[COLOR033]hello[RESET]',
	"bareword pattern with default color"
);

is(
	bleached_output("echo 'hello world' | $HL --force hello world"),
	'[COLOR033]hello[RESET] [COLOR011]world[RESET]',
	"multiple bareword patterns cycle through default colors"
);

###############################################################################
# Color cycling (more patterns than default colors)
###############################################################################

is(
	bleached_output("echo 'a b c d e f g h i j k' | $HL --force a b c d e f g h i j k"),
	'[COLOR033]a[RESET] [COLOR011]b[RESET] [COLOR009]c[RESET] [COLOR047]d[RESET] [COLOR214]e[RESET] [COLOR099]f[RESET] [COLOR015]g[RESET] [COLOR051]h[RESET] [COLOR198]i[RESET] [COLOR094]j[RESET] [COLOR033]k[RESET]',
	"color cycling wraps after 10 default colors (k gets color index 0)"
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
	return bleached_output($cmd);
}

sub bleached_output {
	my $cmd = shift;

	diag("CMD: $cmd") if $debug;

	my $after = `$cmd`;
	$after    = trim($after);

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
