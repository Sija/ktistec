require "../framework/controller"
require "../services/oauth2/client_registration"
require "../api/serializers/application"
require "../api/serializers/instance"
require "../api/serializers/account"

class APIController
  include Ktistec::Controller

  Log = ::Log.for("api")

  skip_auth ["/api/v1/apps"], OPTIONS, POST
  skip_auth ["/api/v1/instance", "/api/v2/instance"], GET

  private macro set_headers
    env.response.headers.add("Access-Control-Allow-Origin", "*")
    env.response.headers.add("Access-Control-Allow-Methods", "POST, OPTIONS")
    env.response.headers.add("Access-Control-Allow-Headers", "Authorization, Content-Type")
    env.response.content_type = "application/json"
  end

  options "/api/v1/apps" do |env|
    set_headers

    no_content
  end

  post "/api/v1/apps" do |env|
    set_headers

    client_name : String
    redirect_uris : Array(String)
    scopes : String
    website : String?

    content_type = env.request.headers["Content-Type"]?.try(&.split(";").first.strip)

    if content_type == "application/json"
      body = env.request.body.try(&.gets_to_end) || ""
      begin
        json = JSON.parse(body)
      rescue JSON::ParseException
        Log.debug { "Invalid JSON" }
        bad_request "Invalid JSON"
      end

      client_name = json["client_name"]?.try(&.as_s?) || ""

      redirect_uris_raw = json["redirect_uris"]?
      redirect_uris =
        if redirect_uris_raw
          if (as_string = redirect_uris_raw.as_s?)
            [as_string]
          elsif (as_array = redirect_uris_raw.as_a?)
            as_array.compact_map(&.as_s?)
          else
            [] of String
          end
        else
          [] of String
        end

      scopes = json["scopes"]?.try(&.as_s?) || "read"
      website = json["website"]?.try(&.as_s?)
    else
      params = env.params.body

      client_name = params["client_name"]?.try(&.as(String)) || ""

      redirect_uris_raw = params["redirect_uris"]?
      redirect_uris =
        if redirect_uris_raw.is_a?(String)
          [redirect_uris_raw]
        else
          [] of String
        end

      scopes = params["scopes"]? || "read"
      website = params["website"]?
    end

    Log.trace { "apps[POST]: client_name=#{client_name}, redirect_uris=#{redirect_uris}, scopes=#{scopes}" }

    result = OAuth2::ClientRegistration.register(
      client_name: client_name,
      redirect_uris: redirect_uris,
      scopes: scopes,
    )

    case result
    in OAuth2::ClientRegistration::Success
      client = result.client
      app = API::V1::Serializers::Application.from_client(client, include_secret: true, website: website)
      app.to_json
    in OAuth2::ClientRegistration::Failure
      Log.debug { result.error }
      unprocessable_entity "api/error", error: result.error
    end
  end

  get "/api/v1/instance" do |env|
    env.response.headers.add("Access-Control-Allow-Origin", "*")
    env.response.content_type = "application/json"

    API::V1::Serializers::Instance.current.to_json
  end

  get "/api/v2/instance" do |env|
    env.response.headers.add("Access-Control-Allow-Origin", "*")
    env.response.content_type = "application/json"

    API::V2::Serializers::Instance.current.to_json
  end

  get "/api/v1/accounts/verify_credentials" do |env|
    env.response.headers.add("Access-Control-Allow-Origin", "*")
    env.response.content_type = "application/json"

    unless (account = env.account?)
      unauthorized "api/error", error: "The access token is invalid"
    end

    API::V1::Serializers::Account.from_account(account, account.actor, include_source: true).to_json
  end
end
