Rails.application.routes.draw do
  root to: 'dashboard#usage_dashboard'

  get '/example' => 'janitor#example'
  get '/dashboard' => 'dashboard#tag_violations'
  get '/usage_dashboard' => 'dashboard#usage_dashboard'
  get '/underutilized' => 'dashboard#underutilized'


  get 'ec2/orphaned_instances'
  get 'ec2/underutilized_instances'
  get 'ec2/orphaned_asgs'
  get 'ec2/orphaned_volumes'
  get 'ec2/untagged_snapshots'
  post 'ec2/update_tags'

  get 'database/orphaned_ddb'
  get 'database/orphaned_rds'
  post 'database/update_tags'

  resources :account

  post 'account/:id' => "account#update"
end
