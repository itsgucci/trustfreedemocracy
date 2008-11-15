require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'rexml/document'
require 'net/http'

class Admin::ThomasTasks < ActiveRecord::Base
  
  def squish
    self.gsub(/\s\s+/, " ")
  end
    
  def self.import_all_IH
    doc.search("a[text()*='ih']").each {|e| puts e.html}
  end
  
  def self.import_from_govtrack
    
  end

  def create_article_from_xml(xml_link)
    xml = REXML::Document.new( open( xml_link ))
    
    tom_id = xml.elements["//congress"].text.match(/\d*/)[0] + "-" + xml.elements["//legis-num"].text.gsub(/\s/, "")
    title = xml.elements["//official-title"].text.squish
    body = puts xml.elements["//legis-body"].to_s
    comites = xml.elements["//committee-name"].text.squish
    
  end
  
#  def import_YIC
#    # allow the user to import different number of days ago.
#    # there was not always congressional action yesterday!
#    Net::HTTP.start('thomas.loc.gov', 80) do |http|
#      yesterday = 1.day.ago.at_beginning_of_day
#      ymd = yesterday.strftime("%Y%m%d")
#      yic_link = "/cgi-bin/bdquery?&Db=d110&querybd=@OR(@FIELD(FLD961+#{ ymd })+@FIELD(FLD010+#{ ymd }))"
#      logger.info "requesting yesterday in congress for #{ ymd }"
#      r = http.request_get( yic_link )
#      r.body =~ /<B> 1\.<\/B> <a href="(.+?)">/
#      link = $1
#      
#      if link
#        while link
#          logger.info "requesting link #{ link }"
#          r = http.request_get( link )
#          
#          # all information link
#          r.body =~ /<a href="(.+?)">All Information<\/a>/
#          all_info_link = $1
#          # full text link
#          r.body =~ /<A HREF="(.+?)">Text of Legislation/
#          full_text_link = $1
#          # next link
#          r.body =~ /<a href="(.+?)">NEXT<\/a>/
#          link = $1
#
#          article = Article.new
#          
#          # modified from govtrack
#          BillTypeMap = {
#            'h.r.' => 'h',
#            'h.con.res.' => 'hc',
#            'h.j.res.' => 'hj',
#            'h.res.' => 'hr',
#            's.' => 's',
#            's.con.res.' => 'sc',
#            's.j.res.' => 'sj',
#            's.res.' => 'sr'
#          }
#          type = BillTypeMap[r.body.match(/<hr><br><b>(.+?)(\d+?)<\/b>/)[1].downcase]
#          number = $2
#          
#          
#          article.tom_id = tom_id
#
#          #get all information
#          r = http.request_get(all_info_link)
#          r.body =~ /<hr><br><b>(.+?)<\/b>/
#          legislation.number = $1
#          r.body =~ /<B>Title:<\/B>(.+?)\n/
#          legislation.title = $1.strip
#          r.body =~ /<B>Sponsor: <\/B><a href=".+?">(.+?)<\/a>/
#          legislation.sponsor = $1
#          r.body =~ /SUMMARY.*?<\/b>(.+?)<hr \/>/m
#          legislation.summary = $1.strip
#          r.body =~ /ALL ACTIONS:<\/b>.*?<\/a>(.+?)<hr \/>/m
#          legislation.actions = $1
#          r.body =~ /COSPONSORS.*?<ul>(.+?)<\/ul>/m
#          legislation.cosponsors = $1.gsub(/<a.*?">/,"").gsub(/<\/a>/, '').gsub(/\n/, '').gsub(/<br>/,"\n")
#          r.body =~ /COMMITTEE\(S\):<\/b><\/a><ul>(.+?)<\/ul>/m
#          legislation.committees = $1
#          r.body =~ /RELATED BILL DETAILS:<\/a><\/b><p><ul>(.+?)<\/ul>/m
#          legislation.related_bills = $1
#          r.body =~ /AMENDMENT\(S\):<\/b><\/a>(.+?)<\/div>/m
#          legislation.amendments = $1
#
#          r = http.request_get(full_text_link)
#          legislation.full_text = r.body
#
#          legislation.closing_time = Time.new
#
#          legislation.save
#
#          #puts number, title, sponsor, summary, actions, cosponsors, committees, related, amendments
#        end
#      else
#        logger.info "no congressional action on #{ ymd }"
#      end
#    end
#
#    flash[:notice] = "import successful"
#    redirect_to :action => :list
#
#  end
  
end
