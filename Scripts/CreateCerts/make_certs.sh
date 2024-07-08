#!/bin/sh

echo ""
echo "Setting up server.cnf."
echo "Please enter the Hostname or IP address of your server."
read IP
sed -i -e "s/<SERVER_IP>/$IP/g" server.cnf
echo "Done."
echo ""

echo ""
echo "Setting up certificates for MDM server testing!"
echo ""
echo "1. Creating Certificate Authority (CA)"
echo " ** For 'Common Name' enter something like 'MDM Test CA'"
echo " ** Create and a remember the PEM pass phrase for use later on"
echo ""
openssl req -new -x509 -extensions v3_ca -keyout cakey.key -out cacert.crt -days 365

echo ""
echo "2. Creating the Web Server private key and certificate request"
echo " ** For 'Common Name' enter your server's IP address **"
echo ""
openssl genrsa 2048 > server.key
openssl req -new -key server.key -out server.csr

echo ""
echo "3. Signing the server key with the CA. You'll use the PEM pass phrase from step 1."
echo ""
openssl x509 -req -days 365 -in server.csr -CA cacert.crt -CAkey cakey.key -CAcreateserial -out server.crt -extfile ./server.cnf -extensions ssl_server



echo ""
echo "4. Creating the device Identity key and certificate request"
echo " ** For 'Common Name' enter something like 'my device'"
echo ""
openssl genrsa 2048 > identity.key
openssl req -new -key identity.key -out identity.csr

echo ""
echo "5. Signing the identity key with the CA. You'll the PEM pass phrase from step 1."
echo " ** Create an export passphrase. You'll need to include it in the IPCU profile."
echo ""
openssl x509 -req -days 365 -in identity.csr -CA cacert.crt -CAkey cakey.key -CAcreateserial -out identity.crt
openssl pkcs12 -legacy -export -out identity.p12 -inkey identity.key -in identity.crt -certfile cacert.crt



echo ""
echo "6. Copying keys and certs to server folder"
# Move relevant certs to the /server/ directory
mv server.key ../../Resources/Certs/Server.key
mv server.crt ../../Resources/Certs/Server.crt
mv cacert.crt ../../Resources/Certs/CA.crt
mv identity.crt ../../Resources/Certs/identity.crt
cp identity.p12 ../../Resources/Certs/Identity.p12
