#!/usr/bin/env python3

import argparse
import plistlib
import os
import subprocess
from base64 import b64encode
import sys
import urllib.request

def p(s):
    sys.stdout.write(s)
    sys.stdout.flush()

def mdm_vendor_sign():
    """
    This utility will create a properly encoded certificate signing request
    that you can upload to identity.apple.com/pushcert
    """

    parser = argparse.ArgumentParser(description=mdm_vendor_sign.__doc__)
    parser.add_argument('--key', help='Private key', required=True)
    parser.add_argument('--csr', help='Certificate signing request', required=True)
    parser.add_argument('--mdm', help='MDM vendor certificate', required=True)
    parser.add_argument('--out', help='Output filename', required=False)

    cli_args = vars(parser.parse_args())

    # Verify CSR
    # openssl req -text -noout -verify -in CSR.csr
    p(f'Verifying {cli_args["csr"]} ... ')
    with open(cli_args['csr'], 'rb') as csr_file:
        csr_data = csr_file.read()
    args = ['openssl', 'req', '-noout', '-verify', '-in', cli_args['csr']]
    command = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = command.communicate()
    if error or b'verify OK' not in output:
        p('FAILED\n')
        print(f'Error: {error.decode("utf-8")}')
        return
    p('OK\n')

    # Verify private key
    # openssl rsa -in privateKey.key -check
    p(f'Verifying {cli_args["key"]} ... ')
    with open(cli_args['key'], 'rb') as key_file:
        key_data = key_file.read()
    args = ['openssl', 'rsa', '-check', '-noout', '-in', cli_args['key']]
    command = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = command.communicate()
    if error or b'RSA key ok' not in output:
        p('FAILED\n\n')
        print(f'Error: {error.decode("utf-8")}')
        print("""If you don't have the plain private key already, you need
to extract it from the pkcs12 file...

First convert to PEM
openssl pkcs12 -in filename.p12 -nocerts -out key.pem

Then export the certificate file from the pfx file
openssl pkcs12 -in filename.pfx -clcerts -nokeys -out cert.pem

Lastly Remove the passphrase from the private key
openssl rsa -in key.pem -out the_private_key.key
""")
        return
    p('OK\n')

    # Verify MDM vendor certificate
    # openssl x509 -noout -in mdm.cer -inform DER
    p(f'Verifying {cli_args["mdm"]} ... ')
    with open(cli_args['mdm'], 'rb') as mdm_cert_file:
        mdm_cert_data = mdm_cert_file.read()
    args = ['openssl', 'x509', '-noout', '-inform', 'DER', '-in', cli_args['mdm']]
    command = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = command.communicate()
    if error or len(output) != 0:
        p('FAILED\n')
        print(f'Error: {error.decode("utf-8")}')
        return
    p('OK\n')

    # Convert CSR to DER format
    # openssl req -inform pem -outform der -in customer.csr -out customer.der
    p(f'Converting {cli_args["csr"]} to DER format... ')
    args = ['openssl', 'req', '-inform', 'pem', '-outform', 'der', '-in', cli_args['csr']]
    command = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    csr_der, error = command.communicate()
    if error:
        p('FAILED\n')
        print(f'Error: {error.decode("utf-8")}')
        return
    p('OK\n')
    csr_b64 = b64encode(csr_der)

    # Sign the CSR with the private key 
    # openssl sha1 -sign private_key.key -out signed_output.rsa data_to_sign.txt
    p('Signing CSR with private key... ')
    args = ['openssl', 'sha1', '-sign', cli_args['key']]
    command = subprocess.Popen(args, stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    signature_bytes, error = command.communicate(input=csr_der)
    if error:
        p('FAILED\n')
        print(f'Error: {error.decode("utf-8")}')
        return
    p('OK\n')
    signature = b64encode(signature_bytes)

    def cer_to_pem(cer_data):
        # openssl x509 -inform der -in mdm.cer -out mdm.pem
        # -in and -out flags are handled by STDIN and STDOUT
        args = ['openssl', 'x509', '-inform', 'der']
        command = subprocess.Popen(args, stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
        output, error = command.communicate(input=cer_data)
        if error:
            p(f'Error converting from cer to pem: {error.decode("utf-8")}')
        return output

    # Download and convert intermediate and root certificates
    p('Downloading WWDR intermediate certificate...')
    with urllib.request.urlopen('https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer') as response:
        intermediate_cer = response.read()
    p(' converting to pem...')
    intermediate_pem = cer_to_pem(intermediate_cer)
    p('OK\n')

    p('Downloading Apple Root Certificate...')
    with urllib.request.urlopen('http://www.apple.com/appleca/AppleIncRootCertificate.cer') as response:
        root_cer = response.read()
    p(' converting to pem...')
    root_pem = cer_to_pem(root_cer)
    p('OK\n')

    mdm_pem = cer_to_pem(mdm_cert_data)

    p('Finishing...')
    plist_dict = {
        'PushCertRequestCSR': csr_b64.decode('utf-8'),
        'PushCertCertificateChain': (mdm_pem + intermediate_pem + root_pem).decode('utf-8'),
        'PushCertSignature': signature.decode('utf-8')
    }
    plist_xml = plistlib.dumps(plist_dict)
    plist_b64 = b64encode(plist_xml)

    output_filename = cli_args['out'] if cli_args['out'] else 'plist_encoded'
    write_path = os.path.join(os.getcwd(), output_filename)
    with open(write_path, 'wb') as output_file:
        output_file.write(plist_b64)
    p(f'DONE\n\nGo upload file \'{output_filename}\' to identity.apple.com/pushcert !\n')

if __name__ == "__main__":
    mdm_vendor_sign()
