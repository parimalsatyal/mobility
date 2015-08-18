require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'net/http'
require 'uri'

# For CSS parsing
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

# First check with a Desktop UA and spit out all linked stylesheets
page = Nokogiri::HTML(RestClient.get page_url, :user_agent => user_agents["WinDesktop"])
desktop_stylesheets = page.css("link[rel=stylesheet]")
desktop_alternate = page.css("link[rel=alternate]")

puts "On Desktop, using #{desktop_stylesheets.class}: \n"
puts desktop_stylesheets
puts "\n"
# puts desktop_alternate

# Then check with a mobile UA and spit out all linked stylesheets
page = Nokogiri::HTML(RestClient.get page_url, :user_agent => user_agents["iPhone"])
mobile_stylesheets = page.css("link[rel=stylesheet]")
mobile_canonical = page.css("link[rel=canonical]")

puts "On Phone: \n"
puts mobile_stylesheets
puts "\n"
# puts mobile_canonical

# Then check if there's a difference in output between the two

if desktop_stylesheets.to_s == mobile_stylesheets.to_s
	puts "\nNot Dynamic serving"
else
	puts "\nDynamic serving"
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

puts "\nChecking for existence of dedicated mobile site at #{mobilesite}...\n"

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


# Inspired by a PHP implementation (need to find author name)
def parseMediaBlocks (rawcss)

    mediablocks = []
    start = 0

    until (!(rawcss.index("@media") == start))
      s = []
        i = rawcss.index("{").begin(start)

        if (!i)
          s.push(rawcss[i])
          i += 1

          loop do
            if (rawcss[i] == "{")
              s.push("{")
            elsif (rawcss[i] == "}")
              s.delete("}")
            end
            i += 1
            break if s.empty?
          end

          mediablocks = rawcss[start, ((i + 1) - start)]
          start = i
        end
    end
    return mediablocks
end


# Next: Visit all CSS files (or limit to non-font files) and check for media queries. Get all breakpoints.
parser = CssParser::Parser.new

desktop_stylesheets.each do |link|
  url_css = link["href"].strip
  parser.load_uri!(url_css)
  raw_css = parser.to_s
  puts "\nMedia query lines for #{url_css} are: \n
  \n"
  puts parseMediaBlocks(raw_css)

end
