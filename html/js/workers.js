/** */
'use strict'
jQuery(() => {
    const button_handler = ev => {
        jQuery('#rm').val(`auth_${ev.target.id}`)
        jQuery('#form').trigger('submit')
    }
    jQuery('#add').on('click', button_handler)
    jQuery('#update').on('click', button_handler)
    jQuery('#delete').on('click', (ev) => {
        if (!confirm('削除しますか?')) { return }
        button_handler(ev)
    })
})
