use Doc;

use warnings;
use strict;
use File::Spec;


print << "INTRO";
+----------------+
| Make Docs v2.0 |
+----------------+

Document Builder for R-packages

INTRO


# COMMAND-LINE
# ************
my @single;
my $assign = {};

foreach (@ARGV) {
  my @splitted = split "=", $_;


  if (scalar(@splitted) == 1) {
    push @single, $_;
  }

  elsif (scalar(@splitted) == 2) {
    $assign->{$splitted[0]} = $splitted[1];
  }

  else {
    die "ERROR: incorrect number of parameters passed through commandline";
  }
}

# SETUP DEFAULTS
# **************
my $dest_file = defined $assign->{dest} ? $assign->{dest} : "doc.tex";
my $conf_file = defined $assign->{conf} ? $assign->{conf} : "order.conf";
my $dir = defined $assign->{outdir} ? $assign->{outdir} : "texs";

# output setup information
print << "INFO";
Summary
*******
 Destination File .... $dest_file
 Configuration File .. $conf_file
 Directory ........... $dir

INFO

print "Are these correct? Y/N";
my $choice = <>;

exit 0 if $choice eq "N" || $choice eq "n";



# FILE HANDLES
# ************

open DOC, ">$dest_file" or die("could not open `$dest_file' for writing");
open CONF, "<$conf_file" or die("could not open `$conf_file' for reading");

# BEGIN MAKING BOOK
# *****************


my $d = new Doc(file => "gamma");
my $tmp_dir = "";
my $book = new Book(
  title => "Zelig",
  author => "Matt Owen, Kosuke Imai, Olivia Lau, and Gary King"
);

my $part = new Part("No one Ever Really Dies");
my $chapter = new Chapter();
my $doc = undef;


$tmp_dir = $book->get_temp_dir();

for my $line (<CONF>) {
  chomp $line;


  # if it is a part
  if ($line =~ m/$DocRegexes::part/) {
    $book->add_parts($part);
    $part = new Part($1);
  }

  elsif ($line =~ m/$DocRegexes::link/) {
    print " * Linking:  '$1' to '$tmp_dir/$1'\n";
    symlink File::Spec->rel2abs($1), "$tmp_dir/$1";
  }

  # chapter with title explicitly set
  elsif ($line =~ m/DocRegexes::chapter/) {
    $chapter = new Chapter($1, $2);
    $part->add_chapters($1 => $chapter);
  }

  # chapter without title explicityly set
  elsif ($line =~ m/^\w+$/) {
    $doc = new Doc(file => $line);
    $chapter = new Chapter($line, $doc->get_title());
    $part->add_chapters($line => $chapter);
  }

  elsif ($line =~ m/$DocRegexes::appendix/) {
  }
}

# add last part
$book->add_parts($part);

# setup build environment
$book->setup_env();
$book->write_book(to_file => 1);


close DOC;
close CONF;
