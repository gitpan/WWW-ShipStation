#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::ShipStation;
use Data::Dumper;

die "Please set ENV SHIPSTATION_USER and SHIPSTATION_PASS"
    unless $ENV{SHIPSTATION_USER} and $ENV{SHIPSTATION_PASS};

my $ws = WWW::ShipStation->new(
    user => $ENV{SHIPSTATION_USER},
    pass => $ENV{SHIPSTATION_PASS}
);

# my $stores = $ws->getStores(
#     filter => "Active eq true"
# );
# my $StoreID = $stores->{d}->[0]->{StoreID};

my $StoreID = 13652;
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
print Dumper(\$order);

1;