require 'metainspector'
require 'csv'

EMAIL_RE = /[\w.!#\$%+-]+@[\w-]+(?:\.[\w-]+)+/
PHONE_RE = /[\s|>]\d{3}[-. ]\d{3}[-. ]\d{4}[\s|<]/
CONTACT_PAGES = ["contact-us","contact_us","contactus","contact"]

class Spider
	def initialize url
		@url = url

		@phones = Set.new
		@emails = Set.new

		crawl_page @url
	end

	def crawl_page url
		page = MetaInspector.new url
		find_phones_in page
		find_emails_in page

		# now let's search all relative links we can find too
		page.links.internal.keep_if{|link| found_contact_page link }.each do |link|
			puts "Searching "+link.to_s+"..."
			other_page = MetaInspector.new link
			find_phones_in other_page
			find_emails_in other_page
		end
	end

	def find_phones_in page
		page.to_s.scan PHONE_RE do |phone|
			phone = phone.gsub /\D/, ""
			phone.strip!
			@phones.add phone
		end
	end
	def find_emails_in page
		page.to_s.scan EMAIL_RE do |email|
			email = email.gsub /<|>|\s/, ""
			email = email.downcase
			email.strip!
			@emails.add email
		end
	end

	def found_contact_page link
		CONTACT_PAGES.each do |site|
			return true if link =~ /#{site}$/
		end
		false
	end

	#getters
	def url
		@url.to_s
	end
	def emails_to_s
		s = StringIO.new
		@emails.each do |e| s << e.to_s+" " end
		s.string
	end
	def phones_to_s
		s = StringIO.new
		@phones.each do |p| s << p.to_s+" " end
		s.string
	end
end

def csv_write_row *values
  CSV.open($path_to_write_csv, "a+") do |csv|
    csv << values
  end
end

# Parse the emails
raise "Proper format is ruby spider.rb path_to_read_csv path_to_write_csv" if !ARGV[0] || !ARGV[1]

path_to_read_csv = ARGV[0]
$path_to_write_csv = ARGV[1]

url_list = CSV.read(path_to_read_csv)
url_list.each do |url| 
	begin
		puts "Searching "+url[0].to_s+"..."
		info = Spider.new url[0]
	rescue
		next
	end
	emails = info.emails_to_s
	phones = info.phones_to_s
	csv_write_row info.url, emails, phones unless emails.empty? && phones.empty?
end