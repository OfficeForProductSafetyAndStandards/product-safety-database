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

    # Ahoy
    Ahoy::Visit.rollup("New visits", column: :started_at, interval: :day)
    Ahoy::Visit.rollup("New visits", column: :started_at, interval: :month)
    Ahoy::Visit.rollup("New visits", column: :started_at, interval: :year)
    ahoy_rollups(name: "Visited help page")
    ahoy_rollups(name: "Performed search")

    ahoy_rollups(name: "Generated notification export")
    ahoy_rollups(name: "Generated product export")
    ahoy_rollups(name: "Generated business export")

    ahoy_rollups(name: "Updated product")
    ahoy_rollups(name: "Created notification from product")
    ahoy_rollups(name: "Added product to existing notification")

    ahoy_rollups(name: "Updated notification name")
    ahoy_rollups(name: "Updated batch number")
    ahoy_rollups(name: "Updated custom codes")
    ahoy_rollups(name: "Updated number of affected units")
    ahoy_rollups(name: "Updated overseas regulator")
    ahoy_rollups(name: "Added test result")
    ahoy_rollups(name: "Updated test result")
  end

  private

  def ahoy_rollups(name:)
    Ahoy::Event.where(name:).joins(:visit).rollup(name, column: :started_at, interval: :day)
    Ahoy::Event.where(name:).joins(:visit).rollup(name, column: :started_at, interval: :month)
    Ahoy::Event.where(name:).joins(:visit).rollup(name, column: :started_at, interval: :year)
  end
end
