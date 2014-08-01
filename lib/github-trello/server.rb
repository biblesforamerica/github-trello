require "json"
require "sinatra/base"
require "github-trello/version"
require "github-trello/http"
require "yaml"

module GithubTrello
  class Server < Sinatra::Base
    post "/posthook" do
      config, http = self.class.config, self.class.http

      payload = JSON.parse(params[:payload])
      committer = payload["head_commit"]["committer"]["username"]
      repo = payload["repository"]["name"]
      # path = File.expand_path(File.dirname(_FILE_) + "/../../conf.yaml")
      # y = YAML::load_file(path)
      puts "hello"
      puts repo
      #make sure needed information is present
      unless config["users"][committer]
        puts "[ERROR] Github username not recognized. Run rake add_user"
      end

      unless config["repos"][repo]
        puts "[ERROR] Github repo not recognized. Run rake add_repo"
      end

      #deploy comment! :) 

      board_id = config["repos"][repo]["board_id"]
      puts board_id
      unless board_id
        puts "[ERROR] Commit from #{payload["repository"]["name"]} but no board_id entry found in config. Run rake update_repo"
        return
      end

      branch = payload["ref"].gsub("refs/heads/", "")
      if config["blacklist_branches"] and config["blacklist_branches"].include?(branch)
        return
      elsif config["whitelist_branches"] and !config["whitelist_branches"].include?(branch)
        return
      end

      payload["commits"].each do |commit|
        # Figure out the card short id
        match = commit["message"].match(/((case|card|close|archive|fix)e?s? \D?([0-9]+))/i)
        next unless match and match[3].to_i > 0

        results = http.get_card(board_id, match[3].to_i)
        unless results
          puts "[ERROR] Cannot find card matching ID #{match[3]}"
          next
        end

        results = JSON.parse(results)

        # Add the commit comment
        message = "#{commit["message"]}\n\n[#{branch}] #{commit["url"]}"
        # message = "hello"
        message.gsub!(match[1], "")
        message.gsub!(/\(\)$/, "")

        http.add_comment(results["id"], message)

        # Determine the action to take
        update_config = case match[2].downcase
          when "doing" then config["repos"][repo]["on_doing"]
          when "review" then config["repos"][repo]["on_review"]
          when "done" then config["repos"][repo]["on_done"]
          when "archive" then {:archive => true}
        end

        next 

        puts update_config

        # next unless update_config.is_a?(Hash)

         # Modify it if needed
         to_update = {}
         move_to = update_config["move_to"]

        # # if update_config["move_to"].is_a?(Hash)
        # #   move_to = update_config["move_to"][payload["repository"]["name"]]
        # # else
        # #   move_to = update_config["move_to"]
        # # end

        unless results["idList"] == move_to
          to_update[:idList] = move_to
        end

        if !results["closed"] and update_config["archive"]
          to_update[:closed] = true
        end

        unless to_update.empty?
          http.update_card(results["id"], to_update)
        end
      end

      ""
    end

   # post "/deployed/:repo" do
    #   config, http = self.class.config, self.class.http
    #   if !config["on_deploy"]
    #     raise "Deploy triggered without a on_deploy config specified"
    #   elsif !config["on_close"] or !config["on_close"]["move_to"]
    #     raise "Deploy triggered and either on_close config missed or move_to is not set"
    #   end

    #   update_config = config["on_deploy"]

    #   to_update = {}
    #   if update_config["move_to"] and update_config["move_to"][params[:repo]]
    #     to_update[:idList] = update_config["move_to"][params[:repo]]
    #   end

    #   if update_config["archive"]
    #     to_update[:closed] = true
    #   end

    #   if config["on_close"]["move_to"].is_a?(Hash)
    #     target_board = config["on_close"]["move_to"][params[:repo]]
    #   else
    #     target_board = config["on_close"]["move_to"]
    #   end

    #   cards = JSON.parse(http.get_cards(target_board))
    #   cards.each do |card|
    #     http.update_card(card["id"], to_update)
    #   end

    #   ""
   #end

    # get "/" do
    #   ""
    # end

  
    def self.config=(config)
      @config = config
      @http = GithubTrello::HTTP.new(config["users"]["burricks"]["oauth_token"], config["users"]["burricks"]["api_key"])
    end

    def self.config; @config end
    def self.http; @http end
  end
end