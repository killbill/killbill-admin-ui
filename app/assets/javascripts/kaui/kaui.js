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

        if (name_in_parts.length > 1){
            $('#account_first_name_length').val(name_in_parts[0].length);
        }else{
            $('#account_first_name_length').val('');
        }
    }

    /*
     *  Validate external key
     */
    const VALIDATE_EXTERNAL_KEY = {
        account: { url: Routes.kaui_engine_accounts_validate_external_key_path(), invalid_msg_class_name: '.account_external_key_invalid_msg' },
        payment_method: {url: Routes.kaui_engine_payment_methods_validate_external_key_path(), invalid_msg_class_name: '.payment_method_external_key_invalid_msg'},
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

    validate_external_key($('#external_key').val(),'subscription');
    $('#external_key').on('change', function(e){
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

})
