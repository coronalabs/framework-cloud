# Corona Cloud Core Documentation

## Overview

Welcome to the core LUA library, a wrapper for all the available APIs in the Corona Cloud.

This is a new, improved version of the existing library. The main differences are:

* replacing the Runtime listeners with listeners being passed to objects upon init
* namespaces and object for each of the relevant aspects of a cloud application lifecycle.


## Cloud objects

The main cloud object is responsible for initialisation, authentication and deallocation, as well as some lifecycle-related methods.

The leaderboards object is responsible for all the leaderboards-related operations.

The achievements object is responsible for all the achievements-related operations.

The analytics object takes care of submitting analytics events.

The chatRoom object creates and manages chat communication.

The friends object takes care of all the friend-related operations.

The news object is responsible for fetching news items.

The multiplayer object does handle all the pre-match operations. For match-related operations, 

The match object will take care of managing flow while a game is active.

## The main cloud object

To start, we will first require the library:

```
local cloud = require ( "cloud" )
```

also, we will require json, because all the responses are raw, so we will have to decode them using json.decode:

````
local json = require( "json" )
````

if you want to see the request responses and various debug information in the console, set the instance variable cloud.debugEnabled to true:

````
-- set the debugEnabled variable
cloud.debugEnabled = true
````

when calling the init method of the library, you pass in the listener you want to use for all the authentication-related events:

````
-- init the main cloud object
cloud.init( "YOUR_ACCESS_KEY", "YOUR_SECRET_KEY", authListener )
````

where authListener is a function you declared earlier in your code. An example would be:

````
-- the authentication listener
local authListener = function( event )
        -- all events contain event.name, event.type, event.error, event.response.
        if event.type == "loggedIn" then
                --print( "User is logged in: ", cloud.isLoggedIn )
                -- get the user profile
                cloud.getProfile()
                -- get the chatrooms
                chatRoom.getAll()
                -- get all friends
                friends.getAll()
                -- get all news
                news.getAll()
                -- get the matches
                multiplayer.getAllMatches()
                --multiplayer.newMatch()
                multiplayer.findMatch( "516192d40fe8298269000006" )
        end
        
        if event.type == "getProfile" then
                --print( "The user profile: ", event.response )
        end

end
````

### Main cloud object methods, and the event they pass to the listener

#### cloud.login( params )

Logs an user in the cloud. params is a table containing the following records:

- params.type (String, possible values: user, facebook or session)
- params.email and params.password (String, relevant only when params.type is equal to "user")
- params.facebookId (String, relevant only when params.type is equal to "facebook", contains the user Facebook ID)
- params.accessToken (String, relevant only when params.type is equal to "facebook", contains the user's Facebook access token)
- params.authToken(String, relevant only when the params.type is equal to "session", contains the authToken obtained after authenticating with the Corona Cloud) 

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "loggedIn" for user authentication
- event.type: "facebookLoggedIn" for Facebook authentication
- event.type: "sessionLoggedIn" for session authentication (auth-token based)
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### cloud.getAuthToken()

Returns the current authToken. Can be saved locally and used for future calls.

##### <i>Event passed to the authListener:</i>

None.

#### cloud.getProfile( [userId] )

Returns the profile of an user. If the userId (String) parameter is omitted, then the currently logged in user's profile is returned, otherwise the user's corresponding to the userId parameter passed in.

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "getProfile" when retrieving the user's own profile
- event.type: "getUserProfile" when retrieving some other user's profile
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### cloud.updateProfile( params )

Updates the profile of an user with the values specified in the params table:

- params.displayName - (String), the user's email address (username)
- params.firstName - (String), the user's first name
- params.lastName - (String), the user's last name
- params.password - (String), the user's password
- params.profilePicture- (String), the user's profile picture
- params.facebookId - (String), the user's Facebook user id
- params.facebookEnabled - (String), is the user's Facebook account connection enabled
- params.facebookAccessToken - (String), the Facebook access token of the user
- params.twitterEnabled - (String), is the user's Twitter account connection enabled
- params.twitterEnabledToken - (String), the Twitter access token of the user

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "updateProfile"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### cloud.registerDevice( deviceToken )

Registers the device with the Corona Cloud for receiving push notifications.

deviceToken - (String), the device's token after registering for remote push notifications with Apple.

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "registerDevice"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### cloud.register( params )

Creates an user account with the values specified in the params table:

- params.displayName - (String), the user's username
- params.firstName - (String), the user's first name
- params.lastName - (String), the user's last name
- params.password - (String), the user's password
- params.email - (String), the user's email

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "registerUser"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### cloud.recoverPassword( email )

Sends a password reset link to the email address specified

email - (String) the email where the link should be sent

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "recoverPassword"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### cloud.getInfo()

Gets information about the current game from the Cloud API.

##### <i>Event passed to the authListener:</i>

- event.name: "authentication"
- event.type: "getInfo"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### Instance variables of the main cloud object

#### cloud.isLoggedIn

Boolean, is true if the user is logged in

### Leaderboards object methods, and the event they pass to the listener

#### Localising the leaderboards object

````
local leaderboards = cloud.leaderboards
````

#### Assigning a listener to the leaderboards object

````
leaderboards.setListener( leaderboardsListener )
````
where leaderboardsListener is a previously declared function.

#### leaderboards.getAll()

Gets a list of all the leaderboards defined for the game

##### <i>Event passed to the leaderboardsListener:</i>

- event.name: "leaderboards"
- event.type: "getAll"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### leaderboards.getScores( leaderboardId )

Gets a list of the scores for the leaderboard leaderboardId

- leaderboardId - (String) the leaderboard ID to retrieve scores for

##### <i>Event passed to the leaderboardsListener:</i>

- event.name: "leaderboards"
- event.type: "getScores"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### leaderboards.submitHighScore( leaderboardId, score )

Submits the score score to the leaderboard leaderboardId

- leaderboardId - (String) the leaderboard ID to post the score on
- score - (String) the score string, no dots or commas

##### <i>Event passed to the leaderboardsListener:</i>

- event.name: "leaderboards"
- event.type: "submitHighScore"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### Achievement object methods, and the event they pass to the listener

#### Localising the achievement object

````
local achievements = cloud.achievements
````

#### Assigning a listener to the achievements object

````
achievements.setListener( achievementsListener )
````
where achievementsListener is a previously declared function.

#### achievements.getAll()

Gets a list of all the achievements defined for the game

##### <i>Event passed to the achievementsListener:</i>

- event.name: "achievements"
- event.type: "getAll"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### achievements.getDetails( achievementId )

Gets the details of the achievement achievementId

- achievementId - (String) the achievement ID to retrieve details for

##### <i>Event passed to the achievementsListener:</i>

- event.name: "achievements"
- event.type: "getDetails"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### achievements.getUnlocked()

Gets a list of all the unlocked achievements of the game

##### <i>Event passed to the achievementsListener:</i>

- event.name: "achievements"
- event.type: "getUnlocked"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### achievements.unlock( achievementId )

Unlocks the achievement achievementId

- achievementId - (String) the achievement ID to unlock

##### <i>Event passed to the achievementsListener:</i>

- event.name: "achievements"
- event.type: "unlock"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### achievements.update( achievementId, progress )

Updates the completion the achievement achievementId with the percentage progress

- achievementId - (String) the achievement ID to update
- progress - (String) the percentage achieved

##### <i>Event passed to the achievementsListener:</i>

- event.name: "achievements"
- event.type: "update"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### Analytics object methods, and the event they pass to the listener

#### Localising the analytics object

````
local analytics = cloud.analytics
````

#### Assigning a listener to the analytics object

````
analytics.setListener( analyticsListener )
````
where analyticsListener is a previously declared function.

#### analytics.submitEvent( params )

Sends a custom analytics event to the API.

params.event_type - (String) the event type (ex. "session")
params.message - (String) a message for the event (ex. "John logged in")
params.name - (String) the event name (ex. "userLogin")

##### <i>Event passed to the analyticsListener:</i>

- event.name: "analytics"
- event.type: "submitEvent"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### ChatRoom object methods, and the event they pass to the listener

#### Localising the chatRoom object

````
local chatRoom = cloud.chatRoom
````

#### Assigning a listener to the chat object

````
chatRoom.setListener( chatListener )
````
where chatListener is a previously declared function.

#### chatRoom.new( name )

Create a chatroom with the name name.

- name - (String) the name of the chatroom to be created

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "create"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.delete( chatroomId )

Delete the chatroom with the id chatroomId

- chatroomId - (String) the id of the chatroom to be deleted

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "delete"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.sendMessage( chatroomId, message )

Sends the message message to the chatroom with the id chatroomId

- chatroomId - (String) the id of the chatroom to post the message in
- message - (String) the message to be sent

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "sendMessage"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.addUser( userID, chatroomId )

Adds the user with the id userID to the chatroom with the id chatroomId

- chatroomId - (String) the id of the chatroom to add the user to
- userID - (String) the id of the user to be added

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "addUser"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.removeUser( userID, chatroomID )

Deletes the user with the id userID from the chatroom with the id chatroomId

- chatroomId - (String) the id of the chatroom to delete the user from
- userID - (String) the id of the user to be added

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "removeUser"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.getAll()

Get all the existing chatrooms 

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "getAll"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.getHistory( chatroomID )

Retrieves the list of chat messages from the chatroom with the id chatroomID

- chatroomId - (String) the id of the chatroom to get the messages for

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "getHistory"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### chatRoom.getUsers( chatroomID )

Retrieves the list of users present in the chatroom with the id chatroomID

- chatroomId - (String) the id of the chatroom to get the users for

##### <i>Event passed to the chatListener:</i>

- event.name: "chat"
- event.type: "getUsers"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### Friends object methods, and the event they pass to the listener

#### Localising the friends object

````
local friends = cloud.friends
````

#### Assigning a listener to the friends object

````
friends.setListener( friendsListener )
````
where friendsListener is a previously declared function.

#### friends.getAll()

Retrieve all the friends of the currently logged in user.

##### <i>Event passed to the friendsListener:</i>

- event.name: "friends"
- event.type: "getAll"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### friends.add( friendID )

Add the user corresponding to friendID to the friend list.

- friendID - (String) the userID of the user to be added as friend

##### <i>Event passed to the friendsListener:</i>

- event.name: "friends"
- event.type: "add"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### friends.remove( friendID )

Delete the user corresponding to friendID from the friend list.

- friendID - (String) the userID of the user to be deleted from the friends list

##### <i>Event passed to the friendsListener:</i>

- event.name: "friends"
- event.type: "remove"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### friends.find( keyword )

Search for users using the given keyword.

- keyword - (String) the search keyword

##### <i>Event passed to the friendsListener:</i>

- event.name: "friends"
- event.type: "find"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### News object methods, and the event they pass to the listener

#### Localising the news object

````
local news = cloud.news
````

#### Assigning a listener to the news object

````
news.setListener( newsListener )
````
where newsListener is a previously declared function.

#### news.getAll()

Retrieve all the news defined in the Cloud Dashboard.

##### <i>Event passed to the newsListener:</i>

- event.name: "news"
- event.type: "getAll"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### news.getAllUnread()

Retrieve all the unread news items.

##### <i>Event passed to the newsListener:</i>

- event.name: "news"
- event.type: "getAllUnread"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### news.getDetails( articleID )

Retrieve the full contents of the news item with the corresponding articleID.

- articleID - (String) the article ID to be retrieved

##### <i>Event passed to the newsListener:</i>

- event.name: "news"
- event.type: "getDetails"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### Multiplayer object methods, and the event they pass to the listener

#### Localising the multiplayer object

````
local multiplayer = cloud.multiplayer
````

#### Assigning a listener to the multiplayer object

````
multiplayer.setListener( multiplayerListener )
````
where multiplayerListener is a previously declared function.

#### multiplayer.poll( userID )

Open channel for the user userID to receive multiplayer data.

- userID - (String) the user ID the channel should be opened for.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "poll"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### multiplayer.getAllMatches()

Retrieve the complete list of matches, in any state.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "getAllMatches"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### multiplayer.newMatch()

Creates a new match.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "newMatch"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### <i>Note for multiplayer.newMatch()

On a successful call, the cloud match object (cloud.match) is automatically initialised, and the variable cloud.match.data is populated with the game information returned by the API. See below for the methods that can be used with the cloud.match object.

#### multiplayer.findMatch( matchID )

Retrieves the match specified by the matchID id.

- matchID - (String) the match id to return information for.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "findMatch"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### <i>Note for multiplayer.findMatch()

On a successful call, the cloud match object (cloud.match) is automatically initialised, and the variable cloud.match.data is populated with the game information returned by the API. See below for the methods that can be used with the cloud.match object.

#### multiplayer.deleteMatch( matchID )

Deletes the match specified by the matchID id.

- matchID - (String) the match id to return information for.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "deleteMatch"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### <i>Note for multiplayer.deleteMatch()

On a successful call, the cloud match object data (cloud.match.data) is automatically set to nil.

#### multiplayer.addPlayerToGroup( userID, groupID, matchID )

Add the user specified by the userID to the group specified by the groupID, for the match matchID. Useful for operations like creating teams of players.

- userID - (String) the user id to be added to the group
- groupID - (String) the group id the user is added to
- matchID - (String) the match id to operate on

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "addPlayerToGroup"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

### Match object methods, and the event they pass to the listener

#### Localising the match object

````
local match = cloud.match
````

#### Assigning a listener to the match object

The match object sends events to the multiplayerListener, where multiplayerListener is a previously declared function.

#### Note for the match methods

All the match methods don't use the dot notation. So please be sure you use match:resign instead of match.resign, same for all the match methods listed below.

#### match:resign( userAlert )

Resigns the current match. If userAlert is set, the other players will receive a push notification.

- userAlert - (String) the alert message to be contained in the push notification.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "resignMatch"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:start()

Starts the match.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "start"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:stop()

Stops the match.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "stop"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:addPlayer( userID, userAlert )

Adds the player specified by userID to the match. If userAlert is set, the user will receive a push notification.

- userID - (String) the user id to add to the match
- userAlert - (String) the alert message to be contained in the push notification.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "addPlayer"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:addRandomPlayer( userAlert )

Adds a random player to the match. If userAlert is set, the user will receive a push notification.

- userAlert - (String) the alert message to be contained in the push notification.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "addRandomPlayer"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:removePlayer( playerID )

Removes the player specified by playerID from the match.

- playerID - (String) the id of the player that is to be removed.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "removePlayer"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:acceptChallenge( userAlert )

Sends a challenge accepted message for the current player. If userAlert is set, all the other players will receive a push notification.

- userAlert - (String) the alert message to be contained in the push notification.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "acceptChallenge"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:declineChallenge()

Sends a challenge declined message for the current player. 

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "declineChallenge"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:submitMove( params )

Sends a move for the current match. The params table contains:

- params.targetGroup - (String) the group the move should be submitted to (if omitted, the move is submitted to all users)
- params.targetUser - (String) the user the move should be submitted to (if omitted, the move is submitted to all users)
- params.userAlert - (String) the alert message to be contained in the push notification.
- params.moveContent - (String) JSON encoded string with any number of records / information pieces

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "submitMove"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:getRecentMoves( [limit] )

Retrieves the history of recent moves for the match.

- limit (optional)(String) - the number of recent moves to retrieve.

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "getRecentMoves"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.

#### match:nudgeUser( userAlert, payLoad )

Nudges an inactive user. Matches become nudgeable once the active player has not submitted a move in more than 24h. Also, a user can only be nudged once every 24h. 

- userAlert - (String) the alert message to be contained in the push notification.
- payLoad - (String) the payload to be added to the push notification. 

##### <i>Event passed to the multiplayerListener:</i>

- event.name: "multiplayer"
- event.type: "nudgeUser"
- event.error: nil if no error occurred, string if error occurred.
- event.response: nil if an error occurred, string if we received valid response.