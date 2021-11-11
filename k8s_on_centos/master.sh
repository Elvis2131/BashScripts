#!/bin/bash

echo "Preferred hostname:"
read hostname

echo "System ip address:"
read ip_address

#Updating the system
sudo yum update -y && sudo yum upgrade -y

#Setting the hostname of the machine
sudo hostnamectl set-hostname $hostname

#Installing containerd
sudo wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
sudo yum localinstall containerd.io-1.2.6-3.3.el7.x86_64.rpm -y

#Enabling the containerd runtime for runtime
sudo systemctl start containerd
sudo systemctl enable containerd

#Setting up the k8s repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo yum -y update
#Installing kubelet, kubeadm and kubectl
sudo yum install -y kubelet kubeadm kubectl
systemctl enable kubelet
systemctl start kubelet

#Setting up the firewall rules
sudo systemctl disable firewalld
sudo systemctl stop firewalld

sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Enable kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Add some settings to sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sudo sysctl --system

# Configure persistent loading of modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Load at runtime
sudo modprobe overlay
sudo modprobe br_netfilter

# Ensure sysctl params are set
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload configs
sudo sysctl --system

sudo mkdir -p /etc/containerd
sudo containerd config default>/etc/containerd/config.toml


sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock