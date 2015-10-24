Rails.application.routes.draw do
  root to: 'ec2#abandoned_instances'
  get 'ec2/abandoned_instances'
  get 'ec2/abandoned_asgs'
  get 'ec2/abandoned_volumes'
  post 'ec2/update_tags'

  get 'database/ddb_orphaned'
  get 'database/rds_orphaned'
  post 'database/update_tags'

  resources :account

  post 'account/:id' => "account#update"
end
