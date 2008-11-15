class TagsController < ApplicationController
  
  
  def index
    redirect_to :action => 'list_interests'
  end
  
  def list
    @interest = Interest.find(params[:id])
    @tags = @interest.tags
  end
  
  def list_interests
    @interests = Interest.find(:all, :order => "name ASC")
  end
  
  def show
    @tag = Tag.find(params[:id])
  end
  
end