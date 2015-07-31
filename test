require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'net/http'
require 'uri'

# This script requires Ruby and the gems Nokogiri and rest-client
# Let's get started

# Ask the user for a URL, then remove whitespaces and lowercase everything
puts "URL to test: "
page_url = gets.strip.downcase

# Make sure it starts with "http://" or "https://"
unless page_url.include?("http://") || page_url.include?("https://")
   page_url = "http://" + page_url
end

# Hash dictionary with user agents, update as needed
user_agents = Hash[
  "iPhone" => "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/419.3",
  "WinDesktop" => "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36"]

# First check with a Desktop UA and spit out all linked stylesheets
page = Nokogiri::HTML(RestClient.get page_url, :user_agent => user_agents["WinDesktop"])
desktop_html = page.css("link[rel=stylesheet]")

puts "On Desktop: \n"
puts desktop_html

# Then check with a mobile UA and spit out all linked stylesheets
page = Nokogiri::HTML(RestClient.get page_url, :user_agent => user_agents["iPhone"])
mobile_html = page.css("link[rel=stylesheet]")

puts "On Phone: \n"
puts mobile_html

# Then check if there's a difference in output between the two

if desktop_html.to_s == mobile_html.to_s
	puts "\nNot Dynamic serving"
else
	puts "\nDynamic serving"
end

# Now to check if a mobile site exists with an m. prefix
# First, get just the base URL and prefix the m. bit
uri = URI.parse(page_url)
base = "#{uri.scheme}://#{uri.host}/"

if base.include?("www.")
	mobilesite = base.gsub("www.", "m.")
else
	mobilesite = base.gsub("http://", "http://m.")
end
 
puts "\nChecking for existence of mobile site at #{mobilesite}...\n"

# Now load that URL and see what response you get
begin
  RestClient.get(mobilesite) { |response, request, result, &block|
  case response.code
    when 200
     puts "Mobile site found with HTTP code #{response.code}. \n"
    else
      response.return!(request, result, &block)
    end
  }
rescue SocketError => e
  puts "Mobile site does not exist at this address."
end

# Next: Visit all CSS files (or limit to non-font files) and check for media queries. Get all breakpoints. 
