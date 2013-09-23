#!/usr/bin/env ruby
# encoding: utf-8
# Author:: Pryz (<ju.pryz@gmail.com>)
# Date:: 2013-09-09 23:48:36 +0200

require 'pathname'
require 'net/ssh'
require 'thor'
require 'highline/import'

# Load the module either with gem or with local resource
begin
  require 'roth'
  require 'roth_common'
rescue LoadError
  $: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'roth'
  require 'roth_common'
end

# To run the tool need a user named 'roth'
# with the homedir : /etc/puppet
# and the sudoers : roth ALL=(ALL) NOPASSWD:ALL
module Roth
  class Cli < Thor
  
    include Roth::Settings
  
    def initialize(*args)
      super
      @root = Pathname.new(Dir.getwd)
      @puppetfolder = Roth::Settings::PUPPET[:folder]
      @modulesfolder = Roth::Settings::PUPPET[:modfolder]
      @password = Roth::Settings::USER[:password]
      @ssh = Roth::SSH.new
    end
  
    # Say hello to the world
    desc "hello NAME", "Say hello to NAME :)"
    def hello(name)
      puts "Hello #{name}"
    end
  
    desc "apply NODE MODULE", "Push and apply a module against a node"
    option :url
    option :user
    def apply(node, modulename)
      puts "Apply #{modulename} on #{node}"
      # Connect to the node in SSH
      user ||= options[:user]
      @ssh.start_ssh node, user
 
      # Get the module 
      if is_module_presents? modulename
        cmd = "cd #{@puppetfolder}/#{@modulesfolder}/#{modulename};sudo git pull"
      else
        # Retrieve the Git url from the modulefolder
        url = options[:url].nil? ? get_module_url(modulename) : options[:url]
        cmd = "sudo git clone #{url} #{@puppetfolder}/#{@modulesfolder}/#{modulename}"
      end
      puts "--- Execute #{cmd}"
      r = @ssh.do_ssh_cmd(cmd)
      Roth::SSH.print_std r
      if r[:exit_code] == 0
        abort "ERROR : Manifest site.pp is missing" unless is_manifest_exists?
        # puppet apply
        r_apply = @ssh.do_ssh_cmd("puppet apply --modulepath #{@modulesfolder} manifests/site.pp")
        puts "--- Execute puppet apply"
        Roth::SSH.print_std r_apply
      else
        Roth::SSH.print_std r
      end
    end
  
    # Clone/Update Puppet module
    desc "get_puppet_module NODE URL MODULE", "Push MODE to NODE"
    option :user
    def get_puppet_module(node, url, modulename)
      user ||= options[:user]
      start_ssh node, user
  
      if is_module_presents? modulename
        puts "Pull the #{modulename} repository"
        cmd = "cd #{@puppetfolder}/#{@modulesfolder}/#{modulename};sudo git pull"
      else
        puts "Clone #{modulename} from #{url}"
        cmd = "sudo git clone #{url} #{@puppetfolder}/#{@modulesfolder}/#{modulename}"
      end
      r = @ssh.do_ssh_cmd(cmd)
      puts r
      close_ssh
    end
  
    # Delete the specified Puppet module on the specified node
    desc "del_puppet_module NODE URL MODULE", "Delete MODULE from NODE"
    option :user
    def del_puppet_module(node, url, modulename)
      user ||= options[:user]
      start_ssh node, user
  
      if is_module_presents? modulename
        r = @ssh.do_ssh_cmd(
          "rm -rf #{@puppetfolder}/#{@modulesfolder}/#{modulename}"
        )
        puts "Module #{modulename} deleted" if r[:exit_code].eql? 0
      end
      close_ssh
    end
  
    # Apply Puppet site.pp manifest
    desc "do_puppet_apply NODE", "Execute puppet apply against manifests/site.pp file on NODE"
    option :user
    option :debug
    def do_puppet_apply(node)
      user ||= options[:user]
      start_ssh node, user
  
      apply = "sudo puppet apply -l /tmp/manifest.log manifests/site.pp"
      apply = "#{apply} --debug" if options[:debug]
      @ssh.do_ssh_cmd(apply) if is_manifest_exists?
      close_ssh
    end  
  
    private
  
    
    def get_module_url(modulename)
      "https://github.com/Pryz/puppet-vim.git"
    end
  
    # Check if the Puppet module exists
    def is_module_presents?(modulename)
      abort "No ssh session found" if @ssh.nil?
      r = @ssh.do_ssh_cmd(
        "ls #{@puppetfolder}/#{@modulesfolder}/#{modulename}"
      )
      r[:exit_code] == 0 ? true : false
    end
  
    # Check the site.pp manifest exists.
    # If not it is impossible to apply Puppet modules
    def is_manifest_exists?
      abort "ERROR : No ssh session found" if @ssh.nil?
      r = @ssh.do_ssh_cmd("ls #{@puppetfolder}/manifests/site.pp")
      r[:exit_code].eql? 0
    end
  
    # Check if Git and Puppet are installed within the current SSH session
    # Return : true/false 
    def is_dependencies_installed?
      is_pkgs = @ssh.do_ssh_cmd('which puppet && which git')
      if is_pkgs[:exit_code] != 0
        abort 'Please install git and puppet on the targeted node'
      end
      true
    end
    
  end
end
