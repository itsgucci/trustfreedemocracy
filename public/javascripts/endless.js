// endless_page.js
var currentPage = 1;

function checkScroll() {
  if (nearBottomOfPage()) {
    currentPage++;
    new Ajax.Request('/articles/grid.js?grid[page]=' + currentPage + "&smaller=" + smaller + "&" + Form.serialize('grid_params'), {asynchronous:true, evalScripts:true, method:'get'});
  } else {
    setTimeout("checkScroll()", 250);
  }
}

function nearBottomOfPage() {
  return scrollDistanceFromBottom() > Element.cumulativeOffset($('bottom_of_list'))[1] - 1322;
}

function scrollDistanceFromBottom(argument) {
  return Element.cumulativeScrollOffset($('bottom_of_list'))[1] - document.viewport.getScrollOffsets()[1]
}

document.observe('dom:loaded', checkScroll);