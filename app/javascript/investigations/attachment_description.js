'use strict'

document.addEventListener('DOMContentLoaded', () => {
  const attachmentFileInput = document.querySelectorAll('#attachment-file-input, #email_attachment')
  const attachmentDescription = document.querySelector('#attachment-description')
  const currentAttachmentDetails = document.querySelector('#current-attachment-details')

  attachmentFileInput.forEach(el => {
    el.addEventListener('change', () => {
      if (this.value) {
        attachmentDescription.style.display = 'block'
      } else {
        attachmentDescription.style.display = 'none'
      }
    })
  })

  if (attachmentDescription) {
    if (currentAttachmentDetails) {
      attachmentDescription.style.display = 'block'
    } else {
      attachmentDescription.style.display = 'none'
    }
  }
})
