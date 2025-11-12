// Function to map operators to user-friendly text
function searchFormatOperator(operator) {
  var operatorMapping = {
    'eq': 'Equals',
    'neq': 'Not Equals',
    'gt': 'Greater Than',
    'gte': 'Greater Than Or Equal',
    'lt': 'Less Than',
    'lte': 'Less Than Or Equal',
    'like': 'Like'
  };
  return operatorMapping[operator] || operator;
}

// Reverse map user-friendly operator text back to operator key
function searchParseOperatorText(text) {
  var reverseMapping = {
    'equals': 'eq',
    'not equals': 'neq',
    'greater than': 'gt',
    'greater than or equal': 'gte',
    'less than': 'lt',
    'less than or equal': 'lte',
    'like': 'like'
  };
  return reverseMapping[(text || '').toString().toLowerCase()] || text;
}

// Function to parse URL parameters
function getUrlParams() {
  var params = {};
  var queryString = window.location.search.substring(1);
  queryString = queryString.replace(/ac_id/g, 'account_id');
  var regex = /([^&=]+)=([^&]*)/g;
  var m;
  while (m = regex.exec(queryString)) {
    params[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
  }
  return params;
}

// Function to populate search labels from URL parameters
function populateSearchLabelsFromUrl() {
  var params = getUrlParams();
  var searchLabelsContainer = $('#search-labels-container');
  searchLabelsContainer.empty();

  var hasBalanceFilter = window.location.search.includes('balance');

  for (var key in params) {
    if (params.hasOwnProperty(key)) {
      var value = params[key];
      value = value.replace(/%/g, '').trim();
      var match = key.match(/(.*)\[(.*)\]/);
      if (match) {
        var columnName = match[1].replace(/_/g, ' ').replace(/^\w/, function(l) { return l.toUpperCase(); });
        var filter = searchFormatOperator(match[2].trim());
        var label = $('<span>', {
          class: 'label label-info d-inline-flex align-items-center gap-2',
          'data-field': columnName.trim(),
          'data-filter': filter.trim(),
          'data-value': value.trim()
        });

        if (hasBalanceFilter && columnName.toLowerCase().trim() !== 'balance') {
          label.attr('class', 'label label-default d-inline-flex align-items-center gap-2');
        }

        var labelText = $('<span>', {
          text: columnName.trim() + ' [' + filter.trim() + '] ' + value.trim()
        });

        var closeIcon = $('<span>', {
          class: 'filter-close-icon',
          style: 'cursor: pointer; margin-left: 5px; display: inline-flex; align-items: center;'
        }).html('<svg width="12" height="12" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M15.8337 4.1665L4.16699 15.8332M4.16699 4.1665L15.8337 15.8332" stroke="#A4A7AE" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>');

        label.append(labelText).append(closeIcon);
        searchLabelsContainer.append(label);
      }
    }
  }
}

function searchQuery(account_id){
  var searchFields = $('.search-field');
  var searchLabelsContainer = $('#search-labels-container');
  
  if (searchFields.length > 0) {
    searchLabelsContainer.empty();
  }
  var searchLabels = '';
  if (searchFields.length > 0) {
    searchLabels = searchFields.map(function() {
      var filter = $(this).find('.search-field-filter').val();
      var value = $(this).find('.search-field-value').val().trim(); // Trim whitespace from value
      var columnName = $(this).find('.search-field-filter').attr('name').replace('Filter', '').toLowerCase().replace(/\s+/g, '_');

      if (value !== '') {
        if (filter === 'like') {
          return columnName + encodeURIComponent('[' + filter + ']') + '=' + encodeURIComponent('%' + value + '%');
        } else {
          return columnName + encodeURIComponent('[' + filter + ']') + '=' + encodeURIComponent(value);
        }
      }
    }).get().join('&');
  } else {
    // Fall back to existing labels on the page (used when closing a single filter from the pills)
    var builtParams = [];
    $('#search-labels-container .label').each(function() {
      var fieldName = ($(this).data('field') || '').toString().toLowerCase().replace(/\s+/g, '_');
      var filterText = ($(this).data('filter') || '').toString().trim(); // Trim whitespace from filter text
      var operator = searchParseOperatorText(filterText);
      var value = ($(this).data('value') || '').toString().trim();
      if (fieldName && operator && value) { // Also check that value is not empty
        if (operator === 'like') {
          builtParams.push(fieldName + encodeURIComponent('[' + operator + ']') + '=' + encodeURIComponent('%' + value + '%'));
        } else {
          builtParams.push(fieldName + encodeURIComponent('[' + operator + ']') + '=' + encodeURIComponent(value));
        }
      }
    });
    searchLabels = builtParams.join('&');
  }

  if (account_id !== undefined && account_id !== '' && account_id.trim() !== '') {
    searchLabels += '&' + encodeURIComponent('account_id[eq]') + '=' + encodeURIComponent(account_id.trim());
  }

  var searchLabelString = searchLabels.length > 0 ? ('_q=1&' + searchLabels) : '';
  if (searchLabelString == '') {
    clearAdvanceSearch();
  }
  return searchLabelString;
};

function clearAdvanceSearch() {
  // Clear all search fields
  $('#search-fields-container').empty();

  // Remove all search labels
  $('#search-labels-container').empty();

  // Reload the page with the original URL (no parameters)
  window.location.href = window.location.pathname;

  // Hide the modal
  $('#advanceSearchModal').modal('hide');
}

function showAdvanceSearchModal() {
  var searchLabelsContainer = $('#search-labels-container');
  var searchFieldsContainer = $('#search-fields-container');
  searchFieldsContainer.empty();

  // Populate the search fields with the current filters
  searchLabelsContainer.find('.label').each(function() {
    var labelText = $(this).text().trim();
    var parts = labelText.split(' [');
    var columnName = parts[0].trim();
    var filterAndValue = parts[1].split('] ');
    var filter = filterAndValue[0].trim();
    var value = filterAndValue[1].trim();

    var template = document.getElementById('search-field-template').content.cloneNode(true);
    template.querySelector('.search-field-label').textContent = columnName.replace(/([A-Z])/g, ' $1').trim();
    template.querySelector('.search-field-filter').name = columnName + 'Filter';
    template.querySelector('.search-field-filter').value = filter;
    template.querySelector('.search-field-value').name = columnName;
    template.querySelector('.search-field-value').value = value;

    searchFieldsContainer.append(template);
    var dropdown = searchFieldsContainer.find('.search-field:last-child .search-field-filter');
    dropdown.find('option').each(function() {
      if ($(this).text().trim().toLowerCase() === filter.toLowerCase()) {
        $(this).prop('selected', true);
      }
    });
  });
}

// Handle the close icon click event to remove applied filters
$(document).on('click', '.filter-close-icon', function() {
  var filterLabel = $(this).closest('.label');
  var fieldName = filterLabel.data('field');
  var filterType = filterLabel.data('filter');
  var filterValue = filterLabel.data('value');
  
  // Remove the filter label
  filterLabel.remove();
  
  // Remove corresponding search field from modal if it exists
  $('#search-fields-container .search-field').each(function() {
    var searchField = $(this);
    var fieldInput = searchField.find('.search-field-value');
    var fieldFilter = searchField.find('.search-field-filter');
    
    if (fieldInput.attr('name') === fieldName && 
        fieldFilter.find('option:selected').text().trim() === filterType.trim() && 
        fieldInput.val().trim() === filterValue.trim()) {
      searchField.remove();
    }
  });
  var searchParams = searchQuery();
  // Reapply search without the removed filter
  var tableSelectors = ['#invoices-table', '#accounts-table', '#payments-table', '#subscriptions-table'];
  var table = null;
  
  for (var i = 0; i < tableSelectors.length; i++) {
    var $tableElement = $(tableSelectors[i]);
    if ($tableElement.length && $.fn.DataTable.isDataTable(tableSelectors[i])) {
      table = $tableElement.DataTable();
      break;
    }
  }
  
  if (table && table.ajax) {
    table.on('preXhr.dt', function(e, settings, data) {
      data.search.value = searchParams;
    });
    table.ajax.reload(null, false);
  }
  
  // Update URL
  if (searchParams) {
    var pushParams = (searchParams || '').replace(/account_id/g, 'ac_id');
    var newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname + '?' + pushParams;
    window.history.pushState({ path: newUrl }, '', newUrl);
  } else {
    var newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
    window.history.pushState({ path: newUrl }, '', newUrl);
  }
});