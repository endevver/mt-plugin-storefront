package StoreFront::CMS;

use strict;
use MT::Util qw( encode_html relative_date format_ts );

sub create_subscription {
    my $app = shift;
}

sub product_details {
    my $app    = shift;
    my $q      = $app->{query};
    my $blog   = $app->blog;
    my $plugin = MT->component('StoreFront');

    my $id     = $q->param('id');
    my $product = MT->model('asset.product')->load($id);

    my $date_format          = "%Y.%m.%d";
    my $datetime_format      = "%Y-%m-%d %H:%M:%S";

    my @payment_loop;
    my @payments = MT->model('sf.payment')->load({ product_id => $id },{ lastn => 10, direction => 'descend', sort => 'created_on' } );
    foreach my $obj (@payments) {
	my $row = {};
        $row->{id}           = $obj->id;
        $row->{is_test}      = $obj->is_test;
        $row->{is_pending}   = $obj->is_pending;
        $row->{is_refunded}  = $obj->is_refunded;
        $row->{status}       = $obj->payment_status;
        $row->{amount}       = sprintf('$%.2f',$obj->gross_amount);
	if ($obj->author_id) {
	    my $author = MT->model('author')->load( $obj->author_id );
	    if ($author) {
		$row->{buyer} = $author->nickname;
		$row->{buyer_id} = $author->id;
	    } else {
		$row->{buyer} = "User not found";
	    }
	} else {
	    $row->{buyer}        = $obj->payer_email;
	}
        if ( my $ts = $obj->created_on ) {
            $row->{created_on_formatted} =
                format_ts( $date_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_time_formatted} =
              format_ts( $datetime_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_relative} =
              relative_date( $ts, time, $app->blog );
        }
	push @payment_loop, $row;
    }

    my $tmpl   = $app->load_tmpl('details.tmpl');
    $tmpl->param( id => $product->id );
    $tmpl->param( product_name => $product->label );
    $tmpl->param( payment_type => $product->payment_type );
    $tmpl->param( list_price => sprintf('$%.2f',$product->list_price) );
    $tmpl->param( sale_price => sprintf('$%.2f',$product->sale_price) );
    $tmpl->param( payment_loop => \@payment_loop );
    my $iter = MT->model('sf.payment')->sum_group_by({ product_id => $id },{ group => ['product_id'], sum => 'gross_amount' });
    if ( my ($amount, $cat, $inv) = $iter->() ) {
      $tmpl->param( total_earned => sprintf('$%.2f',$amount) );
    }
    if ($product->payment_type == 1) {
    } else {
      $tmpl->param( subscriber_count => MT->model('sf.subscription')->count({ product_id => $id, status => 1 }) );
    }
    return $app->build_page($tmpl);
}

sub create_product {
    my $app    = shift;
    my $q      = $app->{query};
    my $blog   = $app->blog;
    my $plugin = MT->component('StoreFront');
    my $config = $plugin->get_config_hash( 'system' );
    my $tmpl   = $app->load_tmpl('dialog/create_product.tmpl');

    my $product;
    my $id     = $q->param('id');
    if ($id) {
        $product = MT->model('asset.product')->load($id);
    }
    unless ($product) {
        $product = MT->model('asset.product')->new();
        $product->status('');
        $product->duration_units('months');
        $product->trial_duration_units('days');
        $product->tax_rate(0.0);
        $product->payment_type(1);
    }

    my @status_loop;
    my $status_text = $config->{statii};
    foreach ( split("\n",$status_text) ) {
        push @status_loop, {
            label => $_,
            value => $_,
            selected => $product->status eq $_ ? 1 : 0
        };
    }
    
    my (@trial_dur_loop,@sub_dur_loop);
    foreach ( ("days","weeks","months","years") ) {
        push @trial_dur_loop, {
            label => $_,
            value => $_,
            selected => $product->trial_duration_units eq $_ ? 1 : 0
        };
    }
    foreach my $unit ( ("days","weeks","months","years") ) {
        my $v = $unit;
        $v =~ s/s$//; # trim the plural HACK!
        push @sub_dur_loop, {
            label => $v,
            value => $unit,
            selected => $product->duration_units eq $unit ? 1 : 0
        };
    }
    
    $tmpl->param( id => $id ) if $id;
    $tmpl->param( blog_id => $blog->id );
    $tmpl->param( status_loop => \@status_loop );
    $tmpl->param( sub_dur_loop => \@sub_dur_loop );
    $tmpl->param( trial_dur_loop => \@trial_dur_loop );
    $tmpl->param( name => $product->label );
    $tmpl->param( tax_rate => sprintf('%.2f%%',$product->tax_rate) );
    $tmpl->param( duration_units => ($product->duration_units ? $product->duration_units : 'months') );
    $tmpl->param( trial_duration_units => ($product->trial_duration_units ? $product->trial_duration_units : 'weeks') );
    foreach ( qw( list_price sale_price shipping_cost trial_price ) ) {
        $tmpl->param( $_ => $product->$_() ? sprintf('$%.2f',$product->$_()) : '' );
    }
    foreach ( qw( description sku_id payment_type requires_shipping inventory_type inventory
                  limit_per_order weight weight_unit offer_trial trial_duration duration recur
                  recurrence_count
                  ) ) {
        $tmpl->param( $_ => $product->$_() );
    }
    return $app->build_page($tmpl);
}

sub save_product {
    my $app    = shift;
    my $q      = $app->{query};
    my $blog   = $app->blog;
    my $plugin = MT->component('StoreFront');
    my $id     = $q->param('id');

    my $obj;
    if ($id) {
        $obj = MT->model('asset.product')->load($id) or
            return $app->error("Could not load product #" . $id);
    } else {
        $obj = MT->model('asset.product')->new;
        $obj->inventory( $q->param('inventory') );
    }
    # TODO - the problem we may have here is that "inventory" should never be saved
    # after the fact. It should only be incremented.
    # Does inventory need to live in its own table so that it is insulated from a 
    # blanket MT::Object->save operation?
    # In a word, it needs to be thread safe!
    foreach my $f (qw( blog_id sku_id label description status list_price sale_price 
                       inventory_type payment_type tax_rate weight weight_unit 
                       requires_shipping limit_per_order requires_shipping shipping_cost 
                       duration duration_units trial_duration trial_duration_units
                       trial_price offer_trial recur recurrence_count
                     )) {
        my $v = $q->param($f);
        $v =~ s/^\$// if ($f =~ /(price|cost)/);
        $v =~ s/\%// if ($f =~ /tax/);
        $obj->$f( $v );
    }
    $obj->save();
    return $app->json_result( { object => $obj } );    
}

sub list_product {
    my $app = shift;
    my %param = @_;

    my $author    = $app->user;
    my $list_pref = $app->list_pref('asset.product');

    my $base = $app->blog->site_url;
    my $date_format          = "%Y.%m.%d";
    my $datetime_format      = "%Y-%m-%d %H:%M:%S";

    my $code = sub {
        my ($obj, $row) = @_;
        
        $row->{id}         = $obj->id;
        $row->{name}       = encode_html($obj->label);
        $row->{type}       = $obj->payment_type == 1 ? 'Product' : 'Subscription';
	$row->{price_f}    = $obj->cost_string;
	$row->{list_price} = $obj->list_price;
	$row->{sale_price} = $obj->sale_price || undef;
        $row->{status}     = $obj->status;
        $row->{inventory}  = $obj->inventory_type == 0 ? 'Unlimitted' : $obj->inventory;

        if ( my $ts = $obj->created_on ) {
            $row->{created_on_formatted} =
                format_ts( $date_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_time_formatted} =
              format_ts( $datetime_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_relative} =
              relative_date( $ts, time, $app->blog );
        }
    };

    my %terms = (
		 blog_id => $app->blog->id,
    );

    my %args = (
		limit => $list_pref->{rows},
		offset => $app->param('offset') || 0,
		sort => 'label',
		direction => 'ascend',
    );

    my %params = (
                  'saved_deleted' => $app->{query}->param('saved_deleted') == 1,
#                  'uri_reset' => $app->{query}->param('uri_reset') == 1,
    );
    my $plugin = MT->component('StoreFront');
    $app->listing({
        type     => 'asset.product',
        terms    => \%terms,
        args     => \%args,
        listing_screen => 1,
        code     => $code,
        template => $plugin->load_tmpl('list_product.tmpl'),
        params   => \%params,
    });
}

sub list_payment {
    my $app = shift;
    my %param = @_;

    my $author    = $app->user;
    my $list_pref = $app->list_pref('payment');

    my $base = $app->blog->site_url;
    my $date_format          = "%Y.%m.%d";
    my $datetime_format      = "%Y-%m-%d %H:%M:%S";

    my $code = sub {
        my ($obj, $row) = @_;
        my $product = MT->model('asset.product')->load( $obj->product_id );

        $row->{id}           = $obj->id;
        $row->{product_name} = encode_html($product->label);
        $row->{is_test}      = $obj->is_test;
        $row->{is_pending}   = $obj->is_pending;
        $row->{is_refunded}  = $obj->is_refunded;
        $row->{status}       = $obj->payment_status;
        $row->{amount}       = sprintf('$%.2f',$obj->gross_amount);

	if ($obj->author_id) {
	    my $author = MT->model('author')->load( $obj->author_id );
	    if ($author) {
		$row->{buyer} = $author->nickname;
		$row->{buyer_id} = $author->id;
	    } else {
		$row->{buyer} = "User not found";
	    }
	} else {
	    $row->{buyer}        = $obj->payer_email;
	}


        if ( my $ts = $obj->created_on ) {
            $row->{created_on_formatted} =
                format_ts( $date_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_time_formatted} =
              format_ts( $datetime_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_relative} =
              relative_date( $ts, time, $app->blog );
        }
    };

    my %terms = (
		 blog_id => $app->blog->id,
    );
    $terms{product_id} = $app->param('product_id') if $app->param('product_id');

    my %args = (
		limit => $list_pref->{rows},
		offset => $app->param('offset') || 0,
		sort => 'created_on',
		direction => 'descend',
    );

    my %params = (
                  'saved_deleted' => $app->{query}->param('saved_deleted') == 1,
    );
    my $plugin = MT->component('StoreFront');
    $app->listing({
        type     => 'sf.payment',
        terms    => \%terms,
        args     => \%args,
        listing_screen => 1,
        code     => $code,
        template => $plugin->load_tmpl('list_payment.tmpl'),
        params   => \%params,
    });
}

sub list_subscription {
    my $app = shift;
    my %param = @_;

    my $author    = $app->user;
    my $list_pref = $app->list_pref('subscription');

    my $base            = $app->blog->site_url;
    my $date_format     = "%b %d, %Y";
    my $datetime_format = "%Y-%m-%d %H:%M:%S";

    my $code = sub {
        my ($obj, $row) = @_;
        my $product = MT->model('asset.product')->load( $obj->product_id );
	my $payment = MT->model('sf.payment')->load({ subscription_id => $obj->id },
						    { lastn => 1,
						      sort => 'created_on',
						      direction => 'descend', 
						  });
	if ($payment && $payment->author_id) {
	    my $author = MT->model('author')->load( $payment->author_id );
	    if ($author) {
		$row->{payer_name} = $author->nickname;
		$row->{payer_id} = $author->id;
	    } else {
		$row->{payer_name} = "User not found";
	    }
	} else {
	    $row->{payer_name} = "Anonymous";
	}
        $row->{id}           = $obj->id;
        $row->{product_name} = encode_html($product->label);
        $row->{product_id}   = $product->id;
        $row->{is_test}      = $obj->is_test;
	$row->{status}       = $obj->status_string;
	$row->{value}        = $product->cost_string;

	# For the dialog
	$row->{external_id}  = $obj->external_id;
	$row->{source}       = $obj->source;

	if ($payment) {
	    $row->{last_payment} = 
                format_ts( $date_format, $obj->created_on, 
			   $app->blog, $app->user ? $app->user->preferred_language : undef );
	} else {
	    $row->{last_payment} = 'Never';
	}

        if ( my $ts = $obj->created_on ) {
            $row->{created_on_formatted} =
                format_ts( $date_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_time_formatted} =
              format_ts( $datetime_format, $ts, $app->blog, $app->user ? $app->user->preferred_language : undef );
            $row->{created_on_relative} =
              relative_date( $ts, time, $app->blog );
        }
    };

    my %terms = (
		 blog_id => $app->blog->id,
    );
    $terms{product_id} = $app->param('product_id') if $app->param('product_id');
    $terms{author_id} = $app->param('author_id') if $app->param('author_id');
    $terms{status} = $app->param('status') if $app->param('status');
    my %args = (
		limit => $list_pref->{rows},
		offset => $app->param('offset') || 0,
		sort => 'created_on',
		direction => 'descend',
    );

    my %params = (
                  'saved_deleted' => $app->{query}->param('saved_deleted') == 1,
    );
    my $plugin = MT->component('StoreFront');
    $app->listing({
        type     => 'sf.subscription',
        terms    => \%terms,
        args     => \%args,
        listing_screen => 1,
        code     => $code,
        template => $plugin->load_tmpl('list_subscription.tmpl'),
        params   => \%params,
    });
}

1;
__END__
