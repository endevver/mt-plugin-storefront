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
    
    my @status_loop;
    my $status_text = $config->{statii};

    foreach ( split("\n",$status_text) ) {
        push @status_loop, {
            label => $_,
            value => $_,
            selected => 0
        };
    }
    my @period_loop;
    foreach ( ("monthly","yearly","weekly","bi-weekly","quarterly") ) {
        push @period_loop, {
            label => $_,
            value => $_,
            selected => 0
        };
    }
    
    my $tmpl = $app->load_tmpl('dialog/create_product.tmpl');
    $tmpl->param( blog_id => $blog->id );
    $tmpl->param( period_loop => \@period_loop );
    $tmpl->param( status_loop => \@status_loop );
    return $app->build_page($tmpl);
}

sub edit_product {
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
    }
    foreach my $f (qw( blog_id sku_id label description status list_price sale_price period
                 inventory inventory_type payment_type start_date recurrence )) {
        my $v = $q->param($f);
        $v =~ s/^\$// if ($f =~ /price/);
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
        $row->{list_price} = $obj->list_price;
        $row->{sale_price} = $obj->sale_price || undef;
        $row->{list_price_f} = sprintf("\$%.2f",$obj->list_price);
        $row->{sale_price_f} = sprintf("\$%.2f",$obj->sale_price);
        $row->{status}     = $obj->status;
        $row->{inventory}  = $obj->inventory_type == 1 ? 'Unlimitted' : $obj->inventory;

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
#                  'map_saved' => $app->{query}->param('map_saved') == 1,
#                  'uri_reset' => $app->{query}->param('uri_reset') == 1,
    );
    my $plugin = MT->component('StoreFront');
    $app->listing({
        type     => 'asset.product',
        terms    => \%terms,
        args     => \%args,
        listing_screen => 1,
        code     => $code,
        template => $plugin->load_tmpl('list.tmpl'),
        params   => \%params,
    });
}

1;
__END__
