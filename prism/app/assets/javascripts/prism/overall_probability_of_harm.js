'use strict'

/* eslint-disable no-unused-vars */
const attachOpssStepEventHandler = () => {
  document.querySelectorAll('.opss-step-probability-decimal').forEach(probability => {
    probability.addEventListener('input', () => {
      getOverallProbabilityOfHarm()
    })
  })
  document.querySelectorAll('.opss-step-probability-frequency').forEach(probability => {
    probability.addEventListener('input', () => {
      getOverallProbabilityOfHarm()
    })
  })
}

const getOverallProbabilityOfHarm = async () => {
  const probabilitiesDecimal = [...document.querySelectorAll('.opss-step-probability-decimal')].map(el => el.value).filter(Number)
  const probabilitiesFrequency = [...document.querySelectorAll('.opss-step-probability-frequency')].map(el => el.value).filter(Number)
  const response = await fetch(`/prism/api/overall-probability-of-harm?probabilities_decimal=${probabilitiesDecimal}&probabilities_frequency=${probabilitiesFrequency}`)
  const result = await response.json()

  if (result.status === 200) {
    document.querySelector('#overall-probability-of-harm').innerHTML = result.result.probability_human
  }
}
