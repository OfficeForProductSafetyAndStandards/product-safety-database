'use strict'

window.setDateInput = (date, inputDay, inputMonth, inputYear) => {
  inputDay.value = date.getDate()
  inputMonth.value = date.getMonth() + 1
  inputYear.value = date.getFullYear()
}

window.dateInput = (id) => {
  document.addEventListener('DOMContentLoaded', () => {
    const currentDate = new Date()
    const dateYesterday = new Date(currentDate.getTime())

    const element = document.querySelector(`#${id}`)
    const day = element.querySelector("input[name*='day']")
    const month = element.querySelector("input[name*='month']")
    const year = element.querySelector("input[name*='year']")

    // This sets the date to the previous day, since setting
    // the date to 0 sets the date to the last day of the
    // previous month.
    dateYesterday.setDate(dateYesterday.getDate() - 1)

    document.querySelector('#today').addEventListener('click', (e) => {
      e.preventDefault()
      window.setDateInput(currentDate, day, month, year)
      return false
    })
    document.querySelector('#yesterday').addEventListener('click', (e) => {
      e.preventDefault()
      window.setDateInput(dateYesterday, day, month, year)
      return false
    })
  })
}
