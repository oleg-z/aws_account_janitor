Rails.application.routes.draw do
  root to: 'janitor#dashboard'

  get '/example' => 'janitor#example'
  get '/dashboard' => 'janitor#dashboard'

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
