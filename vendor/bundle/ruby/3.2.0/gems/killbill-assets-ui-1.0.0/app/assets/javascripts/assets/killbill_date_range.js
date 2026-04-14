function setDateRange(option) {
  var currentDate = new Date();
  var startDate, endDate;

  if (option === "day") {
    startDate = new Date();
    endDate = new Date();
    endDate.setDate(endDate.getDate() + 1);
  } else if (option === "week") {
    startDate = new Date(currentDate.setDate(currentDate.getDate() - currentDate.getDay() + 1));
    currentDate = new Date();
    endDate = new Date(currentDate.setDate(currentDate.getDate() - currentDate.getDay() + 7));
  } else if (option === "month") {
    startDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
  } else if (option === "year") {
    startDate = new Date(currentDate.getFullYear(), 0, 1);
    endDate = new Date(currentDate.getFullYear(), 11, 31);
  }

  var startDateFormatted = formatDate(startDate);
  var endDateFormatted = formatDate(endDate);

  $('#startDate').val(startDateFormatted);
  $('#endDate').val(endDateFormatted);
  $('#startDate, #endDate').prop('disabled', true);
}

function formatDate(date) {
  var year = date.getFullYear();
  var month = String(date.getMonth() + 1).padStart(2, '0');
  var day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
