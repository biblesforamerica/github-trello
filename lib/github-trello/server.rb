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
      unless config["users"][committer]
        puts "[ERROR] Github username not recognized. Run rake add_user"
      end

      unless config["repos"][repo]
        puts "[ERROR] Github repo not recognized. Run rake add_repo"
      end

      #deploy comment

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

         # Modify it if needed
         to_update = {}
         move_to = update_config["move_to"]

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

    def self.config=(config)
      @config = config
      @http = GithubTrello::HTTP.new(config["users"]["burricks"]["oauth_token"], config["users"]["burricks"]["api_key"])
    end

    def self.config; @config end
    def self.http; @http end
  end
end