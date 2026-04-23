module AboutYou
  class CollegesController < BaseController
    MAX_RESULTS = 10
    MIN_QUERY_LENGTH = 2

    def search
      query = params[:q].to_s.strip
      results = if query.length < MIN_QUERY_LENGTH
        College.none
      else
        College.visible_to(therapist)
          .where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query)}%")
          .order(Arel.sql("lower(name)"))
          .limit(MAX_RESULTS)
      end

      render json: results.map { |c| { id: c.id, name: c.name, status: c.status } }
    end
  end
end
