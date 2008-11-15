require 'open-uri'
require 'rexml/document'

open "http://thomas.loc.gov/home/gpoxmlc110/h835_ih.xml" do |page|
	xml = REXML::Document.new(page.read)
	puts xml.elements["//calendar"].text
end

