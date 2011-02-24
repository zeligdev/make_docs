package Doc;

use File::Temp qw/ tempdir tempfile /;
use List::MoreUtils qw/ uniq /;


=head1 NAME

LaTeX::Doc

=head1 SYNOPSIS

  use LaTeX::Doc;
  doc = new LaTeX::Doc FILE;


=head1 METHODS

=over 2

=item new Doc(file => "file_name")

  param: file a character string specifying a file name
  return: a LaTeX::Doc object

=cut

sub new {
  my ($class, %hash) = @_;

  my $file_name = $hash{file};
  my $hard_link = $hash{link};

  # add error-checking here
  # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 

  $file = "$file.tex" unless $file =~ m/\.tex$/;
  # define
  my $self = {
    _file => "$file_name.tex",
    _link => $hard_link
  };

  bless $self, $class;
}


=item DESTROY

  deconstructor

=cut

sub DESTROY {
}



=item get_packages()

  return: list of packages used in document

=cut
sub get_packages {
  my ($self, %params) = @_;

  my $file = $self->{_file};

  open FI, "$file";


  my $old_slash = $/;
  $/ = \0;

  my @packages = <FI> =~ m/[^%](\\usepackage(?:\[.*?\])?{.*?}(?:\[.*?\])?)/gs;

  close FI;

  $/ = $old_slash;

  my @results = map { /\\usepackage(\[.*?\])?{(.*?)}/; "$2" } @packages;

  @results;
}



=item get_body()

  gets all text between \begin{document} ... \end{document}, or
  returns entire document as a string
  return: the body text of the document

=cut
sub get_body {
  my ($self, %params) = @_;

  my $slash = \0;
  ($/, $slash) = ($slash, $/);

  open FI, "<$self->{_file}";

  if (<FI> =~ m/\\begin{document}(.*?)\\end{document}/s) {
    close FI;
    $/ = $slash;
    return $1;
  }
  
  $/ = $slash;
  close FI;
  return <FI>;
}


=item get_bibliographies()

  return: a list of bibliography files required by the package

=cut
sub get_bibliographies {
  
  my ($self, %params) = @_;

  my $slash = $/;

  ($/, $slash) = (\0, $/);

  open FI, "<$self->{_file}";


  my @bibs;
 
  @bibs = <FI> =~ m/\\bibliography{(.*?)}/gs;
  @bibs = map { split /\s*,\s*/, $_ } @bibs;
   
  close FI;

  $/ = $slash;
  uniq @bibs;
}



=item get_file_location()

  return: location of file

=cut
sub get_file_location {
  my $self = shift;

  $self->{file}
}


=item get_title()

  get title of TeX document
  param: ..1 a blob of text
  return: content of the title tags in the block of text

=cut
sub get_title {
  my $self = shift;
  open FI, "<$self->{_file}" or die("could not open Doc file");

  my $slash = $/;
  $/ = \0;
  my @titles = <FI> =~ m/\\title\{(.*?)}/g;

  $/ = $slash;
  close FI;

  my $result = pop @titles;

  defined $result ? $result : "";
}






package DocTools;

# @_: list of arguments as an array
# result - a list with unique entries
sub uniq {
  my $hits = {};
  grep { ! $hits->{$_}++ } @_;
}

# compares two dates, used for sorting lists of strings
# param: $a a string formatted like dd/dd/dddd
# param: $b ta string formatted like dd/dd/ddd
# return: -1, 0, 1 - less than, equal, greater than
sub date_cmp {
  # convert left hand side into a triplet of numbers
  $a =~ /(\d?\d)\/(\d?\d)\/(\d{4})/;
  my ($lmon, $lday, $lyear) = ($1, $2, $3);

  # convert right hand side into ... """
  $b =~ /(\d?\d)\/(\d?\d)\/(\d{4})/;
  my ($rmon, $rday, $ryear) = ($1, $2, $3);

  # compare
  return $lyear <=> $ryear unless $lyear == $ryear;
  return $lmon <=> $rmon unless $lmon == $rmon;
  $lday <=> $rday;
}


# reduces a list of packages to unique entries
# params: @_ a list of package preamble commands
# return: a reduced list - containing only the earliest dated
#         of each package
# future: allow to set an option that can choose between
#         earliest and oldest package
sub reduce_packages {
  my @packages;
  my @package_names = uniq map { m/\\usepackage{(.*?)}/ } @_;

  for (@package_names) {
    # generate regex
    my $regex = qr{\\usepackage{$_}\[(.*?)\]};

    # sort list of dates and get earliest
    my @dates = sort { &date_cmp } map { m/$regex/ } @_;

    my $date = shift @dates;

    # construct earliest dated package
    my $pack = q/\usepackage/;
    $pack .= "{$_}";
    $pack .= "[$date]" if defined $date;

    push @packages, $pack;
  }

  @packages;
}



#
#
package Book;

use File::Temp qw/ tempfile tempdir /;
sub new {

  my ($self, %params) = @_;


  my $title = $params{title};
  my $tmp_dir = tempdir("make_docs_XXXX");
  my ($handle, $tmp_file) = tempfile("Zelig_XXXX", DIR => $tmp_dir);

  my $obj = {
             _FILE => $handle,
             _title => $params{title},
             _authors => $params{authors},
             _parts => [],
             _part_order => {},

             # temporary environment stuff
             #   this manages where hard links, etc.
             #   are located during the build process
             _temp_dir => $tmp_dir,
             _temp_file => $tmp_file,
             _temp_handle => $handle,

             # dependency management stuff
             _packages => [],
             _commands => [],
             _styles => [],
             _bibs => []
  };

  bless $obj, $self;
}



sub add_parts {

  my ($self, @parts) = @_;
  my @packages, @styles, @bibs, @commands;

  for (@parts) {
    push @{$self->{_parts}}, $_;
  }

}


=item write_book(to_file => T/F)

  param: to_file boolean. determines whether the book is
         printed into a temporary environment, rather than
         standard output
  return: none

=cut
sub write_book {
  my $self = shift;
  my $handle;

  #print "TITLE=$self->{_temp_file}\n";
  open $handle, ">$self->{_temp_file}";

  print $handle "\\documentclass{book}\n\n";

  @packages = $self->get_packages();

  print $handle "% packages\n";
  print $handle join "\n", map { "\\usepackage{$_}" } @packages;
  print $handle "\n\n";
  print $handle "\\begin{document}\n\n";

  for (@{$self->{_parts}}) {
    # print "FILE: ", $_->{_title}, "\n";
    # print "PACKAGES: ";
    # print join " ", $_->get_packages();
    # print "\n";
    $_->write($handle)
  }

  print $handle q/\end{document}/;

  close $handle;
}


=item setup_env()

  creates a temporary directory to build the book

=cut
sub setup_env {
  my $self = shift;

  my $tmp_dir = $self->{_temp_dir};
  my $tmp_file = $self->{_temp_file};

  my @packages = ();

  print << "TEMP";
Building Temporary Environment
 Directory ....... $tmp_dir
 TeX Document .... $tmp_file

Linking Files
TEMP
  for my $part (@{ $self->{_parts} }) {

  
    for my $file (keys %{ $part->{_chapters} }) {

      my $doc = new Doc (file => $file);
      push @packages, @{[ $doc->get_packages() ]};

      $file = "$file.tex" unless m/\.tex$/;
      $newfile = "$self->{_temp_dir}/$file";

 
      print " $file to $newfile\n";

      open FI, ">$newfile";
      print FI $doc->get_body();
      close FI;
    }

  }

  print "\n\n\n\n";
}

sub remove_env {

}


=item get_packages()

  return: a list of all the packages from all the articles
          composing the book

=cut
sub get_packages {

  my $self = shift;
  my @packages = ();

  for (@{$self->{_parts}}) {
    push @packages, $_->get_packages();
  }

  return @packages;
}


# end
sub get_temp_dir {
  shift()->{_temp_dir};
}


package Part;


sub new {
  my ($class, $title) = @_;

  my $self = {
              _chapters => {},
              _order => [],
              _title => $title
  };

  bless $self, $class;
}

# title
sub set_title {
  my ($self, $title) = @_;

  $self->{_title} = $title;
}


# key-value pair style submission
sub add_chapters {
  my ($self, %params) = @_;

  map {

    # add file to list
    $self->{_chapters}->{$_} = $params{$_};

    # maintain order
    push @{$self->{_order}}, $_;

  } keys %params;

}


# write part as a TeX file
#
#
sub write {
  my ($self, $handle) = @_;
  my $title = $self->{_title};

  if (defined $title) {
    print $handle q/\part{/, $title, "}\n";
    print $handle q/\label{part:/, $title, "}\n\n";
  }

  for (values %{$self->{_chapters}}) {
    $_->print_as_include($handle);
    print $handle "\n";
  }
}

=item get_packages()

  return: listed packages

=cut
sub get_packages {

  my $self = shift;
  my @packages = ();

  for (keys %{$self->{_chapters}}) {

    my $doc = new Doc(file => $_);
    push @packages, $doc->get_packages();
  }

  @packages;
}
package Chapter;

sub new {
 my ($class, $file_name, $chapter_name, $short_name) = @_;

 my $self = {
   _file_name => $file_name,
   _chapter_name => defined $chapter_name ? $chapter_name : undef,
   _short_name => defined $short_name ? $short_name : undef
 };

 bless $self, $class;
}


sub print_as_include {
  my ($self, $handle) = @_;

  #
  my $chapter_name = $self->{_chapter_name};
  my $label = $self->{_short_name};
  
  # ...
  $chapter_name = $self->{file_name} if not defined $chapter_name;
  $label = $self->{_file_name} if not defined $label;
  
  #
  print $handle q/\chapter/;
  print $handle "[$self->{_short_name}]" if defined $self->{_short_name};
  print $handle "{$chapter_name}\n";
  print $handle "\\label{chapter:$label}\n";
  print $handle q/\include{/, $self->{_file_name}, "}\n";
}

sub hard_link {



}

sub print_inline {
}


# CONF TOOLS
package DocRegexes;

use strict;
use warnings;


# {part name}
our $part = qr/^\{(.*?)\}$/;

# ***
our $appendix = qr/^\*\*\*$/;

# *file name
our $chapter_wo_file = qr/^\*\s*(.*)$/;

# :chapter name
our $title = qr/^:(.*)$/;

# file: chapter name
our $chapter = qr/(.*?):(.*)/;

# hard links
our $link = qr/\[(.*?)\]/;


1;
