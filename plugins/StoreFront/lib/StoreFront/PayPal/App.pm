package StoreFront::PayPal::App;

use strict;

use MT;
#use MT::Util qw( encode_xml format_ts );
#use MT::I18N qw( length_text substr_text );
use base qw( MT::App );

use MT::Log::Log4perl qw( l4mtdump );
use Log::Log4perl qw( :resurrect );
our $logger ||= MT::Log::Log4perl->new();

sub init {
    my $app = shift;
    $logger ||= MT::Log::Log4perl->new();    #$logger->trace();
    $logger->debug('Initializing app...');
    $app->{no_read_body} = 1
      if $app->request_method eq 'POST' || $app->request_method eq 'PUT';
    $app->SUPER::init(@_) or return $app->error("Initialization failed");
    $app->request_content
      if $app->request_method eq 'POST' || $app->request_method eq 'PUT';
    $app->add_methods( handle => \&handle, );
    $app->{default_mode}  = 'handle';
    $app->{is_admin}      = 0;
    $app->{warning_trace} = 0;
    $app;
}

sub handle {
    my $app = shift;

    #$logger->debug('Entering "handle"...');
    my $out;
    return $out;
}

1;
__END__
