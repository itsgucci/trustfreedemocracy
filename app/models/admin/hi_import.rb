require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'rexml/document'
require 'net/http'

class Admin::HiImport < ActiveRecord::Base
  
  @community = Community.find_by_name('Hawaii State Congress')
  
  def self.first_import
    create_districts
    import_users
    identify_reps
    create_comites
    bill = "HB5"
    import_house_bill(bill)
  end
  
  def self.daily_import
    6.upto 10 do |n|
      import_house_bill("HB" + n.to_s )
    end
  end
  
  private
  
  def import_users
    puts "no users imported"
  end
  
  def self.identify_reps
    page = open("http://capitol.hawaii.gov/site1/house/members/members.asp") { |f| Hpricot(f) }
    rows = page.at("//div[@id='maincontent']/table").children[3..-1]
    rows.each do |row|
      line = row.at('//td[1]')
      user = line.html if line
      if user
        User.find_by_last_name(user.match(/\w+/)).grant_role("representative", District.find_by_name(row.at('//td[2]').html))
      end
    end
    page = open("http://capitol.hawaii.gov/site1/senate/members/members.asp") { |f| Hpricot(f) }
    rows = page.at("//div[@id='maincontent']/table").children[3..-1]
    rows.each do |row|
      line = row.at('//td[1]')
      user = line.html if line
      if user
        User.find_by_last_name(user.match(/\w+/)).grant_role("representative", District.find_by_name(row.at('//td[2]').html))
      end
    end
  end
  
  def self.create_districts
    page = open("http://capitol.hawaii.gov/site1/house/members/members.asp") { |f| Hpricot(f) }
    rows = page.at("//div[@id='maincontent']/table").children[3..-1]
    rows.each do |row|
      line = row.at('//td[2]')
      District.create(:community => @community, :name => "House " + line.html) if line
    end
    page = open("http://capitol.hawaii.gov/site1/senate/members/members.asp") { |f| Hpricot(f) }
    rows = page.at("//div[@id='maincontent']/table").children[3..-1]
    rows.each do |row|
      line = row.at('//td[2]')
      District.create(:community => @community, :name => "Senate " + line.html) if line
    end
  end
  
  def self.import_reports
    doc = open("http://capitol.hawaii.gov/session2008/commreports/") { |f| Hpricot(f) }
    puts "loaded reports page"
    @community.articles.each do |article|
      if title = article.title
        if number = title.match(/\d+/)
          puts "working on bill #{ number }"
          report_links = doc.search("a").select { |ele| ele.inner_text =~ /HB#{ number }_.*_\.htm/ }
          report_links.each do |link|
            #puts("http://capitol.hawaii.gov#{ link }")
            import_report(article, "http://capitol.hawaii.gov/session2008/commreports/#{ link.html }")
          end
        end
      end
    end
  end
  
  def self.import_report(article, url)
    report = open(url) { |f| Hpricot(f) }
    
    # seems that it is usually at 22, but occasionally at 21. go figure.
    title_tag = report.at("/html/body/div/p[22]")
    if title_tag
      title = title_tag.html
    else
      title = report.at("/html/body/div/p[21]").html
    end
    
    content = "Original Source: #{ url }"
    # remove the html tags and blank rows
    content << report.at("/html/body").html.gsub(/<\/?[^>]*>/, "").gsub(/\r\n&nbsp;/, "")
    
    if article.add_report(title, content)
      puts "processed #{title}"
    else
      puts "failed #{ title }"
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
  
  def self.import_bills
    #doc = open("http://capitol.hawaii.gov/session2008/bills/") { |f| Hpricot(f) }
    20.upto 200 do |n|
      import_bill("http://capitol.hawaii.gov/session2008/bills/HB#{ n.to_s }_.htm")
    end
  end
  
  def self.import_actions
    @community.articles[116..-1].each do |article|
      if title = article.title
        if number = title.match(/\d+/)
          import_action("HB #{ number[0] }")
        end
      end
    end
  end
  
  def self.import_action(bill)
    begin
      puts "Importing action for #{ bill }"
      article = Article.find_by_tom_id("http://capitol.hawaii.gov/session2008/bills/#{bill.gsub(/\s/,'').upcase}_.htm")
      puts "found article" if article
      doc = open("http://www.capitol.hawaii.gov/session2008/rss/#{bill.gsub(/\s/,'').upcase}.xml") { |f| Hpricot(f) }
      doc.search('item').each do |item|
        puts date = (item/"title").html.match(/\d\d?\/\d\d?\/\d\d/)[0]
        puts title = (item/"title").html
        puts house = (item/"description").html.match(/: (H|S)/)[1]
        article.actions.create(:created_at => date, :action => title, :house => house)
      end
    rescue
      puts "Actions failed to import on #{ bill }"
    end
  end
  
  def self.import_bill(url)
    begin
      puts "Importing #{url}"
      doc = open(url) { |f| Hpricot(f) }
      article = Article.find_or_create_by_tom_id(:tom_id => url, :community_id => @community.id)
      header_section = doc.search("//p[@class='ChamberHeading']")
      article.title = doc.at("//p[@class='MeasureNumberHeading']").html + " " + header_section[1].html + ": " + doc.at("//p[@class='ReportTitle']/i").html
      article.summary = doc.at("//p[@class='Description']/i").html
      article.text = doc.at("//div[@class='Section3']").children[1..-8].join
      article.text += doc.at("//div[@class='Section4']").children[1..-8].join if doc.at("//div[@class='Section4']")
      article.certified = true
      article.stage = 0
      article.save
      puts "Success: #{ article.title }"
    rescue
      puts "Unable to find Bill at #{ url }"
      return false
    end
  end
  
  def self.import_action_on_bill(bill)
    report_page = open("http://capitol.hawaii.gov/session2008/CommReports/") { |f| Hpricot(f) }
    
    #find or create the article
    article = Article.find_by_tom_id( bill )
    
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