require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

get '/' do
  @meetups = Meetup.all
  erb :index
end


get '/create' do
  authenticate!
  erb :create
end

post '/create' do
    meetup = Meetup.create(
    title: params[:title],
    description: params[:description],
    location: params[:location],
    start_date: params[:start_date],
    start_time: params[:start_time],
    created_by: current_user.id )
    flash[:notice] = "Meetup Created!"
    redirect "/meetup/#{meetup.id}"
end

post '/delete_meetup' do
  meetup_id = params[:meetup]
  meetup = Meetup.find_by(
  id: meetup_id
  )
  meetup.destroy
  flash[:notice] = "You Have Deleted #{meetup.title}"
  redirect '/'

end

post '/leave_meetup' do
  meetup_id = params[:meetup]
  attendee = Attendee.find_by(
  user_id: current_user.id,
  meetup_id: meetup_id
  )
  attendee.destroy
  flash[:notice] = "You Left The Meetup"
  redirect "/meetup/#{meetup_id}"
end

get '/meetup/:id' do
  meetup_id = params[:id]
  # binding.pry
  @comments = Comment.order('created_at DESC').where meetup_id: meetup_id
  @meetup = Meetup.find_by id: meetup_id
  @user = User.find_by id: @meetup.created_by
  erb :show_meetup
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect back
end

post '/add_attendee' do
  Attendee.create(
  user_id: current_user.id,
  meetup_id: params[:meetup]
  )
  flash[:notice] = "You Joined The Meetup"
  redirect "/meetup/#{params[:meetup]}"
end

post '/add_comment' do
  Comment.create(
  title: params[:title],
  comment: params[:comment],
  meetup_id: params[:meetup],
  user_id: current_user.id
  )
  flash[:notice] = "Comment Posted"
  redirect "/meetup/#{params[:meetup]}"
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end
