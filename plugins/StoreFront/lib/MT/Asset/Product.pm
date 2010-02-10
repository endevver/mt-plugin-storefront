package MT::Asset::Product;

use strict;
use base qw( MT::Asset );

__PACKAGE__->install_properties( { class_type => 'product', } );
__PACKAGE__->install_meta( { columns => [ 
                                 'sku_id',
                                 'list_price',
                                 'sale_price',
                                 'inventory_type',
                                 'inventory',
                                 'payment_type',
                                 'status',
                                 'period',
                                 'start_date',
                                 'recurrence',
                                 ] 
                           } );

sub class_label { MT->translate('Product'); }
sub class_label_plural { MT->translate('Products'); }

sub file_name { my $asset   = shift; return $asset->label; }
sub file_path { my $asset   = shift; return undef; }
sub on_upload { my $asset   = shift; my ($param) = @_; 1; }
sub has_thumbnail { 0; }

# CONSTANTS
# Inventory Type
# 1 - unlimitted
# 2 - limitted
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
