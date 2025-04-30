'use strict'

// Dynamically fills the product subcategory <select> element based on what is
// chosen from the product category <select> element.
document.addEventListener('DOMContentLoaded', async () => {
  // Get the main category and sub-category <select> elements
  const parentElement = document.querySelector('#product-category-field, #product-category-field-error, #product-recall-form-product-type-field, #product-recall-form-product-type-field-error')
  const childElement = document.querySelector('#product-subcategory-field, #product-subcategory-field-error, #product-recall-form-subcategory-field, #product-recall-form-subcategory-field-error')

  if (parentElement && childElement && !parentElement.disabled && !childElement.disabled) {
    // Get a list of all product subcategories and their parent product categories
    // from the API - this happens once per page load of a relevant page
    const productSubcategoriesApi = await fetch('/api/v1/products/product_subcategories')
    const productSubcategories = await productSubcategoriesApi.json()

    // Create an <option> element for each product subcategory and save it
    // under its parent product category
    const productSubcategoryOptions = {}
    productSubcategories.forEach(productSubcategory => {
      const option = document.createElement('option')
      // NOTE: this semicolon is needed to prevent the next line from looking like a function call
      option.value = option.text = productSubcategory[0];
      (productSubcategoryOptions[productSubcategory[1]] ||= []).push(option)
    })

    // Sync the initial state of the product subcategory <select> element
    // while also keeping the user's selection if the list doesn't change
    const currentSelection = childElement.value
    childElement.length = 0
    childElement.options.add(document.createElement('option'))

    if (parentElement.value !== '') {
      productSubcategoryOptions[parentElement.value].forEach(el => {
        childElement.options.add(el)
      })
    }

    // Attempt to restore the user's previous selection
    childElement.value = currentSelection

    // Re-populate the sub-category <select> element depending on which product
    // category is selected from the main category <select> element
    parentElement.addEventListener('change', () => {
      childElement.length = 0
      childElement.options.add(document.createElement('option'))

      if (parentElement.value !== '') {
        productSubcategoryOptions[parentElement.value].forEach(el => {
          childElement.options.add(el)
        })
      }
    })
  }
})
