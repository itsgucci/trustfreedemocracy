class Admin::TagsController < ApplicationController
  
  before_filter :require_admin
  
  def index
    redirect_to :action => 'list'
  end
  
  def list
    @tags = Tag.find(:all, :order => "name ASC")
  end
  
  def create
    @tag = Tag.new(params[:tag])
    @tag.save
    redirect_to :action => 'list', :add_flash => [ :notice => "#{@tag.name} added" ]
  end
  
end