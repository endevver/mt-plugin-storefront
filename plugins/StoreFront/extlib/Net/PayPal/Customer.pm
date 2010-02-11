package Net::PayPal::Customer;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);

use base qw(Class::Accessor);
Net::PayPal::Customer->mk_accessors(qw(firstname lastname address1 address2 city state zip email phone1 phone2 phone3));

# We are exporting functions
use base qw/Exporter/;
# Export list - to allow fine tuning of export table
@EXPORT_OK = qw(  );

use strict;

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;    # autoflush

my $MAP = {
    firstname => 'first_name',
    lastname  => 'last_name',
    address1  => 'address1',
    address2  => 'address2',
    city      => 'city',
    state     => 'state',
    zip       => 'zip',
    email     => 'email',
    phone1    => 'night_phone_a',
    phone2    => 'night_phone_b',
    phone3    => 'night_phone_c'
};

sub new {
    my $class  = shift;
    my $params = shift;
    my $self   = {};
    foreach my $prop (qw( firstname lastname address1 address2 city state zip email phone1 phone2 phone3 )) {
        if ( exists $params->{$prop} ) {
            $self->{$prop} = $params->{$prop};
        } else {
            $self->{$prop} = "";
        }
    }
    bless $self, $class;
    return $self;
}

sub as_html {
    my $self = shift;
    my $html;
    foreach my $key (sort keys %$MAP) {
	$html .= '<input type="hidden" name="'.$MAP->{$key}.'" value="'.$self->{$key}.'" />'."\n"; 
    }
    return $html;
}

sub as_params {
    my $self = shift;
    my $txt;
    foreach my $key (sort keys %$MAP) {
	$txt .= $MAP->{$key}.'='.$self->{$key}."\n"; 
    }
    return $txt;
}

1;
__END__
