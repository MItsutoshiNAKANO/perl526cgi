/** */
'use strict'
jQuery(() => {
    jQuery('#select').on('click', ev => {
        jQuery('#workers').trigger('submit')
    })
})
