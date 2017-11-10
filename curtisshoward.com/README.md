# curtisshoward.com and handcraftedbits.com VM

The VM for [https://curtisshoward.com](curtisshoward.com) and [https://handcraftedbits.com](handcraftedbits.com).

# Configuration

## Variables

### Docker

Rename `provision_data/environment.properties.template` to `provision_data/environment.properties` and set

* `HUGO_GITHUB_SECRET`

## Certificates

Copy `/etc/letsencrypt` to `provision_data/data/etc/letsencrypt` (also, fix ownership):

```bash
mkdir cp -R /etc/letsencrypt provision_data/data/etc/letsencrypt
```

## dhparam.pem

Make a link from `/etc/ssl/dhparam.pem` to `provision_data/data/etc/ssl/dhparam.pem`:

```bash
mkdir -p data/etc/ssl && ln -sf /etc/ssl/dhparam.pem provision_data/data/etc/ssl/dhparam.pem
```

## Post-provisioing

DigitalOcean always adds `PasswordAuthentication yes` to `/etc/ssh/sshd_config`, so manually disable that after the VM
has been provisioned.