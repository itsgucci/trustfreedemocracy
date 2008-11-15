require 'hpricot'
require 'firewatir'
include FireWatir
require 'ruby-debug'

class Admin::HawaiiCounty < ActiveRecord::Base
  
  Hpricot.buffer_size = 262144
  
  def self.current_community
    @community ||= Community.find_by_name("Hawaii County Council")
  end
  
  def self.import_bills(start = nil)
    ff_master = Firefox.new
    ff_master.goto("http://records.co.hawaii.hi.us/weblink/")
    ff_master.link(:href, "javascript:__doPostBack('TheFolderTree$_ctl1$_ctl2','')").click
    ff_master.link(:href, "javascript:__doPostBack('TheFolderTree$_ctl1$_ctl14$_ctl28$_ctl2','')").click
    ff_master.link(:href, "javascript:__doPostBack('TheFolderTree$_ctl1$_ctl14$_ctl28$_ctl14$_ctl29$_ctl2','')").click
    ff_master.link(:href, "javascript:__doPostBack('TheFolderTree$_ctl1$_ctl14$_ctl28$_ctl14$_ctl29$_ctl14$_ctl37$_ctl2','')").click
    doc = Hpricot ff_master.html
    bills = []
    (doc/".DocumentBrowserNameLink").each do |document|
      if document.attributes['href'].match(/DocView.aspx/)
        bills << document.attributes['href']
      end
    end
    start_index = if start
      bills.index(start) + 1
    else
      0
    end
      
    puts "starting at bill #{start}"
    #import_bill "file:///Users/drake/Desktop/laserfish/DocView33588.html"
    #import_bill("http://records.co.hawaii.hi.us/weblink/DocView.aspx?id=33588")
    bills[start_index..-1].each do |bill|
      import_bill("http://records.co.hawaii.hi.us/weblink/#{bill}")
    end
  end
  
  def self.import_bill(doc_location)
    puts "importing #{doc_location}"    
    @article = current_community.articles.find_by_tom_id(doc_location) || Article.create(:community => current_community, :certified => true, :tom_id => doc_location)

    ff = Firefox.new
    ff.goto(doc_location)    
    ff.link(:id, "ViewTextLink").click
    doc = Hpricot ff.html
    page_count = (doc/".PageNumberToolbarCount").first.html
    puts "reading page 1"
    text_mess = (doc/"#TheTextDisplay_DisplayDiv").html
    (page_count.to_i - 1).times do |n|
      puts "reading page #{n + 2}"
      ff.link(:id, "ThePageNumberToolbar_NextPageButton").click
      doc = Hpricot ff.html
      text_mess << (doc/"#TheTextDisplay_DisplayDiv").html
    end
    @article.text = text_mess
    if title_text = text_mess.gsub(/\t|\n/,'').match(/ORDINANCE  ?NO\.(.*)BE  ?IT  ?ORDAINED  ?BY  ?THE  ?COUNCIL/)
      @article.title = title_text[1].gsub(/<(.|\n)*?>/, '')
    end
    @article.save
    
    actions = (doc/"#TheFieldDisplay_DisplayDiv")
    case (actions/".FieldDisplayTemplateName").html
    when "Template: Bill/Resolution"
      parse_bill actions
    else
      raise "template not defined"
    end
  end
  
  def self.parse_bill(actions)
    (actions/".FieldDisplayName").each do |field|
      title = field.html
      value = field.next.html
      case title
      when "Type"
        case value
        when "BIL"
          @article.article_type_id = 1
        end
      when "Council Term"
        @article.session = value
      when "Bill/Resolution"
        @article.number = value
        puts "article #{@article.number}"
        draft_title = actions.search("div[text()*='Draft']")
        #draft_number = draft_title.next.html
      when "Introducer"
        name = value.match(/[^,]+/)[0] # <- K. Angel Pilago, Councilmember Chair, Planning Committee
        last_name = name.match(/\w+$/)[0] # <- K. Angel Pilago
        if rep = current_community.representatives.find(:first, :conditions => ["users.name LIKE ?", "%#{last_name}"])
          @article.author = rep
          @article.district = current_community.district_represented rep
        end
      when "Referred To"
        # parse comites
      # PC
      when /Action \d+/
        unless value.blank?
          action = Action.new(:community => current_community )
          #action.district = @article.district
          action.created_at = value.match(/\S+\s?$/)[0].strip # <- Council:  Bill 1 postponed to Janaury 19, 2007 Council Meeting - 1/04/07
          if match = value.match(/(.+) - \d?\d[\/|-]\d?\d[\/|-]\d?\d?\d\d$/) # <- Council:  Bill 1 postponed to Janaury 19, 2007 Council Meeting - 1/04/07
            action.action = match[1]
          else
            action.action = value
          end
          @article.actions << action
        end
      when "Status"
        case value
        when "Adopted"
          @article.stage = 5
          adoption_title = actions.search("div[text()*='Date To Mayor or Adoption Date']")
          adoption_date = adoption_title[1].next.html
          @article.updated_at = adoption_date
          #add action signed by mayor!
          action = Action.new(:community => current_community)
          action.created_at = adoption_date
          action.action = "Hawaii County: Bill Signed into Law"
          #@article.actions << action
        else
          @article.stage = 3
        end
      when /Reading Number/
        unless value.blank?
          puts "processing reading #{value}"
          roll_number = @article.number + "-" + value
          roll = @article.rolls.find_by_number(roll_number) || @article.rolls.create(:number => roll_number)
          roll.tom_id = @article.tom_id
          # beyond this, i am practical, not eloquent
          roll.created_at = field.next.next.next.html
          ayes_line = field.next.next.next.next.next.html
          if ayes_match = ayes_line.match(/^(\d+)-?(.*)/)
            roll.aye_count = ayes_match[1]
            ayes_match[2].split(";").each do |last_name|
              roll_vote = RollVote.new
              roll_vote.user = current_community.representatives.find(:first, :conditions => ["users.name LIKE ?", "%#{last_name}"])
              roll_vote.district = current_community.district_represented(roll_vote.user)
              roll_vote.vote = 1
              roll_vote.created_at = roll.created_at
              roll.roll_votes << roll_vote
            end
          end
          noes_line = field.next.next.next.next.next.next.next.html
          if noes_match = noes_line.match(/^(\d+)-?(.*)/)
            roll.nay_count = noes_match[1]
            noes_match[2].split(";").each do |last_name|
              roll_vote = RollVote.new
              roll_vote.user = current_community.representatives.find(:first, :conditions => ["users.name LIKE ?", "%#{last_name}"])
              roll_vote.district = current_community.district_represented(roll_vote.user)
              roll_vote.vote = 0
              roll_vote.created_at = roll.created_at
              roll.roll_votes << roll_vote
            end
          end
          absent_line = field.next.next.next.next.next.next.next.next.next.html
          if absent_match = absent_line.match(/^(\d+)-?(.*)/)
            # super fucking gross. super fucking embarassing. fuck it. 
            absent_count = absent_match[1]
            absent_names = absent_match[2].split(";")
          else
            absent_count = 0
            absent_names = []
          end
          excused_line = field.next.next.next.next.next.next.next.next.next.next.next.html
          if excused_match = excused_line.match(/^(\d+)-?(.*)/)
            roll.novote_count = excused_match[1].to_i + absent_count.to_i
            novote_names = excused_match[2].split(";") + absent_names
          else
            roll.novote_count = absent_count.to_i
            novote_names = absent_names
          end
          novote_names.each do |last_name|
            roll_vote = RollVote.new
            roll_vote.user = current_community.representatives.find(:first, :conditions => ["users.name LIKE ?", "%#{last_name}"])
            roll_vote.district = current_community.district_represented(roll_vote.user)
            roll_vote.vote = 2
            roll_vote.created_at = roll.created_at
            roll.roll_votes << roll_vote
          end
          roll.result = if roll.aye_count > roll.nay_count && roll.aye_count > roll.novote_count
            "Passed"
          elsif roll.nay_count > roll.aye_count && roll.nay_count > roll.novote_count
            "Rejected"
          else
            "Not Sustained"
          end
          roll.save
        end
        if false # to collapse the example. maybe there is an easier way. 
      # Reading Number
      # 1
      # Reading Date
      # 1/19/2007
      # when "Ayes"
      # 6-Higa;Hoffmann;Ikeda;Naeole;Yagong;Yoshimoto
      # "Noes"
      # 3-Ford;Jacobson;Pilago
      # "Absent"
      # 0-
      # "Excused"
      # 0-
      # Reading Number .
      # 2
      # Reading Date .
      # 2/7/2007
      # Ayes .
      # 5-Higa;Hoffmann;Ikeda;Yagong;Yoshimoto
      # Noes .
      # 3-Ford;Jacobson;Pilago
      # Absent .
      # 1-Naeole
      # Excused .
      # 0-
      # Reading Number ..
      # 
      # Reading Date ..
      # 
      # Ayes ..
      # 
      # Noes ..
      # 
      # Absent ..
      # 
      # Excused ..
      # 
        end
      
      end
    # File Code
    # 
    # Comments  
    end
    @article.save
  end
  
  def self.parse_text(text_mess)
    puts "parsing text"
    puts text_mess
  end
end