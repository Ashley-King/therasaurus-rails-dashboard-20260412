class Avo::Resources::BusinessHour < Avo::BaseResource
  self.title = :day_name

  def fields
    field :id, as: :id
    field :therapist, as: :belongs_to
    field :day_of_week, as: :select, options: {
      "Sunday": 0,
      "Monday": 1,
      "Tuesday": 2,
      "Wednesday": 3,
      "Thursday": 4,
      "Friday": 5,
      "Saturday": 6
    }
    field :open_time, as: :text
    field :close_time, as: :text
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
