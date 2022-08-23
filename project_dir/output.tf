output "cidr_zomato" {

    value = module.vpc[0].vpc_id
}

output "cidr_uber" {

    value = module.vpc[1].vpc_id
}

output "public_subnet_zomato" {

    value = module.vpc[0].public_subnet[*]
}

output "public_subnet_uber" {

    value = module.vpc[1].public_subnet[*]
}

output "private_subnet_zomato" {

    value = module.vpc[0].private_subnet
}

output "private_subnet_uber" {

    value = module.vpc[1].private_subnet
}

output "zomato_private" {

    value = module.vpc[0].private_route_zomato
}

output "public_route_zomato" {

    value = module.vpc[0].public
}

output "private_route_zomato" {

    value = module.vpc[0].private_route_zomato
}

output "public_route_uber" {

    value = module.vpc[1].public
}

output "private_route_uber" {

    value = module.vpc[1].private_route_uber
}

output "vpc_id_zomato" {

    value = module.vpc[0].vpc_id
}

output "vpc_id_uber" {

    value = module.vpc[1].vpc_id
}

output "zomatoprivateroute" {

    value = module.vpc[0].private_route_zomato[0]
}


output "zomato_pub_cidr" {

    value = module.vpc[0].public_cidr[*]
}