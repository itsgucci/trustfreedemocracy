/* ******************************************************************* *
CSS/JavaScript Table Hilighting 0.3
---------------------------
Author: Ryan Scherf

This script gives multiple ways to hilight active columns, rows, and
cells in any give table. It is abstracted enough to ensure that
styles can be modified with simple CSS. Also, the hilighting can
be overridden on any page with simple scripts inside the page.

This script uses the DOM for tables to apply the hilighting very
quickly and efficiently while preserving all other classes and
styles of the table that may have existed.

Tested in: IE6, IE7, FF, and Win Opera 9.

Coming Soon:
- Ability to use multiple colors for different hilighting options
- Support for multiple tables with different hilights on the same page

Known Issues:
- Colspan & rowspan do not function correctly, the script stops
at each of these events and may cause some display problems.

* ******************************************************************* */
// These classes must coincide with your stylesheet
var hilightClass = "hoverHilight"; // Default hilight class
var activeHilightClass = "activeCellHilight"; // Active cell hilight class

var hilightActive = 1; // Hilight active cell beneath cursor differently
var hilightCol = 1; // Hilight active column 0,1
var hilightRow = 1; // Hilight active row 0,1
var hilightTopHeader = 1; // Hilight top header cell 0,1
var hilightLeftHeader = 1; // Hilight leftmost header cell 0,1
var hilightRightHeader = 0; // Hilight rightmost header cell 0,1
var hilightBottomHeader = 0; // Hilight bottom footer cell 0,1

// BETA -- surrounds active cell with styling via JAVASCRIPT, not CSS
var surroundActive = 0; // Surround active cell with different backgrounds

/* ******************************************************************* */
// NO NEED TO EDIT BELOW

/* ******************************************************************* */
/* START THE TABLE HILIGHTING */
/* ******************************************************************* */
function initCrossHairsTable(id, topPad, rightPad, bottomPad, leftPad) {
	var tableObj = document.getElementById(id);

	/* TODO:
	this does not work for header/footers -- why?
	this is also broken for ie6 -- setAttribute doesn't work?
	*/

	var c = tableObj.rows[0].cells.length - rightPad;
	var r = tableObj.rows.length - bottomPad;

	for (var i = topPad; i < r; i++)
	{
		for (var j = leftPad; j < c; j++)
		{
			if(!document.all) {
				tableObj.rows[i].cells[j].setAttribute("onmouseover","addHilight(this);");
				tableObj.rows[i].cells[j].setAttribute("onmouseout","removeHilight(this);");
			}
			else
			{
				tableObj.rows[i].cells[j].onmouseover = function() { addHilight(this); }
				tableObj.rows[i].cells[j].onmouseout = function() { removeHilight(this); }
			}
		}
	}
}

/* ******************************************************************* */
/* HILIGHT TOP AND LEFT HEADERS */
/* ******************************************************************* */
function addHilight(cell)
{
	applyHilight(cell.parentNode.parentNode.parentNode,
		cell.parentNode.rowIndex, cell.cellIndex, 1);
	}

	/* ******************************************************************* */
	/* REMOVE MOUSEOVER HILIGHT */
	/* ******************************************************************* */
	function removeHilight(cell)
	{
		applyHilight(cell.parentNode.parentNode.parentNode,
			cell.parentNode.rowIndex, cell.cellIndex, 0);
		}

		// Global Variables used for swapping and preserving classes - DO NOT EDIT
		var oldRowClasses = "";
		var oldHeaderClasses = "";
		var oldCellClasses = new Array();

		/* ******************************************************************* */
		/* APPLY THE HILIGHT TO THE CORRECT CELLS */
		/* ******************************************************************* */
		function applyHilight(obj, rowIndex, colIndex, state)
		{
			// Make sure the browser has W3C DOM support
			var W3CDOM = (document.createElement && document.getElementsByTagName);
			if (!W3CDOM)
			{
				alert("This script requires W3C DOM support")
				return;
			}

			// There is no hilightClass set
			if (hilightClass == "") alert("Please set a hilight class.");

			// Apply entire row hilighting
			if (hilightRow) applyHilightRow(obj, rowIndex, colIndex, state);
			// Apply entire column hilighting
			if (hilightCol) applyHilightCol(obj, rowIndex, colIndex, state);
			// Apply hilighting to top header cell
			if (hilightTopHeader) applyHilightTopHeader(obj, rowIndex, colIndex, state);
			// Apply hilighting to leftmost header cell
			if (hilightLeftHeader) applyHilightLeftHeader(obj, rowIndex, colIndex, state);
			// Apply hilighting to rightmost header cell
			if (hilightRightHeader) applyHilightRightHeader(obj, rowIndex, colIndex, state);
			// Apply hilighting to bottom footer cell
			if (hilightBottomHeader) applyHilightBottomFooter(obj, rowIndex, colIndex, state);

			// Apply hilighting to the active cell beneath the cursor
			if (hilightActive) applyHilightActiveCell(obj, rowIndex, colIndex, state);

			// Apply hilighting to surround cells (beta)
			if (surroundActive) applySurroundActiveHilight(obj, rowIndex, colIndex, state);
		}

		// state == 1 when the mouse is hovering the cell
		// state == 0 when the mouse has left the cell and move to another

		/* ******************************************************************* */
		/* HILIGHT LEFTMOST HEADER CELL */
		/* ******************************************************************* */
		function applyHilightLeftHeader(obj, rowIndex, colIndex, state)
		{
			var classArray;
			var rowClasses = "";

			if (state == 1)
			{
				obj.rows[rowIndex].cells[0].className += " " + hilightClass;
			}
			else
			{
				classArray = obj.rows[rowIndex].cells[0].className.split(" ");
				for(var i = 0; i < (classArray.length - 1); i++)
				if(classArray[i] != "") rowClasses += " " + classArray[i];
				obj.rows[rowIndex].cells[0].className = rowClasses;
			}
		}

		/* ******************************************************************* */
		/* HILIGHT RIGHTMOST HEADER CELL */
		/* ******************************************************************* */
		function applyHilightRightHeader(obj, rowIndex, colIndex, state)
		{
			var classArray;
			var rowClasses = "";

			if (state == 1)
			{
				obj.rows[rowIndex].cells[obj.rows[rowIndex].cells.length-1].className += " " + hilightClass;
			}
			else
			{
				classArray = obj.rows[rowIndex].cells[obj.rows[rowIndex].cells.length-1].className.split(" ");
				for(var i = 0; i < (classArray.length - 1); i++)
				if(classArray[i] != "") rowClasses += " " + classArray[i];
				obj.rows[rowIndex].cells[obj.rows[rowIndex].cells.length-1].className = rowClasses;
			}
		}

		/* ******************************************************************* */
		/* HILIGHT TOP HEADER CELL */
		/* ******************************************************************* */
		function applyHilightTopHeader(obj, rowIndex, colIndex, state)
		{
			var classArray;
			var colClasses = "";

			if (state == 1)
			{
				obj.rows[0].cells[colIndex].className += " " + hilightClass;
			}
			else
			{
				classArray = obj.rows[0].cells[colIndex].className.split(" ");
				for(var i = 0; i < (classArray.length - 1); i++)
				if(classArray[i] != "") colClasses += " " + classArray[i];
				obj.rows[0].cells[colIndex].className = colClasses;
			}
		}

		/* ******************************************************************* */
		/* HILIGHT BOTTOM FOOTER CELL */
		/* ******************************************************************* */
		function applyHilightBottomFooter(obj, rowIndex, colIndex, state)
		{
			var classArray;
			var colClasses = "";

			if (state == 1)
			{
				obj.rows[obj.rows.length-1].cells[colIndex].className += " " + hilightClass;
			}
			else
			{
				classArray = obj.rows[obj.rows.length-1].cells[colIndex].className.split(" ");
				for(var i = 0; i < (classArray.length - 1); i++)
				if(classArray[i] != "") colClasses += " " + classArray[i];
				obj.rows[obj.rows.length-1].cells[colIndex].className = colClasses;
			}
		}

		/* ******************************************************************* */
		/* HILIGHT ENTIRE ROW */
		/* ******************************************************************* */
		function applyHilightRow(obj, rowIndex, colIndex, state)
		{
			if (state == 1)
			{
				oldRowClasses = obj.rows[rowIndex].className;
				obj.rows[rowIndex].className = hilightClass;
			}
			else
			{
				obj.rows[rowIndex].className = oldRowClasses;
			}
		}

		/* ******************************************************************* */
		/* HILIGHT ENTIRE COLUMN */
		/* ******************************************************************* */
		function applyHilightCol(obj, rowIndex, colIndex, state)
		{
			var cellClasses = new Array();

			if (state == 1)
			{
				for(var i = 0; i < obj.rows.length; i++)
				{
					cellClasses.push(obj.rows[i].cells[colIndex].className);
					obj.rows[i].cells[colIndex].className += " " + hilightClass;
				}

				oldCellClasses = cellClasses;
			}
			else
			{
				oldCellClasses.reverse();
				for(var i = 0; i < obj.rows.length; i++)
				obj.rows[i].cells[colIndex].className = oldCellClasses.pop();
			}
		}

		/* ******************************************************************* */
		/* HILIGHT ACTIVE CELL IF NEEDED */
		/* ******************************************************************* */
		var oldActiveCellClasses; // store the previous state of the cell

		function applyHilightActiveCell(obj, rowIndex, colIndex, state)
		{
			if (state == 1)
			{
				oldActiveCellClasses = null;
				oldActiveCellClasses = obj.rows[rowIndex].cells[colIndex].className;
				obj.rows[rowIndex].cells[colIndex].className += " " + activeHilightClass;
			}
			else
			{
				// set the cell back to its previous state
				var oldClasses = oldActiveCellClasses.split(" ");
				obj.rows[rowIndex].cells[colIndex].className = "";

				for(var i = 0; i < oldClasses.length; i++)
				{
					if(oldClasses[i] != hilightClass) obj.rows[rowIndex].cells[colIndex].className += " " + oldClasses[i];
					oldActiveCellClasses = "";
				}
			}
		}

		/* ******************************************************************* */
		/* SURROUND ACTIVE CELL WITH HILIGHTING (BETA) */
		/* ******************************************************************* */
		function applySurroundActiveHilight(obj, rowIndex, colIndex, state)
		{
			/* TODO:
			- abstract bgcolor to class
			- fix for cells on borders
			*/

			var surroundRadius = 1;
			var radiusColor = "#c0dbff"
			var cell;

			if(!parseInt(surroundRadius)) return;

			if (state == 1)
			{
				for(var i = (rowIndex - surroundRadius); i <= (rowIndex + surroundRadius); i++)
				{
					if (i < 0) continue;
					if (!obj.rows[i]) continue;

					for(var j = (colIndex - surroundRadius); j <= (colIndex + surroundRadius); j++)
					{
						if (j < 0) continue;
						if (!obj.rows[i].cells[j]) continue;

						cell = obj.rows[i].cells[j].style
						cell.backgroundColor = radiusColor;
						cell.opacity = (.5);
						cell.MozOpacity = (.5);
						cell.KhtmlOpacity = (.5);
						cell.filter = "alpha(opacity=50)";
					}
				}

				obj.rows[rowIndex].cells[colIndex].style.backgroundColor = "";
			}
			else
			{
				for(var i = (rowIndex - surroundRadius); i <= (rowIndex + surroundRadius); i++)
				{
					if (i < 0) continue;
					if (!obj.rows[i]) continue;

					for(var j = (colIndex - surroundRadius); j <= (colIndex + surroundRadius); j++)
					{
						if (j < 0) continue;
						if (!obj.rows[i].cells[j]) continue;

						cell = obj.rows[i].cells[j].style
						cell.backgroundColor = "";
						cell.opacity = (1);
						cell.MozOpacity = (1);
						cell.KhtmlOpacity = (1);
						cell.filter = "alpha(opacity=100)";
					}
				}
			}
		}