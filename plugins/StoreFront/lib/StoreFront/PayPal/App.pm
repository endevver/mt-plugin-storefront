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

    # TODO - validate the receiver is registered to user
    # TODO - verify the item ordered, its price, etc, correspond to the correct amounts

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
    # TODO - trigger email
    return 0;
}

sub handle {
    my $app = shift;
    $logger->debug('Entering "handle"...');

    my $out = ''; # Paypal does not expect response content
    unless (validate( $app )) {
	MT->log({
	    message => "There was an error processing the IPN from PayPal. IPN invalid."
	});
	$app->response_code( 500 );
	$app->response_message( 'IPN Validation Failure' );
	return $out;
    }

    my $result;
    my $meth = $app->param('txn_type');
    do { no strict 'refs'; $result = $meth->( $app ); };
    if ($result) {
	$app->response_code( 200 );
	$app->response_message( 'IPN Successfully Processed' );
    } else {
	$app->response_code( 500 );
	$app->response_message( 'IPN Failure: ' . $app->errstr() );
    }
    return $out;
}

# A dispute has been resolved and closed
sub adjustment {
    my $app = shift;
    $logger->debug('Processing adjustment');
    return 1;
}

# Payment received for multiple items; source is Express Checkout or the PayPal
# Shopping Cart.
sub cart {
    my $app = shift;
    $logger->debug('Processing cart');
    return 1;
}

# Payment received for a single item; source is Express Checkout
sub express_checkout {
    my $app = shift;
    $logger->debug('Processing express_checkout');
    return 1;
}

# Payment sent using MassPay
sub masspay {
    my $app = shift;
    $logger->debug('Processing masspay');
    return 1;
}

# Monthly subscription paid for Website Payments Pro
sub merch_pmt {
    my $app = shift;
    $logger->debug('Processing merchant payment');
    return 1;
}

# A new dispute was filed
sub new_case {
    my $app = shift;
    $logger->debug('Processing new dispute');
    return 1;
}

# Recurring payment received
sub recurring_payment {
    my $app = shift;
    $logger->debug('Processing recurring payment');
    return 1;
}

# Recurring payment profile created
sub recurring_payment_profile_created {
    my $app = shift;
    $logger->debug('Processing recurring payment (with profile)');
    return 1;
}

# Payment received; source is the Send Money tab on the PayPal website
sub send_money {
    my $app = shift;
    $logger->debug('Processing a "send money" request, forwarding to web_accept');
    return _web_accept($app);
}

# Subscription canceled
sub subscr_cancel {
    my $app = shift;
    $logger->debug('Processing subscription cancellation');
    my $id = $app->param('subscr_id');
    my $subsc = MT->model('subscription')->load({ external_id => $id });
    unless ($subsc) {
	MT->log({ message => "Could not find subscription with ID: $id" });
	return $app->error("Error processing subscription cancellation");
    }
    my $pid = $subsc->product_id;
    my $product = MT->model('asset.product')->load( $pid );
    unless ($product) {
	MT->log({ blog_id => $subsc->blog_id,
		  message => "Warning: could not find product with ID: $pid, cancelling anyway." });
    }
    $subsc->status( MT->model('subscription')->CANCELLED() );
    $subsc->save or return $app->error("Unable to cancel subscription.");;
    # TODO - fire an email
    # TODO - fire callbacks
    return 1;
}

# Subscription expired
sub subscr_eot {
    my $app = shift;
    $logger->debug('Processing subscription expired');
    my $id = $app->param('subscr_id');
    my $subsc = MT->model('subscription')->load({ external_id => $id });
    unless ($subsc) {
	MT->log({ message => "Could not find subscription with ID: $id" });
	return $app->error("Error processing subscription expiration");
    }
    my $pid = $subsc->product_id;
    my $product = MT->model('asset.product')->load( $pid );
    unless ($product) {
	MT->log({ blog_id => $subsc->blog_id,
		  message => "Warning: could not find product with ID: $pid, expiring anyway." });
    }
    $subsc->status( MT->model('subscription')->EXPIRED() );
    $subsc->save or return $app->error("Unable to expire subscription.");;
    # TODO - fire an email
    # TODO - fire callbacks
    return 1;
}

# Subscription signup failed
sub subscr_failed {
    my $app = shift;
    $logger->debug('Processing subscription failure');
    my $id = $app->param('subscr_id');
    my $subsc = MT->model('subscription')->load({ external_id => $id });
    my $pid = $subsc->product_id;
    unless ($subsc) {
	MT->log({ message => "Could not find product with ID: $pid" });
	$subsc = MT->model('subscription')->new;
	$pid = $app->param( 'item_number' );
    }
    my $product = MT->model('asset.product')->load( $pid );
    unless ($product) {
	MT->log({ blog_id => $subsc->blog_id,
		  message => "Warning: could not find product with ID: $pid, expiring anyway." });
    }
    unless ($subsc->id) {
	$subsc->product_id( $pid );
	$subsc->blog_id( $product->blog_id );
	$subsc->external_id( $id );
	$subsc->author_id( $app->param('custom') );
    }
    $subsc->status( MT->model('subscription')->FAILURE() );
    $subsc->save or return $app->error("Unable to expire subscription.");;
    # TODO - fire an email
    # TODO - fire callbacks
    return 1;
}

# Subscription modified
sub subscr_modify {
    my $app = shift;
    $logger->debug('Processing subscription modification');
    # TODO - not currently implemented
    return 1;
}

# Subscription payment received
sub subscr_payment {
    my $app = shift;
    $logger->debug('Processing subscription payment');

    my $id = $app->param('subscr_id');
    my $subsc = MT->model('subscription')->load({ external_id => $id });
    unless ($subsc) {
	MT->log({ message => "Could not find subscription with ID: $id" });
	return $app->error("Error processing subscription payment");
    }
    my $pid = $subsc->product_id;
    my $product = MT->model('asset.product')->load( $pid );
    unless ($product) {
	MT->log({ blog_id => $subsc->blog_id,
		  message => "Warning: could not find product with ID: $pid." });
	return $app->error("Product ID $pid not found. Cannot process payment.");
    }
    my $payment = _process_payment($app, $product);
    $payment->subscription_id( $subsc->id );
    $payment->save or return $app->error("Unable to save payment.");
    return 1;
}

# Subscription started
sub subscr_signup {
    my $app = shift;
    $logger->debug('Processing signup');

    my $pid = $app->param('item_number');
    my $product = MT->model('asset.product')->load($pid);
    unless ($product) {
	MT->log({ message => "Could not find product with ID: $pid" });
	return $app->error("Error processing subscription sign-up");
    }

    my $subsc = MT->model('subscription')->new;
    $subsc->blog_id( $product->blog_id );
    $subsc->product_id( $product->id );
    $subsc->author_id( $app->param('custom') );
    $subsc->external_id( $app->param('subscr_id') );
    $subsc->status( MT->model('subscription')->ACTIVE() );
    $subsc->save or return $app->error("Unable to save new subscription.");;

    return 1;
}

# Payment received; source is Virtual Terminal
sub virtual_terminal {
    my $app = shift;
    $logger->debug('Processing payment from virtual terminal, forwarding to web_accept');
    return _web_accept($app);
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

    my $payment = _process_payment($app, $product);
    $payment->save or return $app->error("Unable to save payment.");;
    # TODO - fire callback
    # TODO - save options
    return 1;
}

sub _process_payment {
    my $app = shift;
    my ($product) = @_;
    my $txn_id = $app->param('txn_id');

    my $payment = MT->model('payment')->load( { external_transaction_id => $txn_id } );
    unless ($payment) {
	$payment = _init_new_payment($app,$product);
    }
    if ($payment->payment_status && $payment->payment_status ne $app->param('payment_status')) {
	# TODO - fire payment status change callbacks
    }
    $payment->payment_status( $app->param('payment_status') );
    if ($payment->payment_status() eq 'Pending') {
	$payment->is_pending( 1 );
	MT->log({
	    blog_id => $payment->blog_id,
	    message => "Received a PENDING payment: " . _reason_string( $payment->payment_status() )
	});
    } elsif ($payment->payment_status() eq 'Completed') {
	# TODO - fire payment completed callbacks
    }
    return $payment;
}

sub _init_new_payment {
    my $app = shift;
    my ($product) = @_;
    my $payment = MT->model('payment')->new;
    $payment->blog_id( $product->blog_id );
    $payment->product_id( $app->param('item_number') );
    $payment->payer_email( $app->param('payer_email') );
    $payment->is_test( $app->param('test_ipn') ? 1 : 0 );
    $payment->quantity( $app->param('quantity') );
    $payment->external_transaction_id( $app->param('txn_id') );
    $payment->external_payer_id( $app->param('payer_id') );
    $payment->company_name( $app->param('business') );
    $payment->contact_first_name( $app->param('first_name') );
    $payment->contact_last_name( $app->param('last_name') );
    $payment->address_name( $app->param('address_name') );
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
    $payment->shipping_amount( $app->param('shipping') );
    $payment->tax( $app->param('tax') );
    $payment->payment_type( $app->param('payment_type') );
    $payment->payment_date( $app->param('payment_date') );
    return $payment;
}

sub _reason_string {
    my ($code) = @_;
    if ($code eq 'address') { 
	return "The payment is pending because your customer did not include a confirmed shipping address and your Payment Receiving Preferences is set yo allow you to manually accept or deny each of these payments. To change your preference, go to the Preferences section of your Profile.";
    } elsif ($code eq 'authorization') {
	return "You set the payment action to Authorization and have not yet captured funds.";
    } elsif ($code eq 'echeck') {
	return "The payment is pending because it was made by an eCheck that has not yet cleared.";
    } elsif ($code eq 'intl') {
	return "The payment is pending because you hold a non-U.S. account and do not have a withdrawal mechanism. You must manually accept or deny this payment from your Account Overview.";
    } elsif ($code eq 'multi-currency') {
	return "You do not have a balance in the currency sent, and you do not have your Payment Receiving Preferences set to automatically convert and accept this payment. You must manually accept or deny this payment.";
    } elsif ($code eq 'order') { 
	return "You set the payment action to Order and have not yet captured funds.";
    } elsif ($code eq 'paymentreview') { 
	return "The payment is pending while it is being reviewed by PayPal for risk.";
    } elsif ($code eq 'unilateral') { 
	return "The payment is pending because it was made to an email address that is not yet registered or confirmed.";
    } elsif ($code eq 'upgrade') {
	return "The payment is pending because it was made via credit card and you must upgrade your account to Business or Premier status in order to receive the funds. upgrade can also mean that you have reached the monthly limit for transactions on your account.";
    } elsif ($code eq 'verify') {
	return "The payment is pending because you are not yet verified. You must verify your account before you can accept this payment.";
    } elsif ($code eq 'other') {
	return "Unspecified reason";
    } elsif ($code eq 'adjustment_reversal') {
	return "Reversal of an adjustment.";
    } elsif ($code eq 'buyer-complaint') {
	return "A reversal has occurred on this transaction due to a complaint about the transaction from your customer.";
    } elsif ($code eq 'chargeback') {
	return "A reversal has occurred on this transaction due to a chargeback by your customer.";
    } elsif ($code eq 'chargeback_reimbursement') {
	return "Reimbursement for a chargeback";
    } elsif ($code eq 'chargeback_settlement') {
	return "Settlement of a chargeback";
    } elsif ($code eq 'guarantee') {
	return "A reversal has occurred on this transaction due to your customer triggering a money-back guarantee.";
    } elsif ($code eq 'refund') {
	return "A reversal has occurred";
    } else {
	return "Unknown reason code: $code.";
    }
}

1;
__END__

qw(payment_type payment_date payment_status pending_reason address_status payer_status first_name last_name payer_email payer_id address_name address_country address_country_code address_zip address_state address_city address_street business receiver_email receiver_id residence_country item_name item_number quantity shipping tax mc_currency mc_fee mc_gross txn_type txn_id notify_version custom invoice charset)

