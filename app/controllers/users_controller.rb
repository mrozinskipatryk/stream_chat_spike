# frozen_string_literal: true

require 'stream-chat'

class UsersController < ApplicationController
  before_action :set_user, only: %i[create create_channel list_of_channels leave_channel]

  def create
    if @user.nil?
      user = User.create(user_params)

      if user.valid?
        user.save
        render json: { status: true, user: user, token: chat_token(user.name) }

        return
      end

      render json: { status: false, message: 'Could not create an account for the user' }

      return
    end

    render json: { status: true, user: @user, token: chat_token(@user.name) }
  end

  def create_channel
    chat_veryfied_members = params[:chat_members].map do |chat_member_name|
      User.find_by(name: chat_member_name)&.name
    end

    data_hash =  {  'members' => chat_veryfied_members << @user.name,
                    "channel_detail" => { "topic" => params[:channel_topic].gsub(' ', '-')} }
    channel = client.channel('messaging', channel_id: params[:channel_id].gsub(' ', '-'), data: data_hash)
    channel.create(@user.name)

    if channel
      render json: { status: true, message: "Channel with id #{params[:channel_id]} created" }
    else
      render json: { status: false, message: 'Could not create channel' }
    end
  end

  def list_of_channels
    if @user
      response = client.query_channels({'members' => { '$in' => ["#{@user.name}"] } })
      channels_name = response['channels'].map { |channel_response| channel_response.dig('channel', 'id') }

      render json: { status: true, channels: channels_name }
    else
      render json: { status: false, message: 'Could not find member' }
    end
  end

  def add_members_to_channel
    members_names = params[:list_of_members].map do |member_name|
      User.find_by(name: member_name)&.name
    end.compact

    hide_history = params[:hide_history]
    hide_history == 'true' ? phide_history = true : hide_history = false

    success = channel.add_members(members_names, hide_history: hide_history, message: { "text" => "#{members_names} joined the channel.", "user_id" => members_names.first })

    if success
      render json: { status: true, user: @user }
    else
      render json: { status: false, message: 'Could not add members to channel' }
    end
  end

  def leave_channel
    channel.remove_members([@user.name])

    render json: { message: "#{@user.name} left the channel." }, status: :ok
  end

  def all_members
    members_resposne = client.query_users({})
    members_ids = members_resposne['users'].map { |user| user['id'] }

    if members_ids.present?
      render json: { status: true, ids: members_ids }
    else
      render json: { status: false, message: 'Could not return members' }
    end
  end

  def list_of_members_in_channel
    members_names = channel.query_members['members'].map { |member| member['user_id'] }

    if members_names.present?
      render json: { status: true, members_names: members_names }
    else
      render json: { status: false, message: 'Could not find members or channel' }
    end
  end

  private

  def chat_token(username)
    token = client.create_token(username)
    client.update_user({ id: username, name: username })

    token
  rescue StandardError => e
    p e
    ''
  end

  def user_params
    params.permit(:name)
  end

  def client
    @client ||= StreamChat::Client.new(api_key = Rails.configuration.stream_api_key, api_secret = Rails.configuration.stream_api_secret)
  end

  def channel
    client.channel('messaging', channel_id: params[:channel_id])
  end

  def set_user
    @user = User.find_by(name: params[:username])
  end
end