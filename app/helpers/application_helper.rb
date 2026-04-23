module ApplicationHelper
  # US state codes for <select> options. Memoized per-request so a page with
  # multiple ZIP comboboxes doesn't hit the DB repeatedly.
  def us_state_codes
    @us_state_codes ||= State.order(:code).pluck(:code)
  end
end
