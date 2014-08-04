require "bundler"
Bundler.setup

require "rake"
require "rspec"
require "rspec/core/rake_task"
require "yaml"

RSpec::Core::RakeTask.new("spec") do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

def check_file (file, string)
	File.open( file ) do |io|
		io.each { |line| line.chomp! ; return true if line.include? string}
	end
	false
end

def prompt_edit(key_type, key_name, yml_file)
	if key_type == "users"
		then array = ["oauth_token", "api_key"]
		elsif key_type == "repos"
		then array = ["board_id", "on_doing", "on_review", "on_done"]
		else print "Error: key_type not recognized" 
	end

	begin 
		puts "Please enter an integer value corresponding to the field you would like to edit, or 0 to cancel:"
		puts "0) Cancel"
		array.each_with_index do |k, i|
			puts (i + 1).to_s+") "+k.to_s+": "+yml_file[key_type][key_name][k].to_s
		end
		puts "Which field would you like to edit? (eg. 1) \n"
		field_no = STDIN.gets.strip
	end while field_no.to_i < 0 || field_no.to_i > array.size + 1

	unless field_no == "0"
		field = array.at(field_no.to_i - 1)
		edit_field(key_type, key_name, field, yml_file)
	end

	puts "Canceled"
end

def edit_field(key_type, key_name, field_name, yml_file)
		print "Please enter a new "+ field_name + ": "
		ot = STDIN.gets.strip
		print "Press y to save or any other key to cancel: "
		if STDIN.gets.strip == "y" 
		then 
			yml_file[key_type][key_name][field_name] = ot
			File.open('conf.yml', 'w') { |f| YAML.dump(yml_file, f)}
			print "To make any further edits, press y, to cancel press any other key: "
			if STDIN.gets.strip == "y" 
			then prompt_edit(key_type, key_name, yml_file)
			else end
		else end
end

task :default => :spec

task :user?, :username do |t, args|
	yml_file = YAML.load_file('conf.yml')
	username = args[:username]
	if yml_file["users"][username]
		puts true
	else puts false
	end
end

task :repo?, :repo do |t, args|
	yml_file = YAML.load_file('conf.yml')
	repo = args[:repo]
	if yml_file["repos"][repo]
		puts true
	else puts false
	end
end

task :add_user do
	STDOUT.puts "What is your github username?"
	username = STDIN.gets.strip
	yml_file = YAML.load_file('conf.yml') 
	if yml_file["users"][username]
		STDOUT.puts "This username exists in the configuration file. Press 'y' to edit the username, or any other key to cancel"
		edit = STDIN.gets.strip
		if edit == 'y' then puts "I need to run a rake task" else end
	else 
		STDOUT.puts "Your username will be added to the configuration file. Press 'y' to continue, or any other key to exit"
		continue = STDIN.gets.strip
		if continue == 'y' 
			then puts "First, input your key. To find this, go to https://trello.com/1/appKey/generate"
				key = STDIN.gets.strip
				puts "\nNow, input your token. This can be found at: https://trello.com/1/authorize?response_type=token&name=Trello+Github+Integration&scope=read,write&expiration=never&key="+key
				token = STDIN.gets.strip
				puts "Thank you for your cooperation. Your input values appear below - please review them"
				puts "username: "+username+"\n"+ 
				"key: "+key+"\n"+
				"token: "+token
				print "To save, press \'y\', to exit, press any other key." 
				save = STDIN.gets.strip
				if save == "y" then 
					yml_file["users"][username] = {"oauth_token" => token, "api_key" => key}
					File.open('conf.yml', 'w') { |f| YAML.dump(yml_file, f)}
					puts "Saved"
				else end
			else
		end
	end
end

task :add_repo do
	STDOUT.puts "Which github repository would you like to integrate? (eg. bfa_oms) "
	repo = STDIN.gets.strip
	yml_file = YAML.load_file('conf.yml')
	if yml_file["repos"][repo]
		STDOUT.print "This repo exists in the configuration file. Press 'y' to edit the repo, or any other key to exit: "
		edit = STDIN.gets.strip
		if edit == 'y' then puts "I need to run a rake task" else end
	else 
		STDOUT.print "This repo will be added to the configuration file. Continue (y) or exit (any other key): "
		continue = STDIN.gets.strip
		if continue == 'y' 
			then puts "First, please supply the trello board-id where you would like your commit messages to appear. This can be found by clickling on a card in the board, finding the \'share and more\' link on the bottom right, and exporting the JSON. In the JSON output, find a field called idBoard. This is your input value."
				board = STDIN.gets.strip
				puts "\nNow, follow the same method within specific lists on your trello board to provide the list ids which correspond to the locations where you would like cards to be placed while in progress (Doing), ready for review (Review), or finished (Done)."
				print "Doing: "
				doing = STDIN.gets.strip
				print "Review: "
				review = STDIN.gets.strip
				print "Done: "
				done = STDIN.gets.strip
				puts "Thank you for your cooperation. Your input values appear below - please review them"
				puts 
				"repository name: "+repo+"\n"+
				"board id: "+board+"\n"+
				"doing list id: "+doing+"\n"+
				"review list id: "+review+"\n"+
				"done list id: "+done
				print "To save, press \'y\', to exit, press any other key." 
				save = STDIN.gets.strip
				if save == "y" then 
					yml_file["repos"][repo] = { "board_id" => board, 
						"on_doing" => {"move_to" => doing, "archive" => true},
						"on_review" => {"move_to" => review, "archive" => true},
						"on_done" => {"move_to" => done, "archive" => true}
						}
					File.open('conf.yml', 'w') { |f| YAML.dump(yml_file, f)}
					puts "Saved"
				else end
			else
		end
	end
end

task :edit_user do
	STDOUT.puts "Which user would you like to edit?"
	username = STDIN.gets.strip
	yml_file = YAML.load_file('conf.yml')

	if yml_file["users"][username]
		#display variables associated with user
		prompt_edit("users", username, yml_file)	
	else 
		puts "This username does not exist. To create it, run rake add_user."
	end
end

task :edit_repo do
	STDOUT.puts "Which repo would you like to edit?"
	repo = STDIN.gets.strip
	yml_file = YAML.load_file('conf.yml')

	#check if the user exists
	if yml_file["repos"][repo]
		#display variables associated with user
		prompt_edit("repos", repo, yml_file)
	else
		puts "This repo does not exist. To create it, run rake add_repo."
	end
end

