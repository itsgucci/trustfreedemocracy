class Admin::DistrictsController < ApplicationController
    
  def index
    redirect_to :action => :show
  end
  
  def show
    @items = Community.find(:all)
    @item = Community.find(:first)
    # select according to your choice...
    #this item will be selected node by default in the tree when it will first be loaded.
  end

  def display_clicked_item
    # this action will handle the two way syncronization...all the tree nodes(items) will be linked
    # to this action to show the detailed item on the left of the tree when the item is clicked
    # from the tree
    if request.xhr?
      @item = Community.find(params[:id]) rescue nil
      if @item
        # the code below will render all your RJS code inline and
        # u need not to have any .rjs file, isnt this interesting
        render :update do |page|
          page.hide "selected_item"
          page.replace_html "selected_item", :partial=>"item", :object=>@item
          page.visual_effect 'slide_down', "selected_item"
        end
      else
        return render :nothing => true
      end
    end
  end

  def sort_ajax_tree
    if request.xhr?
      if @item = Community.find(params[:id].split("_").first) rescue nil
        parent_item = Community.find(params[:parent_id])
        render :update do |page|
          @item.parent_id = parent_item.id
          @item.save
          @items = Community.find(:all)
          page.replace_html "ajaxtree", :partial=>"ajax_tree", :object=>[@item,@items]
          page.hide "selected_item"
          #page.replace_html "selected_item", :partial=>"item", :object=>@item
          #page.visual_effect 'toggle_appear', "selected_item"
        end
      else
        return render :nothing => true
      end
    end
  end
  
  def create_community
    if request.xhr?
      @community = Community.new(params[:community])
      @community.save
      render :update do |page|
        @items = Community.find(:all)
        @item = @community
        page.replace_html "ajaxtree", :partial=>"ajax_tree", :object=>[@item,@items]
        page.replace_html 'community_name', ""
      end
    end
  end
  
  def update
      district = Community.find(params[:id])
      district.name = params[:value]
      district.save
      district.reload
      render :text => district.name
    end

end
