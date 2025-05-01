module InspectionsHelper
  def format_inspection_count(user)
    count = user.inspections.count
    if user.inspection_limit > 0
      "#{count} / #{user.inspection_limit} inspections"
    else
      "#{count} inspections"
    end
  end
end
