
import { nodeListForEach } from 'govuk-frontend/govuk/common'

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
  var items = []
  var itemCount = 0

  while (true) {
    var itemKeyPrefix = 'item-' + (itemCount + 1)

    var itemHrefKey = itemKeyPrefix + '-href'
    var itemTextKey = itemKeyPrefix + '-text'

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

  for (var item of items) {
    var itemLink = document.createElement('a')
    itemLink.setAttribute('href', item.href)
    itemLink.setAttribute('role', 'menuitem')
    itemLink.setAttribute('data-module', 'govuk-button')
    itemLink.setAttribute('class', 'app-menu__item app-button--case-bar-secondary')
    itemLink.textContent = item.text

    this.$menu.appendChild(itemLink)
  }

  this.$menu.addEventListener('keydown', this.menuItemKeyedDown.bind(this))

  this.$module.appendChild(this.$menu)
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
  var previousLink = currentLink.previousSibling

  if (previousLink) {
    previousLink.focus()
  } else {
    // focus the last lank
    var menuLinks = this.$menu.querySelectorAll('a')
    menuLinks[menuLinks.length - 1].focus()
  }
}

Menu.prototype.focusNext = function (currentLink) {
  var nextLink = currentLink.nextSibling

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
  var linkButton = this.$module.querySelector('.govuk-button')

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

document.addEventListener('DOMContentLoaded', function () {
  var $menus = document.querySelectorAll('[data-module="app-menu"]')
  nodeListForEach($menus, function ($menu) {
    new Menu($menu).init()
  })
})
