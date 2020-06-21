provider "aws" {
  alias = "requester"
}

provider "aws" {
  alias = "accepter"
}

# VPC data

data "aws_vpc" "requester" {
  provider = "aws.requester"

  filter {
    name   = "tag:Name"
    values = ["${upper(var.requester_account_alias)}*"]
  }
}

data "aws_vpc" "accepter" {
  provider = "aws.accepter"

  filter {
    name   = "tag:Name"
    values = ["${upper(var.accepter_account_alias)}*"]
  }
}

# Route table data
data "aws_route_tables" "requester" {
  provider = "aws.requester"
  vpc_id   = "${data.aws_vpc.requester.id}"

  filter {
    name   = "tag:Type"
    values = ["PrivateRouteTable*"]
  }
}

data "aws_route_tables" "requester_transit" {
  provider = "aws.requester"
  vpc_id   = "${data.aws_vpc.requester.id}"

  filter {
    name   = "tag:Type"
    values = ["TransitRouteTable*"]
  }
}

data "aws_route_tables" "accepter" {
  provider = "aws.accepter"
  vpc_id   = "${data.aws_vpc.accepter.id}"

  filter {
    name   = "tag:Type"
    values = ["PrivateRouteTable*"]
  }
}

data "aws_route_tables" "accepter_transit" {
  provider = "aws.accepter"
  vpc_id   = "${data.aws_vpc.accepter.id}"

  filter {
    name   = "tag:Type"
    values = ["TransitRouteTable*"]
  }
}

# Caller identity
data "aws_caller_identity" "peer" {
  provider = "aws.accepter"
}

# Route table routes

resource "aws_route" "requester" {
  provider                  = "aws.requester"
  count                     = "${length(data.aws_route_tables.requester.ids)}"
  route_table_id            = "${data.aws_route_tables.requester.ids[count.index]}"
  destination_cidr_block    = "${data.aws_vpc.accepter.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.peer.id}"
}

resource "aws_route" "accepter" {
  provider                  = "aws.accepter"
  count                     = "${length(data.aws_route_tables.accepter.ids)}"
  route_table_id            = "${data.aws_route_tables.accepter.ids[count.index]}"
  destination_cidr_block    = "${data.aws_vpc.requester.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.peer.id}"
}

resource "aws_route" "requester_transit" {
  provider                  = "aws.requester"
  count                     = "${length(data.aws_route_tables.requester_transit.ids)}"
  route_table_id            = "${data.aws_route_tables.requester_transit.ids[count.index]}"
  destination_cidr_block    = "${data.aws_vpc.accepter.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.peer.id}"
}

resource "aws_route" "accepter_transit" {
  provider                  = "aws.accepter"
  count                     = "${length(data.aws_route_tables.accepter_transit.ids)}"
  route_table_id            = "${data.aws_route_tables.accepter_transit.ids[count.index]}"
  destination_cidr_block    = "${data.aws_vpc.requester.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.peer.id}"
}

# VPC peering connection

resource "aws_vpc_peering_connection" "peer" {
  provider      = "aws.requester"
  vpc_id        = "${data.aws_vpc.requester.id}"
  peer_vpc_id   = "${data.aws_vpc.accepter.id}"
  peer_owner_id = "${data.aws_caller_identity.peer.account_id}"
  auto_accept   = false
  peer_region = "${var.peer_owner_region}"

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = "${merge(var.common_tags, map("Side" ,"Requester"), map("Peered Account", "${var.accepter_account_alias}"))}"
  lifecycle {
    ignore_changes = [ "requester"]
  }
}

# VPC peering connection accepter

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = "aws.accepter"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
  auto_accept               = true

  tags = "${merge(var.common_tags, map("Side" ,"Accepter"), map("Peered Account", "${var.requester_account_alias}"))}"
}

resource "aws_vpc_peering_connection_options" "requester" {
  provider                  = "aws.requester"
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.peer.id}"

  requester {
    allow_classic_link_to_remote_vpc = "${var.requester_allow_classic_link_to_remote_vpc}"
    allow_remote_vpc_dns_resolution = "${var.requester_allow_remote_vpc_dns_resolution}"
  }
}

# VPC peering connection options

resource "aws_vpc_peering_connection_options" "accepter" {
  provider                  = "aws.accepter"
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.peer.id}"

  accepter {
    allow_classic_link_to_remote_vpc = "${var.accepter_allow_classic_link_to_remote_vpc}"
    allow_remote_vpc_dns_resolution = "${var.accepter_allow_remote_vpc_dns_resolution}"
  }
}
