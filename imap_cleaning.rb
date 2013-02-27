#!/usr/bin/env ruby
#
#
$: << '.'
require 'imap_process'

# Remove emails in INBOX
sorter = IMAPprocess.new(:server => 'imap.gmail.com')
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
