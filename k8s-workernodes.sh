#!/bin/bash

KUBERNETES_VERSION=v1.29

sudo swapoff -a
sudo ufw disable

#Install Packages
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br-netfilter
EOF

sudo modprobe overlay
sudo modprobe br-netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#Install container runtime
sudo apt-get update && sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo sysctl --system

sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

#Add worker node to cluster
kubeadm join 10.0.13.179:6443 --token p5dsbj.7q4l32tmedduy71z --discovery-token-ca-cert-hash sha256:f8669c64b8cb903ed31e769d0c4a49ff84f7fe446476119ea2267855c1571ab1

