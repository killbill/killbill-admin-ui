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

        var table = $(this).parent('table'),
            current = table.find('tr:nth-of-type(2)'),
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

        var table = $(this).parent('table'),
            current = table.find('tr:nth-of-type(2)'),
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
    $('.toggler .first-line').click(function (e) {
        e.preventDefault();
        $(this).parent('.toggler').toggleClass('toggled');
    });

})
