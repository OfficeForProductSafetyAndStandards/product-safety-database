'use strict'

function clearRadiosOnOtherInput (inputElements, radioButtons) {
  for (let i = 0; i < inputElements.length; i++) {
    inputElements[i].addEventListener('input', (e) => {
      if (e.target.value !== '') {
        resetAllRadioButtons(radioButtons)
      }
    })
  }

  for (let i = 0; i < radioButtons.length; i++) {
    radioButtons[i].addEventListener('change', (e) => {
      if (e.target.checked) {
        clearAllInputElements(inputElements)
      }
    })
  }
}

function resetAllRadioButtons (radioButtons) {
  for (let i = 0; i < radioButtons.length; i++) {
    radioButtons[i].checked = false
  }
}

function clearAllInputElements (inputElements) {
  for (let i = 0; i < inputElements.length; i++) {
    inputElements[i].value = ''
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const inputs = document.querySelectorAll('.js-input-handle-other')
  const radios = document.querySelectorAll('.js-radio-handle-other')

  if (inputs && radios) {
    clearRadiosOnOtherInput(inputs, radios)
  }
})
