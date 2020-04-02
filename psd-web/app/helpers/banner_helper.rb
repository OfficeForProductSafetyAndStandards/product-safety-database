module BannerHelper
  # Use the banner component to display an important site-wise message.
  #
  # Example:
  #
  # <%= banner(text: "We are experiencing temporary performance issues") %>
  #
  # The component can contain HTML, given either as a `html` param or a block:
  #
  # <%= banner do %>
  #   <%= tag.p "We are experiencing temporary performance issues" %>
  #   <%= tag.p link_to("Read more", ""https://blog.example.com/temporary-performance-issue"") %>
  # <% end %>
  def banner(text: nil, html: nil, &block)
    tag.div(class: "app-banner") do

      if block_given?
        tag.div(class: "app-banner__message", &block)
      else
        tag.div((html || text), class: "app-banner__message")
      end
    end
  end
end
