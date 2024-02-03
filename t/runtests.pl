#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use Getopt::Long;
use File::Basename;

my $debug;
GetOptions(
	'debug' => \$debug,
);

my $dir = dirname($0);
my $HL  = "$dir/../highlight";

###############################################################################
###############################################################################

my $total_tests = 0;
my $pass        = 0;

# Vanilla
$pass += run_test("cats and dogs"      , ['cats']        , '[COLOR033]cats[RESET] and dogs');
$pass += run_test("two different words", ['two', 'words'], '[COLOR033]two[RESET] different [COLOR011]words[RESET]');

# Case (in)sensitive
$pass += run_test("case INSENSITIVE"        , ['129,CASE','42,insensitive'], '[COLOR129]case[RESET] [COLOR042]INSENSITIVE[RESET]', ['--case_insensitive']);
$pass += run_test("CaSe InSeNsItIvE DEFAULT", ['36,insensitive']           , 'CaSe [COLOR036]InSeNsItIvE[RESET] DEFAULT'         , []);
$pass += run_test("Case sensitive case"     , ['177,Case']                 , '[COLOR177]Case[RESET] sensitive case'              , []);
$pass += run_test("case sensitive Forced"   , ['55,Forced']                , 'case sensitive [COLOR055]Forced[RESET]'            , ['--case_sensitive']);

# Specific colors
$pass += run_test("Specific color"  , ['red,color']                               , 'Specific [COLOR160]color[RESET]');
$pass += run_test("OMG three colors", ['green,OMG','yellow,three','orange,colors'], '[COLOR034]OMG[RESET] [COLOR226]three[RESET] [COLOR214]colors[RESET]');

# Regexs
$pass += run_test("Match : Regexp"  , ['227,.+?: \w+']  , '[COLOR227]Match : Regexp[RESET]');
$pass += run_test("Only  : Paren"  , ['58,.+?: (\w+)'] , 'Only  : [COLOR058]Paren[RESET]');
$pass += run_test("--Full: Matches", ['82,.+?: (\w+)'] , '[COLOR082]--Full: Matches[RESET]' , ['--full_matches']);

# Test --bold
$pass += run_test("Bolder", ['11,bold'], '[BOLD][COLOR011]Bold[RESET]er', ['--bold']);

my $exit = 0;

print "\n";
if ($pass != $total_tests) {
	print color("orange", "Warning:") . " not all tests pass\n";
	$exit = 9;
}

print "Passed $pass of $total_tests tests\n";

exit($exit);

###############################################################################
###############################################################################

sub run_test {
	my ($text, $filters, $expected, $opts) = @_;

	my $filter_str = '';
	foreach my $f (@$filters) {
		#$f = quotemeta($f);
		$filter_str .= "--filter '$f' ";
	}

	$opts //= [];
	my $opt_str = join(' ', @$opts);

	my $cmd   = "echo '$text' | $HL --force $opt_str $filter_str";
	my $after = `$cmd`;
	$after    = trim($after);

	my $human    = output_human($after);
	my $bleached = bleach_text($human);

	my $status = 0;
	if ($expected eq $bleached) {
		$status = 1;
	}

	my $white = color('white');
	my $red   = color('red');
	my $green = color('green');
	my $reset = color();


	if ($status == 1) {
		my $str = color("");
		print "${white}[${green}PASS${white}]${reset}  Output: $after\n";
	} else {
		print "${white}[${red}FAIL${white}]${reset}  Output: $after\n";
		print "  Expected : $expected\n";
		print "  Got      : $bleached\n";
	}

	if ($debug) {
		print "CMD   : $cmd\n";
	}
	#print "Before: $text\n";
	#print "After : $after\n";

	$total_tests++;

	return $status;
}

sub argv {
	state $ret = {};

	if (!%$ret) {
		for (my $i = 0; $i < scalar(@ARGV); $i++) {
			# If the item starts with "-" it's a key
			if ((my ($key) = $ARGV[$i] =~ /^--?([a-zA-Z_][\w-]*)/) && ($ARGV[$i] !~ /^-\w\w/)) {
				# If the next item does not start with "--" it's the value for this item
				if (defined($ARGV[$i + 1]) && ($ARGV[$i + 1] !~ /^--?\D/)) {
					$ret->{$key} = $ARGV[$i + 1];
					$ARGV[$i]    = $ARGV[$i++] = undef; # Flag key/val to be removed
				} else { # Bareword like --verbose with no options
					$ret->{$key}++;
					$ARGV[$i] = undef; # Flag item to be removed
				}
			}
		}
		@ARGV = grep { defined($_); } @ARGV; # Remove processed items from ARGV
	};

	if (defined($_[0])) { return $ret->{$_[0]}; } # Return requested item

	return $ret;
}

sub trim {
	my ($s) = (@_, $_); # pass in var, or default to $_
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my ($str, $txt) = @_;

	# If we're NOT connected to a an interactive terminal don't do color
	if (-t STDOUT == 0) { return ''; }

	# No string sent in, so we just reset
	if (!length($str) || $str eq 'reset') { return "\e[0m"; }

	# Some predefined colors
	my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

	# Get foreground/background and any commands
	my ($fc,$cmd) = $str =~ /^(\d{1,3})?_?(\w+)?$/g;
	my ($bc)      = $str =~ /on_(\d{1,3})$/g;

	# Some predefined commands
	my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
	my $cmd_num = $cmd_map{$cmd // 0};

	my $ret = '';
	if ($cmd_num)     { $ret .= "\e[${cmd_num}m"; }
	if (defined($fc)) { $ret .= "\e[38;5;${fc}m"; }
	if (defined($bc)) { $ret .= "\e[48;5;${bc}m"; }
	if ($txt)         { $ret .= $txt . "\e[0m";   }

	return $ret;
}

sub file_get_contents {
	open (my $fh, "<", $_[0]) or return undef;

	my $array_mode = ($_[1]) || (!defined($_[1]) && wantarray);

	if ($array_mode) { # Line mode
		return my @lines  = readline($fh);
	} else {     # String mode
		local $/ = undef; # Input rec separator (slurp)
		return my $ret  = readline($fh);
	}
}

sub file_put_contents {
	my ($file, $data) = @_;
	open (my $fh, ">", $file) or return undef;

	print $fh $data;
	return length($data);
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

###############################################

sub output_raw {
	while (<>) {
		s/\e/\\e/g;
		print;
	}
}

sub dump_ansi {
	my $str   = shift();
	if ($str !~ /^\e/) {
		return "";
	}

	my $raw   = $str;
	my $human = $str =~ s/\e/ESC/rg;

	# Remove the ANSI control chars, we just want the payload
	$str =~ s/^\e\[//g;
	$str =~ s/m$//g;

	# Make the [HUMAN] text reset and white to make it easier to see
	my $ret  = "\e[0m";
	$ret    .= "\e[38;5;15m";

	my @parts = split(";",$str);

	#k(\@parts);

	my @basic_mapping = qw(BLACK RED GREEN YELLW BLUE MAGNT CYAN WHITE);

	if (!@parts) {
		$ret .= "[RESET]";
	}

	for (my $count = 0; $count < @parts; $count++) {
		my $p = $parts[$count];

		#print "[$count = '$p']\n";
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
			#$ret .= sprintf("[BASIC%03d]",$color);
		} else {
			$ret .= "[UKN: $p]";
		}
	}

	# Append the ANSI color string to end of the human readable one
	$ret .= $raw;

	return $ret;
}

# Creates methods k() and kd() to print, and print & die respectively
BEGIN {
	if (eval { require Data::Dump::Color }) {
		*k = sub { Data::Dump::Color::dd(@_) };
	} else {
		require Data::Dumper;
		*k = sub { print Data::Dumper::Dumper(\@_) };
	}

	sub kd {
		k(@_);

		printf("Died at %2\$s line #%3\$s\n",caller());
		exit(15);
	}
}

sub bleach_text {
	my $str = shift();

	$str =~ s/\e\[\d*(;\d+)*m//g;

	return $str;
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4

