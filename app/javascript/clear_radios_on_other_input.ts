function clearRadiosOnOtherInput(inputElements: NodeListOf<HTMLInputElement>, radioButtons: NodeListOf<HTMLInputElement>): void {
  for (let i = 0; i < inputElements.length; i++) {
    inputElements[i].addEventListener('input', (e) => {
      const value = (e.target as HTMLInputElement).value
      if (value !== '') {
        resetAllRadioButtons(radioButtons)
      }
    })
  }

  for (let i = 0; i < radioButtons.length; i++) {
    radioButtons[i].addEventListener('change', (e) => {
      if ((e.target as HTMLInputElement).checked) {
        clearAllInputElements(inputElements)
      }
    })
  }
}


function resetAllRadioButtons(radioButtons: NodeListOf<HTMLInputElement>): void {
  for (let i = 0; i < radioButtons.length; i++) {
    radioButtons[i].checked = false
  }
}

function clearAllInputElements(inputElements: NodeListOf<HTMLInputElement>): void {
  for (let i = 0; i < inputElements.length; i++) {
    inputElements[i].value = ''
  }
}

document.addEventListener('DOMContentLoaded', (_) => {
  const inputs = document.querySelectorAll('.js-input-handle-other') as NodeListOf<HTMLInputElement>
  const radios = document.querySelectorAll('.js-radio-handle-other') as NodeListOf<HTMLInputElement>

  if (inputs && radios) {
    clearRadiosOnOtherInput(inputs, radios)
  }
})