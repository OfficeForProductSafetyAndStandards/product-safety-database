module TestsHelper
  def test_result_summary_rows(test_result)
    rows = [
      {
        key: { text: "Date of test" },
        value: { text: test_result.date.to_s(:govuk) }
      },
      {
        key: { text: "Product tested" },
        value: { html: link_to(test_result.product.name, product_path(test_result.product)) }
      },
      {
        key: { text: "Legislation" },
        value: { text: test_result.legislation }
      },
      {
        key: { text: "Standards" },
        value: { text: test_result.standards_product_was_tested_against }
      },
      {
        key: { text: "Result" },
        value: { text: test_result.result.upcase_first }
      }
    ]

    if test_result.details.present?
      rows << {
        key: { text: "Further details" },
        value: { text: test_result.details }
      }
    end

    attachment_description = test_result.document.blob.metadata["description"]
    if attachment_description.present?
      rows << {
        key: { text: "Attachment description" },
        value: { text: attachment_description }
      }
    end

    rows
  end
end
