function makeDataTable(tableObj) {
  var cols = [];
  var sortCols = [];
  tableObj.find("th").each(function(idx, headObj) {
    var classes = ($(headObj).attr('class') || "").split(/\s+/);

    if (classes.indexOf("sort-title-string") >= 0) {
      cols.push({ "sType": "title-string" });
    }
    else {
      cols.push(null);
    }
    if (classes.indexOf("data-table-sort-desc") >= 0) {
      sortCols.push([ idx, "desc"]);
    }
    else if (classes.indexOf("data-table-sort-asc") >= 0) {
      sortCols.push([ idx, "asc"]);
    }
  });

  var numRows = 25;
  var rowRegexp = /(\d+)rows/;
  var classes = (tableObj.attr('class') || "").split(/\s+/);
  for (var idx = 0; idx < classes.length; idx++) {
    var match = rowRegexp.exec(classes[idx]);
    if (match && match.length > 1) {
      numRows = parseInt(match[1]);
    }
  }
  tableObj.dataTable({
    "sDom": "<'row'<'col-md-6'l><'col-md-6'f>r>t<'row'<'col-md-6'i><'col-md-6'p>>",
    "sPaginationType": "bootstrap",
    "oLanguage": {
      "sLengthMenu": "_MENU_ records per page"
    },
    "aoColumns": cols,
    "aaSorting": sortCols,
    "iDisplayLength": numRows
  });
}

$(document).ready(function() {
  // for the datatables + bootstrap tweaks, see http://datatables.net/blog/Twitter_Bootstrap_2

  // datatables tweaks for bootstrap
  $.extend($.fn.dataTableExt.oStdClasses, {
    "sWrapper": "dataTables_wrapper form-inline"
  });
  // sorting based on sub element with title attribute
  $.fn.dataTableExt.oSort["title-string-asc"]  = function(a,b) {
    var aMatch = a.match(/title="(.*?)"/);
    var bMatch = b.match(/title="(.*?)"/);
    var x = aMatch && aMatch.length > 1 ? aMatch[1].toLowerCase() : a;
    var y = bMatch && bMatch.length > 1 ? bMatch[1].toLowerCase() : b;
    return ((x < y) ? -1 : ((x > y) ?  1 : 0));
  };
  $.fn.dataTableExt.oSort["title-string-desc"] = function(a,b) {
    var aMatch = a.match(/title="(.*?)"/);
    var bMatch = b.match(/title="(.*?)"/);
    var x = aMatch && aMatch.length > 1 ? aMatch[1].toLowerCase() : a;
    var y = bMatch && bMatch.length > 1 ? bMatch[1].toLowerCase() : b;
    return ((x < y) ?  1 : ((x > y) ? -1 : 0));
  };
  // add row filtering based on whether the tr element has the hide css class or not
  $.fn.dataTableExt.afnFiltering.push(
    function(oSettings, aData, iDataIndex) {
      var nTr = $(oSettings.aoData[iDataIndex].nTr);
      return !nTr.hasClass("hide");
    }
  );

  // API method to get paging information
  $.fn.dataTableExt.oApi.fnPagingInfo = function(oSettings) {
    return {
      "iStart": oSettings._iDisplayStart,
      "iEnd": oSettings.fnDisplayEnd(),
      "iLength": oSettings._iDisplayLength,
      "iTotal": oSettings.fnRecordsTotal(),
      "iFilteredTotal": oSettings.fnRecordsDisplay(),
      "iPage": Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength),
      "iTotalPages": Math.ceil(oSettings.fnRecordsDisplay() / oSettings._iDisplayLength)
    };
  };

  // datatables bootstrap style pagination control
  $.extend($.fn.dataTableExt.oPagination, {
    "bootstrap": {
      "fnInit": function(oSettings, nPaging, fnDraw) {
        var oLang = oSettings.oLanguage.oPaginate;
        var fnClickHandler = function(e) {
          e.preventDefault();
          if (oSettings.oApi._fnPageChange(oSettings, e.data.action)) {
            fnDraw(oSettings);
          }
        };

        $(nPaging).addClass('pagination').append('<ul>' + '<li class="prev disabled"><a href="#">&larr; ' + oLang.sPrevious + '</a></li>' + '<li class="next disabled"><a href="#">' + oLang.sNext + ' &rarr; </a></li>' + '</ul>');
        var els = $('a', nPaging);
        $(els[0]).bind('click.DT', {
          action: "previous"
        }, fnClickHandler);
        $(els[1]).bind('click.DT', {
          action: "next"
        }, fnClickHandler);
      },

      "fnUpdate": function(oSettings, fnDraw) {
        var iListLength = 5;
        var oPaging = oSettings.oInstance.fnPagingInfo();
        var an = oSettings.aanFeatures.p;
        var i, j, sClass, iStart, iEnd, iHalf = Math.floor(iListLength / 2);

        if (oPaging.iTotalPages < iListLength) {
          iStart = 1;
          iEnd = oPaging.iTotalPages;
        } else if (oPaging.iPage <= iHalf) {
          iStart = 1;
          iEnd = iListLength;
        } else if (oPaging.iPage >= (oPaging.iTotalPages - iHalf)) {
          iStart = oPaging.iTotalPages - iListLength + 1;
          iEnd = oPaging.iTotalPages;
        } else {
          iStart = oPaging.iPage - iHalf + 1;
          iEnd = iStart + iListLength - 1;
        }

        for (i = 0, iLen = an.length; i < iLen; i++) {
          // Remove the middle elements
          $('li:gt(0)', an[i]).filter(':not(:last)').remove();

          // Add the new list items and their event handlers
          for (j = iStart; j <= iEnd; j++) {
            sClass = (j == oPaging.iPage + 1) ? 'class="active"' : '';
            $('<li ' + sClass + '><a href="#">' + j + '</a></li>').insertBefore($('li:last', an[i])[0]).bind('click', function(e) {
              e.preventDefault();
              oSettings._iDisplayStart = (parseInt($('a', this).text(), 10) - 1) * oPaging.iLength;
              fnDraw(oSettings);
            });
          }

          // Add / remove disabled classes from the static elements
          if (oPaging.iPage === 0) {
            $('li:first', an[i]).addClass('disabled');
          } else {
            $('li:first', an[i]).removeClass('disabled');
          }

          if (oPaging.iPage === oPaging.iTotalPages - 1 || oPaging.iTotalPages === 0) {
            $('li:last', an[i]).addClass('disabled');
          } else {
            $('li:last', an[i]).removeClass('disabled');
          }
        }
      }
    }
  });

  // make any table with css class data-table a datatable
  $("table.data-table").each(function() {
    makeDataTable($(this));
  });

  // make any input field with css class date-picker a datepicker
  $("input.date-picker").each(function() {
    $(this).datepicker({
      format: 'yyyy-mm-dd'
    });
  });
});