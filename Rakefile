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

task :default => :spec

task :add_user do
	STDOUT.puts "What is your github username?"
	username = STDIN.gets.strip
	yaml = YAML.load_stream(File.open('conf.yml'))
	yml_file = YAML.load_file('conf.yml')
	yml_hash = yml_file.inspect
	if yml_hash[username]
		STDOUT.puts "This username exists in the configuration file. Would you like to edit it? (y/n)"
		edit = STDIN.gets.strip
		if edit == 'y' then puts "I need to run a rake task" else end
	else 
		STDOUT.puts "Your username will be added to the configuration file. Would you like to continue? (y/n)"
		continue = STDIN.gets.strip
		if continue == 'y' 
			then puts "First, input your key. To find this, go to https://trello.com/1/appKey/generate"
				key = STDIN.gets.strip
				puts "Now, input your token. This can be found at: https://trello.com/1/authorize?response_type=token&name=Trello+Github+Integration&scope=read,write&expiration=never&key="+key
				token = STDIN.gets.strip
				puts "Now, input the name of the repository you will be pushing from. \n For example, if I am pushing from biblesforamerica/ivr the repository name is ivr"
				repo = STDIN.gets.strip
				puts "Finally, please supply the trello board-id where you would like your commit messages to appear. This can be found by clickling on a card in the board, finding the \'share and more\' link on the bottom right, and exporting the JSON. In the JSON output, find a field called idBoard. This is your input value."
				board = STDIN.gets.strip
				puts "Now, follow the same method within specific lists on your trello board to provide the list ids which correspond to the locations where you would like cards to be placed while in progress (Doing), ready for review (Review), or finished (Done)."
				print "Doing: "
				doing = STDIN.gets.strip
				print "Review: "
				review = STDIN.gets.strip
				print "Done: "
				done = STDIN.gets.strip
				puts "Thank you for your cooperation. Your input values appear below - please review them"
				puts "\nusername: "+username+"\n"+ 
				"key: "+key+"\n"+
				"token: "+token+"\n"+
				"repository name: "+repo+"\n"+
				"board id: "+board+"\n"+
				"Doing list id"+doing+"\n"+
				"Review list id"+review+"\n"+
				"Done list id"+done
				print "To save, press \'y\', to exit, press any other key." 
				save = STDIN.gets.strip
				if save == "y" then 
					yml_file[username] = [{"oauthtoken" => token.to_i, "api_key" => key.to_i, "board_ids" => {repo => board.to_i}, 
						"on_doing" => {"move_to" => doing.to_i, "archive" => true}
						"on_review" => {"move_to" => review.to_i, "archive" => true}
						"on_done" => {"move_to" => done.to_i, "archive" => true}
						}]
					File.open('conf.yml', 'w') { |f| YAML.dump(yml_file, f)}
					puts "Saved"
				else end
			else
		end
	end

end