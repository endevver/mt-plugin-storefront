package Net::PayPal::Item;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);

#use base qw(Class::Accessor);
#Net::PayPal::Item->mk_accessors(qw(apikey url cache));

# We are exporting functions
use base qw/Exporter/;
# Export list - to allow fine tuning of export table
@EXPORT_OK = qw(  );

use strict;

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;    # autoflush

my $MAP = {
    name => 'item_name',
    amount => 'amount',
    quantity => 'quantity',
    item_number => 'item_number',
    edit_quantity => 'undefined_quantity',
    shipping_amount => 'shipping',
    shipping_per_item => 'shipping2',
    handling_amount => 'handling',
    tax_rate => 'tax_rate',
    weight => 'weight',
    weight_unit => 'weight_unit'
};

sub new {
    my $class  = shift;
    my $params = shift;
    my $self   = {};
    foreach my $prop (qw( name amount quantity item_number edit_quantity 
                          shipping_amount shipping_per_item handling_amount 
                          tax_rate weight weight_unit )) {
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
    my $html;
    foreach my $key (sort keys %$MAP) {
        $html .= '<input type="hidden" name="'.$MAP->{$key}.$idx.'" value="'.$self->{$key}.'" />'."\n" if $self->{$key}; 
    }
    my @options = @{$self->options};
    my $i = 0;
    foreach my $o (@options) {
        $html .= '<input type="hidden" name="on'.$i.$idx.'" value="'.$o->{label}.'" />'."\n";
        $html .= '<input type="hidden" name="os'.$i.$idx.'" value="'.$o->{value}.'" />'."\n";
        $i++;
    }
    return $html;
}

sub as_params {
   my $self = shift;
   my ($idx) = @_;
   $idx ||= '';
   $idx = '_' . $idx unless $idx eq '';
   my $txt;
   foreach my $key (sort keys %$MAP) {
       $txt .= $MAP->{$key}.$idx.'='.$self->{$key}."\n" if $self->{key};
   }
   my @options = @{$self->options};
   my $i = 0;
   foreach my $o (@options) {
       $txt .= 'on'.$i.$idx.'='.$o->{label}."\n";
       $txt .= 'os'.$i.$idx.'='.$o->{value}."\n";
       $i++;
   }
   return $txt;
}

1;
__END__
