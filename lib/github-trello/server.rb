require "json"
require "sinatra/base"
require "github-trello/version"
require "github-trello/postgres"
require "github-trello/http"
require "yaml"


module GithubTrello
  class Server < Sinatra::Base
    post "/posthook" do

      #connect to database  
      pg = GithubTrello::Postgres.new
      pg.connect

      #load data from payload
      payload = JSON.parse(params[:payload])
      committer = payload["head_commit"]["committer"]["username"]
      repo = payload["repository"]["name"]
      unless pg.userTable[committer] 
        puts "[ERROR] Github username not recognized. Run rake add_user"
        return
      end
      unless pg.repoTable[repo] 
        puts "[ERROR] Github repo not recognized. Run rake add_repo"
        return
      end
      branch = payload["ref"].gsub("refs/heads/", "")

      #load board_id from the database
      board_id = pg.repoTable[repo]["board_id"] 
      unless board_id
        puts "[ERROR] Commit from #{payload["repository"]["name"]} but no board_id entry found in config. Run rake update_repo"
        return
      end

      #connect to Trello's server
      http = GithubTrello::HTTP.new(pg.userTable[committer]["oauth_token"], pg.userTable[committer]["api_key"])

      #search each commit from the payload for a flag to make a comment on a Trello card
      commits = payload["commits"].each do |commit|
        match = commit["message"].match(/((card|doing|review|done|archive)e?s? \D?([0-9]+))/i)
        next unless match and match[3].to_i > 0
        results = http.get_card(board_id, match[3].to_i)
        unless results
          puts "[ERROR] Cannot find card matching ID #{match[3]}"
          next
        end
        results = JSON.parse(results)

        # Add the commit comment
        message = "#{commit["message"]}\n\n[#{branch}] #{commit["url"]}"
        message.gsub!(match[1], "")
        message.gsub!(/\(\)$/, "")

        http.add_comment(results["id"], message)

        #move card if doing, review, done, or archive was flagged in commit message
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

          #only move card if destination is not equal to origin
          unless results["idList"] == move_to
            to_update[:idList] = move_to
          end

          #move card
          unless to_update.empty?
             http.update_card(results["id"], to_update)
          end
        end

       end

      "" #line needed so that sinatra can return a string
    end

    get '/' do
      ""
    end

  end
end