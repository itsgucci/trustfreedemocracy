#!/usr/local/bin/ruby
require 'net/http'

Net::HTTP.start('thomas.loc.gov', 80) do |http|
  yesterday = Time.new - 86400 # 86400 seconds is one day
  ymd = yesterday.strftime("%Y%m%d")
  link = "/cgi-bin/bdquery?&Db=d110&querybd=@OR(@FIELD(FLD961+#{ymd})+@FIELD(FLD010+#{ymd}))"
  r = http.request_get(link)
  r.body =~ /<B> 1\.<\/B> <a href="(.+?)">/
  first_link = $1
  
  r = http.request_get(first_link)
  while r.body do
    
    # all information link
    r.body =~ /<a href="(.+?)">All Information<\/a>/
    all_info_link = $1
    # full text link
    r.body =~ /<A HREF="(.+?)">Text of Legislation/
    full_text_link = $1
    # next link
    r.body =~ /<a href="(.+?)">NEXT<\/a>/
    next_link = $1
    
    #get all information
    r = http.request_get(all_info_link)
    r.body =~ /<hr><br><b>(.+?)<\/b>/
    number = $1
    r.body =~ /<B>Title:<\/B>(.+?)\n/
    title = $1.strip
    r.body =~ /<B>Sponsor: <\/B><a href=".+?">(.+?)<\/a>/
    sponsor = $1
    r.body =~ /SUMMARY.*?<\/b>(.+?)<hr \/>/m
    summary = $1.strip
    r.body =~ /ALL ACTIONS:<\/b>.*?<\/a>(.+?)<hr \/>/m
    actions = $1.strip
    r.body =~ /COSPONSORS.*?<ul>(.+?)<\/ul>/m
    cosponsors = $1
    r.body =~ /COMMITTEE\(S\):<\/b><\/a><ul>(.+?)<\/ul>/m
    committees = $1
    r.body =~ /RELATED BILL DETAILS:<\/a><\/b><p><ul>(.+?)<\/ul>/m
    related = $1
    r.body =~ /AMENDMENT\(S\):<\/b><\/a>(.+?)<\/div>/m
    amendments = $1
    
    #puts number, title, sponsor, summary, actions, cosponsors, committees, related, amendments
    
    #get full text
    r = http.request_get(full_text_link)
    #puts r.body
    

    r = http.request_get(next_link)
    puts next_link
    break if r.body == nil
  end
  
  
end