using Genie, Genie.Router

# Change the static assets directory to 'app/resources'
# Genie.config.server_static_dir = "app/resources"

route("/") do
    serve_static_file("app/resources/index.html")
end

Genie.up()
