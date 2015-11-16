require './const.rb'
require 'active_record'

module RoleID
	VILLAGER = 1
	WEREWOLF = 2
	BODYGUARD = 3
	SEER = 4

	ROLE_NAME = {
		RoleID::VILLAGER => '村人',
		RoleID::WEREWOLF => '人狼',
		RoleID::BODYGUARD => 'ボディガード',
		RoleID::SEER => '預言者'
	}

	def self.all
		self.constants.map { |name| self.const_get(name) }
	end
end

class PlayerFactory

	def create(id, name, role)

		p ("role is : " + role.to_s)
		player = nil
		case role
		when RoleID::WEREWOLF
			player =  Werewolf.new
		when RoleID::BODYGUARD
			player = Bodyguard.new
		when RoleID::SEER
			player = Seer.new
		else
			player = Player.new
		end

		player.user_id = id
		player.name = name
		player.role = role
		player.votes_count = 0
		player.is_dead = false
		player.is_saved = false
		p player
		return player
	end
end

class Player < ActiveRecord::Base

	def action(selected_player)
	end

	def vote(selected_player)
		selected_player.votes_count += 1
	end
end

class Werewolf < Player
	def action(selected_player)
		if selected_player.is_saved
			p sprintf("%s はボディガードに守られました", selected_player.name)
			return
		elsif selected_player.role == RoleID::WEREWOLF
			p "人狼の同士討ちはできません"
			return
		else
			selected_player.is_dead = 1
		end
	end
end

class Bodyguard < Player
	def action(selected_player)
		selected_player.is_saved = true
	end
end

class Seer < Player
	def action(selected_player)
		if selected_player.role == RoleID::WEREWOLF
			p sprintf("%s は 人狼 です", selected_player.name)
		else
			p sprintf("%s は 村人 です", selected_player.name)
		end
	end
end
