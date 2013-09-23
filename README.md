# Use puppet in DMZ

## Purpose 
    Give the possibility for DMZ server to use Puppet manifests.

## The workflow
    Developper -> modules-dmz
    modules-dmz --- git push remote dmz ---> dmz machine
    dmz machine = puppet apply

## Cli commands example

    $ roth apply dmz1.domain.local sudoers
    $ roth getlog dmz1.domain.local
    $ roth pushonly dmz1.domain.local sudoers
    $ roth applyonly dmz1.domain.local sudoers

## Create roth user

    $ useradd roth
    $ usermod -d /etc/puppet roth
    $ usermod -aG puppet roth
    $ cat ~/.ssh/id_rsa.pub | ssh root@ctsr0523.vallourec.net \
     'cat >> ~roth/.ssh/authorized_keys'

## Masterless

    - Open SSH session
    - git clone of the Puppet module and manifest
    - puppet apply

## With master

    - Open SSH tunnel
    - Run puppet agent --test
