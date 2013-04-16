local cloud = require( "cloud" )
local json = require ( "json" )

-- forward declarations
local chatRoom
local friends
local news
local multiplayer

-- also a forward declaration, will be assigned to the cloud.match object in the multiplayer listener
local match

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
		multiplayer.findMatch( "SOME_MATCH_ID" )
	end
	
	if event.type == "getProfile" then
		--print( "The user profile: ", event.response )
	end

end

-- the leaderboards listener
local leaderboardsListener = function( event )
	local leaderboards = json.decode( event.response )
	--print( "Leaderboard 1: ", leaderboards[ 1 ]._id )
end

-- the achievements listener
local achievementsListener = function( event )
	local achievements = json.decode( event.response )
	--print( "Achievement 1: ", achievements[ 1 ]._id )
end

-- the analytics listener
local analyticsListener = function( event )
	local analytics = json.decode( event.response )
	--print ( event.response )
end

-- the chat room listener
local chatRoomListener = function( event )
	local chatRoom = json.decode( event.response )
	--print( "Chatrooms: ", event.response )
end

-- the friends listener
local friendsListener = function( event )
	local friends = json.decode( event.response )
	--print( "Friends: ", event.response )
end

local newsListener = function( event )
	local news = json.decode( event.response )
	--print( "Unread News: ", event.response )
end

local multiplayerListener = function( event )
	if event.type == "getAllMatches" then
		local gamesTable = json.decode( event.response )
		for i = 1, #gamesTable do
			--print ( gamesTable[ i ]._id )
		end
	end
	if event.type == "newMatch" then
		-- the match table is now available
		match = cloud.match
		--print( match.data._id )
	end
	if event.type == "findMatch" then
		-- the match table is now available
		match = cloud.match
		--print( match.data._id )
		--match:resign()
	end
end


-- set the debugEnabled variable
cloud.debugEnabled = false

-- init the main cloud object
cloud.init( "YOUR_ACCESS_KEY", "YOUR_SECRET_KEY", authListener )

-- prepare the parameters for the login method
local loginParams = {}
loginParams.type = "user"
loginParams.email = "USER.EMAIL"
loginParams.password = "USER.PASSWORD"

-- login to the cloud
cloud.login( loginParams )

-- localize the leaderboards object of the cloud
local leaderboards = cloud.leaderboards

-- set the leaderboards listener
leaderboards.setListener( leaderboardsListener )

-- get the leaderboards
leaderboards.getAll()

-- localize the achievements object of the cloud
local achievements = cloud.achievements

-- set the achievements listener
achievements.setListener( achievementsListener )

-- get the achievements
achievements.getAll()

-- localize the analytics object of the cloud
local analytics = cloud.analytics

-- set the analytics listener
analytics.setListener( analyticsListener )

-- submit analytics event
local aParams = {}
aParams.event_type = "Session"
aParams.message = "The user logged In"
aParams.name = "logIn"

-- send the event
analytics.submitEvent( aParams )

-- localize the chatRoom object of the cloud
chatRoom = cloud.chatRoom

-- set the chatRoom listener
chatRoom.setListener( chatRoomListener )

-- localize the friends object of the cloud
friends = cloud.friends

-- set the friends listener
friends.setListener( friendsListener )

-- localize the news object of the cloud
news = cloud.news

-- set the news listener
news.setListener( newsListener )

-- localize the multiplayer object
multiplayer = cloud.multiplayer

-- set the listener
multiplayer.setListener( multiplayerListener )




