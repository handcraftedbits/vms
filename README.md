# Personal VMs

Configuration for personal VMs that are provisioned with [Packer](https://www.packer.io) and
[Ansible](https://www.ansible.com).  VMs can be created on [DigitalOcean](https://www.digitalocean.com) or
[VMWare ESXi](https://www.vmware.com/products/vsphere-hypervisor.html).

# Usage

## Creating VMs

Run Packer from the `packer` subdirectory:

```shell
packer build -var-file=../<hostname>/variables-[digitalocean|esxi].json -var 'playbook=ansible/<role>.yml' -only=[digitalocean|vmware-iso] <packerfile> 
```

## Properties for File Specified via `-var-file`

| Property                  | Description                                                                                                             | VM Host      | Ansible Role |
| :------------------------ | :---------------------------------------------------------------------------------------------------------------------- | :----------- | :----------- |
| datastore-cache-directory | The directory where the ISO cache should be stored                                                                      | ESXi         |              |
| datastore-cache-name      | The name of the data store where the ISO cache should be stored                                                         | ESXi         |              |
| datastore-name            | The name of the data store where the VM will be created                                                                 | ESXi         |              |
| digitalocean-apitoken     | The DigitalOcean API key to use                                                                                         | DigitalOcean |              |
| digitalocean-region       | The DigitalOcean region to use (see [API documentation](https://developers.digitalocean.com/documentation/v2/#regions)) | DigitalOcean |              |
| disk-size                 | The size of the disk to create for the VM                                                                               | ESXi         |              |
| esxi-host                 | The hostname of the ESXi server                                                                                         | ESXi         |              |
| esxi-password             | The password for the ESXi server                                                                                        | ESXi         |              |
| esxi-port                 | The port used by the ESXi server                                                                                        | ESXi         |              |
| esxi-username             | The username for the ESXi server                                                                                        | ESXi         |              |
| extra-ports               | Additional ports to let through the firewall, comma-separated                                                           | Both         | secured      |
| git-email                 | The e-mail address for the default Git user                                                                             | Both         | development  |
| git-name                  | The name for the default Git user                                                                                       | Both         | development  |
| github-id                 | The GitHub ID to use                                                                                                    | Both         | development  |
| github-key-passphrase     | The GitHub SSH key passphrase to use                                                                                    | Both         | development  |
| ssh-port                  | The SSH port to use                                                                                                     | Both         | secured      |
| vm-cpus                   | The number of virtual CPUs to use                                                                                       | ESXi         |              |
| vm-mem                    | The amount of RAM (in MB) to allocate for the VM                                                                        | Both         |              |
| vm-name                   | The hostname of the VM                                                                                                  | Both         |              |
| vm-network                | The name of the virtual network to use                                                                                  | ESXi         |              |
| vm-password               | The password for the `vm-username` account, encrypted with `mkpasswd --method=sha-512`                                  | Both         |              |
| vm-password-raw           | The password for the `vm-username` account, unencrypted                                                                 | ESXi         |              |
| vm-publickey              | The public key used for SSH connections                                                                                 | Both         | secured      |
| vm-user-fullname          | The full name of the user account to create                                                                             | Both         |              |
| vm-username               | The user account to create                                                                                              | Both         |              |  |

## Available `<role>`s

| Name        | Description                                                                                             |
| :---------- | :------------------------------------------------------------------------------------------------------ |
| development | Standard HandcraftedBits development environment                                                        |
| docker-host | Bare-bones environment that auto-starts Docker services specified in `../<hostname>/docker-compose.yml` |

## Available `<packerfile>`s

| Name          | Description                                       |
| :------------ | :------------------------------------------------ |
| vm-ubuntu1604 | Ubuntu [16.04](http://releases.ubuntu.com/16.04/) |
