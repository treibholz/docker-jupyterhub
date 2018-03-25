#!/bin/bash
set -e

STORE_SYSTEM_USERS="${KEEP_SYSTEM_USERS:-false}"

if [[ ${STORE_SYSTEM_USERS} == "true" ]]; then
    if [[ -d "/srv/jupyterhub/_etc" ]]; then
        cp -a /srv/jupyterhub/_etc/* /etc
        echo "session required pam_mkhomedir.so umask=0022 skel=/etc/skel" >> /etc/pam.d/common-session
        echo "c.LocalAuthenticator.create_system_users = True" >> /etc/jupyterhub/jupyterhub_config.py
    else
        mkdir -p /srv/jupyterhub/_etc
    fi
fi

/usr/local/bin/jupyterhub ${@}

if [[ ${STORE_SYSTEM_USERS} == "true" ]]; then
    cp /etc/passwd /etc/group /etc/shadow /srv/jupyterhub/_etc/
fi
