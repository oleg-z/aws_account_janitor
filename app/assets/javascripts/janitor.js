//= require jquery
//= require bootstrap

jQuery(function($) {
    $('form[data-async]').on('submit', function(event) {
        var $form = $(this);
        var $target = $($form.attr('data-target'));

        $.ajax({
            type: $form.attr('method'),
            url: $form.attr('action'),
            data: $form.serialize(),

            success: function(data, status) {
                $target.html(data);
            }
        });

        event.preventDefault();
    });
});

jQuery(function($) {
    $('form[mass-assignment]').on('submit', function(event) {
        var $form = $(this);
        $form.find("input[name='objects[]']").remove()
        $("input[mass-selector]:checked:visible").each(function() {
            $("<input type='hidden' name='objects[]'/>")
                .attr('value', $(this).attr('aws-object-id'))
                .appendTo($form)
        })

        $("<input type='hidden' name='region'/>")
            .attr('value', $("#regions[role='tablist'] li.active").attr('region'))
            .appendTo($form)

        $("<input type='hidden' name='account_id'/>")
            .attr('value', $("body[data-account-id]").attr('data-account-id'))
            .appendTo($form)

        var $target = $($form.attr('data-target'));
        var $alert_box = $("div[role='dialog']:visible div.alert")

        $alert_box
            .removeClass('alert-danger')
            .addClass('alert-info')
            .text("Processing, please wait...")
            .show()

        $.ajax({
            type: $form.attr('method'),
            url: $form.attr('action'),
            data: $form.serialize(),

            success: function(data, status) {
                var $active_dialog = $("div[role='dialog']:visible")
                $alert_box
                    .removeClass('alert-info')
                    .addClass('alert-success')
                    .text(data.message)
                    .show()
                    .delay(1000)
                    .fadeOut("slow");

                setTimeout(function() { $active_dialog.modal('hide') }, 2000)
            }
        });

        event.preventDefault();
    });
});
