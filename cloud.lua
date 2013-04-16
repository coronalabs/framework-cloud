--****************************************************************************************
--
-- ====================================================================
-- Corona Cloud low-level layer LUA Library - Corona Plugin Format
-- ====================================================================
--
-- File: lib-cloud.lua
--
-- Copyright © 2013 Corona Labs Inc. All Rights Reserved.
--
--****************************************************************************************

-- Create library
local cloudCore = {}

-------------------------------------------------
-- Imports
-------------------------------------------------

local json = require( "json" )

-------------------------------------------------
-- Constants
-------------------------------------------------

-- the api url
cloudCore.CC_URL = "api.coronalabs.com"

-- the corona cloud access key
cloudCore.CC_ACCESS_KEY = ""

-- the corona cloud secret key
cloudCore.CC_SECRET_KEY = ""

-------------------------------------------------
-- Instance variables
-------------------------------------------------

-- the session authentication token returned by the api upon login
cloudCore.authToken = ""

-- the logged in state variable
cloudCore.isLoggedIn = false

-- the authentication listener
cloudCore._authListener = nil

-- the leaderboards object and listener
cloudCore.leaderboards = {}
cloudCore._leaderboardsListener = nil

-- the achievements object and listener
cloudCore.achievements = {}
cloudCore._achievementsListener = nil

-- the analytics object and listener
cloudCore.analytics = {}
cloudCore._analyticsListener = nil

-- the chat object and listener
cloudCore.chatRoom = {}
cloudCore._chatRoomListener = {}

-- the friends object and listener
cloudCore.friends = {}
cloudCore._friendsListener = {}

-- the news object and listener
cloudCore.news = {}
cloudCore._newsListener = {}

-- the multiplayer object and listener
cloudCore.multiplayer = {}
cloudCore._multiplayerListener = {}

-- the match object
cloudCore.match = {}

-- public debug variable
cloudCore.debugEnabled = false

-- public variable, prefix for all the print output if debug is enabled
cloudCore.debugTextPrefix = "Corona Cloud: "

-------------------------------------------------
-- Private helper methods
-------------------------------------------------

-- url encoding
local function _urlencode( str )
	if str then
		str = string.gsub ( str, "\n", "\r\n" )
		str = string.gsub ( str, "([^%w ])",
		function ( c ) return string.format ( "%%%02X", string.byte( c ) ) end )
		str = string.gsub ( str, " ", "+" )
	end
	return str
end

-- b64 encoding
local function _b64enc( data )
    -- character table string
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    return ( (data:gsub( '.', function( x ) 
        local r,b='', x:byte()
        for i=8,1,-1 do r=r .. ( b % 2 ^ i - b % 2 ^ ( i - 1 ) > 0 and '1' or '0' ) end
        return r;
    end ) ..'0000' ):gsub( '%d%d%d?%d?%d?%d?', function( x )
        if ( #x < 6 ) then return '' end
        local c = 0
        for i = 1, 6 do c = c + ( x:sub( i, i ) == '1' and 2 ^ ( 6 - i ) or 0 ) end
        return b:sub( c+1, c+1 )
    end) .. ( { '', '==', '=' } )[ #data %3 + 1] )
end

-- b64 decoding
local function _b64dec( data )
	-- character table string
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    data = string.gsub( data, '[^'..b..'=]', '' )
    return ( data:gsub( '.', function( x )
        if ( x == '=' ) then return '' end
        local r,f = '', ( b:find( x ) - 1 )
        for i = 6, 1, -1 do r = r .. ( f % 2 ^ i - f % 2 ^ ( i - 1 ) > 0 and '1' or '0' ) end
        return r;
    end ):gsub( '%d%d%d?%d?%d?%d?%d?%d?', function( x )
        if ( #x ~= 8 ) then return '' end
        local c = 0
        for i = 1, 8 do c = c + ( x:sub( i, i ) == '1' and 2 ^ ( 8 - i ) or 0 ) end
        return string.char( c )
    end ))
end

-- authentication header creation
local function _createBasicAuthHeader( username, password )
	-- the header format is "Basic <base64 encoded username:password>"
	local header = "Basic "
	local authDetails = _b64enc( username .. ":" .. password )
	header = header .. authDetails
	return header
end

-- Corona Cloud POST method 
local function _postCC( path, parameters, networkListener )
	
	if not parameters then
		parameters = ""
	end

	local params = {}

	params.body = parameters

	local authHeader = _createBasicAuthHeader( cloudCore.CC_ACCESS_KEY, cloudCore.CC_SECRET_KEY )

	local headers = {}
	
	-- set the authentication header
	headers[ "Authorization" ] = authHeader
	-- set the content-type header
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	
	params.headers = headers

	local url = "https://" .. cloudCore.CC_URL

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\n----------------" )
		print( cloudCore.debugTextPrefix .. "-- POST Call ---" )
		print( cloudCore.debugTextPrefix .. "Post URL: "..url )
		print( cloudCore.debugTextPrefix .. "Post Path: "..path )
		print( cloudCore.debugTextPrefix .. "Post Parameters: "..parameters )
		print( cloudCore.debugTextPrefix .. "----------------" )
	end

	local hReq = url .. "/" .. path
	
	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\nPost Request: " .. hReq )
	end
	
	network.request( hReq, "POST", networkListener, params )
end

-- Corona Cloud GET method
local function _getCC( path, parameters, networkListener )

	local params = {}

	local authHeader = _createBasicAuthHeader( cloudCore.CC_ACCESS_KEY, cloudCore.CC_SECRET_KEY )

	local headers = {}
	headers[ "Authorization" ] = authHeader

	params.headers = headers

	local url = "https://" .. cloudCore.CC_URL

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\n----------------" )
		print( cloudCore.debugTextPrefix .. "-- GET Call ---" )
		print( cloudCore.debugTextPrefix .. "Get URL: "..url )
		print( cloudCore.debugTextPrefix .. "Get Path: "..path )
		print( cloudCore.debugTextPrefix .. "Get Parameters: "..parameters )
		print( cloudCore.debugTextPrefix .. "----------------" )
	end

	local hReq = url .. "/" .. path .. "?" .. parameters

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\nGet Request: " .. hReq )
	end
	
	network.request( hReq, "GET", networkListener, params )
end

-- Corona Cloud PUT method
local function _putCC( path, parameters, networkListener )

	local params = {}

	local authHeader = _createBasicAuthHeader( cloudCore.CC_ACCESS_KEY, cloudCore.CC_SECRET_KEY )

	local headers = {}
	
	-- set the authentication header
	headers[ "Authorization" ] = authHeader
	-- set the content type header
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	
	params.headers = headers
	params.body = putData

	local url = "https://" .. cloudCore.CC_URL

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\n----------------" )
		print( cloudCore.debugTextPrefix .. "-- PUT Call ---" )
		print( cloudCore.debugTextPrefix .. "Put URL: "..url )
		print( cloudCore.debugTextPrefix .. "Put Path: " .. path )
		print( cloudCore.debugTextPrefix .. "Put Parameters: " .. parameters )
		print( cloudCore.debugTextPrefix .. "----------------")
	end
	
	local hReq = url.."/"..path.."?"..parameters

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\nPut Request: " .. hReq )
	end
	
	network.request( hReq, "PUT", networkListener, params )
end

-- Corona Cloud DELETE method
local function _deleteCC(path, parameters, networkListener)

	local params = {}

	local authHeader = _createBasicAuthHeader( cloudCore.CC_ACCESS_KEY, cloudCore.CC_SECRET_KEY )

	local headers = {}
	-- set the auth header
	headers["Authorization"] = authHeader

	params.headers = headers

	local url = "https://" .. cloudCore.CC_URL

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\n----------------" )
		print( cloudCore.debugTextPrefix .. "-- DELETE Call ---" )
		print( cloudCore.debugTextPrefix .. "Delete URL: " .. url )
		print( cloudCore.debugTextPrefix .. "Delete Path: " .. path )
		print( cloudCore.debugTextPrefix .. "Delete Parameters: " .. parameters )
		print( cloudCore.debugTextPrefix .. "----------------" )
	end

	local hReq = url .. "/" .. path .. "?" .. parameters

	if cloudCore.debugEnabled then
		print( cloudCore.debugTextPrefix .. "\nDelete Request: " .. hReq )
	end
	
	network.request( hReq, "DELETE", networkListener, params )
end


-------------------------------------------------
-- Public Methods
-------------------------------------------------

-------------------------------------------------
-- Main Object / Authentication / Init
-------------------------------------------------

-------------------------------------------------
-- cloudCore.init( accessKey, secretKey, listener )
-------------------------------------------------
function cloudCore.init( accessKey, secretKey, listener )	-- constructor
	-- initialize the Corona Cloud connection
	cloudCore.CC_ACCESS_KEY = accessKey
	cloudCore.CC_SECRET_KEY = secretKey
	if nil ~= listener then
		cloudCore._authListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.init call." )
	end
	
end

-------------------------------------------------
-- cloudCore.login( params )
-------------------------------------------------
function cloudCore.login( params )
	-- params.type has to be user, facebook or session
	-- for user, we read params.email and params.password
	-- for facebook, params.facebookId and params.accessToken
	-- for session, params.authToken
	
	local path
	local pathParams
	local eventType = "loggedIn"
	
	if nil == params or nil == params.type then
		print( cloudCore.debugTextPrefix .. "You have to provide a type parameter. Type can be user, facebook or session." )
		return false
	end
	
	if params.type ~= "user" and params.type ~= "facebook" and params.type ~= "session" then
		print( cloudCore.debugTextPrefix .. "The valid values of the type parameter are user, facebook or session." )
		return false
	end
	
	if params.type == "user" then
		
		if nil ~= params.email and nil ~= params.password then
			pathParams = "login=" .. params.email .. "&password=" .. params.password
		else
			print( cloudCore.debugTextPrefix .. "You need to provide the email and password fields in the params table." )
			return false
		end
		
		path = "user_sessions/user_login.json"
		
	elseif params.type == "facebook" then
		
		if nil ~= params.facebookId and nil ~= params.accessToken then
			pathParams = "facebook_id=" .. params.facebookId .. "&access_token=" .. params.accessToken
		else
			print( cloudCore.debugTextPrefix .. "You need to provide the user facebook id (facebookId) and facebook access token (accessToken) fields in the params table." )
			return false
		end
		
		eventType = "facebookLoggedIn"
		path = "facebook_login.json"
	
	elseif params.type == "session" then
		if nil ~= params.authToken then
			cloudCore.authToken = params.authToken
		end
		
		eventType = "sessionLoggedIn"
		
	end

	local function networkListener( event )
		
		local response = json.decode( event.response )
		
		if ( event.isError ) then
			
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type=eventType, error = response.errors[ 1 ], response = nil }
				cloudCore._authListener( event )
			end
			
		else
			
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "login response: " .. event.response )
			end
			
			if ( response.auth_token ) then
				-- we set the class auth_token
				cloudCore.authToken = response.auth_token
				-- we set the user as being logged in
				cloudCore.isLoggedIn = true
				
				if cloudCore.debugEnabled then
					print( cloudCore.debugTextPrefix .. "User Logged In!" )
					print( cloudCore.debugTextPrefix .. "Auth Token: " .. cloudCore.authToken )
				end
				
				if nil ~= cloudCore._authListener then
					local event = { name="authentication", type=eventType, error = nil, response = event.response }
					cloudCore._authListener( event )
				end
				
				return true
			else
				if cloudCore.debugEnabled then
					print( cloudCore.debugTextPrefix .. "Login Error: " .. event.response )
				end
				
				if nil ~= cloudCore._authListener then
					local event = { name="authentication", type=eventType, error = response.errors[ 1 ], response = nil }
					cloudCore._authListener( event )
				end
				
			end
		end
		
	end

	if params.type == "facebook" or params.type == "user" then
		_postCC( path, pathParams, networkListener )
	end

	return true
end

-------------------------------------------------
-- cloudCore.getAuthToken()
-------------------------------------------------
function cloudCore.getAuthToken()
	return cloudCore.authToken
end

-------------------------------------------------
-- cloudCore.getProfile( [userId] )
-------------------------------------------------
function cloudCore.getProfile( userId )

	local params = "auth_token=" .. cloudCore.authToken
	local path
	local eventType = "getProfile"
	
	if nil ~= userId then
		path = "users/" .. userId .. ".json"
		eventType = "getUserProfile"
	else
		path = "my_profile.json"
	end

	local  function networkListener( event )
		if ( event.isError ) then
			
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type=eventType, error = event.response, response = nil }
				cloudCore._authListener( event )
			end
			
		else
			
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "User Profile: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type=eventType, error = nil, response = event.response }
				cloudCore._authListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.updateProfile()
-------------------------------------------------
function cloudCore.updateProfile( params )
		
	local pathParams = "auth_token=" .. cloudCore.authToken
	
	if params.displayName ~= nil then pathParams = pathParams .. "&username=" .. params.displayName end
	if params.firstName ~= nil then pathParams = pathParams .. "&first_name=" .. params.firstName end
	if params.lastName ~= nil then pathParams = pathParams .. "&last_name=" .. params.lastName end
	if params.password ~= nil then pathParams = pathParams .. "&password=" .. params.password end
	if params.profilePicture ~= nil then pathParams = pathParams .. "&profile_picture=" .. params.profilePicture end
	if params.facebookId ~= nil then pathParams = pathParams .. "&facebook_id=" .. facebookId end
	if params.facebookEnabled ~= nil then pathParams = pathParams .. "&facebook_enabled=" .. params.facebookEnabled end
	if params.facebookAccessToken ~= nil then pathParams = pathParams .. "&facebook_access_token=" .. params.facebookAccessToken end
	if params.twitterEnabled ~= nil then pathParams = pathParams .. "&twitter_enabled=" .. params.twitterEnabled end
	if params.twitterEnabledToken ~= nil then pathParams = pathParams .. "&twitter_enabled_token=" .. params.twitterEnabledToken end
	
	local path = "my_profile.json"

	local  function networkListener( event )
		
		if ( event.isError ) then
		
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
		
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="updateProfile", error = event.response, response = nil }
				cloudCore._authListener( event )
			end

		else
			
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "My Profile Updated: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="updateProfile", error = nil, response = event.response }
				cloudCore._authListener( event )
			end

		end
	end

	_putCC( path, pathParams, networkListener )

end

-------------------------------------------------
-- cloudCore.registerDevice( deviceToken )
-------------------------------------------------
function cloudCore.registerDevice ( deviceToken )
	
	-- detect current device and populate platform
	local curDevice = system.getInfo( "model" )
	local platform

	if curDevice == "iPhone" or curDevice == "iPad" or curDevice == "iPod" then
		if cloudCore.debugEnabled then
			print( cloudCore.debugTextPrefix .. "Current Device is: " .. curDevice )
		end
		platform = "iOS"
	else
		-- Not iOS so much be Android
		if cloudCore.debugEnabled then
			print( cloudCore.debugTextPrefix .. "Current Device is: " .. curDevice )
		end
		platform = "Android"
	end

	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&device_id=" .. deviceToken
	params = params .. "&platform=" .. platform

	local path = "devices.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="registerDevice", error = event.response, response = nil }
				cloudCore._authListener( event )
			end

		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Device Registered: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="registerDevice", error = nil, response = event.response }
				cloudCore._authListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.register( params )
-------------------------------------------------
function cloudCore.registerUser( params )
	
	local pathParams = "auth_token=" .. cloudCore.authToken
	
	if params.displayName ~= nil then pathParams = pathParams .. "&username=" .. params.displayName end
	if params.firstName ~= nil then pathParams = pathParams .. "&first_name=" .. params.firstName end
	if params.lastName ~= nil then pathParams = pathParams .. "&last_name=" .. params.lastName end
	if params.email ~= nil then pathParams = pathParams .. "&email=" .. _urlencode( params.email ) end
	if params.password ~= nil then pathParams = pathParams .. "&password=" .. params.password end

	local path = "users.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="registerUser", error = event.response, response = nil }
				cloudCore._authListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "User Registered: " .. event.response )
			end

			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="registerUser", error = nil, response = event.response }
				cloudCore._authListener( event )
			end
			
		end
	end

	_postCC( path, pathParams, networkListener )

end

-------------------------------------------------
-- cloudCore.recoverPassword( email )
-------------------------------------------------
function cloudCore.recoverPassword( email )
	
	local params = "email=" .. email

	local path = "users/forgot.json"

	local function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="recoverPassword", error = event.response, response = nil }
				cloudCore._authListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Password Recovery Initiated: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="recoverPassword", error = nil, response = event.response }
				cloudCore._authListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )

end

-------------------------------------------------
-- Leaderboards namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.leaderboards.setListener( listener )
-------------------------------------------------
function cloudCore.leaderboards.setListener( listener )
	if nil ~= listener then
		cloudCore._leaderboardsListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.leaderboards.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.leaderboards.getAll()
-------------------------------------------------
function cloudCore.leaderboards.getAll()
	
	local params = "auth_token=" .. cloudCore.authToken
	local path = "leaderboards.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._leaderboardsListener then
				local event = { name="leaderboards", type="getAll", error = event.response, response = nil }
				cloudCore._leaderboardsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Leaderboards" .. event.response )
			end
			
			if nil ~= cloudCore._leaderboardsListener then
				local event = { name="leaderboards", type="getAll", error = nil, response = event.response }
				cloudCore._leaderboardsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.leaderboards.getScores( leaderboardID )
-------------------------------------------------
function cloudCore.leaderboards.getScores( leaderboardID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "leaderboards/" .. leaderboardID .. "/scores.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._leaderboardsListener then
				local event = { name="leaderboards", type="getScores", error = event.response, response = nil }
				cloudCore._leaderboardsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Leaderboard Details: " .. event.response )
			end
			
			if nil ~= cloudCore._leaderboardsListener then
				local event = { name="leaderboards", type="getScores", error = nil, response = event.response }
				cloudCore._leaderboardsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.leaderboards.submitHighScore( leaderboardID, score )
-------------------------------------------------
function cloudCore.leaderboards.submitHighScore( leaderboardID, score )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&value=" .. score
	
	local path = "leaderboards/" .. leaderboardID .. "/scores.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._leaderboardsListener then
				local event = { name="leaderboards", type="submitHighScore", error = event.response, response = nil }
				cloudCore._leaderboardsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Leaderboard Details: " .. event.response )
			end
			
			if nil ~= cloudCore._leaderboardsListener then
				local event = { name="leaderboards", type="submitHighScore", error = nil, response = event.response }
				cloudCore._leaderboardsListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- Achievements namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.achievements.setListener( listener )
-------------------------------------------------
function cloudCore.achievements.setListener( listener )
	if nil ~= listener then
		cloudCore._achievementsListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.achievements.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.achievements.getAll()
-------------------------------------------------
function cloudCore.achievements.getAll()
	
	local params = ""
	
	local path = "achievements.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="getAll", error = event.response, response = nil }
				cloudCore._achievementsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Achievements: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="getAll", error = nil, response = event.response }
				cloudCore._achievementsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.achievements.getDetails( achievementID )
-------------------------------------------------
function cloudCore.achievements.getDetails( achievementID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "achievements/" .. achievementID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="getDetails", error = event.response, response = nil }
				cloudCore._achievementsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Achievement: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="getDetails", error = nil, response = event.response }
				cloudCore._achievementsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.achievements.getUnlocked()
-------------------------------------------------
function cloudCore.achievements.getUnlocked()
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "achievements_user.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="getUnlocked", error = event.response, response = nil }
				cloudCore._achievementsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Achievement: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="getUnlocked", error = nil, response = event.response }
				cloudCore._achievementsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.achievements.unlock( achievementID )
-------------------------------------------------
function cloudCore.achievements.unlock( achievementID )

	local params = "auth_token=" .. cloudCore.authToken

	local path = "achievements/unlock/" .. achievementID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="unlock", error = event.response, response = nil }
				cloudCore._achievementsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Achievement Unlocked: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="unlock", error = nil, response = event.response }
				cloudCore._achievementsListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.achievements.update( achievementID, progress )
-------------------------------------------------
function cloudCore.achievements.update( achievementID, progress )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&progress=" .. progress

	local path = "achievements/unlock/" .. achievementID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="update", error = event.response, response = nil }
				cloudCore._achievementsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Achievement Updated: " .. event.response )
			end

			if nil ~= cloudCore._achievementsListener then
				local event = { name="achievements", type="update", error = nil, response = event.response }
				cloudCore._achievementsListener( event )
			end

		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- Analytics namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.analytics.setListener( listener )
-------------------------------------------------
function cloudCore.analytics.setListener( listener )
	if nil ~= listener then
		cloudCore._analyticsListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.analytics.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.analytics.submitEvent( params )
-------------------------------------------------
function cloudCore.analytics.submitEvent( params )
	
	local pathParams = "auth_token=" .. cloudCore.authToken
	pathParams = pathParams .. "&event_type=" .. params.event_type
	pathParams = pathParams .. "&message=" .. params.message
	pathParams = pathParams .. "&name=" .. params.name

	local path = "analytic_events.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._analyticsListener then
				local event = { name="analytics", type="submitEvent", error = event.response, response = nil }
				cloudCore._analyticsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Analytics Event Submitted: " .. event.response )
			end
			
			if nil ~= cloudCore._analyticsListener then
				local event = { name="analytics", type="submitEvent", error = nil, response = event.response }
				cloudCore._analyticsListener( event )
			end
			
		end
	end

	_postCC( path, pathParams, networkListener )
end

-------------------------------------------------
-- ChatRoom namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.chatRoom.setListener( listener )
-------------------------------------------------
function cloudCore.chatRoom.setListener( listener )
	if nil ~= listener then
		cloudCore._chatRoomListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.chatRoom.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.chatRoom.new( name )
-------------------------------------------------
function cloudCore.chatRoom.new( name )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&name=" .. name

	local path = "chats.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="create", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Chat Room Created: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="create", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.chatRoom.delete( chatroomID )
-------------------------------------------------
function cloudCore.chatRoom.delete( chatroomID )
	
	local params = "auth_token=" .. cloudCore.authToken
	
	local path = "chats/" .. chatroomID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="delete", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
			print( cloudCore.debugTextPrefix .. "Chat Room Deleted: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="delete", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_deleteCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.chatRoom.sendMessage( chatroomID, message )
-------------------------------------------------
function cloudCore.chatRoom.sendMessage( chatroomID, message )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&content=" .. message

	local path = "chats/" .. chatroomID .. "/send_message.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="sendMessage", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Message Sent: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="sendMessage", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.chatRoom.addUser( userID, chatroomID )
-------------------------------------------------
function cloudCore.chatRoom.addUser( userID, chatroomID )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&user_id=" .. userID

	local path = "chats/" .. chatroomID .. "/add_user.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="addUser", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "User Added to Chat Room: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="addUser", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.chatRoom.removeUser( userID, chatroomID )
-------------------------------------------------
function cloudCore.chatRoom.removeUser( userID, chatroomID )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&user_id=" .. userID
	
	local path = "chats/" .. chatroomID .. "/remove_user.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="removeUser", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "User Removed from Chat Room: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="removeUser", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_deleteCC( path, params, networkListener )

end
-------------------------------------------------

-------------------------------------------------
-- cloudCore.chatRoom.getAll()
-------------------------------------------------
function cloudCore.chatRoom.getAll()
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "chats.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="getAll", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Chat Rooms: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="getAll", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.chatRoom.getHistory( chatroomID )
-------------------------------------------------
function cloudCore.chatRoom.getHistory( chatroomID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "chats/" .. chatroomID .. "/get_recent_chats.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="getHistory", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Chat Room History: " .. event.response )
			end

			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="getHistory", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end

		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.chatRoom.getUsers( chatroomID )
-------------------------------------------------
--Return what users are currently in a chat room
function cloudCore.chatRoom.getUsers( chatroomID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "chats/" .. chatroomID .. "/members.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="getUsers", error = event.response, response = nil }
				cloudCore._chatRoomListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Chat Room Members: " .. event.response )
			end
			
			if nil ~= cloudCore._chatRoomListener then
				local event = { name="chat", type="getUsers", error = nil, response = event.response }
				cloudCore._chatRoomListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )

end

-------------------------------------------------
-- Friends namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.friends.setListener( listener )
-------------------------------------------------
function cloudCore.friends.setListener( listener )
	if nil ~= listener then
		cloudCore._friendsListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.friends.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.friends.getAll()
-------------------------------------------------
function cloudCore.friends.getAll()
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "friends.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="getAll", error = event.response, response = nil }
				cloudCore._friendsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Friends: " .. event.response )
			end

			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="getAll", error = nil, response = event.response }
				cloudCore._friendsListener( event )
			end

		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.friends.add( friendID )
-------------------------------------------------
function cloudCore.friends.add( friendID )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&friend_id=" .. friendID

	local path = "friends.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="add", error = event.response, response = nil }
				cloudCore._friendsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Friend Added: " .. event.response )
			end

			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="add", error = nil, response = event.response }
				cloudCore._friendsListener( event )
			end

		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.friends.remove( friendID )
-------------------------------------------------
function cloudCore.friends.remove( friendID )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&user_id=" .. friendID

	local path = "friends.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="remove", error = event.response, response = nil }
				cloudCore._friendsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Friend Deleted: " .. event.response )
			end

			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="remove", error = nil, response = event.response }
				cloudCore._friendsListener( event )
			end

		end
	end

	_deleteCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.friends.find( keyword )
-------------------------------------------------
function cloudCore.friends.find( keyword )

    local params = "keyword=" .. _urlencode(keyword)

    local path = "users/search.json"

    local  function networkListener( event )
        if ( event.isError ) then
			if cloudCore.debugEnabled then
            	print( cloudCore.debugTextPrefix .. "findUser Network Error" )
            	print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
            
			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="find", error = event.response, response = nil }
				cloudCore._friendsListener( event )
			end

        else
			if cloudCore.debugEnabled then
            	print( cloudCore.debugTextPrefix .. "Search Results: " .. event.response )
			end
            
			if nil ~= cloudCore._friendsListener then
				local event = { name="friends", type="find", error = nil, response = event.response }
				cloudCore._friendsListener( event )
			end

        end
    end

    _getCC( path, params, networkListener )
end

-------------------------------------------------
-- News namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.news.setListener( listener )
-------------------------------------------------
function cloudCore.news.setListener( listener )
	if nil ~= listener then
		cloudCore._newsListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.news.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.news.getAll()
-------------------------------------------------
function cloudCore.news.getAll()
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "news.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._newsListener then
				local event = { name="news", type="getAll", error = event.response, response = nil }
				cloudCore._newsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "News: " .. event.response )
			end
			
			if nil ~= cloudCore._newsListener then
				local event = { name="news", type="getAll", error = nil, response = event.response }
				cloudCore._newsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.news.getAllUnread()
-------------------------------------------------
function cloudCore.news.getAllUnread()
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "news/unread.json"

	local  function networkListener(event)
		if (event.isError) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._newsListener then
				local event = { name="news", type="getAllUnread", error = event.response, response = nil }
				cloudCore._newsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "News (Unread): " .. event.response )
			end
			
			if nil ~= cloudCore._newsListener then
				local event = { name="news", type="getAllUnread", error = nil, response = event.response }
				cloudCore._newsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.news.getDetails( articleID )
-------------------------------------------------
function cloudCore.news.getDetails( articleID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "news/" .. articleID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._newsListener then
				local event = { name="news", type="getDetails", error = event.response, response = nil }
				cloudCore._newsListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "News Article: " .. event.response )
			end
			
			if nil ~= cloudCore._newsListener then
				local event = { name="news", type="getDetails", error = nil, response = event.response }
				cloudCore._newsListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- Multiplayer namespace
-------------------------------------------------

-------------------------------------------------
-- cloudCore.multiplayer.setListener( listener )
-------------------------------------------------
function cloudCore.multiplayer.setListener( listener )
	if nil ~= listener then
		cloudCore._multiplayerListener = listener
	else
		print( cloudCore.debugTextPrefix .. "You must provide a listener to the cloud.multiplayer.setListener call." )
	end
end

-------------------------------------------------
-- cloudCore.multiplayer.poll( userID )
-------------------------------------------------
function cloudCore.multiplayer.poll( userID )
	
	local path = "https://" .. cloudCore.CC_URL .. "/receive.json"
	path = path .. "?player_id=" .. userID

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="poll", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Connecting to the Corona Cloud Server: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="poll", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	network.request( path, "GET", networkListener )
end

-------------------------------------------------
-- cloudCore.multiplayer.getAllMatches()
-------------------------------------------------
function cloudCore.multiplayer.getAllMatches()
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "matches.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="getAllMatches", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Get Matches: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="getAllMatches", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.multiplayer.newMatch()
-------------------------------------------------
function cloudCore.multiplayer.newMatch()
	
	local params = "auth_token=" .. cloudCore.authToken
	
	local path = "matches.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="newMatch", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Match Created: " .. event.response )
			end
				
			-- assign to the match object
			cloudCore.match.data = json.decode( event.response )
	
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="newMatch", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.multiplayer.findMatch( matchID )
-------------------------------------------------
function cloudCore.multiplayer.findMatch( matchID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "matches/" .. matchID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="findMatch", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Get Match Details: " .. event.response )
			end
			
			-- assign to the match object
			cloudCore.match.data = json.decode( event.response )
	
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="findMatch", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.multiplayer.deleteMatch( matchID )
-------------------------------------------------
function cloudCore.multiplayer.deleteMatch( matchID )
	
	local params = "auth_token=" .. cloudCore.authToken

	local path = "matches/" .. matchID .. ".json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="deleteMatch", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Match Deleted: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="deleteMatch", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
			-- reinit the match data variable
			cloudCore.match.data = {}
			
		end
	end

	_deleteCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.multiplayer.addPlayerToGroup( userID, groupID, matchID )
-------------------------------------------------
function cloudCore.multiplayer.addPlayerToGroup( userID, groupID, matchID )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&user_id=" .. userID
	params = params .. "&group_id=" .. groupID
	
	local path = "matches/" .. matchID .. "/add_player_to_group.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="addPlayerToGroup", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Player Added to Match Group: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="addPlayerToGroup", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:resign( userAlert )
-------------------------------------------------
function cloudCore.match:resign( userAlert )
	
	local params = "auth_token=" .. cloudCore.authToken

	if ( userAlert ~= nil ) then
		params = params .. "&user_alert=" .. _urlencode(userAlert)
	end 
	
	local matchID = self.data._id

	local path = "matches/" .. matchID .. "/resign.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="resignMatch", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Match Resigned: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="resignMatch", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_deleteCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.match:start()
-------------------------------------------------
function cloudCore.match:start()
	
	local params = "auth_token=" .. cloudCore.authToken
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/start.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="start", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Match Started: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="start", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:stop()
-------------------------------------------------
function cloudCore.match:stop()
	
	local params = "auth_token=" .. cloudCore.authToken
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/stop.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="stop", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Match Stopped: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="stop", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end

		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:addPlayer( userID, userAlert )
-------------------------------------------------
function cloudCore.match:addPlayer( userID, userAlert )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&user_id=" .. userID

	if ( userAlert ~= nil ) then
		params = params .. "&user_alert=" .. _urlencode(userAlert)
	end 

	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/add_player.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="addPlayer", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Player Added to Match: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="addPlayer", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:addRandomPlayer( userAlert )
-------------------------------------------------
function cloudCore.match:addRandomPlayer( userAlert )
	
	local params = "auth_token=" .. cloudCore.authToken
	
	if matchType ~= nil then 
		params = params .. "&match_type=" .. matchType
	end

	if (userAlert ~= nil) then
		params = params .. "&user_alert=" .. _urlencode(userAlert)
	end 

	local path = "matches/random_match_up.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="addRandomPlayer", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Random Challenge Sent: " .. event.response )
			end

			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="addRandomPlayer", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end

		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:removePlayer( playerID )
-------------------------------------------------
function cloudCore.match:removePlayer( playerID )
	
	local params = "auth_token=" .. cloudCore.authToken
	params = params .. "&player_id=" .. playerID
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/remove_player.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="removePlayer", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Player Removed: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="removePlayer", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_deleteCC( path, params, networkListener )

end

-------------------------------------------------
-- cloudCore.match:acceptChallenge( userAlert )
-------------------------------------------------
function cloudCore.match:acceptChallenge( userAlert )
	
	local params = "auth_token=" .. cloudCore.authToken
	
	if ( userAlert ~= nil ) then
		params = params .. "&user_alert=" .. _urlencode(userAlert)
	end 

	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/accept_request.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="acceptChallenge", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Challenge Accepted: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="acceptChallenge", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:declineChallenge()
-------------------------------------------------
function cloudCore.match:declineChallenge()
	
	local params = "auth_token=" .. cloudCore.authToken

	if ( userAlert ~= nil ) then
		params = params .. "&user_alert=" .. _urlencode(userAlert)
	end 
	
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/reject_request.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="declineChallenge", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Challenge Declined: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="declineChallenge", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_deleteCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:submitMove( params )
-------------------------------------------------
function cloudCore.match:submitMove( params )
	
	local pathParams = "auth_token=" .. cloudCore.authToken
	
	-- if targetgroup specified then add parameter
	if ( params.targetGroup ~= nil ) then
		pathParams = pathParams .. "&group_id=" .. params.targetGroup
	end
	
	-- if targetUser specified then add parameter
	if ( params.targetUser ~= nil ) then
		pathParams = pathParams .. "&target_user_id=" .. params.targetUser
	end

	-- if userAlert specified then add parameter
	if ( params.userAlert ~= nil ) then
		pathParams = pathParams .. "&user_alert=" .. _urlencode(params.userAlert)
	end

	-- Base64 encode moveContent
	params.moveContent = _b64enc( params.moveContent )

	pathParams = pathParams .. "&content=" .. params.moveContent
	
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/move.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="submitMove", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Move Submitted: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="submitMove", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, pathParams, networkListener )
end

-------------------------------------------------
-- cloudCore.match:getRecentMoves( [limit] )
-------------------------------------------------
function cloudCore.match:getRecentMoves( limit )
	
	local params = "auth_token=" .. cloudCore.authToken
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/get_recent_moves.json"

	-- Force get all moves
	params = params .. "&criteria=all"

	-- Check if limit provided, if so add param
	if ( limit ~= nil ) then
		params = params .. "&move_count=" .. limit
	end

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end

			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="getRecentMoves", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end

		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Recent Match Moves: " .. event.response )
			end
			local response = json.decode(event.response)

			-- Decode content - Convenient!
			-- TODO: Need to made it iterate through all moves,
			-- not just one.
			if ( response[1] ~= nil ) then
				if cloudCore.debugEnabled then
					print (cloudCore.debugTextPrefix .. "Decoding Content" )
				end
				response[1].content = _b64dec( response[1].content )
			end

			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="getRecentMoves", error = nil, response = response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.match:nudgeUser( userAlert, payLoad )
-------------------------------------------------
function cloudCore.match:nudgeUser( userAlert, payLoad )
	
	local params = "auth_token=" .. cloudCore.authToken
	
	if ( userAlert ~= nil ) then
		params = params .. "&user_alert=" .. _urlencode(userAlert)
	end 

	if (payLoad ~= nil) then
		params = params .. "&payload=" .. payLoad
	end
	local matchID = self.data._id
	local path = "matches/" .. matchID .. "/nudge.json"

	local  function networkListener( event )
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="nudgeUser", error = event.response, response = nil }
				cloudCore._multiplayerListener( event )
			end
			
		else
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "Send a nudge to a user: " .. event.response )
			end
			
			if nil ~= cloudCore._multiplayerListener then
				local event = { name="multiplayer", type="nudgeUser", error = nil, response = event.response }
				cloudCore._multiplayerListener( event )
			end
			
		end
	end

	_postCC( path, params, networkListener )
end

-------------------------------------------------
-- cloudCore.getInfo()
-------------------------------------------------
function cloudCore.getInfo()

	local params = "auth_token=" .. cloudCore.authToken

	local path = "info.json"

	local  function networkListener( event )
		
		if ( event.isError ) then
			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "getInfo Network Error" )
				print( cloudCore.debugTextPrefix .. "Error: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="getInfo", error = event.response, response = nil }
				cloudCore._authListener( event )
			end
			
		else
 			if cloudCore.debugEnabled then
				print( cloudCore.debugTextPrefix .. "getInfo Results: " .. event.response )
			end
			
			if nil ~= cloudCore._authListener then
				local event = { name="authentication", type="getInfo", error = nil, response = event.response }
				cloudCore._authListener( event )
			end
		end
	end

	_getCC( path, params, networkListener )
end

-------------------------------------------------
-- End of implementation.
-------------------------------------------------

return cloudCore

