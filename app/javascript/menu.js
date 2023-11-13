'use strict'

function Menu ($module) {
  this.$module = $module
  this.keys = { esc: 27, up: 38, down: 40, tab: 9 }
}

Menu.prototype.init = function () {
  // Check for module
  if (!this.$module) {
    return
  }

  this.convertLinkToButton()
  this.addMenuLinksFromDataAttributes()
}

Menu.prototype.addMenuLinksFromDataAttributes = function () {
  const items = []
  let itemCount = 0

  while (true) {
    const itemKeyPrefix = 'item-' + (itemCount + 1)

    const itemHrefKey = itemKeyPrefix + 'Href'
    const itemTextKey = itemKeyPrefix + 'Text'

    if (this.$module.dataset[itemHrefKey] && this.$module.dataset[itemTextKey]) {
      items.push({
        href: this.$module.dataset[itemHrefKey],
        text: this.$module.dataset[itemTextKey]
      })

      itemCount += 1
    } else {
      break
    }
  }

  if (itemCount === 0) {
    return
  }

  this.$menu = document.createElement('div')
  this.$menu.setAttribute('class', 'app-menu__wrapper app-menu__wrapper--right')
  this.$menu.setAttribute('role', 'menu')

  for (const item of items) {
    const itemLink = document.createElement('a')
    itemLink.setAttribute('href', item.href)
    itemLink.setAttribute('role', 'menuitem')
    itemLink.setAttribute('data-module', 'govuk-button')
    itemLink.setAttribute('class', 'app-menu__item app-button--case-bar-secondary')
    itemLink.textContent = item.text

    this.$menu.appendChild(itemLink)
  }

  this.$menu.addEventListener('keydown', this.menuItemKeyedDown.bind(this))

  this.$module.appendChild(this.$menu)

  document.addEventListener('click', this.documentClicked.bind(this))
}

Menu.prototype.toggle = function () {
  if (this.$button.getAttribute('aria-expanded') === 'false') {
    this.showMenu()
    this.$menu.querySelector('[role=menuitem]').focus()
  } else {
    this.hideMenu()
    this.$button.focus()
  }
}

Menu.prototype.menuButtonClicked = function () {
  this.toggle()
}

Menu.prototype.documentClicked = function (event) {
  if (!this.$module.contains(event.target)) {
    this.hideMenu()
  }
}

Menu.prototype.menuButtonKeyedDown = function (event) {
  switch (event.keyCode) {
    case this.keys.down:
      this.toggle()
      break
  }
}

Menu.prototype.menuItemKeyedDown = function (event) {
  if (event.target && event.target.nodeName === 'A') {
    switch (event.keyCode) {
      case this.keys.up:
        event.preventDefault()
        this.focusPrevious(event.target)
        break
      case this.keys.down:
        event.preventDefault()
        this.focusNext(event.target)
        break
      case this.keys.esc:
        this.$button.focus()
        this.hideMenu()
        break
      case this.keys.tab:
        this.hideMenu()
    }
  }
}

Menu.prototype.focusPrevious = function (currentLink) {
  const previousLink = currentLink.previousSibling

  if (previousLink) {
    previousLink.focus()
  } else {
    // focus the last link
    const menuLinks = this.$menu.querySelectorAll('a')
    menuLinks[menuLinks.length - 1].focus()
  }
}

Menu.prototype.focusNext = function (currentLink) {
  const nextLink = currentLink.nextSibling

  if (nextLink) {
    nextLink.focus()
  } else {
    // focus the first link
    this.$menu.querySelector('a').focus()
  }
}

Menu.prototype.showMenu = function () {
  this.$button.setAttribute('aria-expanded', 'true')
}

Menu.prototype.hideMenu = function () {
  this.$button.setAttribute('aria-expanded', 'false')
}

Menu.prototype.convertLinkToButton = function () {
  const linkButton = this.$module.querySelector('.govuk-button')

  this.$button = document.createElement('button')
  this.$button.textContent = linkButton.textContent
  this.$button.setAttribute('class', 'govuk-button app-button--case-bar-secondary app-menu__toggle-button app-menu__toggle-button--secondary')
  this.$button.setAttribute('aria-expanded', 'false')
  this.$button.setAttribute('aria-haspopup', 'true')
  this.$button.addEventListener('click', this.menuButtonClicked.bind(this))
  this.$button.addEventListener('click', this.menuButtonKeyedDown.bind(this))

  this.$module.removeChild(linkButton)
  this.$module.appendChild(this.$button)
}

document.addEventListener('DOMContentLoaded', () => {
  const $menus = document.querySelectorAll('[data-module="app-menu"]')
  $menus.forEach($menu => {
    new Menu($menu).init()
  })
})
