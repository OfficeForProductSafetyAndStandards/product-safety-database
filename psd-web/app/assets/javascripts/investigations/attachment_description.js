import $ from 'jquery';

$(document).ready(() => {
  const attachmentFileInput = document.getElementById('attachment-file-input');
  const attachmentDescription = document.getElementById('attachment-description');
  const currentAttachmentDetails = document.getElementById('current-attachment-details');

  if (attachmentFileInput) {
    attachmentFileInput.onchange = function onAttachmentInputChange() {
      if (this.value) {
        $(attachmentDescription).show();
      } else {
        $(attachmentDescription).hide();
      }
    };
  }

  if (attachmentDescription) {
    if (currentAttachmentDetails) {
      $(attachmentDescription).show();
    } else {
      $(attachmentDescription).hide();
    }
  }
});
