#!/bin/sh
###### Terraform command options ######
while true; do
echo "Terraform command options: "
echo "1.  Terraform init"
echo "2.  Terrafom plan"
echo "3.  Terraform apply"
echo "4.  Terraform init + plan"
echo "5.  Terraform init + plan + apply"
echo "6.  Terraform init + apply"
echo "7.  Terraform plan + apply"
echo "0.  Exit"
echo

echo -n "Enter your choice, or 0 for exit: "
read choice
echo 

case $choice in
     1)
        terraform init
     ;;
     2)
        terraform plan
     ;;
     3)
        terraform apply
     ;;
     4)
        terraform init
        terraform plan
     ;;
     5)
        terraform init
        terraform plan
        terraform apply
     ;;
     6)
        terraform init
        terraform apply
     ;;
     7)
        terraform plan
        terraform apply
     ;;
     0)
        echo "EXIT!"
        break
     ;;
     *)
        echo "That is not a valid choice, try a number from 0 to 7."
     ;;
esac  
done