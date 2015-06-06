package PacUtils;

use strict;
use warnings;

use XSLoader;
use Exporter qw( import );

our $VERSION = 'v0.0.1';
our %EXPORT_TAGS = ( all => [] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

XSLoader::load('PacUtils', $VERSION);

1;
