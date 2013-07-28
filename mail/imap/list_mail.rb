#!/usr/bin/env ruby
#
#
$: << '.'
require 'imap_process'

# List email INBOX
#
sorter = IMAPprocess.new(:server => 'imap.gmail.com')
sorter.prompt_login

puts "[#{Time.now}] Searching for emails.."

status = {}
broken = false

sorter.imap.list("", "INBOX").each do |folder|
  mails = sorter.find_since('2012-01-01', folder.name)

  mails.each do |id|
    puts "[#{Time.now}] + Found email with UID #{id} - #{sorter.get_message_date(id)}"
  end

end

sorter.imap.logout
sorter.imap.disconnect
