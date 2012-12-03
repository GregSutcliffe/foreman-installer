#!/usr/bin/ruby

require 'yaml'
require "highline/import"

# colour scheme

HighLine.color_scheme = HighLine::ColorScheme.new do |cs|
        cs[:headline]        = [ :bold, :yellow, :on_black ]
        cs[:horizontal_line] = [ :bold, :white, :on_black]
        cs[:question]        = [ :bold, :green, :on_black]
        cs[:info]            = [ :bold, :cyan, :on_black]
     end

# defaults

$terminal.wrap_at = 60
$terminal.page_at = 22

$outfile = "answers.yaml"
$output = {
  "foreman" => true,
  "foreman_proxy" => true,
  "puppet" => true,
  "puppetmaster" => true,
}

# helpers

def save_and_exit
  File.open($outfile, 'w') {|f| f.write(YAML.dump($output)) }
  say("\nOkay, you're all set! Check answers.yaml for your config")
  exit 0
end

def display_hash modulename = nil
  stat = if modulename.nil?
           "\n#{YAML.dump($output)}"
         elsif $output[modulename] == true
           "#{modulename.capitalize} is enabled with defaults\n"
         elsif $output[modulename] == false
           "#{modulename.capitalize} is disabled with defaults\n"
         else
           "#{modulename.capitalize} is enabled with overrides:\n#{YAML.dump($output[modulename])}"
         end
  say("\n<%= color('Current config is:\n#{stat}', :info) %>")
end

def configure_module modulename
  while true do
    choose do |menu|
      display_hash modulename
      menu.prompt = "Choose an option from the menu... "

      menu.choice :enable_module do $output[modulename] = true end
      menu.choice :disable_module do $output[modulename] = false end
      menu.choice :add_keyvalue_pair do add_keyvalue_pair(modulename) end
      menu.choice :exit do return end
    end
  end
end

def add_keyvalue_pair modulename
  $output[modulename] = Hash.new if [true,false].include?($output[modulename])
  key   = ask("<%= color('Key name? ', :question) %>")
  value = ask("<%= color('Value? ', :question) %>")
  # fix some simple cases
  value = true if value == "true"
  value = false if value == "false"
  value = Integer(value) rescue value
  $output[modulename][key] = value
end

# Usage statement

say("<%= color('Welcome to the Foreman Installer!', :headline) %>")
say("<%= color('---------------------------------', :horizontal_line) %>")
say(<<END)

This installer will help you set up Foreman and the associated extra configuration necessary to get you up and running. There is an interactive shell which will ask you questions, but if you just want to get up and running as fast as possible, answer 'yes' to the all-in-one install at the beginning

END

agree("\n<%= color('Ready to start?', :question) %> (y/n)",false)

# Start with the basics

if agree("\n<%= color('Do you want to use the default all-in-one setup?', :question) %>\nThis will configure Foreman, Foreman-Proxy, Puppet (including a puppetmaster), several puppet environments, TFTP (for provisioning) and sudo (for puppet certificate management) (y/n)",false)
  save_and_exit
end

say("\n<%= color('Main Config Menu', :headline) %>")

while true do
  choose do |menu|
    menu.prompt = 'Choose an option from the menu... '

    menu.choice :foreman do configure_module "foreman" end
    menu.choice :foreman_proxy do configure_module "foreman_proxy" end
    menu.choice :puppet do configure_module "puppet" end
    menu.choice :puppetmaster do configure_module "puppetmaster" end
    menu.choice :display_config do display_hash end
    menu.choice :save_and_exit do save_and_exit end
  end
end
