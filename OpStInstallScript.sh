sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo -u stack -i <<EOF
git clone https://opendev.org/openstack/devstack
cd devstack
sudo echo -e "[[local|localrc]]\nADMIN_PASSWORD=nomoresecret\nDATABASE_PASSWORD=nomoresecret\nRABBIT_PASSWORD=nomoresecret\nSERVICE_PASSWORD=nomoresecret" >> local.conf
./stack.sh
EOF
