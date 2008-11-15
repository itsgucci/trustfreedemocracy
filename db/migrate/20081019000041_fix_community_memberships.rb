class FixCommunityMemberships < ActiveRecord::Migration
  def self.up
    Certification.all.each do |cert|
      cert.community = cert.district.community if cert.district
      cert.save
    end
  end

  def self.down
  end
end
