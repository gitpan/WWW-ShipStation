package WWW::ShipStation;

use strict;
use 5.008_005;
our $VERSION = '0.04';

use LWP::UserAgent;
use JSON;
use Carp 'croak';
use URI::Escape qw/uri_escape/;
use HTTP::Request;

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    $args{user} or croak "user is required.";
    $args{pass} or croak "pass is required.";

    $args{ua} ||= LWP::UserAgent->new();
    $args{json} ||= JSON->new->allow_nonref->utf8;

    $args{API_BASE} ||= 'https://data.shipstation.com/1.3/';

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

    my $req = HTTP::Request->new(GET => $self->{API_BASE} . $url);
    $req->authorization_basic($self->{user}, $self->{pass});
    $req->header('Accept', 'application/json'); # JSON is better
    my $res = $self->{ua}->request($req);
    # use Data::Dumper; print STDERR Dumper(\$res);
    if ($res->header('Content-Type') =~ m{application/json}) {
        return $self->{json}->decode($res->decoded_content);
    }
    unless ($res->is_success) {
        return {
            'error' => {
                'code' => '',
                'message' => {
                    'lang' => 'en-US',
                    'value' => $res->status_line,
                }
            }
        };
    }
}

sub __now {
    my @d = localtime();
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d', $d[5] + 1900, $d[4] + 1, $d[3], $d[2], $d[1]);
}

sub createOrder {
    my $self = shift;

    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $__now = __now();
    my $content = <<XML;
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<entry xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xmlns="http://www.w3.org/2005/Atom">
  <category scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme" term="SS.WebData.Order" />
  <title />
  <author>
    <name />
  </author>
  <updated>$__now.1022961Z</updated>
  <id />
  <content type="application/xml">
    <m:properties>
XML

    # bool
    foreach my $x ('Active', 'AdditionalHandling', 'Gift', 'NonMachinable', 'SaturdayDelivery', 'ShowPostage') {
        if ($args{$x}) {
            $content .= qq~<d:$x m:type="Edm.Boolean">true</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Boolean">false</d:$x>\n~;
        }
    }

    # byte
    foreach my $x ('AddressVerified', 'Confirmation', 'InsuranceProvider') {
        my $v = $args{$x} ? 1 : 0;
        $content .= qq~<d:$x m:type="Edm.Byte">$v</d:$x>\n~;
    }

    # decimal
    foreach my $x ('AmountPaid', 'ConfirmationCost', 'Height', 'Length', 'Width', 'InsuranceCost', 'InsuredValue', 'OrderTotal', 'OtherCost', 'ShippingAmount') {
        if (exists $args{$x}) {
            my $v = sprintf('%.2f', $args{$x});
            $content .= qq~<d:$x m:type="Edm.Decimal">$v</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Decimal" m:null="true" />\n~;
        }
    }

    # int32
    foreach my $x ('CustomerID', 'EmailTemplateID', 'PackageTypeID', 'PackingSlipID', 'MarketplaceID', 'OrderID', 'OrderStatusID', 'ProviderID', 'RequestedServiceID', 'SellerID', 'ServiceID', 'StoreID', 'WarehouseID', 'WeightOz') {
        $args{$x} ||= 0 if $x eq 'OrderID';
        if (exists $args{$x}) {
            $content .= qq~<d:$x m:type="Edm.Int32">$args{$x}</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Int32" m:null="true" />\n~;
        }
    }

    # DateTime
    foreach my $x ('ImportBatch') {
        if (exists $args{$x}) {
            $content .= qq~<d:$x m:type="Edm.Guid">$args{$x}</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Guid" m:null="true" />\n~;
        }
    }

    # DateTime
    foreach my $x ('CreateDate', 'HoldUntil', 'ModifyDate', 'OrderDate', 'PayDate', 'ShipDate') {
        if (exists $args{$x}) {
            $content .= qq~<d:$x m:type="Edm.DateTime">$args{$x}</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.DateTime" m:null="true" />\n~;
        }
    }

    foreach my $x ('BuyerEmail', 'ExternalPaymentID', 'ExternalUrl', 'ImportKey', 'NonDelivery', 'CustomsContents', 'NotesFromBuyer', 'NotesToBuyer', 'InternalNotes', 'OrderNumber', 'RateError', 'RequestedShippingService', 'ResidentialIndicator', 'ShipCity', 'ShipCompany', 'ShipCountryCode', 'ShipName', 'ShipPhone', 'ShipPostalCode', 'ShipState', 'ShipStreet1', 'ShipStreet2', 'ShipStreet3', 'Username') {
        if (exists $args{$x}) {
            $content .= qq~<d:$x>~ . __simple_escape($args{$x}) . qq~</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:null="true" />\n~;
        }
    }

    $content .= <<'XML';
    </m:properties>
  </content>
</entry>
XML

    $self->__request('POST', 'https://data.shipstation.com/1.2/Orders', $content);
}

sub __simple_escape {
    my $str = shift;
    $str =~ s/\&/\&amp;/g;
    $str =~ s/\</\&lt;/g;
    $str =~ s/\>/\&gt;/g;
    $str;
}

sub deleteOrder {
    my ($self, $orderID) = @_;

    $self->__request('DELETE', "http://data.shipstation.com/1.2/Orders($orderID)");
}

sub createOrderItem {
    my $self = shift;

    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $__now = __now();
    my $content = <<XML;
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<entry xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xmlns="http://www.w3.org/2005/Atom">
  <category scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme" term="SS.WebData.OrderItem" />
  <title />
  <author>
    <name />
  </author>
  <updated>$__now.6214402Z</updated>
  <id />
  <content type="application/xml">
    <m:properties>
XML

    # bool
    foreach my $x ('Inactive') {
        if ($args{$x}) {
            $content .= qq~<d:$x m:type="Edm.Boolean">true</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Boolean">false</d:$x>\n~;
        }
    }

    # decimal
    foreach my $x ('ExtendedPrice', 'ShippingAmount', 'TaxAmount', 'WeightOz') {
        if (exists $args{$x}) {
            my $v = sprintf('%.2f', $args{$x});
            $content .= qq~<d:$x m:type="Edm.Decimal">$v</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Decimal" m:null="true" />\n~;
        }
    }

    # int32
    foreach my $x ('OrderID', 'OrderItemID', 'ProductID', 'Quantity', 'UnitCost', 'UnitPrice') {
        $args{$x} ||= 0 if $x eq 'OrderID' or $x eq 'OrderItemID';
        if (exists $args{$x}) {
            $content .= qq~<d:$x m:type="Edm.Int32">$args{$x}</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.Int32" m:null="true" />\n~;
        }
    }

    # DateTime
    foreach my $x ('CreateDate', 'ModifyDate') {
        if (exists $args{$x}) {
            $content .= qq~<d:$x m:type="Edm.DateTime">$args{$x}</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:type="Edm.DateTime" m:null="true" />\n~;
        }
    }

    foreach my $x ('Description', 'ItemUrl', 'Options', 'SKU', 'ThumbnailUrl', 'UPC', 'WarehouseLocation') {
        if (exists $args{$x}) {
            $content .= qq~<d:$x>~ . __simple_escape($args{$x}) . qq~</d:$x>\n~;
        } else {
            $content .= qq~<d:$x m:null="true" />\n~;
        }
    }

    $content .= <<'XML';
    </m:properties>
  </content>
</entry>
XML

    $self->__request('POST', 'https://data.shipstation.com/1.2/OrderItems', $content);
}

sub __request {
    my ($self, $method, $url, $content) = @_;

    my $req = HTTP::Request->new($method => $url);
    $req->authorization_basic($self->{user}, $self->{pass});
    $req->header('Accept', 'application/json'); # JSON is better
    $req->header('Accept-Charset' => 'UTF-8');
    if ($method eq 'POST') {
        $req->header('Content-Type' => 'application/atom+xml');
    }
    $req->content($content) if $content;

    my $res = $self->{ua}->request($req);
    # use Data::Dumper; print STDERR Dumper(\$res);
    if ($method eq 'DELETE') {
        return $res->code == 204 ? 1 : 0;
    }
    if ($res->header('Content-Type') =~ m{application/json}) {
        return $self->{json}->decode($res->decoded_content);
    }
    unless ($res->is_success) {
        return {
            'error' => {
                'code' => '',
                'message' => {
                    'lang' => 'en-US',
                    'value' => $res->status_line
                }
            }
        };
    }
    return $res->decoded_content;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::ShipStation - ShipStation API

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

=head2 createOrder

    my $order = $ws->createOrder(
        StoreID => 0,
        OrderNumber => "TEST001",
        ImportKey   => "TEST001",
        OrderDate   => "2014-07-02T09:30:00",
        PayDate     => "2014-07-02T09:30:00",
        OrderStatusID => 2,
        RequestedShippingService => "USPS Priority Mail",
        OrderTotal => '123.45',
        AmountPaid => '123.45',
        ShippingAmount => '4.50',
        WeightOz => 16,
        NotesFromBuyer => "Please make sure it gets here by Monday!",
        Username       => 'customer@mystore.com',
        BuyerEmail     => 'customer@mystore.com',
        ShipName       => "The President",
        ShipCompany    => "US Govt",
        ShipStreet1    => "1600 Pennsylvania Ave",
        ShipCity       => "Washington",
        ShipState      => "DC",
        ShipPostalCode => "20500",
        ShipCountryCode => "US",
        ShipPhone      => "512-555-5555",
    );

=head2 createOrderItem

    my $orderItem = $ws->createOrderItem(
        OrderID => $OrderID,
        SKU => "FD88821",
        Description   => "My Product Name",
        ThumbnailUrl   => "http://www.mystore.com/products/12345.jpg",
        WeightOz => 8,
        Quantity => 2,
        UnitPrice => 13.99,
        Options => "Size: Large\nColor: Green",
    );

=head2 deleteOrder

    my $is_success = $ws->deleteOrder($OrderID);

=head2 request

    my $data = $ws->request('Customers()');
    my $data = $ws->request('Warehouses()',
        filter => 'Default eq true'
    );

internal use

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
