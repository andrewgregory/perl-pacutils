package PacUtils::Config v0.0.1;

use strict;
use warnings;

use PacUtils;

sub get {
    my ($self, $field) = @_;
    return $self->{ lc $field };
}

1;
