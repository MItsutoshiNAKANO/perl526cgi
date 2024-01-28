/**
 * @file a jQuery UI Dialog exsample.
 * @see https://api.jqueryui.com/dialog/#entry-examples
 * @see https://qiita.com/tamakiiii/items/51f919ea1007424bd52b
 */
'use strict'

function ya_confirm (title, message, ok, cancel) {
    const parent = document.getElementById('body')
    const dialog = document.createElement('span')
    dialog.innerText = message
    parent.insertAdjacentElement('beforeend', dialog)
    jQuery(dialog).dialog({
        autoOpen: true,
        modal: true,
        title: title,
        buttons: [
            {
                text: 'OK',
                click: function () {
                    if (ok) { ok() }
                    jQuery(dialog).dialog('destroy')
                    dialog.remove()
                }
            },
            {
                text: 'Cancel',
                click: function () {
                    if (cancel) { cancel() }
                    jQuery(dialog).dialog('destroy')
                    dialog.remove()
                }
            }
        ]
    })
}

function ya_alert (title, message) {

}

jQuery(() => {
    jQuery('#btn_1').on('click', function() {
        ya_confirm('title', 'button_1', alert)
    })
    jQuery('#btn_2').on('click', function() {
        ya_confirm('title', 'button_2', alert)
    })
})
