output "vpc_id" {

    value = aws_vpc.main.id
}



output "public_subnet" {

    value = aws_subnet.public[*].id
}

output "public_cidr" {

    value = aws_subnet.public[*].cidr_block
}

output "private_subnet" {

    value = aws_subnet.private.id
}


output "private_route_zomato" {

    value = aws_route_table.private1[*].id
}

output "private_route_uber" {

    value = aws_route_table.private2[*].id
}

output "public" {

    value = aws_route_table.public.id
}