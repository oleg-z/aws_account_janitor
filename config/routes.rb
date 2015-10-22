Rails.application.routes.draw do
  root to: 'ec2#abandoned_instances'
  get 'ec2/abandoned_instances' => 'ec2#abandoned_instances'
  get 'ec2/abandoned_asgs' => 'ec2#abandoned_asgs'
  get 'ec2/abandoned_volumes' => 'ec2#abandoned_volumes'

  get 'dynamo_db/' => 'dynamo_db#unused_tables'

  resources :account

  post 'account/:id' => "account#update"
end
