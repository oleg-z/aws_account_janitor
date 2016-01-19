Rails.application.routes.draw do
  root to: 'janitor#usage_dashboard'

  get '/example' => 'janitor#example'
  get '/dashboard' => 'janitor#dashboard'
  get '/usage_dashboard' => 'janitor#usage_dashboard'

  get 'ec2/orphaned_instances'
  get 'ec2/orphaned_asgs'
  get 'ec2/orphaned_volumes'
  post 'ec2/update_tags'

  get 'database/orphaned_ddb'
  get 'database/orphaned_rds'
  post 'database/update_tags'

  resources :account

  post 'account/:id' => "account#update"
end
