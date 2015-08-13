#ruby 1.9.3
require 'rake'
require 'nokogiri'
require 'open-uri'
require 'net/http'

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

# urls = ['http://www.bodybuilding.com/store/opt/whey.html']

# product_ratings = Array.new

# urls.each do |url|
# 	tries ||= 3

# 	begin
# 		puts "Fetching URL #{url} ..."
# 		uri = URI.parse(url)

# 		doc = Nokogiri::HTML(open(uri))	
		
# 		review_count = doc.css("div.product-overview span.votes a").text
# 		members_taking = doc.css("div#product-members-taking")
		
# 		puts review_count[/([\d,])+/]
# 		puts members_taking.inspect
		
# 		#container = product_containers.first
# 		# product_containers.each do |container|
# 		# 	product_node = container.css(".product-details")
# 		# 	title_node = product_node.css(".product-details h3 a")

# 		# 	title_url = title_node.attr('href').text
			
# 		# 	title_uri = URI.parse(title_url)
# 		# 	unless title_uri.absolute?
# 		# 		title_url = uri.scheme + "://" + uri.hostname + title_node.attr('href').text
# 		# 	end
			
# 		# 	title_text = title_node.text
# 		# 	rating_node = product_node.css(".product-rating .med-rating a")
# 		# 	rating = rating_node.text

# 		# 	product_ratings << [title_url[/([^;]+)/], title_text, rating]
# 		# end
		
		
# 	rescue OpenURI::HTTPError => error
# 		retry unless (tries -= 1).zero?
# 		response = error.io
# 		puts response.status
# 	end
# end
