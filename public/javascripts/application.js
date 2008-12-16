// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


// create popups for each element with a title attribute
Event.observe(window,"load",function() {
	$$("*").findAll(function(node){
		return node.getAttribute('title');
	}).each(function(node){
		new Tooltip(node,node.title,'tooltip');
		node.removeAttribute("title");
	});
});

// grow_text_area written by markos.gaivo.net
function grow_text_area(textarea) {
	// Opera isn't just broken. It's really twisted.
	while (textarea.scrollHeight > textarea.clientHeight && !window.opera)
		textarea.rows += 3;
}

// limit the text area length from http://www.mediacollege.com/internet/javascript/form/limit-characters.html
function limitText(field, limitNum, update) {
	if (field.value.length > limitNum)
		field.value = field.value.substring(0, limitNum);
	$(update).innerHTML = field.value.length;
}

//fade the flash
Event.observe(window, 'load', function() { 
  $A(document.getElementsByClassName('alert')).each(function(o) {
	new Effect.Fade(o, {duration: 4.0, delay: 10.0});
  });
});

// from http://actsasflinn.com/Ajax_Tabs/index.html
function tabselect(tab_controller, tab) {
  var tablist = $(tab_controller).getElementsByTagName('li');
  var nodes = $A(tablist);
  var lClassType = tab.className.substring(0, tab.className.indexOf('-') );

  nodes.each(function(node){
    if (node.id == tab.id) {
      tab.className=lClassType+'-selected';
    } else {
      node.className=lClassType+'-unselected';
    };
  });
}
function paneselect(pane_controller, pane) {
  //var panelist = $(pane_controller).getElementsByTagName('li');
  // fixed this. above code was making nested lists have unselected and never undoing it. below code appears to work
  var panelist = $(pane_controller).childNodes;
  var nodes = $A(panelist);

  nodes.each(function(node){
    if (node.id == pane.id) {
      pane.className='pane-selected';
    } else {
      node.className='pane-unselected';
    };
  });
}
function loadPane(pane, src) {
  if (pane.innerHTML=='' || pane.innerHTML=='<div style="text-align:center"><img alt="Wait" src="/images/indicator.png" style="margin: 0 auto; height: 240px" /></div>' || pane.className == 'pane-selected') {
    reloadPane(pane, src);
  }
}
function reloadPane(pane, src) {
  new Ajax.Updater(pane, src, {asynchronous:1, evalScripts:true, onLoading:function(request){pane.innerHTML='<div style="text-align:center"><img alt="Wait" src="/images/indicator.png" style="margin: 0 auto; height: 240px" /></div>'}})
}

// enable the table ruler
// to activate this script a table must have the class of ruler
Event.observe(window, 'load', function() {
	if (document.getElementById && document.createTextNode)
	{
		var tables=document.getElementsByTagName('table');
		for (var i=0;i<tables.length;i++)
		{
			if(tables[i].className.match('ruler'))
			{
				var trs=tables[i].getElementsByTagName('tr');
				for(var j=0;j<trs.length;j++)
				{
					if(trs[j].parentNode.nodeName=='TBODY' && trs[j].parentNode.nodeName!='TFOOT')
					{
						trs[j].onmouseover=function(){this.className=this.className + ' ruled';return false}
						// this should probably actually be done with a regex for ultimate bombproofness.
						trs[j].onmouseout=function(){this.className=this.className.slice(0,-6);return false}
					}
				}
			}
		}
	}
});

function addLink()
{
  htmlLinkToText(link, getSelText());
}

// from http://www.codetoad.com/javascript_get_selected_text.asp
// written more consicely, but could probably be better. note to self: become better javascript programmer
function getSelText()
{
  if (window.getSelection)
    return window.getSelection();
  else if (document.getSelection)
    return document.getSelection();
  else if (document.selection)
    return document.selection.createRange().text;
  else 
    return '';
}

function htmlLinkToText(link, text)
{
  return "<a href='" + link + "'>" + text + "</a>";
}



// lifted from http://www.pjhyett.com/posts/190-the-lightbox-effect-without-lightbox
var accountable_form;
function showBox(box, form){
    accountable_form = form;
    //$('overlay').show();
    Effect.Appear('overlay', { to: 0.68});
    center(box);
    Effect.Grow(box)
    return false;
}

function hideBox(){
    //$(visible_box).hide();
    Effect.SwitchOff('login_required');
    Effect.Fade('overlay');
    //$('overlay').hide();
    return false;
}

function center(element){
    try{
        element = $(element);
    }catch(e){
        return;
    }

    var my_width  = 0;
    var my_height = 0;

    if ( typeof( window.innerWidth ) == 'number' ){
        my_width  = window.innerWidth;
        my_height = window.innerHeight;
    }else if ( document.documentElement && 
             ( document.documentElement.clientWidth ||
               document.documentElement.clientHeight ) ){
        my_width  = document.documentElement.clientWidth;
        my_height = document.documentElement.clientHeight;
    }
    else if ( document.body && 
            ( document.body.clientWidth || document.body.clientHeight ) ){
        my_width  = document.body.clientWidth;
        my_height = document.body.clientHeight;
    }

    element.style.position = 'absolute';
    element.style.zIndex   = 99;

    var scrollY = 0;

    if ( document.documentElement && document.documentElement.scrollTop ){
        scrollY = document.documentElement.scrollTop;
    }else if ( document.body && document.body.scrollTop ){
        scrollY = document.body.scrollTop;
    }else if ( window.pageYOffset ){
        scrollY = window.pageYOffset;
    }else if ( window.scrollY ){
        scrollY = window.scrollY;
    }

    var elementDimensions = Element.getDimensions(element);

    var setX = ( my_width  - elementDimensions.width  ) / 2;
    var setY = ( my_height - elementDimensions.height ) / 2 + scrollY;

    setX = ( setX < 0 ) ? 0 : setX;
    setY = ( setY < 0 ) ? 0 : setY;

    element.style.left = setX + "px";
    element.style.top  = setY + "px";

    //element.style.display  = 'block';
}

var loaded_articles = new Array();
function showArticle(id) {
  if ($F('smaller') != 'shrunk') {
    // scale it and hide it to the right
    new Effect.Morph('browse_box', {style: 'width:18%'});
    new Effect.Move('browse_box', { x: $('content').getWidth() - $('content').getWidth() * .21 }); 
    new Effect.multiple($$('.col3'), Effect.Fade, {speed: 0});
    new Effect.multiple($$('.col4'), Effect.Fade, {speed: 0});
    new Effect.Fade('extra_header');
    $('smaller').value = 'shrunk'
  }
  if (loaded_articles.include(id)) {
    Effect.ScrollTo( 'article'+id);
  }
  else {
    new Ajax.Request('/a/' + id, {asynchronous:true, evalScripts:true, onSuccess:function(request){$('article_target').insert(request.responseText);Effect.ScrollTo('article'+id, {offset: -68});}});    
    loaded_articles.push(id)
  }
  return false;
}
