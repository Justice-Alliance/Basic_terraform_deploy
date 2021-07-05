output "vpc_cidr" {
    value = aws_vpc.module_vpc.cidr_block         
}
  
output "public_subnet_1_cidr" {
    value = aws_subnet.module_public_subnet_1.cidr_block
}

output "private_subnet_1_cidr" {
    value = aws_subnet.module_private_subnet_1.cidr_block 
}