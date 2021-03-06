#ruby 1.9.3
#gem install nokogiri
#gem install watir-webdriver
#sudo apt-get install xvfb
#gem install headless
require 'rake'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'watir-webdriver'
require 'headless'
require 'csv'

urls = ['http://www.bodybuilding.com/store/top50.htm']

product_ratings = Array.new

urls.each do |url|
	tries ||= 3

	begin
		puts "Fetching URL #{url} ..."
		uri = URI.parse(url)

		doc = Nokogiri::HTML(open(uri))	
		
		product_containers = doc.css(".store-layout-product-item")
		
		puts "Found #{product_containers.size} item(s)..."
		puts 'Scraping them now....'
		
		#container = product_containers.first
		product_containers.each do |container|
			product_node = container.css(".product-details")
			title_node = product_node.css(".product-details h3 a")

			title_url = title_node.attr('href').text
			
			title_uri = URI.parse(title_url)
			unless title_uri.absolute?
				title_url = uri.scheme + "://" + uri.hostname + title_node.attr('href').text
			end
			
			title_text = title_node.text
			rating_node = product_node.css(".product-rating .med-rating a")
			rating = rating_node.text

			product_ratings << [title_url[/([^;]+)/], title_text, rating]
		end
		
		
	rescue OpenURI::HTTPError => error
		retry unless (tries -= 1).zero?
		response = error.io
		puts response.status
	end
end

puts product_ratings.inspect

products = Array.new
#product_ratings = [["http://www.bodybuilding.com/store/opt/whey.html", "Optimum Nutrition Gold Standard 100% Whey", "9.2"], ["http://www.bodybuilding.com/store/jym/pre-jym.html", "JYM Pre JYM", "9.3"]]

product_ratings.each do |pr|
 	tries ||= 3

 	begin
 		url = pr[0]
 		puts "Fetching URL #{url} ..."
 		uri = URI.parse(url)

 		headless = Headless.new
		headless.start

		browser = Watir::Browser.start url
		doc = Nokogiri::HTML(browser.html)

		members_taking = doc.css("div#product-members-taking h2").text[/([\d])+/]
 		review_count = doc.css("div.product-overview span.votes a").text[/([\d,])+/]
 		
 		fb_recommend_src = doc.css("div#wrapper-facebook-recommend span iframe").attr('src').text
		fb_recommend_browser = Watir::Browser.start(fb_recommend_src)
		fb_recommend_html = Nokogiri::HTML(fb_recommend_browser.html)
		fb_recommend_count = fb_recommend_html.css("span#u_0_3").text[/([\d,])+/]
 		

 		products << pr + [review_count, members_taking, fb_recommend_count]
		
	rescue OpenURI::HTTPError => error
		retry unless (tries -= 1).zero?
		response = error.io
		puts response.status
	else
		browser.close
		headless.destroy
	end
end

puts 'Scraping done...' 
puts 'Saving to CSV file now....'

CSV.open("products.csv", "wb") do |csv|
  csv << ['Date', 'URL', 'Title', 'Rating', 'Reviews', 'Members Taking', 'Facebook Recommendations']
  date = Time.now.strftime("%m/%d/%Y")

  products.each do |product|
  	csv << [date, product[0], product[1], product[2], product[3], product[4], product[5]]
  end
end

puts 'DONE'
