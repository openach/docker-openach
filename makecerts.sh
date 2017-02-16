#/bin/bash
openssl req -x509 -nodes -days 365 -newkey rsa:4086 -keyout ./setup.d/etc/ssl/openach-self-signed.key -out ./setup.d/etc/ssl/openach-self-signed.crt
