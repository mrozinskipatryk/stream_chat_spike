Rails.application.routes.draw do
  post '/users', to: 'users#create'
  post '/create_channel', to: 'users#create_channel'
  post '/add_members_to_channel', to: 'users#add_members_to_channel'
  get '/list_of_channels', to: 'users#list_of_channels'
  get '/list_of_members_in_channel', to: 'users#list_of_members_in_channel'
  get '/all_members', to: 'users#all_members'
  delete '/leave_channel', to: 'users#leave_channel'
end
