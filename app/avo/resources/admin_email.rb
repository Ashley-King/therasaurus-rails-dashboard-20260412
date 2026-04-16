class Avo::Resources::AdminEmail < Avo::BaseResource
  self.title = :admin_email
  self.search = {
    query: -> { query.ransack(admin_email_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :admin_email, as: :text
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
