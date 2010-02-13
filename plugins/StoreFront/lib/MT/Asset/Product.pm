package MT::Asset::Product;

use strict;
use base qw( MT::Asset );

__PACKAGE__->install_properties( { class_type => 'product', } );
__PACKAGE__->install_meta( { column_defs => { 
                                 'sku_id' => 'string',
                                 'inventory_type' => 'integer',
                                 'inventory' => 'integer',
                                 'payment_type' => 'integer',
                                 'status' => 'string',
                                 # Shipping Options
                                 'requires_shipping' => 'integer',
                                 'weight' => 'float',
                                 'weight_unit' => 'string',
                                 'shipping_cost' => 'float',
                                 # One Time Purchase Options
                                 'list_price' => 'float',
                                 'sale_price' => 'float',
                                 'tax_rate' => 'float',
                                 'limit_per_order' => 'integer',
                                 # Subscription Options 
                                 'offer_trial' => 'integer',
                                 'trial_price' => 'float',
                                 'trial_duration' => 'integer',
                                 'trial_duration_units' => 'string',
                                 'duration' => 'integer',
                                 'duration_units' => 'string',
                                 'recur' => 'integer',
                                 'recurrence_count' => 'integer'
                             }
                           } );

sub class_label { MT->translate('Product'); }
sub class_label_plural { MT->translate('Products'); }

sub file_name { my $asset   = shift; return $asset->label; }
sub file_path { my $asset   = shift; return undef; }
sub on_upload { my $asset   = shift; my ($param) = @_; 1; }
sub has_thumbnail { 0; }

# CONSTANTS
# Inventory Type
# 0 - unlimitted
# 1 - limitted
# Payment Type
# 1 - one time
# 2 - recurring

sub as_html {
    my $asset   = shift;
    my ($param) = @_;
    return $asset->enclose('');
}

sub insert_options {
    my $asset = shift;
    my ($param) = @_;

    my $app   = MT->instance;
    my $perms = $app->{perms};
    my $blog  = $asset->blog or return;

    $param->{align_left} = 1;
    $param->{html_head}  = '<link rel="stylesheet" href="'.$app->static_path.'plugins/StoreFront/app.css" type="text/css" />';

    return $app->build_page( '../plugins/StoreFront/tmpl/dialog/asset_options.tmpl', $param );
}

1;
__END__

=head1 NAME

MT::Asset::Product

=head1 AUTHOR & COPYRIGHT

Please see the L<MT/"AUTHOR & COPYRIGHT"> for author, copyright, and
license information.

=cut
