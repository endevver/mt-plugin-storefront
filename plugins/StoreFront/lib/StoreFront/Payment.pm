package StoreFront::Payment;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer not null',
        'product_id' => 'integer not null',
	'payer_email' => 'string(255)',
        'is_test' => 'integer',
        'is_pending' => 'integer',
        'quantity' => 'integer',
	'external_transaction_id' => 'string(100)',
	'external_payer_id' => 'string(100)',

	'company_name' => 'string(100)',
	'contact_first_name' => 'string(50)',
	'contact_last_name' => 'string(50)',
	'address_street' => 'string(100)',
	'address_city' => 'string(50)',
	'address_state' => 'string(30)',
	'address_zip' => 'string(20)',
	'address_country' => 'string(20)',
	'address_country_code' => 'string(3)',
	'contact_phone' => 'string(30)',
	'shipping_method' => 'string(20)',

	'exchange_rate' => 'float',
	'invoice' => 'string(50)',
	'currency' => 'string(3)',
	'fee_amount' => 'float',
	'gross_amount' => 'float',
	'handling_amount' => 'float',
	'shipping_amount' => 'float',
	'tax' => 'float',
	'payment_status' => 'string(20)',
	'payment_type' => 'string(20)',
        'payment_date' => 'datetime',
        'next_payment_date' => 'datetime',
    },
    indexes => {
#        foo => 1,
    },
    defaults => {
#        foo => 0,
    },
    audit => 1,
    meta => 0,
    datasource => 'payment',
    primary_key => 'id',
#    class_type => 'payment',
});

1;
__END__
