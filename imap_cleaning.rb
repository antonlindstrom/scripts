#!/usr/bin/env ruby!

require 'rubygems'
require 'highline/import'
require 'net/imap'
require 'time'

class IMAPCleaning

  # Initialize
  def initialize(opts = {})
    raise "Requires :server" if opts[:server].nil? || opts[:server].empty?
    @opts = {:port => '993', :ssl => true }.merge(opts)
  end

  # Prompt password and login
  #
  # Returns nothing
  def prompt_login
    username = ask("Enter email: ")    { |q| q.echo = true }
    password = ask("Enter password: ") { |q| q.echo = "*" }

    login(username, password)
  end

  # Connect to IMAP server
  #
  # Return Net::IMAP object
  def imap
    @imap ||= Net::IMAP.new(@opts[:server], @opts[:port], @opts[:ssl])
  end

  # Login
  #
  # Returns nothing
  def login(username, password)
    imap.login(username, password)
  end

  # Search since date
  #
  # Returns messages found
  def find_since(date, folder)
    imap_date = Time.parse(date).strftime('%-d-%b-%Y') #1-Jan-2000

    imap.select(folder)
    result = imap.search(["SINCE", imap_date])

    rescue Net::IMAP::NoResponseError => e
      # No response, what ever
    rescue Net::IMAP::ByeResponseError => e
      # Bye response, what ever
    rescue => e
      puts e

    result
  end

  # List all imap folders
  #
  # Returns list of folders
  def list_all_folders
    imap.list('*', '*')
  end

  # Delete messages from server
  #
  # Returns nothing
  def delete_message(message_id, opts = {})

    trash = opts[:trash] || '[Gmail]/Trash'

    imap.copy(message_id, trash) if opts[:copy_to_trash]
    imap.store(message_id, "+FLAGS", [:Deleted])

    imap.expunge

    rescue Net::IMAP::NoResponseError => e
      # No response, what ever
    rescue Net::IMAP::ByeResponseError => e
      # Bye response, what ever
    rescue => e
      puts e

    message_id
  end

end

# Remove emails in INBOX
sorter = IMAPCleaning.new(:server => 'imap.gmail.com')
sorter.prompt_login

puts "[#{Time.now}] Searching for emails in INBOX.."
should_be_deleted = sorter.find_since('2012-01-01', 'INBOX')

puts "[#{Time.now}] Found #{should_be_deleted.length}, these will be deleted."

should_be_deleted.each do |id|
  sorter.delete_message(id)
  puts "[#{Time.now}] + Removed email with UID #{id}"
end

sorter.imap.logout
sorter.imap.disconnect
