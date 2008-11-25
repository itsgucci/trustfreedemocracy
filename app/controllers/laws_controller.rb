class LawsController < ApplicationController
  
  
  def index
    @list = current_community.articles.if_certified(certification_filter?).laws.paginate(:page => params[:page], :per_page => 7)
    render :template => 'shared/list'
  end
  
  def show_dead
    @list = current_community.articles.if_certified(certification_filter?).dead.paginate(:page => params[:page], :per_page => 7)
    render :partial => 'real_list'
  end
  def show_unknown
    @list = current_community.articles.if_certified(certification_filter?).unknown.paginate(:page => params[:page], :per_page => 7)
    render :partial => 'real_list'
  end
  def show_exec
    @list = current_community.articles.if_certified(certification_filter?).to_exec.paginate(:page => params[:page], :per_page => 7)
    render :partial => 'real_list'
  end
  def show_signed
    @list = current_community.articles.if_certified(certification_filter?).signed.paginate(:page => params[:page], :per_page => 7)
    render :partial => 'real_list'
  end
  def show_vetoed
    @list = current_community.articles.if_certified(certification_filter?).vetoed.paginate(:page => params[:page], :per_page => 7)
    render :partial => 'real_list'
  end
  def show_overridden
    @list = current_community.articles.if_certified(certification_filter?).overridden.paginate(:page => params[:page], :per_page => 7)
    render :partial => 'real_list'
  end
  
end