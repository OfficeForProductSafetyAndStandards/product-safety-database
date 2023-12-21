require "pagy/extras/searchkick"
Searchkick.extend Pagy::Searchkick

Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:size]  = [1, 1, 1, 1]
