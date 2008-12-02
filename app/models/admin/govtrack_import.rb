require 'rexml/document'
require 'open-uri'
require 'ruby-debug'

class Admin::GovtrackImport < ActiveRecord::Base

  #@folder = "http://drake.doesntexist.org:3002/~drake/govtrack/us/110"
  #@folder = "http://localhost:3002/~drake/govtrack/us/110"  
  #@folder = "/govtrack/110"
  @folder = "/Users/drake/Sites/govtrack/us/110"
  
  def self.current_community
    @community ||= Community.find_by_name("United States Congress")
  end
  
  def self.import_bills
    Dir[@folder + '/bills/*.xml'].each do |path|
      begin
        puts "importing #{path}"
        import_bill( path )
      rescue
        puts "fail #{path}"
      end
    end
    current_community.update_attribute 'sync_date', Time.now
  end
  
  def self.import_rolls
    Dir[@folder + '/rolls/*.xml'].each do |path|
      begin
        puts "importing #{path}"
        import_roll( path )
      rescue
        puts "fail #{path}"
      end
    end
    current_community.update_attribute 'sync_date', Time.now
  end
  
  def self.import_bill(xml_link)
    xml = REXML::Document.new( open( xml_link ))
    
    bill = xml.elements["//bill"]
    
    @article = Article.find_by_tom_id( tom_id_from_xml(bill) ) || current_community.articles.new
    
    parse_tom_id bill
    parse_session bill
    parse_number
    parse_article_type bill
    parse_status bill.elements["//status"]
    parse_title bill.elements["//titles"]
    parse_summary bill.elements["//summary"]
    
    base_link = xml_link.gsub(/bills\/\S+/,'') + "bills.text/#{ bill.attributes['type'] }/#{ bill.attributes['type'] }#{ bill.attributes['number'] }"
    extensions = [".html", ".xml", "ih.html", "eh.html"]
    begin
      @article.text = open( base_link + ".html" ).read
    rescue
      begin
        @article.text = open(base_link + "eh.html" ).read
      rescue
        begin
          @article.text = open(base_link + "ih.html").read
        rescue
          begin
            @article.text = open(base_link + "es.html").read          
          rescue
            begin
              @article.text = open(base_link + "pcs.html").read
            rescue
              @article.text = open(base_link + "is.html").read
            end
          end
        end
      end
    end
        
    @article.community = current_community
    @article.certified = true
    
    @article.save
    
    parse_actions bill.elements["//actions"]    
    
    #y @article
    puts "imported " + @article.tom_id
  end
  
  def self.import_roll(xml_link)
    xml = REXML::Document.new( open( xml_link ))
    
    roll_xml = xml.elements["//roll"]
    
    puts roll_number = roll_xml.attributes["where"].at(0) + roll_xml.attributes["year"] + "-" + roll_xml.attributes["roll"]
    roll = current_community.rolls.find_by_number( roll_number ) || current_community.rolls.new(:number => roll_number)
    
    
    
    #if article_number
    #  roll.article = current_community.articles.find_by_number( article_number )
    #end
    
    y roll
    gets
    
  end
  
  def self.tom_id_from_xml(xml)
    tom_type = case xml.attributes["type"]
    when "h"
      "hr"
    when "hr"
      "hres"
    when "hj"
      "hjres"
    when "hc"
      "hconres"
    when "s"
      "s"
    when "sr"
      "sres"
    when "sj"
      "sjres"
    when "sc"
      "sconres"
    end
    "http://hdl.loc.gov/loc.uscongress/legislation." + xml.attributes["session"] + tom_type + xml.attributes["number"]
  end
  
  def self.parse_tom_id(xml)
    @article.tom_id = tom_id_from_xml xml
  end
  
  def self.parse_session(xml)
    @article.session = xml.attributes["session"]
  end
  
  def self.parse_number
    #should be off the session, not just putting110 in there. lazy.
    if match = @article.tom_id.match(/110(\w+)/)
      @article.number = match[1]
    end
  end
  
  def self.parse_article_type(xml)
    case xml.attributes["type"]
    when "h" || "s":
      @article_type_id = 1
    else
      @article_type_id = 2
    end
  end
  
  def self.parse_status(xml)
    if status = xml.elements["introduced"]
      @article.stage = 3
      @article.updated_at = status.attributes["datetime"]
    elsif status = xml.elements["calendar"]
      @article.stage = 4
    elsif status = xml.elements["vote"]
      @article.stage = 3
    elsif status = xml.elements["vote2"]
      @article.stage = 7
      @article.updated_at = status.attributes["datetime"]
    elsif status = xml.elements["topresident"]
      @article.stage = 7
      @article.updated_at = status.attributes["datetime"]
    elsif status = xml.elements["signed"]
      @article.stage = 8
      @article.updated_at = status.attributes["datetime"]
    elsif status = xml.elements["veto"]
      @article.stage = 9
      @article.updated_at = status.attributes["datetime"]      
    elsif status = xml.elements["override"]
      @article.stage = 10
      @article.updated_at = status.attributes["datetime"]
    elsif status = xml.elements["enacted"]
      @article.stage = 5
      @article.updated_at = status.attributes["datetime"]
    else
      @article.stage = 0
    end
  end
  
  def self.parse_title(xml)
    @article.title = xml.elements["title[@type='official']"].text
  end
  
  def self.parse_summary(xml)
    @article.summary = xml.to_s
  end
  
  def self.parse_actions(xml)
    if actions = xml.elements.to_a[@article.actions.size..-1]
      actions.each do |action_xml|
        action = Action.new
        
        # action.action_code = case action_xml.elements["text"].text
        #         when 
        #         end
        
        action.community = current_community
        action.action = action_xml.elements["text"].text
        action.created_at = action_xml.attributes['datetime']
        @article.actions << action
      end
    end
  end

end
