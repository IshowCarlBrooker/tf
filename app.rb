require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
  slim(:register)
end

get('/squad') do
  slim(:squadbuilder)
end

get('/playersss') do
  slim(:playersida)
end

post('/playersss') do 
  player_name = params[:player_name]
  player_position = params[:position]
  db = SQLite3::Database.new("db/oversikt.db")
  db.execute("INSERT INTO playerstable ( player_name, player_position) VALUES (?,?)", player_name, player_position)
  redirect('/huvudsida')
end

get('/everyplayer') do
  db = SQLite3::Database.new("db/oversikt.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM playerstable")
  slim(:everyplayer, locals:{players:result})
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
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/huvudsida')
  else
    "FEL LÖSENORD"
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
    redirect('/')
  else 
    "Fel Lösenord"
  end
end

