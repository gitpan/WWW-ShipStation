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

my $OrderID = 123456; # from createOrder
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
print Dumper(\$orderItem);

1;