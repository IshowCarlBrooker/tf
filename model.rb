require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'




def database()
    db = SQLite3::Database.new("db/oversikt.db")
    db.results_as_hash = true
    return db
end

def before_everything()
    protected_routes = ['/everysquad/','/squads/:id/delete','/squads/:id/update','/squads/:id/edit','/admin*','/everyplayer/','/squad','/playersss/new']
    login_routes = ['/login']
    if session[:tag] != nil && login_routes.include?(request.path_info)
        p "Här är nroaml redirect grej"
        p "Här är nroaml redirect grej"

        p "Här är nroaml redirect grej"
        p "Här är nroaml redirect grej"
        p "Här är nroaml redirect grej"
        p "Här är nroaml redirect grej"
        
        redirect('/huvudsida')
    end
    if session[:id] == nil && protected_routes.include?(request.path_info)
        redirect('/')
    end
    if session[:tag] != "ADMIN" && request.path_info.include?('/admin')
        p "Här är admin redirect grej"
        p "Här är admin redirect grej"

        p "Här är admin redirect grej"
        p "Här är admin redirect grej"
        p "Här är admin redirect grej"
        p "Här är admin redirect grej"

        redirect('/huvudsida')
    end
end