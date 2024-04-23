resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "custom"
  }
}

# resource "aws_subnet" "private_subnet_2a" {
#   vpc_id = aws_vpc.vpc.id
#   cidr_block = "10.0.1.0/24"
#   availability_zone = "us-west-2a"

#   tags = {
#     Name = "private_subnet"
#   }
# }

# resource "aws_subnet" "private_subnet_2b" {
#   vpc_id = aws_vpc.vpc.id
#   cidr_block = "10.0.2.0/24"
#   availability_zone =  "us-west-2b"

#   tags = {
#     Name = "private_subnet"
#   }
# }

# resource "aws_subnet" "private_subnet_2c" {
#   vpc_id = aws_vpc.vpc.id
#   cidr_block = "10.0.3.0/24"
#   availability_zone = "us-west-2c"

#   tags = {
#     Name = "private_subnet"
#   }
# }
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet)

  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet[count.index]
  availability_zone = var.availability_zone[count.index % length(var.availability_zone)] // when the number of subnets exceeds the number available zones

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet)

  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet[count.index]
  availability_zone = var.availability_zone[count.index % length(var.availability_zone)]

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "custom"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route = {
    cidr_block = "0.0.0.0/0" // all address IP
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "public_association" {
  for_each = {for k, v in aws_subnet.public_subnet : k => v} // k is index, v is value
  subnet_id = each.value.id // create value.id for route table
  route_table_id = aws_route_table.public.id // Specifies that each subnet in the public subnet will be associated with the routing table identified by aws_route_table.public.id.
}

resource "aws_eip" "nat" { // Allocate a static IP address

}

resource "aws_nat_gateway" "public" {
  depends_on = [ aws_internet_gateway.ig ] // Only when the internet gateway is fully deployed will the nat getway be deployed
  allocation_id = aws_eip.nat.id // Allocate a static IP address form block aws_eip
  subnet_id = aws_subnet.public_subnet[0].id // connect with public_subnet[0]

  tags = {
    Name = "Public_NAT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public.id
  }

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "private_subnet" {
  for_each = {for k, v in aws_subnet.private_subnet : k => v}
  subnet_id = each.value_id
  route_table_id  = aws_route_table.private.id
}
