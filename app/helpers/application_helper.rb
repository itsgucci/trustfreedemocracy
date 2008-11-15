# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def tag_cloud(tag_counts)
      ceiling = Math.log(tag_counts.max { |a,b| a.count <=> b.count }.count)
      floor = Math.log(tag_counts.min { |a,b| a.count <=> b.count }.count)
      range = ceiling - floor

      tag_counts.each do |tag|
        count = tag.count
        size = (((Math.log(count) - floor)/range)*66)+33
        yield tag, size
      end
    end
  
  def login_logout_link
    if logged_in?
      link_to "logout", '/logout', :help => 'Click here to logout of your Account'
    else
      link_to "sign in", '/login', :help => 'Click here to Sign in to your Account', :style => "font-weight: bold"
    end
  end
  
  def clear_both
    # could probably be done more elegantly with %w or something, 
    # but it has currently slipped my mind
    '<div style="clear:both;"></div>'
  end
  
  def time_left(time)
    distance_of_time_in_words time, Time.now
  end
  
  def help_enabled?
    # we want help on by default, so if it doesnt exist or it is on, display it.
	  session[:help].nil? || session[:help] == true
	end
	
	def help_box(string)
	  if help_enabled?
	    output = '<div class="help_box">'
  	  output += '<div class="header">Help</div>'
  	  output += '<div class="body">'
  	  output += string
  	  output += '</div></div>'
	  end
	end
	
	def toggle_help_link
	  if help_enabled?
	    link_to "on", '/help_toggle', :help => "Turn help off. Everything yellow will be hidden"
    else
      link_to "off", '/help_toggle', :title => "Turn interactive Help on"
    end
  end
  
  def toggle_certified_link
    if certification_filter?
      #link_to_remote "certified", :url => '/certify_toggle', :html => {:id => "certified_toggle"}, :update => "certified_toggle", :complete => "$$('.uncertified').each(function(value) { value.show(); });"
      link_to "on", '/certify_toggle', :id => "certified_toggle", :help => "Click here to show all content"
    else
      #link_to_remote "uncertified", :url => '/certify_toggle', :html => {:id => "certified_toggle", :help => "Click here to show only Certified content"}, :update => "certified_toggle", :complete => "$$('.uncertified').each(function(value) { value.hide(); });"
      link_to "off", '/certify_toggle', :help => "Turn on to view only certified content"
    end
  end
  
  def get_tree_data(tree, parent_id)
    ret = "<div class='outer_tree_element' >"
    tree.each do |node|
      if node.parent_id == parent_id
        node.style = (@ancestors and @ancestors.include?(node.id))? 'display:inline' : 'display:none'
        display_expanded = (@ancestors and @ancestors.include?(node.id))? 'inline' : 'none'
        display_collapsed = (@ancestors and @ancestors.include?(node.id))? 'none' : 'inline'
        ret += "<div class='inner_tree_element' id='#{node.id}_tree_div'>"
        unless node.children.empty?
          ret += "<img id='#{node.id.to_s}expanded' src='/images/expanded.gif' onclick='javascript: return toggleMyTree(\"#{node.id}\"); ' style='display:#{display_expanded}; cursor:pointer;'  />  "
          ret += "<img style='display:#{display_collapsed}; cursor:pointer;'  id='#{node.id.to_s}collapsed' src='/images/collapsed.gif' onclick='javascript: return toggleMyTree(\"#{node.id.to_s}\"); '  />  "
        end

        ret += " <img src='/images/drag.gif' style='cursor:move' id='#{node.id}_drag_image' align='absmiddle' class='drag_image' /> "

        ret += "<span id='#{node.id}_tree_item'>"
        ret += yield node
        ret += "</span>"
        ret += "<span id='#{node.id}children' style='#{node.style}' >"
        ret += get_tree_data(node.children, node.id){|n| yield n}
        ret += "</span>"
        ret += "</div>"
      end
    end
    ret += "</div>"
    return ret
  end
  
  def ajax_module_link(module_name, object)
    link_to_remote module_name,
		 	:url => { :controller => '/modules', :action => 'load_module', 
		 	          :type => object.class, :type_id => object.id, 
		 	          :module => module_name }
  end
  
  def render_module(module_name, object)
    render :partial => '/modules/' + module_name + '/' + module_name, :locals => { :object => object }
  end
  
  def new_page_link(text, object)
    link_to text, :controller => 'pages', :action => 'new', :for_type => object.class, :for_id => object
  end
  
  def description_generator
    %W(war atrocities women hunger american terrorism wal-mart children oil propaganda waste corruption fish baseball sports salmon red green blue orange white racism liberty freedom peace money greed wealth popularity contest wicked cricket unlawful lawful just shower).rand
  end
  
  def interest_select
    select_tag("interest_id", options_for_select( Interest.find(:all, :order => "name ASC").collect {|p| [ p.name, p.id ] } ), { :prompt => "Select an Interest" })
  end
  
  def controller_name
    controller.controller_name.singularize
  end
  
  def split_array(array)
    half = array.size / 2
    return array[0..half], array[half+1..-1]
  end
  
  def editable_content(options)
     options[:content] = { :element => 'span' }.merge(options[:content])
     options[:url] = {}.merge(options[:url])
     options[:ajax] = { :okText => "'Save'", :cancelText => "'Cancel'"}.merge(options[:ajax] || {})
     script = Array.new
     script << "new Ajax.InPlaceEditor("
     script << "  '#{options[:content][:options][:id]}',"
     script << "  '#{url_for(options[:url])}',"
     script << "  {"
     script << options[:ajax].map{ |key, value| "#{key.to_s}: #{value}" }.join(", ")
     script << "  }"
     script << ")"

     content_tag(
       options[:content][:element],
       options[:content][:text],
       options[:content][:options]
     ) + javascript_tag( script.join(" ") )
   end
   
   def in_place_select_editor(options)
        options[:ajax] = { :okText => "'Save'", :cancelText => "'Cancel'"}.merge(options[:ajax] || {})
        script = Array.new
        script << "new Ajax.InPlaceCollectionEditor("
        script << "  '#{options[:content][:options][:id]}',"
        script << "  '#{url_for(options[:url])}',"
        script << "  {"
        script << "  collection: #{options[:collection]},"
        script << options[:ajax].map{ |key, value| "#{key.to_s}: #{value}" }.join(", ")
        script << ",  ajaxOptions: {"
        script << "method: 'post'}"
        script << "  }"
        script << ")"

        content_tag(
          options[:content][:element],
          options[:content][:text],
          options[:content][:options]
        ) + javascript_tag( script.join(" ") )
     end
   
   
   def article_tab(name, article, active = false)
    render :partial => '/shared/tab', :locals => { :controller => "articles", :name => name, :object => article, :active => active }
   end
   
   def show_hide_link( id )
     # todo 2 things
     # this will work most of the time, it is based on rand, which is bad, needs to be unique!
     # the thing always says hide when it should say show again after untoggling it
     random_number = rand 10000
     link_to_function("show", nil, :id => "more_link#{ random_number }", :class => "discreet inline") do |page|
       page.visual_effect :toggle_blind, id
       page.replace_html "more_link#{ random_number }", "hide"
     end
   end
  
  
  def money_place(amount, place)
    cost = amount.abs.to_i.to_s.rjust(15, '0')
    case place
      when :trillion : cost[0..2].to_i
      when :billion : cost[3..5].to_i
      when :million : cost[6..8].to_i
      when :thousand : cost[9..11].to_i
      when :dollars : cost[12..14].to_i
    end
  end
  
  def tabs(unique, tabs)
		tabcontroller = "tabcontroller" + unique
		panecontroller = "panecontroller" + unique
		
		selector = "<ul class='tabselector' id='#{ tabcontroller }'>\n"
		pane = "<ul class='panes' id='#{ panecontroller }'>\n"
		tab = tabs[0]
		selector += "<li help='#{ tab[3] if tab[3] }' class='tab-selected' id='#{ tab[1] }_tab#{ unique }'>" + link_to_function(tab[0], "tabselect('#{ tabcontroller }', $('#{ tab[1] }_tab#{ unique }')); paneselect('#{ panecontroller }', $('#{ tab[1] }_pane#{ unique }'))") + "</li>"
		pane += "<li id='#{ tab[1] }_pane#{ unique }' class='pane-selected'>" + tab[2] + "</li>"
		tabs[1..-1].each do |tab|
		  selector += "<li help='#{ tab[3] if tab[3] }' class='tab-unselected' id='#{ tab[1] }_tab#{ unique }'>" + link_to_function(tab[0], "loadPane($('#{ tab[1] }_pane#{ unique }'), '#{ tab[2] }'), tabselect('#{ tabcontroller }', $('#{ tab[1] }_tab#{ unique }')); paneselect('#{ panecontroller }', $('#{ tab[1] }_pane#{ unique }'))") + "</li>"
		  pane += "<li id='#{ tab[1] }_pane#{ unique }' class='pane-unselected'></li>"
	  end
	  pane += "</ul>"
	  selector += "</ul>"
	  
	  selector + pane
  end
  
  def accountable_submit_tag(text)
  	if logged_in?
  	  submit_tag text
  	else
  	  submit_tag text, :onclick => "showBox('login_required', this.form); return false;"
  	end
  end
  
  def to_sentence_with_links(options = {})
    options.assert_valid_keys(:connector, :skip_last_comma)
    options.reverse_merge! :connector => 'and', :skip_last_comma => false
    options[:connector] = "#{options[:connector]} " unless options[:connector].nil? || options[:connector].strip == ''
  
    case length
      when 0
        ""
      when 1
        link_to(self[0].to_s, self[0])
      when 2
        "#{link_to(self[0], self[0])} #{options[:connector]}#{self[1]}"
      else
        "#{self[0...-1].join(', ')}#{options[:skip_last_comma] ? '' : ','} #{options[:connector]}#{self[-1]}"
    end
  end
  
  def certified_class(item)
    item.certified? ? "certified" : "uncertified"
  end
  
  def nonbreaking(string)
    string.gsub(/\s+/, '&nbsp;')
  end
  
  def pluralize_dull(count, singular, plural = nil)
    "#{count || 0} " + "<span class='dull'>" + ((count == 1 || count == '1') ? singular : (plural || singular.pluralize)) + "</span>"
  end
  
  def current_name
    current_district ? h( current_district.name ) : h(current_community.name)
  end
  def current_full_name
    current_district ? h( current_district.full_name ) : h(current_community.name)
  end
  
  def vote_in_english(vote)
    if vote.vote.nil?
      "Abstain"
    elsif vote.vote == 1
      "Approved"
    elsif vote.vote == 0
      "Opposed"
    elsif vote.vote == 2
      "Present"
    end
  end
  
end
