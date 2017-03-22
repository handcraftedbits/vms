# curtisshoward.com and handcraftedbits.com VM

The VM for [https://curtisshoward.com](curtisshoward.com) and [https://handcraftedbits.com](handcraftedbits.com).

# Configuration

## Variables

### VM

Rename `variables-digitalocean.json.template` to `variables-digitalocean.json` and set

* `digitalocean-apitoken`
* `vm-password`
* `vm-publickey`
* `vm-user-fullname`
* `vm-username`

### Docker

Rename `environment.properties.template` to `environment.properties` and set

* `HUGO_GITHUB_SECRET`

## Certificates

Copy `/etc/letsencrypt` to `data/etc/letsencrypt` (also, fix ownership):

```bash
mkdir -p data/etc && cp -R /etc/letsencrypt data/etc/letsencrypt
```

## dhparam.pem

Make a link from `/etc/ssl/dhparam.pem` to `data/etc/ssl/dhparam.pem`:

```bash
mkdir -p data/etc/ssl && ln -sf /etc/ssl/dhparam.pem data/etc/ssl/dhparam.pem
```

# Usage

Provision the VM, from the `packer` subdirectory:

```bash
packer build -var-file=../curtisshoward.com/variables-digitalocean.json -var 'playbook=ansible/docker-host.yml' -only=digitalocean vm-ubuntu1604.json
```