package StoreFront::Subscriber;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'external_id' => 'string(200) not null',
        'subscription_id' => 'integer not null',
        'author_id' => 'integer not null',
        'status' => 'string(50) not null',
        'start_date' => '',
        'end_date' => '',
    },
    indexes => {
#        foo => 1,
    },
    defaults => {
#        foo => 0,
    },
    audit => 1,
    meta => 0,
    datasource => 'subscriber',
    primary_key => 'id',
    class_type => 'subscriber',
});

# Status: ACTIVE, EXPIRED, CANCELLED

# Periods: DAILY, WEEKLY, SEMI_MONTHLY, MONTHLY, EVERY_TWO_MONTHS, QUARTERLY, and YEARLY

# Display Disposition: specifies when the buyer will be able to access purchased digital content. 
#    The only valid values for this tag are OPTIMISTIC and PESSIMISTIC.

1;
__END__
