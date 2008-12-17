# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081217002024) do

  create_table "actions", :force => true do |t|
    t.integer  "district_id"
    t.integer  "article_id"
    t.string   "house",        :limit => 2
    t.text     "action"
    t.datetime "created_at"
    t.boolean  "processed",                 :default => false, :null => false
    t.integer  "community_id"
  end

  create_table "api_users", :force => true do |t|
    t.string   "login"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "article_versions", :force => true do |t|
    t.integer  "article_id",                                                :null => false
    t.integer  "district_id",                                               :null => false
    t.integer  "user_id"
    t.string   "title",       :limit => 420
    t.text     "summary"
    t.text     "text"
    t.decimal  "cost",                       :precision => 20, :scale => 2
    t.integer  "stage",       :limit => 1,                                  :null => false
    t.integer  "version",                                                   :null => false
    t.datetime "updated_at",                                                :null => false
  end

  create_table "articles", :force => true do |t|
    t.string   "tom_id",          :limit => 1000
    t.integer  "community_id",                                                                          :null => false
    t.integer  "district_id"
    t.integer  "user_id"
    t.integer  "article_type_id",                                                    :default => 1,     :null => false
    t.text     "title"
    t.text     "summary"
    t.text     "text",            :limit => 16777215
    t.integer  "stage",           :limit => 1,                                       :default => 1,     :null => false
    t.decimal  "cost",                                :precision => 20, :scale => 2
    t.integer  "version"
    t.datetime "updated_at",                                                                            :null => false
    t.boolean  "certified",                                                          :default => false, :null => false
    t.integer  "support_count",                                                      :default => 0
    t.integer  "session",                                                            :default => 0
    t.integer  "focus_count",                                                        :default => 0
    t.string   "number"
    t.decimal  "cost_per_hour",                       :precision => 8,  :scale => 2
    t.datetime "created_at"
  end

  add_index "articles", ["community_id"], :name => "community"
  add_index "articles", ["stage"], :name => "stage"
  add_index "articles", ["district_id"], :name => "district"

  create_table "articles_supporters", :force => true do |t|
    t.integer  "article_id",                         :null => false
    t.integer  "article_version"
    t.integer  "user_id",                            :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "ended_at"
    t.boolean  "certified",       :default => false
  end

  create_table "badges_privileges", :force => true do |t|
    t.string   "name",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badges_role_privileges", :force => true do |t|
    t.integer  "role_id"
    t.integer  "privilege_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badges_roles", :force => true do |t|
    t.string   "name",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badges_user_roles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "object_type", :default => "",   :null => false
    t.integer  "object_id",                     :null => false
    t.boolean  "active",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "district_id",                         :null => false
    t.string   "certification_number", :limit => 200
    t.string   "certification_pin"
    t.string   "certified_name",       :limit => 155
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "external_source"
    t.string   "external_id"
    t.integer  "community_id"
  end

  add_index "certifications", ["user_id"], :name => "user"

  create_table "comite_stages", :force => true do |t|
    t.integer  "comite_id",                                :null => false
    t.integer  "article_id",                               :null => false
    t.integer  "status_code",               :default => 0, :null => false
    t.datetime "ended_at"
    t.datetime "created_at",                               :null => false
    t.integer  "house_stage",  :limit => 1
    t.integer  "senate_stage", :limit => 1
  end

  create_table "comites", :force => true do |t|
    t.integer "district_id"
    t.string  "name"
    t.string  "tom_id",      :limit => 6
  end

  create_table "comments", :force => true do |t|
    t.integer  "category_code",    :limit => 1,   :default => 0,     :null => false
    t.string   "title",            :limit => 500
    t.text     "comment"
    t.datetime "created_at",                                         :null => false
    t.integer  "commentable_id",                  :default => 0,     :null => false
    t.string   "commentable_type", :limit => 15,  :default => "",    :null => false
    t.integer  "user_id",                         :default => 0
    t.boolean  "certified",                       :default => false
  end

  add_index "comments", ["created_at"], :name => "created"
  add_index "comments", ["category_code"], :name => "category"
  add_index "comments", ["commentable_type", "commentable_id"], :name => "type_and_id"
  add_index "comments", ["user_id"], :name => "fk_comments_user"

  create_table "communities", :force => true do |t|
    t.integer  "parent_id",      :default => 0,    :null => false
    t.string   "name",           :default => "",   :null => false
    t.integer  "tax_population", :default => 1,    :null => false
    t.integer  "user_id"
    t.string   "community_url"
    t.integer  "session",        :default => 1
    t.boolean  "visible",        :default => true
    t.datetime "sync_date"
  end

  add_index "communities", ["parent_id"], :name => "parent_id"
  add_index "communities", ["name"], :name => "name"

  create_table "districts", :force => true do |t|
    t.integer "community_id",                                        :null => false
    t.integer "user_id"
    t.string  "name",                                :default => "", :null => false
    t.string  "description",          :limit => 500
    t.integer "certifications_count",                :default => 0,  :null => false
    t.string  "fip_code",             :limit => 20
    t.integer "top_priority"
  end

  add_index "districts", ["certifications_count"], :name => "residences"

  create_table "endorsements", :force => true do |t|
    t.integer  "article_id",                     :null => false
    t.integer  "user_id",                        :null => false
    t.integer  "district_id",                    :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "ended_at"
    t.boolean  "certified",   :default => false
  end

  create_table "facebook_templates", :force => true do |t|
    t.string   "bundle_id"
    t.string   "template_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "interests", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  create_table "legislations", :force => true do |t|
    t.integer  "article_id",   :null => false
    t.datetime "created_at",   :null => false
    t.datetime "closing_time"
  end

  create_table "mailing_lists", :force => true do |t|
    t.string   "email",                    :default => "",   :null => false
    t.string   "zip",        :limit => 10, :default => "",   :null => false
    t.datetime "created_on",                                 :null => false
    t.boolean  "active",                   :default => true, :null => false
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id",                                     :null => false
    t.integer  "from_user_id"
    t.string   "message",      :limit => 880, :default => "", :null => false
    t.integer  "status_code",  :limit => 1,   :default => 1,  :null => false
    t.datetime "created_at",                                  :null => false
  end

  create_table "page_versions", :force => true do |t|
    t.integer  "page_id"
    t.integer  "version"
    t.string   "title"
    t.text     "content"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.integer "version"
    t.string  "title"
    t.text    "content"
    t.integer "lock_version",  :default => 0
    t.string  "pageable_type"
    t.integer "pageable_id"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rating",                      :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",                 :default => 0,  :null => false
    t.integer  "user_id",                     :default => 0,  :null => false
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "representative_votes", :force => true do |t|
    t.integer  "article_id",  :null => false
    t.integer  "district_id", :null => false
    t.integer  "user_id",     :null => false
    t.boolean  "vote",        :null => false
    t.datetime "created_on",  :null => false
  end

  add_index "representative_votes", ["district_id", "article_id"], :name => "district_article"
  add_index "representative_votes", ["article_id"], :name => "article"
  add_index "representative_votes", ["article_id", "district_id"], :name => "art_dist", :unique => true

  create_table "roll_votes", :force => true do |t|
    t.integer  "roll_id"
    t.integer  "user_id"
    t.integer  "district_id"
    t.integer  "community_id"
    t.integer  "vote"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rolls", :force => true do |t|
    t.integer  "article_id"
    t.string   "tom_id"
    t.string   "number"
    t.string   "house"
    t.string   "session"
    t.string   "kind"
    t.string   "question"
    t.string   "required"
    t.string   "result"
    t.integer  "aye_count",     :default => 0
    t.integer  "nay_count",     :default => 0
    t.integer  "present_count", :default => 0
    t.integer  "novote_count",  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "community_id"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at",    :null => false
  end

  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"

  create_table "tags", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  create_table "tickets", :force => true do |t|
    t.integer  "worth",           :limit => 10
    t.integer  "community_id"
    t.string   "transaction_id"
    t.text     "amazon_response"
    t.string   "currency",                      :default => "leaf"
    t.integer  "amount",          :limit => 10
    t.string   "fee_currency",                  :default => "USD"
    t.integer  "fee_amount",      :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                   :default => "", :null => false
    t.string   "email",                                   :default => "", :null => false
    t.string   "crypted_password",          :limit => 40, :default => "", :null => false
    t.string   "salt",                      :limit => 40, :default => "", :null => false
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.string   "remember_token",                          :default => ""
    t.datetime "remember_token_expires_at"
    t.string   "zip",                       :limit => 20, :default => "", :null => false
    t.string   "facebook_id"
    t.string   "name"
  end

  add_index "users", ["login"], :name => "login"

  create_table "votes", :force => true do |t|
    t.integer  "user_id",                                     :null => false
    t.string   "voteable_type", :limit => 25, :default => "", :null => false
    t.integer  "voteable_id",                                 :null => false
    t.integer  "vote",          :limit => 2
    t.datetime "created_at",                                  :null => false
  end

  create_table "zip_fips", :id => false, :force => true do |t|
    t.integer "zip",                                             :null => false
    t.string  "po_name",          :limit => 20
    t.string  "state_county_fip", :limit => 5
    t.string  "state_fip",        :limit => 2
    t.string  "state",            :limit => 50
    t.string  "county_fip",       :limit => 3
    t.string  "county",           :limit => 50
    t.float   "zip_squaremile",                 :default => 0.0
  end

end
