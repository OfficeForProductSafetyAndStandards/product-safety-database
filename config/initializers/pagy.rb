require "pagy/extras/overflow"
require "pagy/extras/searchkick"

Searchkick.extend Pagy::Searchkick

Pagy::DEFAULT[:items] = 20 # Show 20 items per page
Pagy::DEFAULT[:size]  = [1, 1, 1, 1] # Show first, last and one page either side of the current page for pagination links
Pagy::DEFAULT[:overflow] = :last_page # Show the last page if the current page is after the last page (e.g. 2 pages and asking for page 3)
