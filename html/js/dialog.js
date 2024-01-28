/**
 * @file a jQuery UI Dialog exsample.
 * @see https://api.jqueryui.com/dialog/#entry-examples
 * @see https://qiita.com/tamakiiii/items/51f919ea1007424bd52b
 */
'use strict'

jQuery("#dialog").dialog({
    autoOpen: false,
    modal: true,
    buttons: [
        {
            text: 'OK',
            click: () => {}
        },
        {
            text: 'Cancel',
            click: function () { jQuery(this).dialog("close") }
        }
    ]
});

function ya_confirm (title, message, ok, cancel) {
    jQuery('<div>', { text: message })
}

function ya_alert (title, message) {

}

jQuery(() => {
    jQuery('#btn-1').on('click', function() {
        jQuery("#dialog").dialog("open")
    })
    jQuery('#btn-2').on('click', function() {
        jQuery("#dialog").dialog("open")
    })
})
