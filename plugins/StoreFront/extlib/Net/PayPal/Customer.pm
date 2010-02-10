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
    my ($idx) = @_;
    $idx .= '_' . $idx if $idx;
    my $html = <<ENDHTML;
<!-- Customer Information --> 
<input type="hidden" name="first_name"    value="$self->{'firstname'}" /> 
<input type="hidden" name="last_name"     value="$self->{'lastname'}" /> 
<input type="hidden" name="address1"      value="$self->{'address1'}" /> 
<input type="hidden" name="address2"      value="$self->{'address2'}" /> 
<input type="hidden" name="city"          value="$self->{'city'}" /> 
<input type="hidden" name="state"         value="$self->{'state'}" /> 
<input type="hidden" name="zip"           value="$self->{'zip'}" /> 
<input type="hidden" name="email"         value="$self->{'email'}" /> 
<input type="hidden" name="night_phone_a" value="$self->{'phone1'}" /> 
<input type="hidden" name="night_phone_b" value="$self->{'phone2'}" /> 
<input type="hidden" name="night_phone_c" value="$self->{'phone3'}" />
ENDHTML
    return $html;
}

1;
__END__
