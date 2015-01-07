require "bundler"
Bundler.setup

require "rake"
require "rspec"
require "rspec/core/rake_task"
require "yaml"
require "github-trello/postgres"

RSpec::Core::RakeTask.new("spec") do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

def connect
	@pg = GithubTrello::Postgres.new
	@pg.connect
end

def check_file (file, string)
	File.open( file ) do |io|
		io.each { |line| line.chomp! ; return true if line.include? string}
	end
	false
end

def prompt_edit(key_type, key_name)
	if key_type == "username"
		then array = ["oauth_token", "api_key"]
		elsif key_type == "repo"
		then array = ["board_id", "on_doing", "on_review", "on_done"]
		else print "Error: key_type not recognized" 
	end

	begin 
		puts "Please enter an integer value corresponding to the field you would like to edit, or 0 to cancel:"
		puts "0) Cancel"
		# if key_type == "users" then 
			display(key_type, key_name)
		# array.each_with_index do |k, i|
		# 	puts (i + 1).to_s+") "+k.to_s+": "+@pg.userTable[key_name][k].to_s
		# end
		puts "Which field would you like to edit? (eg. 1) \n"
		field_no = STDIN.gets.strip
	end while (field_no.to_i < 0 || field_no.to_i > array.size)

	unless field_no == "0"
		field = array.at(field_no.to_i - 1)
		edit_field(key_type, key_name, field)
	end

	puts "Canceled"
end

def edit_field(key_type, key_name, field_name)
		print "Please enter a new "+ field_name + " value: "
		ot = STDIN.gets.strip
		print "Press y to save or any other key to cancel: "
		if STDIN.gets.strip == "y" 
		then 
			@pg.update(key_type, key_name, field_name, ot)
			print "To make any further edits, press y, to cancel press any other key: "
			if STDIN.gets.strip == "y" 
			then prompt_edit(key_type, key_name)
			else end
		else end
end

def display(key_type, key_name)
	if key_type == "username"
		then array = ["oauth_token", "api_key"]
			array.each_with_index do |k, i|
				puts (i + 1).to_s+") "+k.to_s+": "+@pg.userTable[key_name][k].to_s
			end
		elsif key_type == "repo"
		then array = ["board_id", "on_doing", "on_review", "on_done"]
			array.each_with_index do |k, i| 
			puts (i + 1).to_s+") "+k.to_s+": "+@pg.repoTable[key_name][k].to_s
			end
		else print "Error: key_type not recognized" 
	end
end



task :default => :spec

task :void do
end

task :list_users do
	connect
	@pg.userTable.each do |k, v|
		puts k
	end
end

task :list_repos do
	connect
	@pg.repoTable.each do |k, v|
		puts k
	end
end

task :show_user, :username do |t, args|
	connect
	username = args[:username]
	if @pg.userTable[username]
		display("username", username)
	else puts "The user does not exist in the configuration file. To add it, run: \n  heroku run rake add_user --app trello-github-integrate "
	end
end

task :show_repo, :repo do |t, args|
	connect
	repo = args[:repo]
	if @pg.repoTable[repo]
		display("repo", repo)
	else puts "This repo does not exist in the configuration file. To add it, run: \n  heroku run rake add_repo --app trello-github-integrate"
	end
end

task :add_user do
	connect
	STDOUT.puts "\nWhat is your github username?"
	username = STDIN.gets.strip
	if @pg.userTable[username]
		puts "\nThis username exists in the configuration file. To edit it, run: \n  heroku run rake edit_user --app trello-github-integrate"
	else 
		STDOUT.puts "Your username will be added to the configuration file. Press 'y' to continue, or any other key to exit"
		continue = STDIN.gets.strip
		if continue == 'y' 
			then puts "\nNext, input your key. To find this, go to https://trello.com/1/appKey/generate"
				key = STDIN.gets.strip
				puts "\nNow, input your token. This can be found at: https://trello.com/1/authorize?response_type=token&name=Trello+Github+Integration&scope=read,write&expiration=never&key="+key
				token = STDIN.gets.strip
				puts "\nThanks! Please review your input values:"
				puts "username: "+username+"\n"+ 
				"key: "+key+"\n"+
				"token: "+token
				print "To save, press \'y\', to exit, press any other key." 
				save = STDIN.gets.strip
				if save == "y" then 
					@pg.addUser(username, token, key)
					puts "Saved"
				else end
			else
		end
	end
end

task :add_repo do
	connect
	STDOUT.puts "Which github repository would you like to integrate? (eg. bfa_oms) "
	repo = STDIN.gets.strip
	if @pg.repoTable[repo]
		puts "\nThis repository exists in the configuration file. To edit it, run: \n  heroku run rake edit_repo --app trello-github-integrate"
	else 
		STDOUT.print "\nThis repo will be added to the configuration file. Continue (y) or exit (any other key): "
		continue = STDIN.gets.strip
		if continue == 'y' 
			then puts "\nFirst, please supply the trello board-id where you would like your commit messages to appear. This can be found by clickling on a card in the board, finding the \'share and more\' link on the bottom right, and exporting the JSON. In the JSON output, find a field called idBoard. This is your input value.\nboard-id: "
				board = STDIN.gets.strip
				puts "\nNow, follow the same method within specific lists on your trello board to provide the list ids which correspond to the locations where you would like cards to be placed while in progress (Doing), ready for review (Review), or finished (Done)."
				print "Doing: "
				doing = STDIN.gets.strip
				print "Review: "
				review = STDIN.gets.strip
				print "Done: "
				done = STDIN.gets.strip
				puts "\nThank you for your cooperation. Please review your input values"
				puts 
				"repository name: "+repo+"\n"+
				"board id: "+board+"\n"+
				"doing list id: "+doing+"\n"+
				"review list id: "+review+"\n"+
				"done list id: "+done
				print "To save, press \'y\', to exit, press any other key." 
				save = STDIN.gets.strip
				if save == "y" then 
					@pg.addRepo(repo, board, doing, review, done)
					puts "Saved"
				else end
			else
		end
	end
end

task :edit_user do
	connect 
	STDOUT.puts "Which user would you like to edit?"
	username = STDIN.gets.strip
	if @pg.userTable[username]
		prompt_edit("username", username)	
	else 
		puts "\nThis username does not exist. To create it, run rake add_user."
	end
end

task :edit_repo do
	connect
	STDOUT.puts "Which repo would you like to edit?"
	repo = STDIN.gets.strip
	if @pg.repoTable[repo]
		prompt_edit("repo", repo)
	else
		puts "\nThis repo does not exist. To create it, run rake add_repo."
	end
end

task :delete_repo do
	connect
	STDOUT.puts "Which repo would you like to delete?"
	repo = STDIN.gets.strip
	print "\nAre you sure you want to delete the repository information for " +repo+"? If so, press 'y'. To cancel, press any other key: "
	response = STDIN.gets.strip
	if response == "y" 
	then 
		@pg.deleteRepo(repo)
		puts "Repo deleted"
	else end 
end

task :delete_user do
	connect
	STDOUT.puts "Which user would you like to delete?"
	user = STDIN.gets.strip
	print "\nAre you sure you want to delete the user information for " +user+"? If so, press 'y'. To cancel, press any other key: "
	response = STDIN.gets.strip
	if response == "y" 
	then 
		@pg.deleteUser(user)
		puts "User deleted"
	else end 
end


