/** */
'use strict'
jQuery(() => {
  jQuery('#select').on('click', ev => {
    const form = document.getElementById('form')
    form.action = 'workers.cgi'
    form.submit()
  })
})
