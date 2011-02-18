package Doc;
use strict;
use warnings;

sub new {

  my $self = {};

  $self = {
    # technical stuff
    _FILE => unshift,
    _iter => undef,
    _title => "",
    _nchar => 0,
    _levels => 0,

    # external includes
    _includes => {},
    _packages => {},
    _styles => {},

    # bibliography stuff
    _citations => {},
    _bibstyle => {},
    _bibliographies => {},

    # highest level tag
    _largest => {},

    # lowest level tag
    _smallest => {}

  }

}
