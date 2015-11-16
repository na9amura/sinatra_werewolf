# encoding: utf-8
require 'rubygems'
require 'active_record'
require 'sinatra/reloader'
require 'sinatra'
require 'yaml'

require './player.rb'
require './const.rb'
require './game_result.rb'

config = YAML.load_file('./database.yml')
ActiveRecord::Base.establish_connection(config["db"]["development"])

class Role < ActiveRecord::Base
end

class User < ActiveRecord::Base
end

configure do
  use Rack::Session::Cookie
end

get '/' do
  erb :'/common/index'
end

get '/chair/note/players/' do
  @subtitle = "参加者を記録"
  erb :'/chair/add_players'
end

post '/chair/add/players/' do
  User.delete_all()
  params.each { |p|
    user = User.new
    user.name = p[1]
    user.is_dead = false;
    user.save
  }

  redirect to('/chair/note/roles/')
end

get '/chair/note/roles/' do
  @subtitle = "役職を記録"
  @users = User.all()
  @roles = Role.all()
  erb :'/chair/set_roles'
end

post '/chair/set/roles/' do
  Player.delete_all()

  params.each { |p|
    user = User.find_by(id: p[0])
    logger.info user
    PlayerFactory.new.create(user.id, user.name, p[1]).save
  }

  redirect to('/chair/start/daytime/')
end

get '/chair/start/daytime/' do
  @subtitle = "昼のターンを開始"
  @action = "/player/select/ban/"
  @players = Player.all()
  erb :'/common/game_start'
end

get '/chair/start/night/' do
  @subtitle = "夜のターンを開始"
  @action = "/player/select/guard/"
  @players = Player.all()
  erb :'/common/game_start'
end

get '/player/select/ban/' do
  @subtitle = "投票人数を記録"
  @players = Player.where(:is_dead => false)
  erb :'/player/ban'
end

get '/player/select/ban/again/' do
  @subtitle = "投票人数を記録"
  @message = "投票人数を再入力してください"
  @players = Player.where(:is_dead => false)
  erb :'/player/ban'
end

post '/player/ban/' do
  max = 0
  params.each { |k, v|
    player = Player.find_by(:id => k.to_i)
    player.update_attribute(:votes_count, v.to_i)
    logger.info player

    if (max < v.to_i)
      max = v.to_i
    end
  }

  top = Player.where(:votes_count => max, :is_dead => false).count
  logger.info "most voted players are : " << top.to_s

  if top != 1
    redirect to('/player/select/ban/again/')
  else
    player = Player.where(:votes_count => max, :is_dead => false)[0]
    player.update_attribute(:is_dead, true)

    logger.info "Banned " + player.name
    @name = player.name
    erb :'/player/banned'
  end
end

get '/chair/show/result/day/' do
    @result = judge()

    if (@result[:Code] == GameReault::CONTINUE[:Code])
      redirect to('/chair/start/night/')
    else
      @subtitle = "判定結果"
      erb :'/common/finish'
    end
end

get '/player/select/guard/' do
  @subtitle = "ボディーガードが守る人を選択"
  @bodyguard = Player.where(:role => RoleID::BODYGUARD)[0]
  if (@bodyguard == nil)
    redirect to('/player/select/bite/')
  end

  @players = Player.where(:is_dead => false)
  erb :'/player/guard'
end

post '/player/guard/' do
  logger.info params[:guarded]
  guarded = Player.find_by(:id => params[:guarded])
  guarded.update_attribute(:is_saved, true)

  logger.info guarded
  redirect to('/player/select/bite/')
end

get '/player/select/bite/' do
    @subtitle = "人狼が襲撃する人を選択"
    @werewolves = Player.where(:role => RoleID::WEREWOLF, :is_dead => false)
    @players = Player.where(:is_dead => false)
    erb :'/player/bite'
end

post '/player/bite/' do
  logger.info params[:bited]
  bited = Player.find_by(:id => params[:bited])
  tail = "守られました"

  if !bited.is_saved
    bited.update_attribute(:is_dead, true)
    session[:die_tonight] = bited
    tail = "死亡しました"
  end

  logger.info bited
  @result = bited.name << "さんは" << tail
  erb :'/player/bitted'
end

get '/player/select/see/' do
    @subtitle = "預言者が見る人を選択"
    @seer = Player.where(:role => RoleID::SEER)[0]
    if (@seer == nil)
      redirect to('/chair/show/result/night/')
    end
    @players = Player.where(:is_dead => false)
    erb :'/player/see'
end

post '/player/see/' do
  logger.info "userid to see : " << params[:seen]
  seen = Player.find_by(:id => params[:seen])
  logger.info seen
  session[:saw_tonight] = seen
  tail = seen.role == RoleID::WEREWOLF ? "です" : "ではありません"
  @result = seen.name << "さんは人狼" << tail

  erb :'/player/seen'
end

get '/chair/show/result/night/' do
  @subtitle = "判定結果"
  @result = judge()

  if (@result[:Code] == GameReault::CONTINUE[:Code])
    redirect to('/chair/start/daytime/')
  else
    @subtitle = "判定結果"
    @players = Player.all()
    erb :'/common/finish'
  end
end

def judge()
  wolves = Player.where(:is_dead => false, :role => RoleID::WEREWOLF)
  players = Player.where(:is_dead => false)

  if wolves.length == 0
      return GameReault::VILLAGER_WON
  elsif players.length - wolves.length <= wolves.length
      return GameReault::WEREWOLF_WON
  else
      return GameReault::CONTINUE
  end
end
