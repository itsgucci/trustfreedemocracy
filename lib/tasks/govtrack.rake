require 'rexml/document'
require 'open-uri'
require 'ruby-debug'

SESSION = 110
GOVTRACK_PATH = "/govtrack/us/#{ SESSION }/"
COMMUNITY_NAME = "United States Congress"

namespace :govtrack do
  
  task :create_congress => :environment do
    Community.create(:name => COMMUNITY_NAME)
    puts "Created #{COMMUNITY_NAME}"
  end
  
  desc "Synchronizes local data with govtrack via rsync"
  task :rsync do
    puts "rsyncing with govtrack. this takes a while..."
    puts "importing bills"
    `rsync -az govtrack.us::govtrackdata/us/#{SESSION}/bills #{GOVTRACK_PATH}bills`
    puts "now grabbing the bill text"
    `rsync -az govtrack.us::govtrackdata/us/bills.text/#{SESSION}/* #{GOVTRACK_PATH}bills.text/`
    puts "getting the rolls"
    `rsync -az govtrack.us::govtrackdata/us/#{SESSION}/rolls #{GOVTRACK_PATH}rolls`
    puts "#{GOVTRACK_PATH} has been synchronized with govtrack.us"
  end
  
  desc "Initializes the Root user Account"
  task :import_bills => :environment do
    #duplicates = ask "Include duplicates? [t/f] "
    puts "importing bills from #{GOVTRACK_PATH}"
    Dir[GOVTRACK_PATH + 'bills/*.xml'].each do |path|
      #begin
        import_bill( path )
      #rescue
      #  puts "fail #{path}"
      #end
    end
    current_community.update_attribute 'sync_date', Time.now
    puts "Finished updating all bills"
  end
  
  task :import_bill => :environment do
    number = ask "Bill Number:"
    import_bill(GOVTRACK_PATH + 'bills/' + number + '.xml')
  end
  

  desc "Run all bootstrapping tasks"
  task :all => [:default_user, :default_community]
  
  def ask message
    print message
    STDIN.gets.chomp
  end
  
    
  @dist_rep_cache = {}
  
  def current_community
    @community ||= Community.find_by_name(COMMUNITY_NAME)
  end
  
  def import_bill(xml_link)
    puts "importing #{xml_link}"
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
    @article.community = current_community
    @article.certified = true
    
    @article.save
        
    # this should grab all versions of the bill
    Dir[GOVTRACK_PATH + "bills.text/#{ govtrack_type_from_tom_type @article.number }/#{ govtrack_number @article.number }[^0-9]*.html"].each do |path|
      next if path.match /gen\.html$/ # do not include govtrack generated reports
      version = path.match(/(\D+).html$/)[1]
      unless @article.versions.include?(version) # do not include fetched versions
        @article.edit_version(version, open(path).read)
        @article.set_current_version(version) # create this version
        puts "added #{version}"
        #puts @article.text[0..50]
      else
        puts "skipped #{version}"
      end
    end
    
    parse_actions bill.elements["//actions"]    
    
    #y @article
    puts "imported " + @article.tom_id
  end
  
  def import_roll(xml_link)
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
    type_table[govtrack_type] || raise("Undefined conversion")
  end
  def govtrack_type_from_tom_type(tom_id)
    tom_type = tom_id.match(/\D+/)[0]
    type_table.index(tom_type) || raise("Undefined conversion")
  end
  def type_table
    { "h" => "hr", 
      "hr" => "hres", 
      "hj" => "hjres",
      "hc" => "hconres",
      "s" => "s",
      "sr" => "sres",
      "sc" => "sconres"}
  end
  def govtrack_number(tom_number)
    tom_number.match /(\D+)(\d+)/
    govtrack_type_from_tom_type($1) + $2
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

