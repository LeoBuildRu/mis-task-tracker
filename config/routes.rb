Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # Simple demo SPA served from public/index.html
  root to: redirect("/index.html")

  get "/up", to: proc { [200, {}, ["ok"]] }

  namespace :api do
    namespace :v1 do
      resources :tasks do
        resources :tags, only: %i[create destroy], controller: "task_tags"

        # Occurrence routes — :date is YYYY-MM-DD
        get    "occurrences/:date", to: "task_occurrences#show",    as: :occurrence,
                                    constraints: { date: /\d{4}-\d{2}-\d{2}/ }
        patch  "occurrences/:date", to: "task_occurrences#update",
                                    constraints: { date: /\d{4}-\d{2}-\d{2}/ }
        put    "occurrences/:date", to: "task_occurrences#update",
                                    constraints: { date: /\d{4}-\d{2}-\d{2}/ }
        delete "occurrences/:date", to: "task_occurrences#destroy",
                                    constraints: { date: /\d{4}-\d{2}-\d{2}/ }
      end

      resources :tags, only: %i[index create update destroy]
    end
  end
end
