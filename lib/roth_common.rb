#!/usr/bin/env ruby
# encoding: utf-8

module Roth

  module Settings
    USER = {
        :name => 'roth',
        :password => nil
    }
    PUPPET  = {
        :folder =>  '/etc/puppet',
        :modfolder => 'modules'
    }
  end
  
  class SSH

    attr_accessor :ssh, :node, :user, :password

    def initialize
    end
    
    # Start a new SSH session
    # By default, the user used is 'roth'
    def start_ssh(node, user=nil)
      user ||= Settings::USER[:name]
      unless user.eql? Settings::USER[:name]
        ask("Enter your password:  ") { |q| q.echo = false }
        @password = pwd
      end
      @node = node
      @user = user
      @ssh = get_ssh_session
      abort "No ssh session found" if @ssh.nil?
      @ssh
    end
  
    # Close the current SSH session  
    def close_ssh
      puts "Close connection"
      @ssh.close unless @ssh.closed?
    end
  
    # Execute a command through a SSH session
    # The function also parses stdin, stdout and stderr 
    def do_ssh_cmd(cmd='uname -a')
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
  
      begin
        @ssh.open_channel do |channel|
          channel.exec(cmd) do |ch, success|
            unless success
              abort "FAILED: couldn't execute command (ssh.channel.exec)"
            end
            channel.on_data do |ch,data|
              stdout_data += data
            end
  
            channel.on_extended_data do |ch,type,data|
              stderr_data+=data
            end
  
            channel.on_request("exit-status") do |ch,data|
              exit_code = data.read_long
            end
          end
        end
        @ssh.loop
      rescue Net::SSH::Exception => e
        abort "Net:SSH Exception : #{e.message}"
      rescue Exception => e
        abort "Unknown Exception : #{e.message}"
      end
      {:stdout => stdout_data, :stderr => stderr_data, :exit_code => exit_code}
    end
    
    def self.print_std(resultssh)
      str = "SSH command result : "
      if resultssh[:exit_code].eql? 0
        str << "success"
      else
        str << "error"
      end
      puts str
      puts "Result : " + resultssh[:stdout] unless resultssh[:stdout].empty?
      puts "Error : " + resultssh[:stderr] unless resultssh[:stderr].empty?

    end

    private
  
    # Create and return a new SSH session 
    # Return nil/Net::SSH
    def get_ssh_session
      ssh = nil
      begin
        ssh = Net::SSH.start(@node, @user, :password => @password)
        ssh.loop(true)
      rescue Exception => e
        puts "Unknown Net:SSH Exception : #{e.message}"
        return nil
      end
      ssh
    end

  end
end
