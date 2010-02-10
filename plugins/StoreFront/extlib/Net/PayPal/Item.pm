package Net::PayPal::Item;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);

use base qw(Class::Accessor);
Net::PayPal::Item->mk_accessors(qw(apikey url cache));

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
    foreach my $prop (qw( name amount quantity item_number edit_quantity 
                          shipping_amount shipping_per_item handling_amount )) {
        if ( exists $params->{$prop} ) {
            $self->{$prop} = $params->{$prop};
        }
    }
    $self->{'options'} = [];
    bless $self, $class;
    return $self;
}

sub add_option {
    my $self = shift;
    my ($label, $value) = @_;
    push @{$self->{'options'}}, {
        label => $label,
        value => $value
    };
}

sub options {
    my $self = shift;
    return $self->{'options'};
}

sub as_html {
    my $self = shift;
    my ($idx) = @_;
    $idx ||= '';
    $idx = '_' . $idx unless $idx eq '';
    my $html = <<ENDHTML;
<input type="hidden" name="item_name$idx" value="$self->{'name'}" />
<input type="hidden" name="amount$idx" value="$self->{'amount'}" />
<input type="hidden" name="quantity$idx" value="$self->{'quantity'}" /> 
<input type="hidden" name="item_number$idx" value="$self->{'item_number'}" />
<input type="hidden" name="undefined_quantity$idx" value="$self->{'edit_quantity'}" />
<input type="hidden" name="shipping$idx" value="$self->{'shipping_amount'}">
<input type="hidden" name="shipping2$idx" value="$self->{'shipping_per_item'}">
<input type="hidden" name="handling$idx" value="$self->{'handling_amount'}">
ENDHTML
    my @options = @{$self->options};
    my $i = 0;
    foreach my $o (@options) {
        $html .= '<input type="hidden" name="on'.$i.$idx.'" value="'.$o->{label}.'" />'."\n";
        $html .= '<input type="hidden" name="os'.$i.$idx.'" value="'.$o->{value}.'" />'."\n";
        $i++;
    }
    return $html;
}

1;
__END__
