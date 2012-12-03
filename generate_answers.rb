#!/usr/bin/ruby

require 'yaml'
require "highline/import"

# defaults
$terminal.wrap_at = 50
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

def display_hash modulename
    stat = if $output[modulename] == true
             "#{modulename.capitalize} is enabled with defaults"
           elsif $output[modulename] == false
             "#{modulename.capitalize} is disabled with defaults"
           else
             "#{modulename.capitalize} is enabled with overrides:\n#{YAML.dump($output[modulename])}"
           end
    say("\n Current config is:\n#{stat}\n")
end

def configure_module modulename
  begin
  display_hash modulename
  $output[modulename] = agree("\nDo you want to use this module? (y/n)",true)
  display_hash modulename
  if agree("\nDo you wish to change the defaults? (y/n)",true)
  begin
    $output[modulename] = Hash.new if [true,false].include?($output[modulename])
    key = ask("Key name? ")
    value = ask("Value? ")
    # fix some simple cases
    value = true if value == "true"
    value = false if value == "false"
    value = Integer(value) rescue value
    $output[modulename][key] = value
    display_hash modulename
  end while agree("\nAdd another override? (y/n)",true)
  end
  end while !agree("\nIs this correct? (y/n)",true)
end

# Usage statement

say(<<END)
Welcome to the Foreman Installer!
---------------------------------

This installer will help you set up Foreman and the associated extra configuration necessary to get you up and running. There is an interactive shell which will ask you questions, but if you just want to get up and running as fast as possible, answer 'yes' to the all-in-one install at the beginning

END

agree("\nReady to start? (y/n)",false)

# Start with the basics

if agree("\nDo you want to use the default all-in-one setup? This will configure Foreman, Foreman-Proxy, Puppet (including a puppetmaster), several puppet environments, TFTP (for provisioning) and sudo (for puppet certificate management) (y/n)",false)
end

while true do
  say("\n")
  choose do |menu|
    menu.prompt = "Choose which module you wish to configure... "

    menu.choice :foreman do configure_module "foreman" end
    menu.choice :foreman_proxy do configure_module "foreman_proxy" end
    menu.choice :puppet do configure_module "puppet" end
    menu.choice :puppetmaster do configure_module "puppetmaster" end
    menu.choice :save_and_exit do save_and_exit end
  end
end
