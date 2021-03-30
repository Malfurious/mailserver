# malfurious/mailserver

### What is this ?

Simple and full-featured mail server as a set of multiple docker images includes :

- **Postfix** : a full set smtp email server supporting custom rules
- **Dovecot** : secure imap and pop3 email server
- **Rspamd** : anti-spam filter with SPF, DKIM, DMARC, ARC, ratelimit and greylisting capabilities
- **Clamav** : antivirus with automatic updates
- **Zeyple** : automatic GPG encryption of all your e-mails
- **Sieve** : email filtering (vacation auto-responder, auto-forward...etc)
- **Fetchmail** : fetch e-mails from external IMAP/POP3 server into local mailbox
- **Unbound**: recursive caching DNS resolver with DNSSEC support
- **NSD** : authoritative DNS server with DNSSEC support
- **SSL** : lets encrypt, custom and self-signed certificates support
- Supporting multiple virtual domains over MySQL backend
- Integration tests with Travis CI
- Automated builds on DockerHub
- Redis Server Cache Built-In

#### Important Note
This docker was built to be used with malfurious/roundcube-postfixadmin.
Goto https://github.com/Malfurious/roundcube-postfixadmin for more information!

### System Requirements

Please check, if your system meets the following minimum system requirements :

| Type | Without ClamAV | With ClamAV |
| ---- | -------------- | ----------- |
| CPU | 1 GHz | 1 GHz |
| RAM | 1 GiB | 2 GiB |
| Disk | 5 GiB (without emails) | 5 GiB (without emails) |
| System | x86_64 | x86_64 |


### Environment variables

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **UID** | postfixadmin user id | *optional* | 991
| **GID** | postfixadmin group id | *optional* | 991
| **MYSQL_HOST** | MariaDB instance ip/hostname | **required** | null
| **POST_USER** | MariaDB Postfix username | *optional* | postfix
| **POST_PASS** | MariaDB Postfix password | **required** | null
| **POST_DB** | MariaDB Postfix Database Name | *optional* | postfix
| **MAIL_HOST** | Mail Server Name | **required** | mail.domain.com
| **RSPAMD_PASSWORD** | Rspamd WebUI and controller password | **required** | null
| **PASS_CRYPT** | Passwords encryption method | *optional* | `SHA512-CRYPT`
| **ADD_DOMAINS** | Add additional domains to the mailserver separated by commas (needed for dkim keys etc.) | *optional* | null
| **RELAY_NETWORKS** | Additional IPs or networks the mailserver relays without authentication | *optional* | null
| **DISABLE_CLAMAV** | Disable virus scanning | *optional* | false
| **DISABLE_SIEVE** | Disable ManageSieve protocol | *optional* | false
| **DISABLE_SIGNING** | Disable DKIM/ARC signing | *optional* | false
| **DISABLE_GREYLISTING** | Disable greylisting policy | *optional* | false
| **DISABLE_RATELIMITING** | Disable ratelimiting policy | *optional* | false
| **ENABLE_POP3** | Enable POP3 protocol | *optional* | false
| **ENABLE_FETCHMAIL** | Enable fetchmail forwarding | *optional* | false
| **FETCHMAIL_INTERVAL** | Fetchmail polling interval | *optional* | 10
| **RECIPIENT_DELIMITER** | RFC 5233 subaddress extension separator (single character only) | *optional* | +
| **VMAILUID** | vmail user id | *optional* | 1024
| **VMAILGID** | vmail group id | *optional* | 1024
| **VMAIL_SUBDIR** | Individual mailbox' subdirectory | *optional* | mail
| **OPENDKIM_KEY_LENGTH** | Size of your DKIM RSA key pair | *optional* | 1024

* **VMAIL_SUBDIR** is the mail location subdirectory name `/var/mail/vhosts/%domain/%user/$subdir`. For more information, read this : https://wiki.dovecot.org/VirtualUsers/Home
* **PASSWORD_SCHEME** for compatible schemes, read this : https://wiki.dovecot.org/Authentication/PasswordSchemes
* Currently, only a single **RECIPIENT_DELIMITER** is supported. Support for multiple delimiters will arrive with Dovecot v2.3.
* **FETCHMAIL_INTERVAL** must be a number between **1** and **59** minutes.

### Relaying from other networks

The **RELAY_NETWORKS** is a space separated list of additional IP addresses and subnets (in CIDR notation) which the mailserver relays without authentication. Hostnames are possible, but generally disadvised. IPv6 addresses must be surrounded by square brackets. You can also specify an absolut path to a file with IPs and networks so you can keep it on a mounted volume. Note that the file is not monitored for changes.

You can use this variable to allow other local containers to relay via the mailserver. Typically you would set this to the IP range of the default docker bridge (172.17.0.0/16) or the default network of your compose. If you are unable to determine, you might just add all RFC 1918 addresses `192.168.0.0/16 172.16.0.0/12 10.0.0.0/8`

:warning: A value like `0.0.0.0/0` will turn your mailserver into an open relay!

### SSL certificates

#### Let's Encrypt certificate authority

This mail setup uses 4 domain names that should be covered by your new certificate :
#### Domains for Malfurious/Mailserver
* **mail.domain.com** (mandatory)
* **spam.domain.com** (recommended)
#### Domains if also using Malfurious/roundcube-postfixadmin
* **postfix.domain.com** (recommended)
* **webmail.domain.com** (optional)

To use the Let's Encrypt certificates, you need to add a volume mount to the mailserver docker:
- **/mnt/docker/nginx/certs:/etc/letsencrypt**

And request the certificate with [xataz/letsencrypt](https://github.com/xataz/docker-letsencrypt) or [cerbot](https://certbot.eff.org/) :
```
docker run -it --rm \
  -v /mnt/docker/nginx/certs:/etc/letsencrypt \
  -p 80:80 -p 443:443 \
  xataz/letsencrypt \
    certonly --standalone \
    --rsa-key-size 4096 \
    --agree-tos \
    -m contact@domain.com \
    -d mail.domain.com \ # <--- Mail FQDN is the first domain name, very important !
    -d webmail.domain.com \
    -d postfix.domain.com \
    -d spam.domain.com
```

### Email client settings :

- IMAP/SMTP username : user@domain.com
- Incoming IMAP server : mail.domain.com (your FQDN)
- Outgoing SMTP server : mail.domain.com (your FQDN)
- IMAP port : 993
- SMTP port : 587
- IMAP Encryption protocol : SSL/TLS
- SMTP Encryption protocol : STARTTLS

#### Installation (Manually, not using UnRAID Template)
Run the following command to pull the latest image: 'docker pull malfurious/mailserver:latest'
Now, Run this to start the docker:
```
docker run -d --name=mailserver \
  -p 25:25 -p 143:143 -p 587:587 -p 993:993 -p 4190:4190 -p 11334:11334 \
  -e MAIL_HOST=mail.domain.com -e POST_USER=postfix -e POST_PASS=password \
  -e POST_DB=postfix -e MYSQL_HOST=mariadb_ipaddress -e RSPAMD_PASSWORD=password \
  -v /mnt/docker/mailserver:/var/mail -v /mnt/docker/redis:/data \
  malfurious/mailserver:latest
```

#### If you get the "Container IP not found with embedded DNS server..." Error
If your error is in regards to the MariaDB/MySQL database container, add the following as an extra argument in Unraid. 
```
--add-host mariadb:<IP of your SQL Container>
```
If your error is in regards to the redis database container, add the following as an extra argument in Unraid. Note: Redis is included by default in this image.
```
--add-host redis:127.0.0.2
```
If you are hosting your own Redis just change that IP address to the one of your Redis. You can have both of these add host lines as below.
```
--add-host mariadb:<IP of your SQL Container> --add-host redis:127.0.0.2
```
#### For a Guide on setting up a Reverse Proxy with SSL Certificates, follow the link below!
https://github.com/Malfurious/mailserver/wiki/Reverse-Proxy-Configuration
#### Setup Complete!

## Credits
All credit for the actual mailserver part of this docker goes to Hardware, I merely integrated the Redis server, and made it usable on UnRAID Servers via a template. Follow the link below to view his original project.

