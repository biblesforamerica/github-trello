The code in this repository is deployed on *heroku* as an app named **trello-github-integrate**. It allows users to integrate *trello* and *github* in such a way that commit messages pushed to *github* with certain flags will add comments to associated cards in *trello boards*. Configuration for each user and repository is stored on a database with a suite of rake commands which allow information in the database to be easily created, read, updated, or destroyed. 

## Set Up
### Add a user
  
As a first time user, to add your information to the database, run:
  
```
heroku run rake add_user --app trello-github-integrate
```

You will be asked to input your github **username**, your **oauth_token**, and your **api_key**. The task will provide help in obtaining your trello token and key. **Ensure that you input your github username, not your trello username.**

### Add a repo
  
If you want to integrate a brand new github repository, run:

```
heroku run rake add_repo --app trello-github-integrate
```

You will be asked to provide the **board_id** for the *trello* board you intend to integrate. Next, you will be asked to provide *list_id*'s for three different lists associated with the commands "doing", "review", and "done". If you choose not to provide a list for a specific action, simply input 'none'. See below for more information about what these list_id's will be used for. As before, the rake task should provide ample information to help you find the needed id's. 

### Establish the webhook
The final step needed before your new repository is fully integrated, is to set up the webhook pointing to the application on *github*. 
* In your browser, go to *github.com* and find the pertinent repository. Once the repository is opened, you should see a list of icons on the right of the screen 
* Click on *Settings*, and then *Webhooks & Services*. **Note: Settings will only be visible if you have admin rights to the repository.** Click *Add Webhook*, and in the *Payload URL* field, input **http://trello-github-integrate.herokuapp.com/posthook** 
* Next, ensure that *Content Type* is set to **application/x-www-form-urlencoded** 
* Input a *Secret* of your choice 
* Submit by clicking **Add Webhook** at the bottom of the form
Your webhook is now set up. Anytime this repository is pushed to, a payload will be sent to http://trello-github-integrate.herokuapp.com/posthook.

## How to use trello-github-integrate
If your github username and the repository you are pushing to are both saved in the database, you are ready to begin writing commit messages that will appear as comments on cards in a Trello board. 

### Find Trello Card ID
First, discover the number of the card on which you want your commit message to appear. Locate the card on the Trello board and select it. On the bottom right, click on a link that says **share and more**. You should see a Card number listed, ex: Card#27. 

### Commit messages
Now, you can add flags to your commit messages to produce the desired result.
* `git commit -m "card 27 added helper"` - Adds the comment "added helper" to card#27 
* `git commit -m "doing 27 initial commit"` - Moves card#27 from whichever list in was in to the list whose id was provided as "Doing" in the rake task add_repo. Also adds the comment "initial commit" to card#27 
* `git commit -m "review 27 all tests passing"` - Comments and moves card#27 to the 'Review' list
* `git commit -m "done 27 ready to deploy"` - Comments and moves card#27 to the 'Done' list 
* `git commit -m "archive 27"` - Archives card#27

##Available rake tasks
To run any task, run `heroku run rake TASK_NAME --app trello-github-integrate`
* `rake add_user`
* `rake add_repo`
* `rake show_user[USERNAME]`
* `rake show_repo[REPONAME]`
* `rake list_users`
* `rake list_repos`
* `rake edit_user`
* `rake edit_repo`
* `rake delete_user`
* `rake delete_repo`
