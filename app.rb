require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
require_relative 'model.rb'

enable :sessions

get('/') do
  slim(:register)
end

before do
  db = database()
  before_everything()
end

error 404 do
  flash[:notice] = "Routen existerar inte"
  redirect('/')
end

get('/squad/new') do
  db = database()
  @players = db.execute("SELECT * FROM playerstable")
  slim(:squadbuilder)
end

post('/squad') do
  db = database()
  user_id = session[:id]
  team_name = params[:team_name]

  selected_players = (1..11).map { |i| params[:"playerr#{i}"] }

  if selected_players.uniq.length != selected_players.length
    flash[:notice] = "Du har valt samma spelare för flera positioner!"
    redirect('/squad/new')
  end

  if db.execute("SELECT id FROM teams WHERE team_name = ? AND user_id = ?", team_name, user_id) == []
    db.execute("INSERT INTO teams (team_name, user_id) VALUES (?, ?)", team_name, user_id)
    flash[:notice] = "Ett lag har skapats"
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

get('/playersss/new') do
  slim(:playersida)
end

post('/playersss') do 
  db = database()
  player_name = params[:player_name]
  player_position = params[:position]
  db.execute("INSERT INTO playerstable ( player_name, player_position) VALUES (?,?)", player_name, player_position)
  flash[:notice] =  "Spelaren är skapad!"
  redirect('/playersss/new')
end

get('/everyplayer/') do
  db = database()
  result = db.execute("SELECT * FROM playerstable")
  slim(:everyplayer, locals:{players:result})
end

get('/everysquad/') do 
  db = database()
  user_id = session[:id]
  @squads = db.execute("SELECT * FROM teams WHERE user_id = ?", user_id)
  @squads.each do |squad|
  squad_id = squad["id"]
  squad["players"] = db.execute("SELECT playerstable.player_name, playerstable.player_position FROM playerstable INNER JOIN player_team_rel ON playerstable.playerid = player_team_rel.player_id WHERE player_team_rel.team_id = ?", squad_id)
  end
  slim(:everysquad)
end

post('/squads/:id/delete') do
  db = database()
  id = params[:id].to_i
  db.execute("DELETE FROM teams WHERE id = ?",id)
  db.execute("DELETE FROM player_team_rel where team_id = ?", id)
  redirect('/everysquad/')
end


post('/squads/:id/update') do
  db = database()
  squad_id = params[:id].to_i
  team_name = params[:team_name]

  selected_players = (1..11).map { |i| params[:"playerr#{i}"] }

  if selected_players.uniq.length != selected_players.length
    flash[:notice] = "Du har valt samma spelare för flera positioner!"
    redirect('/everysquad/')
  end

  db.execute("UPDATE teams SET team_name = ? WHERE id = ?", team_name, squad_id)
  db.execute("DELETE FROM player_team_rel WHERE team_id = ?", squad_id)

  (1..11).each do |i|
    player_name = params[:"playerr#{i}"]
    player_id = db.execute("SELECT playerid FROM playerstable WHERE player_name = ?", player_name).first["playerid"]

    db.execute("INSERT INTO player_team_rel (player_id, team_id) VALUES (?, ?)", player_id, squad_id,)
  end

  redirect('/everysquad/')
end


get('/showlogin') do
  slim(:login)
end

get('/huvudsida') do
  slim(:"main/index")
end

post('/login') do
  db = database()
  username = params[:username]
  password = params[:password]
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
    p "session id är:"
    p session[:id]
    p id
    if username == "carlbrooker1234"
      session[:tag] = "ADMIN"
    else
      session[:tag] = "USER"
    end
    redirect('/huvudsida')
  else 
    flash[:notice] = "Fel Lösenord"
    redirect('/showlogin')
  end
  p "session id är:"
  p session[:id]
  p id
end


post('/users/new') do
  db = database()
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
    flash[:notice] = "Ditt konto har skapats"
  else
    flash[:notice] = "Ditt konto har inte skapats, något gick fel"
    redirect('/')
  end
  redirect('/')
end

get('/logout') do
  session.clear
  redirect('/showlogin')
end

get('/squads/:id/edit') do
  db = database()
  user_id = session[:id].to_i
  id = params[:id].to_i
  user_squad_id = db.execute("SELECT user_id FROM teams WHERE id = ?", id).first
  if user_squad_id.nil? || user_id != user_squad_id[0]
    redirect('/')
  end
  @players = db.execute("SELECT * FROM playerstable")
  result_players = db.execute("SELECT player_name FROM playerstable")
  result = db.execute("SELECT * FROM teams WHERE id = ?",id).first
  slim(:"squadeditor",locals:{result:result,player_name:result_players})
end

get('/admin') do
  slim(:"/admin/adminpage")
end

get('/admin/adminsquad/') do
  db = database()
  user_id = session[:id]
  @squads = db.execute("SELECT * FROM teams")
  @squads.each do |squad|
  squad_id = squad["id"]
  squad["players"] = db.execute("SELECT playerstable.player_name, playerstable.player_position FROM playerstable INNER JOIN player_team_rel ON playerstable.playerid = player_team_rel.player_id WHERE player_team_rel.team_id = ?", squad_id)
  end
  slim(:"/admin/adminsquad")
end

post('/admin/adminsquad/squads/:id/delete') do
  id = params[:id].to_i
  db = database()
  db.execute("DELETE FROM teams WHERE id = ?",id)
  db.execute("DELETE FROM player_team_rel WHERE team_id = ?",id)
  redirect('/admin/adminsquad/')
end

get('/admin/adminsquad/squads/:id/edit') do
  db = database()
  user_id = session[:id].to_i
  id = params[:id].to_i
  user_squad_id = db.execute("SELECT user_id FROM teams WHERE id = ?", id).first
  @players = db.execute("SELECT * FROM playerstable")
  result_players = db.execute("SELECT player_name FROM playerstable")
  result = db.execute("SELECT * FROM teams WHERE id = ?",id).first
  slim(:"squadeditor",locals:{result:result,player_name:result_players})
end