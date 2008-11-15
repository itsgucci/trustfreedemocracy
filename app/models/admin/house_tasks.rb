require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'rexml/document'
require 'net/http'

class Admin::HouseTasks < ActiveRecord::Base
  
  @community = Community.find_by_name "United States Congress"
  
  def self.first_import
    create_districts
    import_users
    identify_reps
    create_comites
    bill = "HB5"
    import_house_bill(bill)
  end
  
  def self.daily_update
  end
  
  private
  
  def import_users
    puts "no users imported"
  end
  
  def self.identify_reps
    page = open("http://www.house.gov/") { |f| Hpricot(f) }
    rest = []
    (page/"#Representative_Alphabetical_Dropdown_Listing//option").each do |option|
      line = option.html.strip
      if line =~ /^([^,]+), ([^,]+), ([^,]+), (\d?\d\w\w|At Large)$/
        User.transaction do
          District.transaction do
            first =$2; last = $1
            user = User.create(:name => first + " " + last, :salt => "")
            user.save_without_validation
            state = $3; district = $4
            district = District.create(:name => "#{state} #{district}", :community_id => @community.id, :user_id => user.id)
            puts "created #{state} #{district} with rep #{first} #{last}"
          end
        end
      else
        rest << line
      end
    end
    puts rest
  end
  
  def create_districts
    page = open("http://capitol.hawaii.gov/site1/house/members/members.asp") { |f| Hpricot(f) }
    rows = page.at("//div[@id='maincontent']/table").children[3..-1]
    rows.each do |row|
      line = row.at('//td[2]')
      District.create(:parent_id => 2, :name => line.html) if line
    end
    page = open("http://capitol.hawaii.gov/site1/senate/members/members.asp") { |f| Hpricot(f) }
    rows = page.at("//div[@id='maincontent']/table").children[3..-1]
    rows.each do |row|
      line = row.at('//td[2]')
      District.create(:parent_id => 2, :name => line.html) if line
    end
  end
  
  def create_comites
    # take it from the house
    page = open("http://capitol.hawaii.gov/site1/house/comm/comm.asp") { |f| Hpricot(f) }
    rows = page.search("//div[@id='maincontent']//ul/li/a")
    rows.each do |row|
      comite = row.html.match(/(\w\w\w): Committee on (.*)$/)
      Comite.create(:district_id => 2, :name => comite[2], :tom_id => comite[1] )
      output "#{comite[2]} created"
    end
    # get it from the senate
    page = open("http://capitol.hawaii.gov/site1/senate/comm/comm.asp") { |f| Hpricot(f) }
    rows = page.search("//div[@id='maincontent']//ul/li/a")
    rows.each do |row|
      comite = row.html.match(/(\w\w\w): Committee on (.*)$/)
      Comite.create(:district_id => 2, :name => comite[2], :tom_id => comite[1] )
      output "#{comite[2]} created"
    end
  end
  
  def self.import_house_bill(bill)
    report_page = open("http://capitol.hawaii.gov/session2008/CommReports/") { |f| Hpricot(f) }
    district = District.find(2)
    
    #find or create the article
    article = district.articles.find_by_tom_id( bill ) || Article.create(:tom_id => bill, :district_id => district.id)
    
    status = open("http://www.capitol.hawaii.gov/session2008/lists/getstatus2.asp?billno=#{ bill }") { |f| Hpricot(f) }
    output "opening #{ bill }"
    
    prev_actions = article.actions
    # find and read all the actions on the item
    actions = status.at("//table").children[3..-1]
    # this should take all new actions and process them
    # new here is based on the assumption actions are added in order and always increase in size
    actions[prev_actions.size..-1].each do |action|
      puts action.html
     # pieces = action.html.match(/<td>(.*)<\/td><td>(.*)<\/td><td>(.*)<\/td>/)
      date = action.at(["/td[1]"]).html
      house = action.at(["/td[2]"]).html
      action = action.at(["/td[3]"]).html
      
      #action parser
      
      logged = false
      
      case action
      when /Introduced and Pass First Reading/
        logger.info "introduced and passed 1st reading by #{ house }"
        #article.author = status.at("/html/body/div[@id='reportwrapper']/div[@id='reportbody']/div[7]/div[2]").html.strip.split(", ")
        doc = open("http://capitol.hawaii.gov/session2008/bills/#{ bill }_.htm") { |f| Hpricot(f) }
        article.title = doc.at("//p[@class='ReportTitle']/i").html
        article.summary = doc.at("//p[@class='Description']/i").html
        article.text = doc.at("//div[@class='Section3']").children[1..-8].join
        if house == "H"
          article.house_stage = 1
        else
          article.senate_stage = 1
        end
        #move it to the comite stage
        article.stage = 3
        output "#{article.title} created"
        logged = true if article.save
      when /Received from House/
        logged = true if article.update_attribute(:senate_stage, 0)
      when /Received from Senate/
        logged = true if article.update_attribute(:house_stage, 0)
      when /Passed First Reading/
        logger.info "passed 1st reading by #{ house }"
        if house == "H"
          article.update_attribute(:house_stage, 1)
        else
          article.update_attribute(:senate_stage, 1)
        end
        logged = true
      when /Referred to/
        tom_ids = action.match(/Referred to (.*)/)[1].gsub(/\//, ", ").gsub(/\./, "").split(", ")
        district.comites.find_all_by_tom_id(tom_ids).each do |comite|
          comite.articles << article
        end
        
        if house == "H"
          article.house_stage = article.house_stage + 1
        else
          article.senate_stage = article.senate_stage + 1
        end
        logged = true
      when /The committee\(?s\)? on \w\w\w recommend/
        # passes out of comite
        tom_id = action.match(/The committee\(?s\)? on (\w\w\w) recommend/)[1]
        district.comites.find_by_tom_id(tom_id).pass(article, date)
        logged = true
      when /Stand. Com. Rep. No./
        # get the report from the file when it exists
        # match needs to be . and not \d because sometimes the number includes a dash
        number = action.match(/\(Stand. Com. Rep. No. (.*)\)/)[1]
        link = report_page.search("a[text()*='HSCR#{ number }_.htm']").html
        report = open("http://capitol.hawaii.gov/session2008/CommReports/#{ link }") { |f| Hpricot(f) }
        
        # seems that it is usually at 22, but occasionally at 21. go figure.
        title_tag = report.at("/html/body/div/p[22]")
        if title_tag
          title = title_tag.html
        else
          title = report.at("/html/body/div/p[21]").html
        end
        
        # remove the html tags and blank rows
        content = report.at("/html/body").html.gsub(/<\/?[^>]*>/, "").gsub(/\r\n&nbsp;/, "")
        if article.add_report(title, content)
          output "report #{link} processed"
          logger.info "added report #{ link }"
          logged = true
        end
      when /Passed Second Reading/
        amendment = action.match(/as amended (in )?\((.*?)\)/)
        if amendment
          # load in the new article
          amend = open("http://capitol.hawaii.gov/session2008/bills/#{ bill }_#{ amendment[2].gsub(/ /, "") }_.htm") { |f| Hpricot(f) }
          article.title = amend.at("//p[@class='ReportTitle']/i").html
          article.summary = amend.at("//p[@class='Description']/i").html
          article.text = amend.at("//div[@class='Section3']").children[1..-8].join
          article.save
        end
        # find comites refered to
        comites = action.match(/referred to (the committee\(s\) on )?(.*)/)
        logger.info "passed 2nd reading by #{ house }"
        if house == "H"
          article.update_attribute(:house_stage, 3)
        else
          article.update_attribute(:senate_stage, 3)
        end
        logged = true
      when /Passed Third Reading/
        amendment = action.match(/as amended (in )?\((.*?)\)/)
        if amendment
          # load in the new article
          amend = open("http://capitol.hawaii.gov/session2008/bills/#{ bill }_#{ amendment[2].gsub(/ /, "") }_.htm") { |f| Hpricot(f) }
          article.title = amend.at("//p[@class='ReportTitle']/i").html
          article.summary = amend.at("//p[@class='Description']/i").html
          article.text = amend.at("//div[@class='Section3']").children[1..-8].join
        end
        logger.info "passed 3rd reading by #{ house }"
        if house == "H"
          article.update_attribute(:house_stage, 5)
        else
          article.update_attribute(:senate_stage, 5)
        end
        logged = true
      end
      
      article.actions << Action.new(:district_id => 2, :created_at => date, :house => house, :action => action, :processed => logged)
    end
  end
    
  def self.output(string)
    puts string
  end
  
end