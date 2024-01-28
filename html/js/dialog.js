/**
 * @file a jQuery UI Dialog exsample.
 * @see https://api.jqueryui.com/dialog/#entry-examples
 * @see https://qiita.com/tamakiiii/items/51f919ea1007424bd52b
 */
'use strict'

function ya_confirm (title, message, ok, cancel) {
    const messagebox = document.getElementById('dialog')
    messagebox.innerText = message
    jQuery(messagebox).dialog({
        autoOpen: true,
        modal: true,
        title: title,
        buttons: [
            {
                text: 'OK',
                click: ok
            },
            {
                text: 'Cancel',
                click: function () { jQuery(this).dialog("close") }
            }
        ]
    })
}

function ya_alert (title, message) {

}

jQuery(() => {
    jQuery('#btn_1').on('click', function() {
        ya_confirm('title', 'button_1')
    })
    jQuery('#btn_2').on('click', function() {
        ya_confirm('title', 'button_2')
    })
})
