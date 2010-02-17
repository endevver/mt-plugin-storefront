package Net::PayPal::Button;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

$DEBUG   = 0;
$VERSION = '0.1';

use base qw(Class::Accessor);
Net::PayPal::Button->mk_accessors(qw( sandbox_mode success_url notify_url cancel_url
                                      method currency_code locale display_comment
                                      comment_header continue_button_text background_color
                                      display_shipping_address display_comment image_url
                                      contact_email custom_field invoice tax customer items 
                                      openssl my_keyfile my_certfile paypal_certfile
                                      button_text button_image cert_id
));

# We are exporting functions
use base qw/Exporter/;
# Export list - to allow fine tuning of export table
@EXPORT_OK = qw( as_html );

use strict;
use Net::PayPal::Item;
use Net::PayPal::Customer;

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;    # autoflush

my $USER_AGENT_NAME = "Net::PayPal::Button $VERSION";
my $MAP = {
    contact_email => "business",
    image_url => "image_url",
    success_url => "return",
    cancel_url => "cancel_return",
    notify_url => "notify_url",
    return_method => "rm",
    currency_code => "currency_code",
    locale => "lc",
    user_agent => "bn",
    continue_button_text => "cbt",
    display_shipping_address => "no_shipping",
    display_comment => "no_note",
    comment_header => "cn",
    background_color => "cs",
    tax => "tax",
    custom_field => "custom",
    invoice => "invoice"
};

sub new {
    my $class  = shift;
    my $params = shift;
    my $self   = {};
    foreach my $prop (qw( sandbox_mode success_url notify_url cancel_url 
                          method currency_code locale display_comment
                          comment_header continue_button_text background_color
                          display_shipping_address display_comment image_url
                          contact_email custom_field invoice tax customer
                          openssl my_keyfile my_certfile paypal_certfile
                          button_text button_image cert_id user_agent
                         )) {
        if ( exists $params->{$prop} ) {
            $self->{$prop} = $params->{$prop};
        }
    }

    $self->{cmd}           = '_xclick';
    $self->{locale}        ||= 'US';
    $self->{button_text}   ||= 'Buy Now';
    $self->{user_agent}    ||= $USER_AGENT_NAME,
    $self->{currency_code} ||= 'USD';
    $self->{return_method} = lc($self->{'method'}) eq 'post' ? 2 : 1;
    $self->{comment_header} ||= 'Comments';
    $self->{continue_button_text} ||= 'Continue &raquo;';
    $self->{background_color} = lc($self->{'background_color'}) eq 'black' ? "1" : "";
    $self->{display_shipping_address} = $self->{display_shipping_address} ? "" : "1";
    $self->{display_comment} = $self->{display_comment} ? "" : "1";
    
    eval 'require File::Which';
    if (!$self->{openssl} && !$@) {
        $self->{openssl} = File::Which::which('openssl');
    }

    $self->{items} = [];

    bless $self, $class;
    return $self;
}

sub url {
    my $self = shift;
    if ($self->sandbox_mode) {
        return 'https://www.sandbox.paypal.com/cgi-bin/webscr';
    } else {
        return 'https://www.paypal.com/cgi-bin/webscr';
    }
}

sub add_item {
    my $self = shift;
    my ($item) = @_;
    push @{$self->{'items'}}, $item;
}

sub items {
    my $self = shift;
    return @{$self->{'items'}};
}

sub encrypt {
    my $self = shift;
    if ($_[0] && $_[0] =~ /^\d+$/) {
        $self->{encrypt} = $_[0];
    } else {
        return $self->{encrypt};
    }
}

sub as_html {
    my $self = shift;
    my @items = $self->items();
    if ($#items == 0) {
        if ( $items[0]->isa('Net::PayPal::Subscription') ) {
            $self->{'cmd'} = '_xclick-subscriptions';
        } else {
            $self->{'cmd'} = '_xclick';
        } 
    } elsif ($#items > 0) {
        $self->{'cmd'} = '_xcart';
    } else {
        die "No items added to PayPal cart.";
    }
    my $url = $self->url;
    my $html;
    if ($self->encrypt) {
	die "No certificate ID specified." unless $self->{'cert_id'} ne '';
	my $params;
	foreach my $key (sort keys %$MAP) {
	    $params .= $MAP->{$key}.'='.$self->{$key}."\n" if $self->{$key}; 
	}
	$params .= $self->customer->as_params();
	$params .= "cert_id=".$self->{'cert_id'}."\n";
	$params .= "cmd=".$self->{'cmd'}."\n";
	if ($#items > 0) {
	    my $cnt = 0;
	    foreach my $i (@items) {
		$params .= $i->as_params(++$cnt);
	    }
	} elsif ($#items == 0) {
	    $params .= $items[0]->as_params();
	} else {
	    # Die?
	}
	$html = <<ENDHTML;
<form method="post" name="paypal_form" action="$url">
<input type="hidden" name="cmd" value="_s-xclick" />
ENDHTML
        $html .= '<input type="hidden" name="encrypted" value="'.$self->_encrypt_params($params).'" />'."\n";
    } else {
	$html = <<ENDHTML;
<form method="post" name="paypal_form" action="$url">
<input type="hidden" name="cmd" value="$self->{cmd}" />
ENDHTML
	foreach my $key (sort keys %$MAP) {
	    $html .= '<input type="hidden" name="'.$MAP->{$key}.'" value="'.$self->{$key}.'" />'."\n" if $self->{$key}; 
	}
	$html .= $self->customer->as_html();
	if ($#items > 0) {
	    my $cnt = 0;
	    foreach my $i (@items) {
		$html .= $i->as_html(++$cnt);
	    }
	} elsif ($#items == 0) {
	    $html .= $items[0]->as_html();
	} else {
	    # Die?
	}
    }
    if ($self->button_image) {
        $html .= '<input type="image" src="'.$self->{button_image}.'" />'."\n";
    } else {
        $html .= '<input type="submit" value="'.$self->{button_text}.'" />'."\n";
    }
    $html .= "</form>\n";
    return $html;
}

# Copyright 2005 by Gray Watson
# http://256.com/gray/docs/paypal_encrypt/ewp.pl
sub _encrypt_params {
    my $self = shift;
    my ($params) = @_;

    require FileHandle;
    require IPC::Open2;

    die "OpenSSL at " . $self->{openssl} . " is not executable" unless -x $self->{openssl};
    die "my_keyfile not specified or does not exist." unless -e $self->{my_keyfile};
    die "my_certfile not specified or does not exist." unless -e $self->{my_certfile};
    die "paypal_keyfile not specified or does not exist." unless -e $self->{paypal_certfile};

    # Send arguments into the openssl commands needed to do the sign,
    # encrypt, s/mime magic commands.  This works under FreeBSD with
    # OpenSSL '0.9.7e 25 Oct 2004' but segfaults with '0.9.7d 17 Mar
    # 2004'.  It also works under OpenBSD with OpenSSL '0.9.7c 30 Sep
    # 2003'.
    my $cmd = $self->{openssl} . 
        " smime -sign -signer " .
        $self->{my_certfile} .
        " -inkey " . 
        $self->{my_keyfile} . 
        " -outform der -nodetach -binary | " .
        $self->{openssl} . 
        " smime -encrypt -des3 -binary -outform pem " .
        $self->{paypal_certfile};

    my $pid = IPC::Open2::open2(*READER, *WRITER, $cmd)
        || die "Could not run open2 on ".$self->{openssl}.": $!\n"; 
    # Write our parameters that we need to be encrypted to the openssl
    # process.
    print WRITER $params;
    # close the writer file-handle
    close(WRITER);
    
    # read in the lines from openssl
    my @lines = <READER>;
    
    # close the reader file-handle which probably closes the openssl processes
    close(READER);
    
    # combine them into one variable
    return join('', @lines);
}

1;
__END__
