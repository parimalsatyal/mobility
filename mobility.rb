require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'net/http'
require 'uri'
require 'css_parser'
include CssParser
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

	puts "\n\nChecking if the website serves different stylesheets for desktop and mobile...\n\n"

# First check with a Desktop UA and spit out all linked stylesheets
page = Nokogiri::HTML(RestClient.get page_url, :user_agent => user_agents["WinDesktop"])
desktop_stylesheets = page.css("link[rel=stylesheet]")
desktop_alternate = page.css("link[rel=alternate]") # We're not using this yet

puts "On Desktop, these stylesheets are being loaded: \n"
puts desktop_stylesheets
puts "\n"
# puts desktop_alternate

# Then check with a mobile UA and spit out all linked stylesheets
page = Nokogiri::HTML(RestClient.get page_url, :user_agent => user_agents["iPhone"])
mobile_stylesheets = page.css("link[rel=stylesheet]")
mobile_canonical = page.css("link[rel=canonical]") # We're not using this yet

puts "On Phone, these stylesheets are being loaded: \n"
puts mobile_stylesheets
puts "\n"
# puts mobile_canonical

# Then check if there's a difference in output between the two

if desktop_stylesheets.to_s == mobile_stylesheets.to_s
	puts "\nThey're identical. This website does not serve different stylesheets dynamically based on the user agent."
else
	puts "\nDynamic serving. Different stylesheets are loaded depending on the user agent."
  dynamicserving = true
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

puts "\nNow checking if a dedicated mobile site exists at #{mobilesite}...\n"

# Now load that URL and see what response you get
begin
  RestClient.get(mobilesite) { |response, request, result, &block|
  case response.code
    when 200
     puts "Mobile site found with HTTP code #{response.code}. \n"
    when 301
     puts "Redirection to mobile site probable, HTTP code #{response.code} returned. \n"
    else
      response.return!(request, result, &block)
    end
  }
rescue SocketError => e
  puts "Mobile site not found at this address."
end

# Next: Visit all CSS files (or limit to non-font files) and check for media queries. Get all breakpoints.
responsive = false
puts "\n\nChecking for @media queries... \n\n"
page.xpath('//link[@rel="stylesheet"]').each do |stylesheet|
  resourceaddress = stylesheet['href']
  realaddr = nil
  if resourceaddress.match(/^\//)
    realaddr = "#{uri.scheme}://#{uri.host}#{resourceaddress}"
  else
    realaddr = resourceaddress
  end
  parser = CssParser::Parser.new
  parser.load_uri!(realaddr)
    raw_css = parser.to_s
    r = /@media ?[^)]*?\([^)]*?(max|min)-width ?: ?([0-9]+)px[^)]*?\)/
    recoveredqueries = raw_css.scan(r)
    unless recoveredqueries.empty?
      recoveredqueries.each do |d,a|
        puts d + ":" + a + "\n"
      end
      responsive = true
    end
end

if responsive
  puts "The website is responsive, with breakpoints listed above."
else
  puts "The website is not responsive"
end
