require 'rexml/document'
require 'open-uri'
require 'ruby-debug'

class Admin::GovtrackImport < ActiveRecord::Base

  @folder = GOVTRACK_FOLDER + "110"
  
  @dist_rep_cache = {}
  
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
    # parse number
    #should be off the session, not just putting110 in there. lazy.
    if match = @article.tom_id.match(/110(\w+)/)
      @article.number = match[1]
    end    
    # parse type
    case bill.attributes["type"]
    when "h" || "s":
      @article_type_id = 1
    else
      @article_type_id = 2
    end
    parse_status bill.elements["//status"]
    parse_title bill.elements["//titles"]
    parse_summary bill.elements["//summary"]
    bill.elements.each("//relatedbills") do |bill|
      
    end
    bill.elements.each("//subjects") do |term|
      @article.tag_with term.text
    end
    
    # this should grab all versions of the bill
    Dir[@folder + "/bills.text/#{ type }/#{ number }[^0-9]*.html"].each do |path|
      next if path.match /gen\.html$/ # do not include govtrack generated reports
      version = path.match(/(\w*).html$/)
      @article.text = open(path).read
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
        
    roll_number = roll_xml.attributes["where"].at(0) + roll_xml.attributes["year"] + "-" + roll_xml.attributes["roll"]
    roll = current_community.rolls.find_by_number( roll_number ) || current_community.rolls.new(:number => roll_number)
    
    if bill_xml = roll_xml.elements["//bill"]
      article_type = tom_type_from_govtrack_type bill_xml.attributes["type"]
      article_number = article_type + bill_xml.attributes["number"]
      roll.article = current_community.articles.find_by_number( article_number )
      puts "inserted into #{article_number}"
    end
    
    roll.created_at = roll_xml.attributes["datetime"]
    roll.session = roll_xml.attributes["session"]
    roll.house = roll_xml.attributes["where"]
    roll.aye_count = roll_xml.attributes["aye"]
    roll.nay_count = roll_xml.attributes["nay"]
    roll.novote_count = roll_xml.attributes["nv"]
    roll.present_count = roll_xml.attributes["present"]
    roll.kind = roll_xml.elements["//type"].text
    roll.question = roll_xml.elements["//question"].text
    roll.required = roll_xml.elements["//required"].text
    roll.result = roll_xml.elements["//result"].text
        
    roll.save
        
    if roll.roll_votes.clear
    #if roll.roll_votes.empty?
      # add individual votes
      roll_xml.elements.each("voter") do |voter|
        state = state_abbr_to_name( state_abbr = voter.attributes["state"] )
        district_number = " " + voter.attributes["district"]
        district_number = " At Large" if district_number == " 0"
        # remember to thank god for teritories. 
        district_number = "" if state_abbr == "VI" || state_abbr == "DC" || state_abbr == "GU" || state_abbr == "PR" || state_abbr == "AS"
        # thanks god
        district_name = state+district_number
        #district = current_community.districts.find_by_name(district_name)
        district_id, rep_id = dist_rep_cache(district_name)
        vote = vote_id_from_govtrack_symbol( voter.attributes["vote"] )
        #roll_vote = roll.roll_votes.new(:community => current_community, :district => district, :user => district.representative, :vote => vote)
        roll_vote = roll.roll_votes.new(:community => current_community, :district_id => district_id, :user_id => rep_id, :vote => vote)
        roll_vote.save
        puts vote
      end
    end
        
    puts "eaten out #{roll_number}"
  end
  
  def self.dist_rep_cache(name)
    @dist_rep_cache[name] ||= [current_community.districts.find_by_name(name).id, current_community.districts.find_by_name(name).user_id]
  end
  
  def self.vote_id_from_govtrack_symbol(govtrack_symbol)
    case govtrack_symbol
    when "+"
      1
    when "-"
      0
    when "P"
      2
    when "0"
      nil
    end
  end
  
  def self.tom_type_from_govtrack_type(govtrack_type)
    case govtrack_type
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
    else
      raise "Translation not found for #{govtrack_type}"
    end
  end
  def self.state_abbr_to_name(abbr)
	  @state_abbr ||= {
     'AL' => 'Alabama',
     'AK' => 'Alaska',
     'AS' => 'American Samoa',
     'AZ' => 'Arizona',
     'AR' => 'Arkansas',
     'CA' => 'California',
     'CO' => 'Colorado',
     'CT' => 'Connecticut',
     'DE' => 'Delaware',
     'DC' => 'District of Columbia',
     'FM' => 'Micronesia1',
     'FL' => 'Florida',
     'GA' => 'Georgia',
     'GU' => 'Guam',
     'HI' => 'Hawaii',
     'ID' => 'Idaho',
     'IL' => 'Illinois',
     'IN' => 'Indiana',
     'IA' => 'Iowa',
     'KS' => 'Kansas',
     'KY' => 'Kentucky',
     'LA' => 'Louisiana',
     'ME' => 'Maine',
     'MH' => 'Islands1',
     'MD' => 'Maryland',
     'MA' => 'Massachusetts',
     'MI' => 'Michigan',
     'MN' => 'Minnesota',
     'MS' => 'Mississippi',
     'MO' => 'Missouri',
     'MT' => 'Montana',
     'NE' => 'Nebraska',
     'NV' => 'Nevada',
     'NH' => 'New Hampshire',
     'NJ' => 'New Jersey',
     'NM' => 'New Mexico',
     'NY' => 'New York',
     'NC' => 'North Carolina',
     'ND' => 'North Dakota',
     'OH' => 'Ohio',
     'OK' => 'Oklahoma',
     'OR' => 'Oregon',
     'PW' => 'Palau',
     'PA' => 'Pennsylvania',
     'PR' => 'Puerto Rico',
     'RI' => 'Rhode Island',
     'SC' => 'South Carolina',
     'SD' => 'South Dakota',
     'TN' => 'Tennessee',
     'TX' => 'Texas',
     'UT' => 'Utah',
     'VT' => 'Vermont',
     'VI' => 'U.S. Virgin Islands',
     'VA' => 'Virginia',
     'WA' => 'Washington',
     'WV' => 'West Virginia',
     'WI' => 'Wisconsin',
     'WY' => 'Wyoming'
   }
   @state_abbr[abbr.upcase]
 end
  
  def self.tom_id_from_xml(xml)
    tom_type = tom_type_from_govtrack_type xml.attributes["type"]
    "http://hdl.loc.gov/loc.uscongress/legislation." + xml.attributes["session"] + tom_type + xml.attributes["number"]
  end
  
  def self.parse_tom_id(xml)
    @article.tom_id = tom_id_from_xml xml
  end
  
  def self.parse_session(xml)
    @article.session = xml.attributes["session"]
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
