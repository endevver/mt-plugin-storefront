package StoreFront::PayPal::Tags;

use strict;
use Net::PayPal;

sub _no_product_error {
    my $ctx = shift;
    my $tag_name = $ctx->stash('tag');
    $tag_name = 'mt' . $tag_name unless $tag_name =~ m/^MT/i;
    return $_[0]->error(MT->translate(
        "You used an '[_1]' tag outside of the context of a product asset; " .
        "perhaps you mistakenly placed it outside of an 'MTAssets type=\"product\"' container?", $tag_name
				      ));
}

sub button {
    my ($ctx, $args, $cond) = @_;

    my $asset = $ctx->stash('asset');
    if ($asset && $asset->class_type ne 'product') {
        return $ctx->_no_product_error();
    }

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
        openssl => $config->{openssl},
        cert_id => $config->{my_cert_id},
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
    my $price = $asset->sale_price ? $asset->sale_price : $asset->list_price;
    $b->add_item(
        Net::PayPal::Item->new({
            name              => $asset->label,
            amount            => $price,
            quantity          => "1",
            item_number       => $asset->sku_id,
            edit_quantity     => 1,
            shipping_amount   => "0.00",
            shipping_per_item => "0.00",
            handling_amount   => "0.00"
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
