import $ from 'jquery'

function dateInput (idPrefix) {
  $(document).ready(() => {
    const currentDate = new Date()
    var dateYesterday = new Date(currentDate.getTime())

    // This sets the date to the previous day, since setting
    // the date to 0 sets the date to the last day of the
    // previous month.
    dateYesterday.setDate(dateYesterday.getDate() - 1)

    const today = document.getElementById('today')
    const yesterday = document.getElementById('yesterday')
    today.onclick = function setDateToToday () {
      const day = document.getElementById(`${idPrefix}[day]`)
      day.value = currentDate.getDate()
      const month = document.getElementById(`${idPrefix}[month]`)
      month.value = currentDate.getMonth() + 1
      const year = document.getElementById(`${idPrefix}[year]`)
      year.value = currentDate.getFullYear()
    }
    yesterday.onclick = function setDateToYesterday () {
      const day = document.getElementById(`${idPrefix}[day]`)
      day.value = dateYesterday.getDate()
      const month = document.getElementById(`${idPrefix}[month]`)
      month.value = dateYesterday.getMonth() + 1
      const year = document.getElementById(`${idPrefix}[year]`)
      year.value = dateYesterday.getFullYear()
    }
  })
}

window.dateInput = dateInput
