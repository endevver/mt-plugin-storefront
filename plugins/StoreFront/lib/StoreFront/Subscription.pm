package StoreFront::Subscription;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
	'blog_id' => 'integer not null',
	'product_id' => 'integer not null',
	'author_id' => 'integer',
	'external_id' => 'string(20)',
	'source' => 'string(20)',
	'status' => 'integer not null',
        'is_test' => 'integer',
	'next_payment_due' => 'datetime',
    },
    indexes => {
	blog_id => 1,
	product_id => 1,
	external_id => {
	    unique => 1
	},
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

sub ACTIVE ()     { 1 }
sub PENDING ()    { 2 }
sub EXPIRED ()    { 3 }
sub CANCELLED ()  { 4 }
sub FAILURE ()    { 5 }
sub IN_PROCESS () { 6 }

use Exporter;
*import = \&Exporter::import;
use vars qw( @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw( ACTIVE PENDING EXPIRED CANCELLED FAILURE IN_PROCESS );
%EXPORT_TAGS = (constants => [ qw(ACTIVE PENDING EXPIRED CANCELLED FAILURE IN_PROCESS) ]);

sub status_string {
    my $self = shift;
    if ($self->status == ACTIVE()) {
	return "Active";
    } elsif ($self->status == PENDING()) {
	return "Pending";
    } elsif ($self->status == EXPIRED()) {
	return "Expired";
    } elsif ($self->status == CANCELLED()) {
	return "Cancelled";
    } elsif ($self->status == FAILURE()) {
	return "Failed";
    } elsif ($self->status == IN_PROCESS()) {
	return "In Process";
    }
}

sub is_active {
    my $self = shift;
    return $self->status == ACTIVE();
}

sub class_label {
    MT->translate("Subscription");
}

sub class_label_plural {
    MT->translate("Subscriptions");
}

1;
__END__
