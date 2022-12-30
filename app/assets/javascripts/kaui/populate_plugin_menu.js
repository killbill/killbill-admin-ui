function populatePluginMenu() {
    var available_engines_path = Routes.available_engines_url({format: "json"});

    var populateHTML = function (allEngines) {
        if (allEngines.length === 0) {
            return;
        }

        var tagSelectBox = $('<div>', {class: 'tag-select-box'});

        $.each(allEngines, function (index, value) {
            tagSelectBox.append($('<a>', {href: value['path']}).html(value['name']));
        });

        var span = $('<span>');
        span.append($('<i>', {class: 'fa fa-plug'}));
        span.append($('<i>', {class: 'fa fa-caret-down'}));

        var tagSelect = $('<div>', {class: 'tag-select'});
        tagSelect.append(span);
        tagSelect.append(tagSelectBox);

        $('#main-menu').find('.tag-bar').prepend(tagSelect);
    };

    return $.ajax({
        type: 'GET',
        contentType: 'application/json',
        dataType: 'json',
        url: available_engines_path
    }).done(populateHTML);
}

$(function () {
    populatePluginMenu();
});
