#!/bin/bash

echo "Preferred hostname:"
read hostname

echo "System ip address:"
read ip_address

#Updating the system
sudo yum update -y && sudo yum upgrade -y

#Setting the hostname of the machine
sudo hostnamectl set-hostname $hostname     <--- To be edited

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

#Installing kubelet, kubeadm and kubectl
sudo yum install -y kubelet kubeadm kubectl
systemctl enable kubelet
systemctl start kubelet

#Setting up the firewall rules
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd --reload

#Updating the Iptables Settings
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

#Disbale SELinux
sudo setenforce 0
sudo sed -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

#Disable SWAP
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

#Adding the an entry to the hosts file
sed -i -e '$a$ip_address $hostname' /etc/hosts

#Pulling configuration images
sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock

#Creating the master-node
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --upload-certs --control-plane-endpoint=$hostname