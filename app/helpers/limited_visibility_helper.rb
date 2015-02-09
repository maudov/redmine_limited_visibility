module LimitedVisibilityHelper
  def function_ids_for_current_viewers(issue)
    viewers = []
    if issue.new_record? # create new issue
      if issue.authorized_viewer_ids.present?
        viewers = issue.authorized_viewer_ids
      else
        current_functions = functional_roles_for_current_user(issue.project)
        if current_functions.present? # current user has at least one functional role
          enabled_functions = []
          current_functions.each do |r|
            enabled_functions |= Function.where("id in (?)", r.authorized_viewer_ids).sorted
          end
          enabled_functions = enabled_functions & Function.available_functions_for(@project).sorted
          enabled_functions.sort_by {|a| a.position}
          viewers = enabled_functions.map{ |f| f.id }
        else # current user has no visibility role (can see all issues available for the current project)
          viewers = Function.available_functions_for(issue.project).sorted.pluck(:id)
        end
      end
    else # update existing issue
      if issue && issue.authorized_viewers.present?
        viewers = issue.authorized_viewer_ids
      else
        viewers = Function.available_functions_for(issue.project).sorted.pluck(:id)
      end
    end
    viewers.reject(&:blank?).map(&:to_i)
  end

  def functional_roles_for_current_user(project)
    Function.joins(:members).where(:members => { :user_id => User.current.id, :project_id => project.id }).sorted
  end

  # Returns a string for users/groups option tags
  def assignable_options_for_select(issue, users, selected=nil)
    s = ''
    if @issue.project.module_enabled?("limited_visibility")
      functional_roles_ids = function_ids_for_current_viewers(issue)
      functional_roles_ids.each do |function_id|
        s << content_tag('option', "#{Function.find(function_id).name}", :value => "function-#{function_id}", :selected => (option_value_selected?(function_id, selected) || function_id == selected))
      end
      s << "<option disabled>──────────────</option>"
    end
    if users.include?(User.current)
      s << content_tag('option', "<< #{l(:label_me)} >>", :value => User.current.id)
    end
    groups = ''
    users.sort.each do |element|
      selected_attribute = ' selected="selected"' if option_value_selected?(element, selected) || element.id.to_s == selected
      (element.is_a?(Group) ? groups : s) << %(<option value="#{element.id}"#{selected_attribute}>#{h element.name}</option>)
    end
    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end
end
