#!/usr/bin/env ruby!

require 'rubygems'
require 'highline/import'
require 'net/imap'
require 'time'

class IMAPprocess
  attr_reader :username, :password

  # Initialize
  def initialize(opts = {})
    raise "Requires :server" if opts[:server].nil? || opts[:server].empty?
    @opts = {:port => '993', :ssl => true }.merge(opts)
  end

  # Prompt password and login
  #
  # Returns nothing
  def prompt_login
    @username = ask("Enter email: ")    { |q| q.echo = true }
    @password = ask("Enter password: ") { |q| q.echo = "*" }
    self.login
  end

  # Clear login
  #
  # Set login params and login
  def clear_login(user, pass)
    @username = user
    @password = pass
    self.login
  end

  # Connect to IMAP server
  #
  # Return Net::IMAP object
  def imap
    @imap ||= Net::IMAP.new(@opts[:server], @opts[:port], @opts[:ssl])
  end

  # Reconnect
  #
  # Returns nothing
  def imap_reconnect
    begin
      imap.logout
      imap.disconnect
    rescue
    end

    sleep 5
    @imap = Net::IMAP.new(@opts[:server], @opts[:port], @opts[:ssl])
    login
  end

  # Login
  #
  # Returns nothing
  def login
    imap.login(@username, @password)
  end

  # Search before date
  #
  # Returns messages found
  def find_before(date, folder)
    imap_date = Time.parse(date).strftime('%-d-%b-%Y') #1-Jan-2000
    find_messages('BEFORE', imap_date, folder)
  end

  # Search since date
  #
  # Returns messages found
  def find_since(date, folder)
    imap_date = Time.parse(date).strftime('%-d-%b-%Y') #1-Jan-2000
    find_messages('SINCE', imap_date, folder)
  end

  # Search mailbox
  #
  # Returns messages found
  def find_messages(operation, argument, folder)

    begin
      imap.select(folder)
      result = imap.search([operation, argument])
    rescue Net::IMAP::NoResponseError => e
      # No response, what ever
    rescue Net::IMAP::ByeResponseError => e
      # Bye response, what ever
    rescue => e
      puts "[#{Time.now}] ! Error: #{e}, retrying."
      imap_reconnect
      retry
    end

    result
  end

  # Get message date
  #
  # Returns date
  def get_message_date(id)
    msg = get_message(id)
    msg.nil? ? nil : msg.date
  end

  # Get message subject
  #
  # Returns subject
  def get_message_subject(id)
    msg = get_message(id)
    msg.nil? ? nil : msg.subject
  end

  # Get envelope message
  #
  # Returns message envelope
  def get_message(id)

    begin
      message = imap.fetch(id, "ENVELOPE").first.attr["ENVELOPE"]
    rescue Net::IMAP::NoResponseError => e
      # No response, what ever
    rescue Net::IMAP::ByeResponseError => e
      # Bye response, what ever
    rescue => e
      puts "[#{Time.now}] ! Error: #{e}, retrying."
      imap_reconnect
      retry
    end

    message
  end

  # List all imap folders
  #
  # Returns list of folders
  def list_all_folders

    begin
      list = imap.list('*', '*')
    rescue Net::IMAP::NoResponseError => e
      # No response, what ever
    rescue Net::IMAP::ByeResponseError => e
      # Bye response, what ever
    rescue => e
      puts "[#{Time.now}] ! Error: #{e}, retrying."
      imap_reconnect
      retry
    end

    list
  end

  # Delete messages from server
  #
  # Returns nothing
  def delete_message(message_id, opts = {})

    trash = opts[:trash] || '[Gmail]/Trash'

    begin
      imap.copy(message_id, trash) if opts[:copy_to_trash]
      imap.store(message_id, "+FLAGS", [:Deleted])

      imap.expunge
    rescue Net::IMAP::NoResponseError => e
      # No response, what ever
    rescue Net::IMAP::ByeResponseError => e
      # Bye response, what ever
    rescue => e
      puts "[#{Time.now}] ! Error: #{e}, retrying."
      imap_reconnect
      retry
    end

    message_id
  end

end
