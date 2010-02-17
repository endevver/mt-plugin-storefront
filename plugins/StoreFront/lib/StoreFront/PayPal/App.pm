package StoreFront::PayPal::App;

use strict;

use MT;
use MT::Util qw( encode_url trim );
#use MT::I18N qw( length_text substr_text );
use LWP::UserAgent;
use base qw( MT::App );

use MT::Log::Log4perl qw( l4mtdump );
use Log::Log4perl qw( :resurrect );
our $logger ||= MT::Log::Log4perl->new();

sub init {
    my $app = shift;
    $logger ||= MT::Log::Log4perl->new(); 
#    $logger->trace();
    $logger->debug('Initializing app...');
    $app->SUPER::init(@_) or return $app->error("Initialization failed");
    $app->request_content
      if $app->request_method eq 'POST' || $app->request_method eq 'PUT';
    $app->add_methods( handle => \&handle, );
    $app->{default_mode}  = 'handle';
    $app->{is_admin}      = 0;
    $app->{warning_trace} = 0;

    my $ua = LWP::UserAgent->new;
    $ua->agent("StoreFront Plugin for Movable Type");
    $app->{ua} = $ua;

    $app;
}

sub validate {
    my $app = shift;

    #$logger->debug("Validating IPN from PayPal");

    my $plugin  = MT->component('StoreFront');
    my $config  = $plugin->get_config_hash( 'system' );

    my $url;
    if ($config->{sandbox_mode}) {
	$url = 'https://www.sandbox.paypal.com/cgi-bin/webscr';
    } else {
	$url = 'https://www.paypal.com/cgi-bin/webscr';
    }

    #$logger->debug("Posting to: $url");

    my $content = 'cmd=_notify-validate';
    my %params = $app->param_hash;
    foreach my $p (keys %params) {
	$content .= '&' . $p . '=' . encode_url( $params{$p} );
    }

    my $req = HTTP::Request->new( POST => $url );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($content);

    #$logger->debug("Posting the following content: $content");

    my $res = $app->{ua}->request($req);    
    if ($res->is_success) {
	if (trim($res->content) eq 'VERIFIED') {
	    # all is well
	    $logger->debug("IPN successfully verified");
	    return 1;
	}  else {
	    $logger->debug( "Response from PayPal INVALID" );
	}
    } else {
	$logger->debug( "PayPal returned an error: " . $res->status_line );
    }
    return 0;
}

sub handle {
    my $app = shift;
    $logger->debug('Entering "handle"...');

    unless (validate( $app )) {
	MT->log({
	    message => "There was an error processing the IPN from PayPal. IPN invalid."
	});
	return $app->error("ERROR: IPN invalid");
    }
    my $meth = $app->param('txn_type');
    $logger->debug("Dispatching IPN to $meth()");
    do { no strict 'refs'; $meth->( $app ); };

    my $out = 'Foo';
    return $out;
}

# A dispute has been resolved and closed
sub adjustment {
    my $app = shift;
    $logger->debug('Processing adjustment');
}

# Payment received for multiple items; source is Express Checkout or the PayPal
# Shopping Cart.
sub cart {
    my $app = shift;
    $logger->debug('Processing cart');
}

# Payment received for a single item; source is Express Checkout
sub express_checkout {
    my $app = shift;
    $logger->debug('Processing express_checkout');

}

# Payment sent using MassPay
sub masspay {
    my $app = shift;
    $logger->debug('Processing masspay');
}

# Monthly subscription paid for Website Payments Pro
sub merch_pmt {
    my $app = shift;
    $logger->debug('Processing merchant payment');
}

# A new dispute was filed
sub new_case {
    my $app = shift;
    $logger->debug('Processing new dispute');
}

# Recurring payment received
sub recurring_payment {
    my $app = shift;
    $logger->debug('Processing recurring payment');
}

# Recurring payment profile created
sub recurring_payment_profile_created {
    my $app = shift;
    $logger->debug('Processing recurring payment (with profile)');
}

# Payment received; source is the Send Money tab on the PayPal website
sub send_money {
    my $app = shift;
    $logger->debug('Processing a "send money" request');
}

# Subscription canceled
sub subscr_cancel {
    my $app = shift;
    $logger->debug('Processing subscription cancellation');
}

# Subscription expired
sub subscr_eot {
    my $app = shift;
    $logger->debug('Processing subscription expired');
}

# Subscription signup failed
sub subscr_failed {
    my $app = shift;
    $logger->debug('Processing subscription failure');
}

# Subscription modified
sub subscr_modify {
    my $app = shift;
    $logger->debug('Processing subscription modification');
}

# Subscription payment received
sub subscr_payment {
    my $app = shift;
    $logger->debug('Processing subscription payment');
}

# Subscription started
sub subscr_signup {
    my $app = shift;
    $logger->debug('Processing signup');
}

# Payment received; source is Virtual Terminal
sub virtual_terminal {
    my $app = shift;
    $logger->debug('Processing payment from virtual terminal');
}

# Payment received; source is a Buy Now, Donation, or Auction Smart Logos button
sub web_accept {
    my $app = shift;
    $logger->debug('Processing buy now button or donation');
    
    my $pid = $app->param('item_number');
    my $product = MT->model('asset.product')->load($pid);
    unless ($product) {
	MT->log({ message => "Could not find product with ID: $pid" });
	return $app->error("Error processing payment");
    }

    my $payment = MT->model('payment')->new;
    $payment->blog_id( $product->blog_id );
    $payment->product_id( $app->param('item_number') );
    $payment->payer_email( $app->param('payer_email') );
    $payment->is_test( $app->param('test_ipn') ? 1 : 0 );
    $payment->is_pending( $app->param('payment_status') eq 'Pending' );
    $payment->quantity( $app->param('quantity') );
    $payment->external_transaction_id( $app->param('txn_id') );
    $payment->external_payer_id( $app->param('payer_id') );
    $payment->company_name( $app->param('business') );
    $payment->contact_first_name( $app->param('first_name') );
    $payment->contact_last_name( $app->param('last_name') );
    $payment->address_street( $app->param('address_street') );
    $payment->address_city( $app->param('address_city') );
    $payment->address_state( $app->param('address_state') );
    $payment->address_zip( $app->param('address_zip') );
    $payment->address_country( $app->param('address_country') );
    $payment->address_country_code( $app->param('address_country_code') );
    $payment->contact_phone( $app->param('contact_phone') );
    $payment->shipping_method( $app->param('shipping_method') );
    $payment->exchange_rate( $app->param('exchange_rate') );
    $payment->invoice( $app->param('invoice') );
    $payment->currency( $app->param('mc_currency') );
    $payment->fee_amount( $app->param('mc_fee') );
    $payment->gross_amount( $app->param('mc_gross') );
#    $payment->handling_amount( $app->param('') );
    $payment->shipping_amount( $app->param('shipping') );
    $payment->tax( $app->param('tax') );
    $payment->payment_status( $app->param('payment_status') );
    $payment->payment_type( $app->param('payment_type') );
    $payment->payment_date( $app->param('payment_date') );
#    $payment->next_payment_date( $app->param('next_payment_date') );

    $payment->save or return $app->error("Unable to save payment.");;
    # TODO - fire callback
}

1;
__END__

qw(payment_type payment_date payment_status pending_reason address_status payer_status first_name last_name payer_email payer_id address_name address_country address_country_code address_zip address_state address_city address_street business receiver_email receiver_id residence_country item_name item_number quantity shipping tax mc_currency mc_fee mc_gross txn_type txn_id notify_version custom invoice charset)

