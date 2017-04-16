#/bin/bash
openssl req -x509 -nodes -days 365 -newkey rsa:4086 -keyout ssl/openach/openach-self-signed.key -out ssl/openach/openach-self-signed.crt
echo 
echo "Ready to install new key and cert as ssl/openach/openach.key and ssl/openach/openach.crt"
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo
    rm -rf ssl/openach/openach.crt ssl/openach/openach.key
    cd ssl/openach/ && \
        ln -s openach-self-signed.key openach.key && \
        ln -s openach-self-signed.crt openach.crt
    cd ../..
    echo "Installed new SSL key as:  ssl/openach/openach.key"
    echo "Installed new SSL cert as: ssl/openach/openach.crt"
    echo "NOTE: You will need to restart your containers for the change to take effect."
else
    echo "Generated the keys, but they are not installed.  You will need to symlink (or copy) them to ssl/openach/openach.key and ssl/openach/openach.crt"
fi
