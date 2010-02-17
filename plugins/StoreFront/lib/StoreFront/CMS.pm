package StoreFront::CMS;

use strict;
use MT::Util qw( encode_html relative_date format_ts );

sub create_subscription {
    my $app = shift;
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
        if ($obj->payment_type == 1) {
            $row->{list_price} = $obj->list_price;
            $row->{sale_price} = $obj->sale_price || undef;
            $row->{list_price_f} = sprintf("\$%.2f",$obj->list_price);
            $row->{sale_price_f} = sprintf("\$%.2f",$obj->sale_price);
        } else {
            $row->{list_price} = $obj->list_price;
            $row->{list_price_f} = sprintf("\$%.2f",$obj->list_price);
        }
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
        $row->{buyer}        = $obj->payer_email;
        $row->{status}       = $obj->payment_status;
        $row->{amount}       = $obj->gross_amount;

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
		sort => 'created_on',
		direction => 'descend',
    );

    my %params = (
                  'saved_deleted' => $app->{query}->param('saved_deleted') == 1,
    );
    my $plugin = MT->component('StoreFront');
    $app->listing({
        type     => 'payment',
        terms    => \%terms,
        args     => \%args,
        listing_screen => 1,
        code     => $code,
        template => $plugin->load_tmpl('list_payment.tmpl'),
        params   => \%params,
    });
}

1;
__END__
