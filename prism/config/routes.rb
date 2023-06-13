Prism::Engine.routes.draw do
  get "/", to: ->(_) { [200, {}, %w[OK]] }
end
