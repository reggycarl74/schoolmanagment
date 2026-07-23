Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resource :profile, only: %i[edit update]
  resources :passwords, param: :token, only: %i[new create edit update]

  namespace :admin do
    resources :users, only: %i[index edit update destroy] do
      member { patch :approve }
    end
  end

  root "dashboard#index"
  get "search", to: "search#index", as: :search

  resources :students, only: %i[index show new create edit update] do
    member { get :assessments }
    collection { post :import }
  end
  resources :guardians, only: %i[index show new create edit update] do
    member do
      post :invite
      patch :toggle_portal_access
    end
  end
  resources :teachers, only: %i[index new create]
  resources :classrooms, only: %i[index new create]
  resources :subjects, only: %i[index new create]
  resources :course_sections, only: :index
  resources :assessments, only: :index do
    member { patch :advance }
  end
  resources :exam_results, only: %i[index new create]
  resources :lesson_notes, only: %i[index new create edit update]
  resources :grades, only: %i[edit update]
  resources :teaching_assignments, only: %i[index new create edit update destroy]
  resource :attendance_register, only: %i[show create]
  resource :promotion, only: %i[new create]
  resources :report_cards, only: :show
  resources :timetable_entries, only: %i[index new create destroy]
  resources :announcements, only: %i[index new create]
  resources :classroom_posts, only: %i[index show new create] do
    resources :student_submissions, only: %i[create update]
  end
  resource :assessment_settings, only: %i[show create]
  resources :invoices, only: %i[index show new create] do
    member do
      patch :cancel
      post :send_reminder
    end
    resources :payments, only: %i[create show] do
      member { patch :reverse }
    end
    resources :invoice_line_items, only: %i[create destroy]
    resources :billing_adjustments, only: :create
    resources :payment_installments, only: %i[create destroy]
  end
  resources :students, only: [] do
    resource :billing_statement, only: %i[show update]
  end
  resources :fee_structures, only: %i[index new create]
  resources :audit_events, only: :index
  resources :student_documents, only: %i[create destroy]
  resources :report_card_comments, only: %i[create update]
  resources :report_card_remark_templates, path: "teacher_remarks", only: %i[index create edit update]
  resource :attendance_analytics, only: :show
  resource :academic_year_rollover, only: %i[new create]
  resource :financial_report, only: :show
  resource :school_setting, only: %i[show update]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
