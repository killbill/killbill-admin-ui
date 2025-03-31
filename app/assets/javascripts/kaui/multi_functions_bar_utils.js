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
      value = value.replace(/%/g, '');
      var match = key.match(/(.*)\[(.*)\]/);
      if (match) {
        var columnName = match[1].replace(/_/g, ' ').replace(/^\w/, function(l) { return l.toUpperCase(); });
        var filter = searchFormatOperator(match[2]);
        var label = $('<span>', {
          class: 'label label-info',
          text: columnName + ' [' + filter + '] ' + value
        });

        if (hasBalanceFilter && columnName.toLowerCase() !== 'balance') {
          label.attr('class', 'label label-default');
        }

        searchLabelsContainer.append(label);
      }
    }
  }
}

function searchQuery(account_id){
  var searchFields = $('.search-field');
  var searchLabelsContainer = $('#search-labels-container');
  searchLabelsContainer.empty();

  var searchLabels = searchFields.map(function() {
    var filter = $(this).find('.search-field-filter').val();
    var value = $(this).find('.search-field-value').val();
    var columnName = $(this).find('.search-field-filter').attr('name').replace('Filter', '').toLowerCase().replace(/\s+/g, '_');

    if (value !== '') {
      if (filter === 'like') {
        return columnName + encodeURIComponent('[' + filter + ']') + '=' + encodeURIComponent('%' + value + '%');
      } else {
        return columnName + encodeURIComponent('[' + filter + ']') + '=' + encodeURIComponent(value);
      }
    }
  }).get().join('&');

  if (account_id !== undefined && account_id !== '') {
    searchLabels += '&' + encodeURIComponent('account_id[eq]') + '=' + encodeURIComponent(account_id);
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
    var labelText = $(this).text();
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