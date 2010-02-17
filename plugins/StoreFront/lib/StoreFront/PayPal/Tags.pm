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

sub _map_units {
    my ($u) = @_;
    if (lc($u) eq 'days') {
        return 'D';
    } elsif (lc($u) eq 'years') {
        return 'Y';
    } elsif (lc($u) eq 'months') {
        return 'M';
    } elsif (lc($u) eq 'weeks') {
        return 'W';
    }
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
    my $options = {
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
        button_image => $button,
        customer => $c,
        display_shipping_address => 0,
#        background_color => 'white',
#        custom_field => 'account_id:2',
#        comment_header => 0,
#        continue_button_text => 'Continue',
#        display_comment => 1,
#        image_url => $config->{purchase_cancel},
#        invoice => 1,
    };
    $options->{display_shipping_address} = 1 if ($asset->requires_shipping);

    my $b = Net::PayPal::Button->new( $options );
    my $item_class;
    my $price = $asset->sale_price ? $asset->sale_price : $asset->list_price;
    if ($asset->payment_type == 1) { # One Time
        $item_class = 'Net::PayPal::Item';
        $options = {
            name              => $asset->label,
            amount            => $price,
            quantity          => 1,
            item_number       => $asset->id,
            edit_quantity     => 0
        };
        $options->{edit_quantity} = 1 if $asset->limit_per_order;
        $options->{tax_rate} = $asset->tax_rate if $asset->tax_rate > 0;
    } else {
        $item_class = 'Net::PayPal::Subscription';
        $options = {
            name               => $asset->label,
            price              => $price,
            item_number        => $asset->id,
            duration           => $asset->duration,
            duration_units     => _map_units($asset->duration_units),
            retry_on_error     => 1, #$asset->retry_on_error,
            modify_rules       => 2
        };
        if ($asset->recur) {
            $options->{recurring_payments} = 1;
            $options->{recurrence_count} = $asset->recurrence_count;
        } else {
            $options->{recurring_payments} = 1;
            $options->{recurrence_count} = 0;
        }
        if ($asset->offer_trial) {
            $options->{trial_price}          = $asset->trial_price;
            $options->{trial_duration}       = $asset->trial_duration;
            $options->{trial_duration_units} = _map_units($asset->trial_duration_units);
        }
    }
    if ($asset->requires_shipping) {
        $options->{shipping_amount} = $asset->shipping_cost;
        $options->{weight} = $asset->weight;
        $options->{weight_unit} = $asset->weight_unit;
#        $options->{shipping_per_item} = "0.00";
#        $options->{handling_amount} = "0.00";
    }
    my $item = $item_class->new( $options );
    $b->add_item( $item );

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
