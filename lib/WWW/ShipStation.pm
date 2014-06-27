package WWW::ShipStation;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use LWP::UserAgent;
use JSON;
use Carp 'croak';
use URI::Escape qw/uri_escape/;

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    $args{user} or croak "user is required.";
    $args{pass} or croak "pass is required.";

    $args{ua} ||= LWP::UserAgent->new();
    $args{json} ||= JSON->new->allow_nonref->utf8;

    $args{API_BASE} ||= 'https://data.shipstation.com/1.1/';

    $args{ua}->default_header('Accept', 'application/json'); # JSON is better
    $args{ua}->credentials('data.shipstation.com:443', 'ShipStation', $args{user}, $args{pass});

    bless \%args, $class;
}

sub getCarriers {
    (shift)->request('Carriers');
}

sub getCustomsItems {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'CustomsItems()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getCustomers {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'Customers()';
    if ($args{customerID}) {
        $url = "Customers($args{customerID})"
    }
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getMarketplaces {
    (shift)->request('Marketplaces');
}

sub getOrderItems {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'OrderItems()';
    if ($args{orderID}) {
        $url = "OrderItems($args{orderID})"
    }
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getOrders {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'Orders()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getPackageTypes {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'PackageTypes()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getProducts {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'Products()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getShipments {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'Shipments()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getShippingProviders {
    (shift)->request('ShippingProviders');
}

sub getShippingServices {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'ShippingServices()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getStores {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'Stores()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub getWarehouses {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $url = 'Warehouses()';
    my %params = map { '$' . $_ => $args{$_} } keys %args;
    $self->request($url, %params);
}

sub request {
    my ($self, $url, %params) = @_;

    if (%params and keys %params) {
        $url .= '?' . join('&', map { join('=', $_, uri_escape($params{$_})) } keys %params);
    }

    my $resp = $self->{ua}->get($self->{API_BASE} . $url);
    # use Data::Dumper; print STDERR Dumper(\$resp);
    unless ($resp->is_success) {
        return { error => $resp->status_line };
    }
    return $self->{json}->decode($resp->decoded_content);
}


1;
__END__

=encoding utf-8

=head1 NAME

WWW::ShipStation - Blah blah blah

=head1 SYNOPSIS

    use WWW::ShipStation;

=head1 DESCRIPTION

WWW::ShipStation is for L<http://api.shipstation.com/>

refer examples for running code

=head1 METHODS

=head2 new

    my $ws = WWW::ShipStation->new(
        user => 'blabla',
        pass => 'blabla'
    );

=over 4

=item * user

required

=item * pass

required

=item * ua

optional, L<LWP::UserAgent> based.

=item * json

optional, L<JSON> based

=back

=head2 getCarriers

    my $carriers = $ws->getCarriers();

L<http://api.shipstation.com/Carriers-Resource.ashx>

=head2 getCustomsItems

    my $customitems = $ws->getCustomsItems(
        filter => "Order/OrderNumber eq '1111113'",
    ); # https://data.shipstation.com/1.1/CustomsItems()?$filter=Order/OrderNumber eq '1111113'

L<http://api.shipstation.com/CustomsItem-Resource.ashx>

=head2 getCustomers

    my $customers = $ws->getCustomers();
    my $customers = $ws->getCustomers(
        orderby => 'Name',
        top => 100
    ); # https://data.shipstation.com/1.1/Customers()?$orderby=Name&$top=100
    my $customers = $ws->getCustomers(
        orderby => 'Name',
        skip => 100,
        top => 100
    ); # https://data.shipstation.com/1.1/Customers()?$orderby=Name&$skip=100&$top=100
    my $customers = $ws->getCustomers(
        customerID => 29229
    ); # https://data.shipstation.com/1.1/Customers(29229)
    my $customers = $ws->getCustomers(
        filter => "Email eq 'support@shipstation.com'"
    ); # http://data.shipstation.com/1.1/Customers()?$filter=Email eq 'support@shipstation.com'

L<http://api.shipstation.com/Customer-Resource.ashx>

=head2 getMarketplaces

    my $marketplaces = $ws->getMarketplaces();

L<http://api.shipstation.com/Marketplace-Resource.ashx>

=head2 getOrderItems

    my $orderitems = $ws->getOrderItems();
    my $orderitems = $ws->getOrderItems(
        filter => "Order/OrderNumber eq '1018'"
    ); # https://data.shipstation.com/1.1/OrderItems()?$filter=Order/OrderNumber eq '1018'

L<http://api.shipstation.com/OrderItems-Resource.ashx>

=head2 getOrders

    my $orders = $ws->getOrders();
    my $orders = $ws->getOrders(
        filter => "(OrderDate ge datetime'2012-06-30T00:00:00') and (OrderDate le datetime'2012-07-01T00:00:00')",
        expand => 'OrderItems',
    ); # https://data.shipstation.com/1.1/Orders()?$filter=(OrderDate ge datetime'2012-06-30T00:00:00') and (OrderDate le datetime'2012-07-01T00:00:00')&$expand=OrderItems

L<http://api.shipstation.com/Order-Resource.ashx>

=head2 getPackageTypes

    my $packagetypes = $ws->getPackageTypes(
        filter => 'Domestic eq true'
    ); # https://data.shipstation.com/1.1/PackageTypes()?$filter=Domestic eq true

L<http://api.shipstation.com/PackageType-Resource.ashx>

=head2 getProducts

    my $products = $ws->getProducts(
        filter => "SKU eq '12345'"
    ); # https://data.shipstation.com/1.1/Products()?$filter=SKU eq '12345'

L<http://api.shipstation.com/Product-Resource.ashx>

=head2 getShipments

    my $shipments = $ws->getShipments(
        filter => "Order/OrderNumber eq '100000001'",
        expand => 'ShipmentItems',
    ); # https://data.shipstation.com/1.1/Shipments()?$filter=Order/OrderNumber%20eq%20'100000001'&$expand=ShipmentItems
    my $shipments = $ws->getShipments(
        filter => "(ShipDate ge datetime'2012-06-01T00:00:00') and (ShipDate lt datetime'2012-06-09T00:00:00')",
    ); # https://data.shipstation.com/1.1/Shipments()?$filter=(ShipDate ge datetime'2012-06-01T00:00:00') and (ShipDate lt datetime'2012-06-09T00:00:00')

L<http://api.shipstation.com/ShipmentItem-Resource.ashx>
L<http://api.shipstation.com/Shipment-Resource.ashx>

=head2 getShippingProviders

    my $shippingproviders = $ws->getShippingProviders();

L<http://api.shipstation.com/ShippingService-Provider.ashx>

=head2 getShippingServices

    my $shippingservice = $ws->getShippingServices(
        filter => "(International eq false) and (ProviderId eq 4)"
    ); # https://data.shipstation.com/1.1/ShippingServices()?$filter=(International eq false) and (ProviderId eq 4)

L<http://api.shipstation.com/ShippingService%20Resource.ashx>

=head2 getStores

    my $stores = $ws->getStores(
        filter => "Active eq true"
    ); # https://data.shipstation.com/1.3/Stores()?$filter=Active eq true

L<http://api.shipstation.com/Store-Resource.ashx>

=head2 getWarehouses

    my $warehouses = $ws->getWarehouses(
        filter => 'Default eq true'
    ); # https://data.shipstation.com/1.1/Warehouses()?$filter=Default eq true

L<http://api.shipstation.com/Warehouse-Resource.ashx>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
