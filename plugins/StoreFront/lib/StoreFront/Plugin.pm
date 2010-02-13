package StoreFront::Plugin;

use strict;

sub load_list_filters {
    my $app = shift;
    return {
        'asset.product' => {
            on_sale => {
              label => "Products on Sale",
              handler => sub {
                  my ( $terms, $args ) = @_;
                  $args->{join} = MT->model('asset.meta')->join_on(
                        'asset_id',
                        {   asset_meta_type => 'sale_price',
                            vfloat => { '>' => 0 },
                        }
                    );
              }
            },
            subscriptions => {
                label => "Subscriptions",
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{payment_type} = 2;
                }
            },
            products => {
                label => "Single Payment",
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{payment_type} = 1;
                }
            },
            out_of_stock => {
                label => "Out of Stock",
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{inventory_type} = 1;
                    $terms->{inventory} = 0;
                }
            },
            low_inventory => {
                label => "Low Inventory",
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{inventory_type} = 1;
                    $terms->{inventory} = { '<' => 5  };
                }
            },
            all => {
                label => "All Products",
                handler => sub {
                    my ( $terms, $args ) = @_;
                }
            }
        }
    }
}

1;
__END__
