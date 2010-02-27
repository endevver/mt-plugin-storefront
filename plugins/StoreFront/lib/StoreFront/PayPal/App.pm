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
    $app->add_methods( handle => \&handle ); 
    $app->{default_mode}  = 'handle';
    $app->{is_admin}      = 0;
    $app->{warning_trace} = 0;

    my $ua = LWP::UserAgent->new;
    $ua->agent("StoreFront Plugin for Movable Type");
    $app->{ua} = $ua;

    $app;
}

# This method belongs to the MT::App::Comments namespace
sub purchase {
    my $app = shift;
    my $asset = MT->model('asset.product')->load( $app->param('id') );
    unless ($asset) {
	return $app->error("Please specify a valid product ID.");
    }
    my $user = _login_user_commenter( $app );
    unless ($user) {
	$app->add_return_arg(
			     '__mode' => 'paypal_purchase',
			     'id' => $asset->id,
			     'static' => 0,
	);
	return $app->login_form(
				blog_id    => $asset->blog_id,
				static     => 0,
				return_url => $app->return_uri, 
				message    => $app->translate( 'Please sign in to purchase.')
				);
    }
    my $tmpl = $app->load_tmpl('paypal/purchase.tmpl');
    my $ctx = $tmpl->context;
    $ctx->stash('asset',$asset);
    $ctx->stash('blog',$asset->blog);
    $ctx->stash('author',$user);
    return $app->build_page( $tmpl, { 
	id => $asset->id,
	blog_id => $asset->blog_id,
    });
}

# FIXME: copied from MT::App::Community
sub _login_user_commenter {
    my $app = shift;

    # Check if native user is logged in
    my ($user) = $app->login();
    return $user if $user;

    # Check if commenter is logged in
    my %cookies = $app->cookies();
    if ( !$cookies{ $app->COMMENTER_COOKIE_NAME() } ) {
        return undef;
    }
    my $session_key = $cookies{ $app->COMMENTER_COOKIE_NAME() }->value() || "";
    $session_key =~ y/+/ /;
    require MT::Session;
    my $sess_obj = MT::Session->load( { id => $session_key } );
    my $timeout = $app->config->CommentSessionTimeout;

    if ($sess_obj) {
        $app->{session} = $sess_obj;
        if ( $user = $app->model('author')->load( { name => $sess_obj->name } ) ) {
            $app->user($user);
            return $user;
        }
        elsif ( $sess_obj->start() + $timeout < time ) {
            delete $app->{session};
            $app->_invalidate_commenter_session( \%cookies );
            return undef;
        }
    }
    return $user;
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
    $logger->debug('Processing adjustment (UNIMPLEMENTED)');
    return 1;
}

# Payment received for multiple items; source is Express Checkout or the PayPal
# Shopping Cart.
sub cart {
    my $app = shift;
    $logger->debug('Processing cart (UNIMPLEMENTED)');
    return 1;
}

# Payment received for a single item; source is Express Checkout
sub express_checkout {
    my $app = shift;
    $logger->debug('Processing express_checkout, forwarding to web_accept');
    return _web_accept($app);
    return 1;
}

# Payment sent using MassPay
sub masspay {
    my $app = shift;
    $logger->debug('Processing masspay (UNIMPLEMENTED)');
    return 1;
}

# Monthly subscription paid for Website Payments Pro
sub merch_pmt {
    my $app = shift;
    $logger->debug('Processing merchant payment (UNIMPLEMENTED)');
    return 1;
}

# A new dispute was filed
sub new_case {
    my $app = shift;
    $logger->debug('Processing new dispute (UNIMPLEMENTED)');
    return 1;
}

# Recurring payment received
sub recurring_payment {
    my $app = shift;
    $logger->debug('Processing recurring payment (UNIMPLEMENTED)');
    return 1;
}

# Recurring payment profile created
sub recurring_payment_profile_created {
    my $app = shift;
    $logger->debug('Processing recurring payment (with profile) (UNIMPLEMENTED)');
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
    my $subsc = MT->model('sf.subscription')->load({ external_id => $id });
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
    $subsc->status( MT->model('sf.subscription')->CANCELLED() );
    $subsc->save or return $app->error("Unable to cancel subscription.");;
    # TODO - fire an email
    # TODO - fire callbacks
    # TODO - increment inventory??
    return 1;
}

# Subscription expired
sub subscr_eot {
    my $app = shift;
    $logger->debug('Processing subscription expired');
    my $id = $app->param('subscr_id');
    my $subsc = MT->model('sf.subscription')->load({ external_id => $id });
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
    $subsc->status( MT->model('sf.subscription')->EXPIRED() );
    $subsc->save or return $app->error("Unable to expire subscription.");;
    # TODO - fire an email
    # TODO - fire callbacks
    # TODO - increment inventory??
    return 1;
}

# Subscription signup failed
sub subscr_failed {
    my $app = shift;
    $logger->debug('Processing subscription failure');
    my $id = $app->param('subscr_id');
    my $subsc = MT->model('sf.subscription')->load({ external_id => $id });
    my $pid = $subsc->product_id;
    unless ($subsc) {
	MT->log({ message => "Could not find product with ID: $pid" });
	$subsc = MT->model('sf.subscription')->new;
	$pid = $app->param( 'item_number' );
    }
    my $product = MT->model('asset.product')->load( $pid );
    unless ($product) {
	MT->log({ blog_id => $subsc->blog_id,
		  message => "Warning: could not find product with ID: $pid, expiring anyway." });
    }
    # Subscription failed so it is unlikely one has been created.
    # Let's create one - this will at least surface in the UI and give admins a chance to follow
    # up with customer.
    my $user_id;
    if ($app->param('custom') =~ /user_id:(\d+)/) {
	$user_id = $1;
    }
    unless ($subsc->id) {
	$subsc->product_id( $pid );
	$subsc->blog_id( $product->blog_id );
	$subsc->is_test( $app->param('ipn_test') );
	$subsc->external_id( $id );
	$subsc->author_id( $user_id );
	$subsc->source( 'paypal' );
    }
    $subsc->status( MT->model('sf.subscription')->FAILURE() );
    $subsc->save or return $app->error("Unable to expire subscription.");;
    # TODO - fire an email
    # TODO - fire callbacks
    return 1;
}

# Subscription modified
sub subscr_modify {
    my $app = shift;
    $logger->debug('Processing subscription modification (UNIMPLEMENTED)');
    # TODO - not currently implemented
    return 1;
}

# Subscription payment received
sub subscr_payment {
    my $app = shift;
    $logger->debug('Processing subscription payment');

    my $pid = $app->param('item_number');
    my $product = MT->model('asset.product')->load( $pid );
    unless ($product) {
	MT->log({ blog_id => 0,
		  message => "Warning: could not find product with ID: $pid." });
	return $app->error("Product ID $pid not found. Cannot process payment.");
    }

    my $id = $app->param('subscr_id');
    my $subsc = MT->model('sf.subscription')->load({ external_id => $id });
    unless ($subsc) {
	MT->log({ message => "Could not find subscription with ID: $id, returning HTTP 500" });
	$app->response_code( 500 );
	$app->response_message( 'IPN Failure' );
	return $app->error('Could not find subscription associated with payment.');

	MT->log({ message => "Could not find subscription with ID: $id, creating temporary subscription" });
	my $user_id;
	if ($app->param('custom') =~ /user_id:(\d+)/) {
	    $user_id = $1;
	}
	$subsc = MT->model('sf.subscription')->new;
	$subsc->external_id( $id );
	$subsc->status( MT->model('sf.subscription')->IN_PROCESS() );
	$subsc->product_id( $app->param( 'item_number' ) );
	$subsc->author_id( $user_id ); # this will get updated later I think...
	$subsc->blog_id( $product->blog_id );
	$subsc->save;
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

    # It is possible that a payment came in for a subscription before the sub 
    # was created. In this case, a place holder subscription is created. So 
    # we load it an populate it with the data we now have on hand.
    my $sid = $app->param('subscr_id');

    my $subsc = MT->model('sf.subscription')->new;
    $subsc->external_id($sid);

#    my $subsc = MT->model('sf.subscription')->load({ external_id => $sid });
#    unless ($subsc) {
#	$subsc = MT->model('sf.subscription')->new;
#	$subsc->external_id($sid);
#	$subsc->save; # save immediately
#    }

    my $pid = $app->param('item_number');
    my $product = MT->model('asset.product')->load($pid);
    unless ($product) {
	MT->log({ message => "Could not find product with ID: $pid" });
	return $app->error("Error processing subscription sign-up");
    }

    if ($product->inventory_type == 1) {
	# Decrement inventory
	my $i = $product->inventory;
	my $q = $app->param('quantity') || 1;
	if ($i < $q) {
	    MT->log({ blog_id => $product->blog_id,
		      message => "ERROR: Attempt to subscribe to more items then are in inventory. Request for $q, but $i are on hand." });
	    return $app->error("Unable to process subscription. Quantity exceeds inventory.");
	    # TODO - send email
	    # TODO - call backend API to place hold
	} else {
	    $product->inventory( $i - $q );
	    $product->save;
	}
    }
    $logger->debug("Creating subscription - product:".$product->id);

    my $user_id;
    if ($app->param('custom') =~ /user_id:(\d+)/) {
	$user_id = $1;
    }

    $subsc->blog_id( $product->blog_id );
    $subsc->product_id( $product->id );
    $subsc->author_id( $user_id );
    $subsc->is_test( $app->param('ipn_test') );
    $subsc->status( MT->model('sf.subscription')->ACTIVE() );
    $subsc->source( 'paypal' );
    $subsc->save or do {
	$logger->debug("Unable to create subscription: " . $subsc->errstr);
	return $app->error("Unable to save new subscription.");
    };

    MT->log({ blog_id => $product->blog_id,
	      message => "Subscription successfully created" });

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

    if ($product->payment_type == 1 && $product->inventory_type == 1) {
	# Decrement inventory
	my $i = $product->inventory;
	my $q = $app->param('quantity') || 1;
	if ($i < $q) {
	    MT->log({ blog_id => $product->blog_id,
		      message => "ERROR: Attempt to purchase more items then are in inventory. Request for $q, but $i are on hand." });
	    return $app->error("Unable to process payment. Quantity exceeds inventory.");
	    # TODO - send email
	    # TODO - call backend API to place hold
	} else {
	    $product->inventory( $i - $q );
	    $product->save;
	}
    }

    my $payment = _process_payment($app, $product);
    $payment->save or return $app->error("Unable to save payment.");;
    # TODO - fire callback
    # TODO - save options
    return 1;
}

sub _process_refund {
    my $app = shift;
    my ($original) = @_; # the original payment record
    $original->is_refunded(1);
    $original->save;
}

sub _process_payment {
    my $app = shift;
    my ($product) = @_;
    my $txn_id = $app->param('txn_id');

    # Process a refund
    if ($app->param('mc_gross') < 0) {
	if (my $parent = $app->param('parent_txn_id')) {
	    my $original = MT->model('sf.payment')->load({ external_transaction_id => $parent });
	    _process_refund($app, $original);
	}
    }

    my $user_id;
    if ($app->param('custom') =~ /user_id:(\d+)/) {
	$user_id = $1;
    }

    my $payment = MT->model('sf.payment')->load( { external_transaction_id => $txn_id } );
    unless ($payment) {
	$payment = _init_new_payment($app,$product);
    }
    if ($payment->payment_status && $payment->payment_status ne $app->param('payment_status')) {
	# TODO - fire payment status change callbacks
    }
    $payment->author_id( $user_id );
    $payment->payment_status( $app->param('payment_status') );
    if ($payment->payment_status() eq 'Pending') {
	$payment->is_pending( 1 );
	MT->log({
	    blog_id => $payment->blog_id,
	    message => "Received a PENDING payment: " . _reason_string( $app->param('pending_reason') )
	});
    } elsif ($payment->payment_status() eq 'Completed') {
	# TODO - fire payment completed callbacks
    }
    return $payment;
}

sub _init_new_payment {
    my $app = shift;
    my ($product) = @_;

    my $user_id;
    if ($app->param('custom') =~ /user_id:(\d+)/) {
	$user_id = $1;
    }

    my $payment = MT->model('sf.payment')->new;
    $payment->source( 'paypal' );
    $payment->blog_id( $product->blog_id );
    $payment->author_id( $user_id );
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

