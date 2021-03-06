#!/usr/bin/perl -CAS
use strict;
use warnings;

use File::Spec;
use File::Basename;
use lib File::Spec->catfile(dirname(__FILE__), '../../lib');
use lib File::Spec->catfile(dirname(__FILE__), '../../src');
use LearnDB qw/read_entry num_entries replace_entry/;
use Helper;
use utf8;
use open qw/:std :utf8/;

Helper::forbid_private();

my ($term, $num, $rest);

for ($ARGV[1]) {
  /^([^\[\]]+?)\[([+-]?\d+)\]?\s+(s[^a-z].+)/i || /^([^\[\]]+?)\s+(s[^a-z].+)/i
    or do {
      print "Syntax is: !learn edit TERM[NUM] s/<search>/<repl>/\n";
      exit 1;
    };
  ($term, $num, $rest) = ($1, $2, $3);
}

$rest = $num, undef($num) if defined($num) && !defined($rest);

s/^\s+//, s/\s+$// for ($term, $rest);

if (!$num && num_entries($term) > 1) {
  print "Use: !learn edit ${term}[NUM] s/<search>/<repl>/\n";
  exit 1;
}
$num ||= 1;

my $text = read_entry($term, $num, 1);

if (!defined($text))
{
  print "I don't have a page labeled $term\[$num] in my learndb.";
  exit;
}

my ($sep) = $rest =~ /^s(.)/;
my $qsep = "\Q$sep";

my ($regex, $replacement, $opts) =
  $rest =~ m{^s$qsep((?:\\.|[^$qsep\\])*)$qsep((?:\\.|[^$qsep\\])*)(?:$qsep([Ig]*) *)?$} or do
{
  print "Syntax is: !learn edit TERM[NUM] s/REGEX/REPLACE/opts";
  exit;
};
$replacement =~ s/\\(.)/$1/g;
$opts ||= '';

$regex = "^" if $regex eq "";
my $case_insensitive = 1;
my $global = 0;

if (index($opts, "I") >= 0)
{
  $case_insensitive = 0;
}
if (index($opts, "g") >= 0)
{
  $global = 1;
}

use re::engine::RE2 -strict => 1;

my $regex_text = $regex;
$regex = Helper::eval_or_exit {
  $case_insensitive ? qr/$regex/i : qr/$regex/
};

my $oldtext = $text;
my $matched = 0;

if ($global)
{
  $matched = $text =~ s/$regex/$replacement/g;
}
else
{
  $matched = $text =~ s/$regex/$replacement/;
}

if (not $matched)
{
  print "No change: regex `$regex_text` does not match `$text`";
  exit;
}

if ($text eq $oldtext)
{
  print "No change!";
  exit;
}

Helper::eval_or_exit {
  LearnDB::check_text_length($text, 'New text')
};

replace_entry($term, $num, $text);
print read_entry($term, $num);
