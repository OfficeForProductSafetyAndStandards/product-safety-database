class GenerateRollupsJob < ApplicationJob
  def perform
    # Users
    User.rollup("New users", interval: :day)
    User.rollup("New users", interval: :month)
    User.rollup("New users", interval: :year)
    User.rollup("Active users", column: :last_sign_in_at, interval: :day)
    User.rollup("Active users", column: :last_sign_in_at, interval: :month)
    User.rollup("Active users", column: :last_sign_in_at, interval: :year)
    User.rollup("Invited users", column: :invited_at, interval: :day)
    User.rollup("Invited users", column: :invited_at, interval: :month)
    User.rollup("Invited users", column: :invited_at, interval: :year)

    # Notifications
    Investigation::Notification.rollup("New notifications", interval: :day)
    Investigation::Notification.rollup("New notifications", interval: :month)
    Investigation::Notification.rollup("New notifications", interval: :year)

    # Products
    Product.rollup("New products", interval: :day)
    Product.rollup("New products", interval: :month)
    Product.rollup("New products", interval: :year)
  end
end
