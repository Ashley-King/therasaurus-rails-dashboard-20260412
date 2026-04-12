module DashboardHelper
  def dashboard_nav_link(label, path)
    active = current_page?(path)
    base_classes = "block rounded-md px-3 py-2 text-sm font-medium"
    classes = if active
      "#{base_classes} bg-plum-bg text-plum"
    else
      "#{base_classes} text-text-muted hover:bg-surface-secondary hover:text-text-secondary"
    end

    link_to label, path, class: classes
  end

  def about_you_sidebar_link(label, path, icon_active: nil, icon_inactive: nil, icon: nil)
    active = current_page?(path) || (path == professional_identity_path && current_page?(about_you_path))

    base = "py-3 px-5 border-b last:border-0 border-gray-100 flex items-center gap-2.5 text-sm font-medium group"
    classes = if active
      "#{base} text-plum bg-plum-bg border-plum-bg"
    else
      "#{base} text-gray-500 hover:text-plum hover:bg-plum-bg hover:border-plum-bg"
    end

    link_to path, class: classes do
      icon_html = if icon
        # Single icon — inherits link color (gray → plum on active/hover)
        icon_color = active ? "text-plum" : "text-gray-400 group-hover:text-plum"
        content_tag(:span, icon.html_safe, class: "w-4 flex items-center justify-center #{icon_color}")
      elsif icon_active && icon_inactive
        active_icon = content_tag(:span, icon_active.html_safe,
          class: "w-4 flex items-center justify-center #{active ? '' : 'hidden'}")
        inactive_icon = content_tag(:span, icon_inactive.html_safe,
          class: "w-4 flex items-center justify-center text-gray-400 group-hover:text-plum #{active ? 'hidden' : ''}")
        active_icon + inactive_icon
      else
        "".html_safe
      end
      icon_html + content_tag(:span, label)
    end
  end

  def dashboard_topnav_link(label, path)
    active = current_page?(path) || request.path.start_with?(path.chomp("/"))
    base_classes = "text-base leading-6 font-medium hover:text-gray-700 focus:outline-none focus:text-gray-700 transition ease-in-out duration-150"
    classes = if active
      "#{base_classes} text-gray-800"
    else
      "#{base_classes} text-gray-400"
    end

    link_to label, path, class: classes
  end
end
