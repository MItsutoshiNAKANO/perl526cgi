/**
 * @file a jQuery UI Dialog exsample.
 * @see https://api.jqueryui.com/dialog/#entry-examples
 * @see https://qiita.com/tamakiiii/items/51f919ea1007424bd52b
 */
'use strict'

function ya_confirm (message, ok, cancel, title) {
    const parent = document.getElementById('body')
    const dialog = document.createElement('span')
    dialog.innerText = message
    parent.insertAdjacentElement('beforeend', dialog)
    jQuery(dialog).dialog({
        autoOpen: true,
        modal: true,
        title: title || 'Confirm',
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

function phase2() {
    const all = document.getElementById('all')
    if (all.checked) {
        ya_confirm('All was checked.  Continue?')
    }
}

jQuery(() => {
    jQuery('#btn_1').on('click', function() {
        ya_confirm('Is the phase 1 OK?', phase2)
    })
    jQuery('#btn_2').on('click', function() {
        ya_confirm('button_2', alert)
    })
})
