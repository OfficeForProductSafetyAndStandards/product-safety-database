module ActivityHelper
  def activity_types
    base_types = {
      "comment": "Add a comment",
      "email": "Record email",
      "phone_call": "Record phone call",
      "meeting": "Record meeting",
      "testing_request": "Record testing request",
      "testing_result": "Record test result",
      "corrective_action": "Record corrective action",
      "product": "Add a product to the case",
      "business": "Add a business to the case"
    }
    base_types["alert"] = "Send email alert about this case" if policy(@investigation).user_allowed_to_raise_alert?

    base_types
  end
end
