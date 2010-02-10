package StoreFront::PayPal::Tags;

use strict;
use Net::PayPal;

sub button {
    my ($ctx, $args, $cond) = @_;

    my $do_encrypt = $args->{encrypt} ? 1 : 0;

    my $plugin  = MT->component('StoreFront');
    my $blog = $ctx->stash('blog');
    my $config  = $plugin->get_config_hash( 'system' );

    my $button;
    $button = 'https://www.paypalobjects.com/WEBSCR-610-20100201-1/en_US/i/btn/btn_xpressCheckout.gif' if ($config->{buynow_button} eq 'Checkout');
    $button = 'https://www.paypalobjects.com/WEBSCR-610-20100201-1/en_US/i/btn/x-click-but23.gif' if ($config->{buynow_button} eq 'Buy Now 1');
    $button = 'https://www.paypalobjects.com/WEBSCR-610-20100201-1/en_US/i/btn/x-click-but3.gif' if ($config->{buynow_button} eq 'Buy Now 2');

    my $c = Net::PayPal::Customer->new({});
    my $b = Net::PayPal::Button->new({
        notify_url => $ctx->_hdlr_admin_cgi_path . MT->config->PayPalScript,
        sandbox_mode => $config->{sandbox_mode} ? 1 : 0,
        success_url => $config->{purchase_success},
        cancel_url => $config->{purchase_cancel},
        contact_email => $config->{paypal_account_id},
        currency_code => $config->{paypal_currency},
        method => 'post',
        locale => 'US',
        display_shipping_address => 0,
#        custom_field => 'account_id:2',
#        comment_header => 0,
#        continue_button_text => 'Continue',
#        background_color => 'white',
#        display_comment => 1,
#        image_url => $config->{purchase_cancel},
        button_image => $button,
#        invoice => 1,
#        tax => 2.99,
        customer => $c
    });
    $b->add_item(
        Net::PayPal::Item->new({
            name => "Widget",
            amount => "9.99",
            quantity => "1",
            item_number => "DBR-111",
            edit_quantity => 1,
            shipping_amount => "2.98",
            shipping_per_item => "0.99",
            handling_amount => "2.00"
        })
    );

    my $key = MT->model('asset')->load( $config->{my_keyfile} );
    my $cert = MT->model('asset')->load( $config->{my_certfile} );
    my $pp_cert = MT->model('asset')->load( $config->{paypal_certfile} );
    if ($do_encrypt) {
        $b->my_keyfile( $key->file_path );
        $b->my_certfile( $cert->file_path );
        $b->paypal_certfile( $pp_cert->file_path );
        $b->encrypt(1);
    }
    return $b->as_html();
}

1;
