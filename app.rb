require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'

enable :sessions

get('/') do
  slim(:register)
end

get('/squad') do
  db = SQLite3::Database.new("db/oversikt.db")
  db.results_as_hash = true
  @players = db.execute("SELECT * FROM playerstable")
  slim(:squadbuilder)
end

post('/squad') do
  db = SQLite3::Database.new("db/oversikt.db")
  db.results_as_hash = true 
  user_id = session[:id]
  team_name = params[:team_name]
  if db.execute("SELECT id FROM teams WHERE team_name = ? AND user_id = ?", team_name, user_id) == []
    db.execute("INSERT INTO teams (team_name, user_id) VALUES (?, ?)", team_name, user_id)
  end
  i = 1
  while i <= 11 do
    player = params[:"playerr#{i}"]
    team_id = db.execute("SELECT id FROM teams WHERE team_name = ? AND user_id = ?", team_name, user_id).first["id"]
    player_id = db.execute("SELECT playerid FROM playerstable WHERE player_name = ?", player).first["playerid"]
    db.execute("INSERT INTO player_team_rel (player_id, team_id) VALUES (?,?)", player_id, team_id)
    i += 1
  end
  redirect('/huvudsida')
end

get('/playersss') do
  slim(:playersida)
end

post('/playersss') do 
  player_name = params[:player_name]
  player_position = params[:position]
  db = SQLite3::Database.new("db/oversikt.db")
  db.execute("INSERT INTO playerstable ( player_name, player_position) VALUES (?,?)", player_name, player_position)
  flash[:notice] =  "Spelaren är skapad!"
  redirect('/playersss')
end

get('/everyplayer') do
  db = SQLite3::Database.new("db/oversikt.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM playerstable")
  slim(:everyplayer, locals:{players:result})
end

get('/everysquad') do 
  db = SQLite3::Database.new("db/oversikt.db")
  db.results_as_hash = true
  user_id = session[:id]
  @squads = db.execute("SELECT * FROM teams WHERE user_id = ?", user_id)
  @squads.each do |squad|
  squad_id = squad["id"]
  squad["players"] = db.execute("SELECT playerstable.player_name, playerstable.player_position FROM playerstable INNER JOIN player_team_rel ON playerstable.playerid = player_team_rel.player_id WHERE player_team_rel.team_id = ?", squad_id)
  end
  slim(:everysquad)
end

get('/showlogin') do
  slim(:login)
end

get('/huvudsida') do
  slim(:"main/index")
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/oversikt.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first


  if result.nil?
    flash[:notice] =  "Användare finns inte"
    redirect('/showlogin')
  else  
    pwdigest = result["pwdigest"]
    id = result["id"]
  end

  if BCrypt::Password.new(pwdigest) == password 
    session[:id] = id
    redirect('/huvudsida')
  else 
    flash[:notice] = "Fel Lösenord"
    redirect('/showlogin')
  end
end


post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/oversikt.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
    flash[:notice] = "Användare skapad"
    redirect('/showlogin')
  else 
    flash[:notice] = "Lösenorden matchar inte"
    redirect('/')
  end
end

get('/logout') do
  session.clear
  redirect('/showlogin')
end