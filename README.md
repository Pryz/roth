# Use puppet in DMZ

Work in progress

## Purpose 
    Give the possibility for DMZ server to use Puppet manifests.
    Using Git workflow

## The workflow
    Developper -> modules-dmz
    modules-dmz --- git push remote dmz ---> dmz machine
    dmz machine = puppet apply

## Cli commands example

[TODO]

## Create roth user

    $ useradd roth
    $ usermod -d /etc/puppet roth
    $ usermod -aG puppet roth
    $ cat ~/.ssh/id_rsa.pub | ssh root@hostname \
     'cat >> ~roth/.ssh/authorized_keys'

## Masterless

    - Open SSH session
    - git clone of the Puppet module and manifest
    - puppet apply

## With master

    - Open SSH tunnel
    - Run puppet agent --test
