module InspectionsHelper
  def format_inspection_count(user)
    count = user.inspections.count
    if user.inspection_limit > 0
      "#{count} / #{user.inspection_limit} inspections"
    else
      "#{count} inspections"
    end
  end

  def inspection_links(user)
    total = user.inspections.count
    overdue = user.inspections.overdue.count

    if total > 0
      links = []
      links << link_to("all (#{total})", inspections_path)
      links << link_to("overdue (#{overdue})", overdue_inspections_path) if overdue > 0
      content_tag(:p, links.join(" / ").html_safe, class: "center") if links.any?
    end
  end
end
