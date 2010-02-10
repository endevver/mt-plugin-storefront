package StoreFront::Payment;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'subscription_id' => 'integer not null',
        'payment_date' => '',
        'gross' => '',
        'fee' => '',
        'status' => '',
        'currency' => '',
        'description' => '',
    },
    indexes => {
#        foo => 1,
    },
    defaults => {
#        foo => 0,
    },
    audit => 0,
    meta => 0,
    datasource => 'payment',
    primary_key => 'id',
    class_type => 'payment',
});

1;
__END__
