package StoreFront::Subscription;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
	'blog_id' => 'integer not null',
	'product_id' => 'integer not null',
	'author_id' => 'integer not null',
	'external_id' => 'string(20)',
	'status' => 'integer not null',
	'next_payment_due' => 'datetime',
    },
    indexes => {
	blog_id => 1,
	product_id => 1,
	author_id => 1,
	status => 1,
        blog_status => {
            columns => [ 'blog_id', 'status' ],
        },
    },
    defaults => {
#        foo => 0,
    },
    audit => 1,
    meta => 0,
    datasource => 'subscription',
    primary_key => 'id',
});

sub ACTIVE ()    { 1 }
sub PENDING ()   { 2 }
sub EXPIRED ()   { 3 }
sub CANCELLED () { 4 }
sub FAILURE ()   { 5 }

use Exporter;
*import = \&Exporter::import;
use vars qw( @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw( ACTIVE PENDING EXPIRED CANCELLED FAILURE );
%EXPORT_TAGS = (constants => [ qw(ACTIVE PENDING EXPIRED CANCELLED FAILURE) ]);

1;
__END__
