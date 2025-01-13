
import HTTP
import JSON

function send_request(data::Dict; endpoint::String = "solve")
    ret = HTTP.request(
        "POST",
        # This should match the URL and endpoint we defined for our server.
        "http://127.0.0.1:8080/api/$endpoint",
        ["Content-Type" => "application/json"],
        JSON.json(data),
    )
    if ret.status != 200
        # This could happen if there are time-outs, network errors, etc.
        return Dict(
            "status" => "failure",
            "code" => ret.status,
            "body" => String(ret.body),
        )
    end
     return JSON.parse(String(ret.body))
end