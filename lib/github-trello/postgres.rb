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
      @conn.exec("INSERT INTO usernames VALUES (\'"+username.to_s+"\',\'"+oauth_token.to_s+"\', \'"+api_key.to_s+"\');")
    end

    def addRepo(repo, board_id, on_doing, on_review, on_done)
      @conn.exec("INSERT INTO repos VALUES (\'"+repo.to_s+"\',\'"+board_id.to_s+"\', \'"+on_doing.to_s+"\', \'"+on_review.to_s+"\', \'"+on_done.to_s+"\');")
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
  end
end