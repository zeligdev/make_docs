use Doc;

use warnings;
use strict;


my $doc = new Doc(file => "gamma", link => 1);
print $doc->get_packages();
