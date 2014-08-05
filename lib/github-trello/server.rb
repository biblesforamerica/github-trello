require "json"
require "sinatra/base"
require "github-trello/version"
require "github-trello/postgres"
require "github-trello/http"
require "yaml"


module GithubTrello
  class Server < Sinatra::Base
    post "/posthook" do
      #connect to database toggled comment for testing
      pg = GithubTrello::Postgres.new
      pg.connect
      payload = JSON.parse(params[:payload])
      committer = payload["head_commit"]["committer"]["username"]
      path = File.expand_path(File.dirname(__FILE__) + "/../../conf.yml")
      #config = YAML::load(File.read(path))
      repo = payload["repository"]["name"]
      unless pg.userTable[committer] #unless config["users"][committer]
        puts "[ERROR] Github username not recognized. Run rake add_user"
      end

      unless pg.repoTable[repo] #unless config["repos"][repo]
        puts "[ERROR] Github repo not recognized. Run rake add_repo"
      end

      #deploy comment

      board_id = pg.repoTable[repo]["board_id"] #config["repos"][repo]["board_id"]
      unless board_id
        puts "[ERROR] Commit from #{payload["repository"]["name"]} but no board_id entry found in config. Run rake update_repo"
        return
      end

      branch = payload["ref"].gsub("refs/heads/", "")
      # if config["blacklist_branches"] and config["blacklist_branches"].include?(branch)
      #   return
      # elsif config["whitelist_branches"] and !config["whitelist_branches"].include?(branch)
      #   return
      # end

      # http = GithubTrello::HTTP.new(config["users"][committer]["oauth_token"], config["users"][committer]["api_key"])

      http = GithubTrello::HTTP.new(pg.userTable[committer]["oauth_token"], pg.userTable[committer]["api_key"])

      payload["commits"].each do |commit|
        # Figure out the card short id
        match = commit["message"].match(/((doing|review|done|archive)e?s? \D?([0-9]+))/i)
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

        if match[2].downcase == "archive"
          then to_update = {:closed => true}
        else
          to_update = {}
          # Determine the action to take
          move_to = case match[2].downcase
            when "doing" then pg.repoTable[repo]["on_doing"] #config["repos"][repo]["on_doing"]
            when "review" then pg.repoTable[repo]["on_review"] #config["repos"][repo]["on_review"]
            when "done" then pg.repoTable[repo]["on_done"] #config["repos"][repo]["on_done"]
          end

           #move_to = update_config["move_to"]

          unless results["idList"] == move_to
            to_update[:idList] = move_to
          end
        end

        unless to_update.empty?
          http.update_card(results["id"], to_update)
        end
      end

      ""
     end

    get '/' do
      pg = GithubTrello::Postgres.new
      pg.connect
      pg.userTable.inspect
    end

    post '/' do
      payload = JSON.parse(params[:payload])
      puts payload
    end

    def self.config=(config)
      @config = config
    end

    def self.config; @config end
  end
end