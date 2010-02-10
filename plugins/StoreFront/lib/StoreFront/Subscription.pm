package StoreFront::Subscription;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'name' => 'string(200) not null',
        'description' => 'text',
        'period' => '',           # DAILY, WEEKLY, MONTHLY, YEARLY
        'duration' => '',         # The number of payments to be made, once per period
        'amount' => 'float',
        'subscriber_count' => '', # Cache the number of suscribers
        'start_date' => '',
    },
    indexes => {
#        foo => 1,
    },
    defaults => {
#        foo => 0,
    },
    audit => 1,
    meta => 0,
    datasource => 'subscription',
    primary_key => 'id',
    class_type => 'subscription',
});

# Periods: DAILY, WEEKLY, SEMI_MONTHLY, MONTHLY, EVERY_TWO_MONTHS, QUARTERLY, and YEARLY
# Display Disposition: specifies when the buyer will be able to access purchased digital content. 
#    The only valid values for this tag are OPTIMISTIC and PESSIMISTIC.

1;
__END__
