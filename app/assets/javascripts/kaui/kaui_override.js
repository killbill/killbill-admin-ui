jQuery(document).ready(function ($) {

    /*
     * Mobile Data Adjustment
     */

    var running = false;
    $('table.mobile-data').each(function () {
        var count = $(this).find($('table.mobile-data tr')).length - 1;
        $(this).append('<span class="left"><i class="fa fa-arrow-circle-left"></i></span>');
        $(this).append('<span class="right"><i class="fa fa-arrow-circle-right"></i></span>');
        $(this).append('<span class="center"><span class="current">1</span>/' + count + '</span>');
    });
    $('table.mobile-data > span.left').click(function () {

        if (running === true)
            return;

        running = true;

        var table = $(this).parent('table').children('tbody'),
            current = table.find('tr:first-of-type'),
            next = table.find('tr:last-of-type'),
            page = table.children('span.center').children('span.current'),
            number = parseInt(page.html()),
            count = table.find($('table.mobile-data tr')).length - 1;

        next.insertBefore(current);
        number--;
        if (number <= 0) {
            number = count;
        }
        page.html(number);

        fixCellHeight(table);

        running = false;

    });
    $('table.mobile-data > span.right').click(function () {

        if (running === true)
            return;

        running = true;

        var table = $(this).parent('table').children('tbody'),
            current = table.find('tr:first-of-type'),
            last = table.find('tr:last-of-type'),
            page = table.children('span.center').children('span.current'),
            number = parseInt(page.html()),
            count = table.find($('table.mobile-data tr')).length - 1;

        current.insertAfter(last);
        number++;
        if (number > count) {
            number = 1;
        }
        page.html(number);

        fixCellHeight(table);

        running = false;

    });

    function fixCellHeight(table) {

        table.find('tr:first-of-type').children('th').each(function (i) {
            i++;
            var brother = table.find('tr:nth-of-type(2)').children('td:nth-of-type(' + i + ')');

            if ($(this).height() > brother.height()) {
                brother.css('height', $(this).outerHeight() + 'px');
            } else {
                $(this).css('height', brother.outerHeight() + 'px');
            }

        });

    }

    if ($(window).width() <= 768) {
        $('table.mobile-data').each(function () {
            fixCellHeight($(this));
        });
    }


    /*
     * Toggler activation
     */
    $('.toggler .first-line').click( function(e){
        if (! ($(e.target).is('a') || $(e.target).parent().is('a'))) {
            e.preventDefault();
            $(this).parent('.toggler').toggleClass('toggled');
        }
    });

    /*
     * Toggle between combobox (US only) and text when entering the state.
     */
    $('#account_country').on('change', function(e){
        toggle_state_input_type($('#account_country').val());
    });

    function toggle_state_input_type(state){
        if (state == 'US'){
            $('.text-state').hide().attr('name','hide');
            $('.select-state').show().attr('name','account[state]');
        }else{
            $('.select-state').hide().attr('name','hide');
            $('.text-state').show().attr('name','account[state]');
        }
    }

    toggle_state_input_type($('#account_country').val());

    /*
     * Calculate first name length
     */

    $('#account_name').on('keyup', function(e){
        set_first_name_length($(this).val());
    });

    $('#account_name').on('change', function(e){
        if ($('#account_first_name_length').empty() ){
            set_first_name_length($(this).val());
        }
    });

    function set_first_name_length(name){
        var name_in_parts = name.trim().split(' ');
        $('#account_first_name_length').val(name_in_parts[0].length);
    }


    /*
     * Custom Fields Errors
     */


    $('#custom_field_object_type').change(function(){

        ajaxCloseAlert();

        var uuid = document.getElementById("custom_field_object_id").value;
        var my_url = '/custom_fields/check_object_exist';
        obj_type = document.getElementById("custom_field_object_type").value;

        if (uuid){
            $.ajax({
                url: my_url,
                type: "GET",
                dataType: "json",
                data: {
                  uuid: uuid,
                  object_type: obj_type
                },
                success: function(data) {
                  if (data.status == 431) {
                    var msg = data["message"];
                    ajaxErrorAlert(msg);

                  }
                }
              });
        }else{
            var msg = 'Object ID cannot be empty';
            ajaxErrorAlert(msg);
        }






      });

    $('#custom_field_object_id').on('keyup', function(e) {

      ajaxCloseAlert();

      var uuid = $(this).val();
      var my_url = '/custom_fields/check_object_exist';
      obj_type = document.getElementById("custom_field_object_type").value;

      $.ajax({
        url: my_url,
        type: "GET",
        dataType: "json",
        data: {
          uuid: $(this).val(),
          object_type: obj_type
        },
        success: function(data) {
          if (data.status == 431) {
            var msg = data["message"];
            ajaxErrorAlert(msg);
          }
        }
      });


    });


    /*
     *  Validate external key
     */
    const VALIDATE_EXTERNAL_KEY = {
        account: { url: Routes.kaui_engine_accounts_validate_external_key_path(), invalid_msg_class_name: '.account_external_key_invalid_msg' },
        payment_method: {url: Routes.kaui_engine_payment_methods_validate_external_key_path(), invalid_msg_class_name: '.payment_method_external_key_invalid_msg'},
        bundle: {url: Routes.kaui_engine_subscriptions_validate_bundle_external_key_path(), invalid_msg_class_name: '.subscription_bundle_external_key_invalid_msg'},
        subscription: {url: Routes.kaui_engine_subscriptions_validate_external_key_path(), invalid_msg_class_name: '.subscription_external_key_invalid_msg'}
    }

    validate_external_key($('#account_external_key').val(),'account');
    $('#account_external_key').on('change', function(e){
        validate_external_key($(this).val(),'account');
    });

    validate_external_key($('#payment_method_external_key').val(),'payment_method');
    $('#payment_method_external_key').on('change', function(e){
        validate_external_key($(this).val(),'payment_method');
    });

    validate_external_key($('#bundle_external_key').val(),'bundle');
    $('#bundle_external_key').on('change', function(e){
        validate_external_key($(this).val(),'bundle');
    });

    validate_external_key($('#subscription_external_key').val(),'subscription');
    $('#subscription_external_key').on('change', function(e){
        validate_external_key($(this).val(),'subscription');
    });

    function validate_external_key(external_key, key_for){
        if (external_key == undefined || external_key == null || external_key.trim().length == 0){
            $(VALIDATE_EXTERNAL_KEY[key_for].invalid_msg_class_name).hide();
        }else {
            $.ajax(
                {
                    url: VALIDATE_EXTERNAL_KEY[key_for].url,
                    type: "GET",
                    dataType: "json",
                    data: {external_key: external_key},
                    success: function (data) {
                        if (data.is_found) {
                            $(VALIDATE_EXTERNAL_KEY[key_for].invalid_msg_class_name).show();
                        } else {
                            $(VALIDATE_EXTERNAL_KEY[key_for].invalid_msg_class_name).hide();
                        }
                    }
                });
        }
    }

    // Restrict numeric input for a text field
    // Using "constraint validation API" to restrict input
    $("input[type=number]").keydown(function(event) {
        $(this).data('oldData', $(this).val());
    }).keyup(function(event) {
        if (event.currentTarget.validity.badInput) {
            $(this).val($(this).data('oldData'));
        }
    });

    // this will register a global ajax error for all jquery ajax requests (not including DataTable)
    $( document ).ajaxError(function( event, jqxhr, settings, thrownError ) {
        if (jqxhr.status == 0) {
            return;
        }

        var message = 'Request error: ' + getMessageFromResponse(jqxhr);

        if (jqxhr.status == 200) {
            message = thrownError.message == undefined ? thrownError : thrownError.message;
        }
        ajaxErrorAlert(message);
    });

    function getMessageFromResponse(jqxhr) {
        if (isBlank(jqxhr.responseJSON)) {
            return jqxhr.responseText;
        }

        if (!isBlank(jqxhr.responseJSON.error)) {
            return jqxhr.responseJSON.error;
        }

        return jqxhr.responseText;
    }

    // this will prevent DataTable to show an alert message box when an error occurs
    // $.fn.DataTable.ext.errMode = 'none';
    // this will try to register a DataTable error event to all tables, and if an error occurs will display the error on screen
    $( document ).find(".table").on('error.dt', function ( e, settings, techNote, message ) {
        ajaxErrorAlert('An error has been reported by DataTables: ' + message);
    });

    setObjectIdPopover();
});


// global function used to show an error message that occurs on a Ajax call, if timeout is passed the box will disappear when the time is up.
function ajaxErrorAlert(message, timeout) {
    ajaxAlert("ajaxErrorAlert", message, timeout);
}

// global function used to show an information message.
function ajaxInfoAlert(message, timeout) {
    ajaxAlert("ajaxInfoAlert", message, timeout);
}

// if timeout is passed the box will disappear when the time is up.
function ajaxAlert(alert_element_id, message, timeout) {
    // do not show ajax alert if there is already an server alert
    var serverAlertStatus = $(".server-alert").css("display");
    if (serverAlertStatus != undefined && serverAlertStatus != "none") {
        return;
    }

    var messageBox = $("#" + alert_element_id);
    messageBox.find("#" + alert_element_id + "Message").text(message);
    messageBox.show();
    messageBox.find("button").click(function(){
        ajaxCloseAlert(messageBox);
    });

    //if timeout is passed the box will disappear when the time is up
    if (!isBlank(timeout)) {
        setTimeout(function(){ ajaxCloseAlert()}, timeout);
    }
}

function ajaxCloseAlert(messageBox) {
    var messageBox = messageBox || $(".ajaxAlert");
    messageBox.find(".ajaxAlertMessage").text('');
    messageBox.hide();
}

// global helper function to validate if a variable is null or empty or undefined
function isNullOrUndefined(value) {
    if (value == undefined || value == null) {
        return true;
    }
    return false;
}

function isBlank(value) {
    if (isNullOrUndefined(value)) {
        return true;
    }

    if (jQuery.type(value) === "string" && value.trim().length == 0) {
        return true;
    } else if (jQuery.type(value) === "array" && value.length == 0) {
        return true;
    } else if (jQuery.type(value) === "object" && jQuery.isEmptyObject(value)) {
        return true;
    } else {
        return false;
    }
}

// this function set popover for all tags that have class object-id-popover
// attributes:
//      data-id = content of the popover,object id; required
//      title = title of the popover; not required
//      id = (must be {{id}}-popover) used to close popover when the copy image is clicked; if present; if not present a timeout of 5s will apply; not required
function setObjectIdPopover(){
    $(".object-id-popover").each(function(idx, e){
        $(this).popover('destroy');
        $(this).off("shown.bs.popover");
        $(this).data("index", idx);

        $(this).popover({
            html: true,
            content: function() {
                var template = '<div class="{{id}}-content" >' +
                    '{{id}}&emsp;<i id="{{id}}-copy" class="fa fa-clipboard copy-icon" aria-hidden="true"></i> ' +
                    '</div>';

                var popover_html = Mustache.render( template , { id: $(this).data("id") });
                return popover_html;
            },
            container: 'body',
            trigger: 'hover',
            delay: { "show": 100, "hide": 4000 }
        });

        $(this).on("show.bs.popover", function(e) {
            var currentPopoverIndex = $(this).data('index');
            $(".object-id-popover").each(function(idx, e){
                var index = $(this).data('index');

                if (currentPopoverIndex != index) {
                    $(this).popover('hide');
                }
            });
        });

        $(this).on("shown.bs.popover", function(e) {
            var objectId = $(this).data('id');
            var copyIdImg = $("#" + objectId + "-copy");

            copyIdImg.data("popover",$(this).attr("id"));
            copyIdImg.click(function(e){
                var id = ($(this).attr("id")).replace('-copy','');
                navigator.clipboard.writeText(id);
                ajaxInfoAlert("Id [" + id + "] was copied into the clipboard!", 4000);

                if (!isBlank(popover)) {
                    popover.popover('hide');
                }

            });

        });

    });

    // close all object id popover on modal show
    $(".modal").on('show.bs.modal',function(e){
        $(".object-id-popover").each(function(idx, e) {
            $(this).popover('destroy');
        });
    });

    // check if object id must be restored
    $(".modal").on('hide.bs.modal',function(e){
        setObjectIdPopover();
    });
}
