require 'rake'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'spreadsheet'

links = ["http://amzn.to/1Mf9i1J","http://bit.ly/1foedTM","http://amzn.to/1NPdjud","http://amzn.to/1LWJVop","http://amzn.to/1eGnLsf","http://amzn.to/1dMP3ws","http://amzn.to/1eH3QcG","http://amzn.to/1Rlfw6S","http://amzn.to/1HgwGuw","http://amzn.to/1NTJWrk","http://amzn.to/1D1nt5c","http://amzn.to/1fof2vI","http://amzn.to/1HbBIWM","http://amzn.to/1Hh9c5c","http://amzn.to/1fobqtU","http://amzn.to/1gosmAp","http://amzn.to/1CpMFrg"]
#links = ["http://amzn.to/1Mf9i1J","http://bit.ly/1foedTM","http://amzn.to/1NPdjud"]

review_count_array = []
rank_count_array = []
links.each do |url|
	tries ||= 3
	
	begin
	doc = Nokogiri::HTML(open(url))	
	
	puts doc.at_css(".product-reviews-link").text
	
	review_count = doc.at_css(".product-reviews-link").text
	#review_count_array << review_count.to_i
	review_count_array << review_count.strip
	
	var = doc.at_css("#SalesRank").text
	
	rank_array = []
	
	doc.at_css("#SalesRank").css(".zg_hrsr .zg_hrsr_item").each do |i|
	 	rank =  i.css('.zg_hrsr_rank').text
	 	category = i.css('.zg_hrsr_ladder b a').text
  	rank_array << category + rank
	end
	
	rank_count_array << rank_array.join(',')
	
	rescue OpenURI::HTTPError => error
		retry unless (tries -= 1).zero?
		response = error.io
		puts response.status
	end
end

#rank_count_array = ["482", "1", "10,258"]
#review_count_array = ["Post-Workout & Recovery#5,BCAAs#10,Supplements#381", "Nitric Oxide Boosters#124,Vitamins & Dietary Supplements#39854", "Whey#1"]


# Open source spreadsheet
review_sheet_path = "/home/vineets/Documents/Review Database Rank.xls"
review_open_book = Spreadsheet.open(review_sheet_path)
rank_sheet_path = "/home/vineets/Documents/Rank Count.xls"
rank_open_book = Spreadsheet.open(rank_sheet_path)

review_sheet = review_open_book.worksheet(0)
rank_sheet = rank_open_book.worksheet(0)
new_review_row_index = review_sheet.last_row_index + 1
new_rank_row_index = rank_sheet.last_row_index + 1

bold = Spreadsheet::Format.new(:weight => :bold)
review_sheet.row(0).replace(['Date', '', 'Link', 'Review Count']) 
review_sheet.row(0).set_format(0, bold)

rank_sheet.row(0).replace(['Date', '', 'Link', 'Rank Count']) 
rank_sheet.row(0).set_format(0, bold)

# Insert row
date = Time.now.strftime("%m/%d/%Y")

review_count_array.each_with_index do |count, i|
	review_row = [date, '']
	review_row << links[i]
	review_row << count
	review_open_book.worksheet(0).insert_row(new_review_row_index, review_row)
	new_review_row_index += 1
end

rank_count_array.each_with_index do |count, i|
	rank_row = [date, '']
	rank_row << links[i]
	rank_row << count
	rank_open_book.worksheet(0).insert_row(new_rank_row_index, rank_row)
	new_rank_row_index += 1
end

# File.delete(review_sheet_path)
# File.delete(rank_sheet_path)
FileUtils.rm(review_sheet_path, :force => true)
FileUtils.rm(rank_sheet_path, :force => true)

	# Write out the Workbook again
review_open_book.write(review_sheet_path)
rank_open_book.write(rank_sheet_path)

print "Task Complete.\n"




