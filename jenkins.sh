#!/bin/bash

echo "Enter hostname:"
read hostname


#Setting the hostname of the machine
sudo hostnamectl set-hostname $hostname

#Upgrading system
sudo yum update -y && sudo yum upgrade -y

#Getting the jenkins repo and importing it.
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum upgrade -y

#Installing the jenkins package.
sudo yum install epel-release java-11-openjdk-devel -y
sudo yum install jenkins -y

#Setting up the systemctl
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

#Setting up firewall rules.
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload

sleep 20

#Get the jenkins admin password
cat /var/lib/jenkins/secrets/initialAdminPassword