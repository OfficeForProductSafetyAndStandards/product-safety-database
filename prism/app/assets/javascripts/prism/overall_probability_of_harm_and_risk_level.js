'use strict'

/* eslint-disable no-unused-vars */
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.opss-step-probability-choice, .opss-step-probability-decimal, .opss-step-probability-frequency').forEach(probability => {
    probability.addEventListener('input', () => {
      getOverallProbabilityOfHarmAndRiskLevel()
    })
  })
})

const getOverallProbabilityOfHarmAndRiskLevel = async () => {
  const probabilitiesDecimal = [...document.querySelectorAll('.govuk-radios__conditional:not(.govuk-radios__conditional--hidden) .opss-step-probability-decimal')].map(el => el.value).filter(Number)
  const probabilitiesFrequency = [...document.querySelectorAll('.govuk-radios__conditional:not(.govuk-radios__conditional--hidden) .opss-step-probability-frequency')].map(el => el.value).filter(Number)
  const severityLevel = document.querySelector('input#harm_scenario_severity_level').value
  const response = await fetch(`/prism/api/overall-probability-of-harm-and-risk-level?probabilities_decimal=${probabilitiesDecimal}&probabilities_frequency=${probabilitiesFrequency}&severity_level=${severityLevel}`)
  const result = await response.json()

  if (result.status === 200) {
    document.querySelector('#overall-probability-of-harm').innerHTML = result.result.probability_human
    document.querySelector('#overall-risk-level').innerHTML = result.result.risk_level_tag_html
  }
}
