namespace :search do
  desc "Rebuild the public search read table"
  task refresh_public_points: :environment do
    PublicSearchPointRefresh.rebuild_all
  end
end
