xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.bill do
  xml.status do
    if @article.draft? || @article.focus?
      xml.development
    elsif @article.in_comite?
      xml.introduced
    elsif @article.legislation?
      xml.vote
    elsif @article.to_exec?
      xml.topresident
    elsif @article.signed?
      xml.signed
    elsif @article.vetoed?
      xml.veto
    elsif @article.overridden?
      xml.override
    elsif @article.law?
      xml.enacted
    elsif @article.dead?
      xml.dead
    else
      xml.calendar
      xml.vote2
    end
  end
  xml.introduced @article.updated_at
  xml.titles do
    xml.title @article.title
  end
  xml.sponsor @article.author.name if @article.author
  xml.cosponsors do
    @article.cosponsors.each do |user|
      xml.cosponsor
    end
  end
  xml.actions do
    @article.actions.each do |action|
      xml.action action.action
    end
  end
  xml.committees do
    @article.comites.each do |comite|
      xml.committee
    end
  end
end