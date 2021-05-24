#!/bin/bash
# NOTE: If we can gaurantee that telegraf base will be in $HOME/telegraf this can be simplified
#       Else, pass telegraf's root directory as argument 1
if [ $# -ne 0 ]; then
    telegraf_dir=$1
else
    telegraf_dir=$HOME/telegraf
mkdir ~/daap_certs
cd ~/daap_certs
echo 01 > ./serial &&
mkdir certs_by_serial &&
touch ./index.txt &&
cat >./openssl.conf <<EOF
[ ca ]
default_ca = daap_ca

[ daap_ca ]
certificate = ./cacert.pem
database = ./index.txt
new_certs_dir = ./certs_by_serial
private_key = ./cakey.pem
serial = ./serial

default_crl_days = 3650
default_days = 3650
default_md = sha256

policy = daap_ca_policy
x509_extensions = certificate_extensions

[ daap_ca_policy ]
commonName = supplied

[ certificate_extensions ]
basicConstraints = CA:false

[ req ]
default_bits = 1024
default_keyfile = ./cakey.pem
default_md = sha256
prompt = yes
distinguished_name = root_ca_distinguished_name
x509_extensions = root_ca_extensions

[ root_ca_distinguished_name ]
commonName = hostname

[ root_ca_extensions ]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

[ client_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature
subjectAltName = @client_alt_names
extendedKeyUsage = 1.3.6.1.5.5.7.3.2

[ client_alt_names ]
DNS.1 = localhost
IP.1 = 127.0.0.1

[ server_ca_extensions ]
basicConstraints = CA:false
subjectAltName = @server_alt_names
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage = 1.3.6.1.5.5.7.3.1

[ server_alt_names ]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF
openssl req -x509 -config ./openssl.conf -days 3650 -newkey rsa:1024 -out ./cacert.pem -keyout ./cakey.pem -subj "/CN=DAAP CA/" -nodes &&

# Create server keypair
openssl genrsa -out ./server_key.pem 1024 &&
openssl req -new -key ./server_key.pem -out ./servercsr.pem -outform PEM -subj "/CN=server.localdomain/O=server/" &&
openssl ca -config ./openssl.conf -in ./servercsr.pem -out ./server_cert.pem -notext -batch -extensions server_ca_extensions &&

# Create client keypair
openssl genrsa -out ./client_key.pem 1024 &&
openssl req -new -key ./client_key.pem -out ./clientcsr.pem -outform PEM -subj "/CN=client.localdomain/O=client/" &&
openssl ca -config ./openssl.conf -in ./clientcsr.pem -out ./client_cert.pem -notext -batch -extensions client_ca_extensions

cd $telegraf_dir
sed -i.bkup -e "s/\/hng\//\/${USER}\//" telegraf-agg.conf
sed -i.bkup -e "s/\/hng\//\/${USER}\//" telegraf-client.conf
rm -f telegraf-agg.conf.bkup
rm -f telegraf-client.conf.bkup
