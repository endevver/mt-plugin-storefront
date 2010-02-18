package StoreFront::Payment;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer not null',
        'product_id' => 'integer not null',
        'subscription_id' => 'integer',
	'source' => 'string(20)',
	'payer_email' => 'string(255)',
        'is_test' => 'integer',
        'is_pending' => 'integer',
        'is_refunded' => 'integer',
        'quantity' => 'integer',
	'external_transaction_id' => 'string(36)',
	'external_payer_id' => 'string(20)',

	'company_name' => 'string(127)',
	'contact_first_name' => 'string(64)',
	'contact_last_name' => 'string(64)',
	'address_name' => 'string(128)',
	'address_street' => 'string(200)',
	'address_city' => 'string(40)',
	'address_state' => 'string(40)',
	'address_zip' => 'string(20)',
	'address_country' => 'string(64)',
	'address_country_code' => 'string(2)',
	'contact_phone' => 'string(20)',
	'shipping_method' => 'string(20)',

	'exchange_rate' => 'float',
	'invoice' => 'string(127)',
	'currency' => 'string(3)',
	'fee_amount' => 'float',
	'gross_amount' => 'float',
	'shipping_amount' => 'float',
	'tax' => 'float',
	'payment_status' => 'string(20)',
	'payment_type' => 'string(20)',
        'payment_date' => 'datetime',
        'next_payment_date' => 'datetime',
    },
    indexes => {
        subscription_id => 1,
	product_id => 1,
	blog_id => 1,
	external_payer_id => 1,
	payment_status => 1,
        blog_payment_status => {
            columns => [ 'blog_id', 'payment_status' ],
        },
    },
    defaults => {
#        foo => 0,
    },
    audit => 1,
    meta => 0,
    datasource => 'payment',
    primary_key => 'id',
});

sub class_label {
    MT->translate("Payment");
}

sub class_label_plural {
    MT->translate("Payments");
}

1;
__END__
