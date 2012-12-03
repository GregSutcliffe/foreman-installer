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

# Line wrapping - don't go over 80 chars even the terminal is huge...

data = HighLine::SystemExtensions.terminal_size
$terminal.wrap_at = data.first > 80 ? 80 : data.first
$terminal.page_at = data.last

# defaults

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
  say("\nOkay, you're all set! Check <%= color('answers.yaml', :cyan) %> for your config")
  exit 0
end

def display_hash modulename = nil
  stat = if modulename.nil?
           "\n#{YAML.dump($output)}"
         elsif $output[modulename] == true
           "#{modulename.capitalize} is enabled with defaults\n"
         elsif $output[modulename] == false
           "#{modulename.capitalize} is disabled\n"
         else
           "#{modulename.capitalize} is enabled with overrides:\n#{YAML.dump($output[modulename])}"
         end
  say("\n<%= color('Current config is:\n#{stat}', :info) %>")
end

def menu_helper type,name,key=nil,value=nil
  case type
  when "agree"
    add_keyvalue_pair(name, key, agree("y/n?",true))
  end
end

def foreman_questions
  {
    "Should Foreman require SSL to be enabled? (default: true) " \
    => 'menu_helper("agree", "foreman", "ssl")',
    "Should Foreman run under apache & passenger? (default: true) " \
    => 'menu_helper("agree", "foreman", "passenger")',
    "Should Foreman be installed from the unstable repo? (default: false) " \
    => 'menu_helper("agree", "foreman", "use_testing")',
  }
end

def foreman_proxy_questions
  {
    "Should Foreman_proxy be installed from the unstable repo? (default: false) " \
    => 'menu_helper("agree", "foreman_proxy", "use_testing")',
    "Should Foreman_proxy manage Puppet (needed for puppet classes)? (default: true) " \
    => 'menu_helper("agree", "foreman_proxy", "puppetrun")',
    "Should Foreman_proxy manage PuppetCA (needed for certificates)? (default: true) " \
    => 'menu_helper("agree", "foreman_proxy", "puppetca")',
    "Should Foreman_proxy manage TFTP? (default: true) " \
    => 'menu_helper("agree", "foreman_proxy", "tftp")',
    "Should Foreman_proxy manage DNS? (default: false) " \
    => 'menu_helper("agree", "foreman_proxy", "dns")',
    "Should Foreman_proxy manage DHCP? (default: false) " \
    => 'menu_helper("agree", "foreman_proxy", "dhcp")',
  }
end

def puppet_questions
  {
  }
end

def puppetmaster_questions
  {
    "Should Puppetmaster use Git for dynamic environments? (default: false) " \
    => 'menu_helper("agree", "puppetmaster", "git_repo")',
    "Should Puppetmaster run under apache & passenger? (default: true) " \
    => 'menu_helper("agree", "puppetmaster", "passenger")',
  }
end

def configure_module modulename
  while true do
    choose do |menu|
      display_hash modulename
      say("\n<%= color('#{modulename.capitalize} Config Menu', :headline) %>")
      menu.prompt = "Choose an option from the menu... "

      menu.choice "Enable #{modulename} with all defaults" do $output[modulename] = true end
      menu.choice "Disable #{modulename} completely" do $output[modulename] = false end
      eval("#{modulename}_questions").each do |question, code|
        menu.choice question do eval(code) end
      end
      menu.choice "Add other key/value pair to the config" do add_keyvalue_pair(modulename) end
      menu.choice "Go up to main menu" do return end
    end
  end
end

def add_keyvalue_pair modulename, key=nil, value=nil
  $output[modulename] = Hash.new if [true,false].include?($output[modulename])
  key   = key.nil?   ? ask("<%= color('Key name? ', :question) %>") : key
  value = value.nil? ? ask("<%= color('Value? ', :question) %>")    : value
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

exit 0 unless agree("\n<%= color('Ready to start?', :question) %> (y/n)",false)

# Start with the basics

if agree("\n<%= color('Do you want to use the default all-in-one setup?', :question) %>\nThis will configure Foreman, Foreman-Proxy, Puppet (including a puppetmaster), several puppet environments, TFTP (for provisioning) and sudo (for puppet certificate management) (y/n)",false)
  save_and_exit
end

while true do
  say("\n<%= color('Main Config Menu', :headline) %>")
  choose do |menu|
    menu.prompt = 'Choose an option from the menu... '

    ["foreman","foreman_proxy","puppet","puppetmaster"].each do |name|
      menu.choice "Configure #{name.capitalize} settings" do configure_module name end
    end
    menu.choice :display_config do display_hash end
    menu.choice :save_and_exit do save_and_exit end
  end
end
