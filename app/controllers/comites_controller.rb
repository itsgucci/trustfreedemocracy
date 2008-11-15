class ComitesController < ApplicationController
  # GET /comites
  # GET /comites.xml
  def index
    #@comites = current_district.parent.comites.find(:all)
    #@unassigned_articles = current_district.parent.children.map(&:articles_in_comite).flatten - current_district.articles.in_comite
    
    @list = current_community.articles.if_certified(certification_filter?).in_comite.paginate(:page => params[:page], :per_page => 13)
    render :template => '/shared/list'
  end
  
  def assign
    article = Article.find(params[:id])
    comite = Comite.find(params[:comite])
    comite.articles << article
  end

  # GET /comites/1
  # GET /comites/1.xml
  def show
    @comite = Comite.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comite }
    end
  end

  # GET /comites/new
  # GET /comites/new.xml
  def new
    @comite = Comite.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comite }
    end
  end

  # GET /comites/1/edit
  def edit
    @comite = Comite.find(params[:id])
  end

  # POST /comites
  # POST /comites.xml
  def create
    @comite = Comite.new(params[:comite])

    respond_to do |format|
      if @comite.save
        flash[:notice] = 'Comite was successfully created.'
        format.html { redirect_to(@comite) }
        format.xml  { render :xml => @comite, :status => :created, :location => @comite }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comite.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comites/1
  # PUT /comites/1.xml
  def update
    @comite = Comite.find(params[:id])

    respond_to do |format|
      if @comite.update_attributes(params[:comite])
        flash[:notice] = 'Comite was successfully updated.'
        format.html { redirect_to(@comite) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comite.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comites/1
  # DELETE /comites/1.xml
  def destroy
    @comite = Comite.find(params[:id])
    @comite.destroy

    respond_to do |format|
      format.html { redirect_to(comites_url) }
      format.xml  { head :ok }
    end
  end
end
