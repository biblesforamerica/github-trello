require "json"
require "sinatra/base"
require "github-trello/version"
require "github-trello/http"
require "yaml"
require "pg"

module GithubTrello
  class Postgres

  # CONNECT
  def connect
    @conn = PG.connect(
        :dbname => 'daoej6cm9u6nbj',
        :user => 'bdttiqmmgykpvt',
        :password => 'hxdYT4VWTXSzEpeUUYER2ZAJy8',
        :host => 'ec2-54-225-101-124.compute-1.amazonaws.com',
        :port => 5432)
  end

  ## CREATE
  def addUser(username, oauth_token, api_key)
    @conn.exec("INSERT INTO usernames VALUES (\'"+username.to_s+"\',"+oauth_token.to_s+", "+api_key.to_s+");")
  end

  def addRepo(repo, board_id, on_doing, on_review, on_done)
    @conn.exec("INSERT INTO repos VALUES (\'"+repo.to_s+"\',"+board_id.to_s+", "+on_doing.to_s+", "+on_review.to_s+", "+on_done.to_s+");")
  end

  ## READ
  def userTable
    @conn.exec("SELECT * FROM usernames") do |result|
      hash = {}
      result.each do |row|
        user = row["username"]
        hash[user] = {"oauth_token" => row["oauth_token"], "api_key" => row["api_key"]}
      end
      return hash
    end 
  end

  def repoTable
    @conn.exec("SELECT * FROM repos") do |result|
      hash = {}
      result.each do |row|
        repo = row["repo"]
        hash[repo] = {"board_id" => row["board_id"], "on_doing" => row["on_doing"], "on_review" => row["on_review"], "on_done" => row["on_done"]}
      end
      return hash
    end 
  end

  ## UPDATE

  def update(table, row, column, value)
    @conn.exec("UPDATE "+table.to_s+"s SET "+column.to_s+" = "+value.to_s+" WHERE "+table+" = \'"+row.to_s+"\';")
  end

  def updateUser(row, column, value)
    update("username", row, column, value)
  end

  def updateRepo(row, column, value)
    update("repo", row, column, value)
  end

  ##DELETE

  def delete(table, row)
    @conn.exec("DELETE FROM "+table+"s WHERE "+table+" = \'"+row+"\'")
  end

  def deleteRepo(row)
    delete("repo", row)
  end

  def deleteUser(row)
    delete("username", row)
  end


  # Prepared statements prevent SQL injection attacks.  However, for the connection, the prepared statements
  # live and apparently cannot be removed, at least not very easily.  There is apparently a significant
  # performance improvement using prepared statements.
  # def prepareInsertUserStatement
  #   @conn.prepare("insert_user", "insert into users (name, oauth_token, api_key) values ($1, $2, $3)")
  # end

  # # Add a user with the prepared statement.
  # def addUser(name, oauth_token, api_key)
  #   @conn.exec_prepared("insert_user", [name, oauth_token, api_key])
  # end

  

  # def prepareInsertRepoStatement
  #   @conn.prepare("insert_repo", "insert into repos (repo, board_id, on_doing, on_review, on_done) values ($1, $2, $3, $4, $5")
  # end

  # def addRepo(repo, board_id, on_doing, on_review, on_done)
  #   @conn.exec_prepared("insert_repo", [repo, board_id, on_doing, on_review, on_done])
  # end

  

  # Get our data back
#   def queryUserTable(varname)
#     @conn.exec( "SELECT * FROM users" ) do |result|
#       result.each do |row|
#         puts row
#         varname = row
#         yield row if block_given?
#       end
#     end
#   end
# end

  class Server < Sinatra::Base
    post "/posthook" do
      conn = PGconn.open(:dbname => )
      payload = JSON.parse(params[:payload])
      committer = payload["head_commit"]["committer"]["username"]
      path = File.expand_path(File.dirname(__FILE__) + "/../../conf.yml")
      config = YAML::load(File.read(path))
      repo = payload["repository"]["name"]
      unless config["users"][committer]
        puts "[ERROR] Github username not recognized. Run rake add_user"
      end

      unless config["repos"][repo]
        puts "[ERROR] Github repo not recognized. Run rake add_repo"
      end

      #deploy comment

      board_id = config["repos"][repo]["board_id"]
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

      http = GithubTrello::HTTP.new(config["users"][committer]["oauth_token"], config["users"][committer]["api_key"])

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
            when "doing" then config["repos"][repo]["on_doing"]
            when "review" then config["repos"][repo]["on_review"]
            when "done" then config["repos"][repo]["on_done"]
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
      path = File.expand_path(File.dirname(__FILE__) + "/../../conf.yml")
      config = YAML::load(File.read(path)).inspect
      # hi = YAML.load_file('/../../conf.yml')
      # hello = YAML.load_file('/../../conf.yml').inspect
      # puts "hi "+hi
      # puts "hello: "+hello
      puts config
      "hello"
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