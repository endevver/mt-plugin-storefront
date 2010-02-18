package Net::PayPal::Subscription;

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
    item_number => 'item_number',
    trial_price => 'a1',
    trial_duration => 'p1',
    trial_duration_units => 't1',
    price => 'a3',
    duration => 'p3',
    duration_units => 't3',
    recurring_payments => 'src',
    recurrence_count => 'srt',
    retry_on_error => 'sra',
    modify_rules => 'modify'
};

sub new {
    my $class  = shift;
    my $params = shift;
    my $self   = {};
    foreach my $prop (qw( name trial_price trial_duration trial_duration_units
                          price duration duration_units recurring_payments item_number
                          recurrence_count retry_on_error modify_rules )) {
        if ( exists $params->{$prop} ) {
            $self->{$prop} = $params->{$prop};
        }
    }
    bless $self, $class;
    return $self;
}

sub as_html {
    my $self = shift;
    my $html;
    foreach my $key (sort keys %$MAP) {
        $html .= '<input type="hidden" name="'.$MAP->{$key}.'" value="'.$self->{$key}.'" />'."\n" if $self->{$key}; 
    }
    return $html;
}

sub as_params {
   my $self = shift;
   my $txt;
   foreach my $key (sort keys %$MAP) {
       $txt .= $MAP->{$key}.'='.$self->{$key}."\n" if $self->{key};
   }
   return $txt;
}

1;
__END__
