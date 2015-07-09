$(document).ready(function(){
  $('.dataTables_paginate').hide();
});

$(document).on('init.dt', function(){
  $('.dataTables_paginate').find('ul').addClass('pagination');
  $('.dataTables_paginate').show();
});
