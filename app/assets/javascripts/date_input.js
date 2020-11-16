import $ from 'jquery'

function dateInput (id) {
  $(document).ready(() => {
    const setDateInput = (date) => {
      return () => {
        day.value = date.getDate()
        month.value = date.getMonth() + 1
        year.value = date.getFullYear()
      }
    }

    const currentDate = new Date()
    const dateYesterday = new Date(currentDate.getTime())

    const element = document.getElementById(id)
    const day = element.querySelector("input[name*='day']")
    const month = element.querySelector("input[name*='month']")
    const year = element.querySelector("input[name*='year']")

    // This sets the date to the previous day, since setting
    // the date to 0 sets the date to the last day of the
    // previous month.
    dateYesterday.setDate(dateYesterday.getDate() - 1)

    const today = document.getElementById('today')
    const yesterday = document.getElementById('yesterday')
    today.onclick = setDateInput(currentDate)
    yesterday.onclick = setDateInput(dateYesterday)
  })
}

window.dateInput = dateInput
