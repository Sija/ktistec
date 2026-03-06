require "../../src/controllers/api"
require "../../src/models/oauth2/provider/client"

require "../spec_helper/controller"
require "../spec_helper/factory"

Spectator.describe APIController do
  setup_spec

  JSON_HEADERS = HTTP::Headers{"Content-Type" => "application/json", "Accept" => "application/json"}
  FORM_HEADERS = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded", "Accept" => "application/json"}

  describe "OPTIONS /api/v1/apps" do
    it "returns 204" do
      options "/api/v1/apps"
      expect(response.status_code).to eq(204)
    end

    it "includes Access-Control-Allow-Origin header" do
      options "/api/v1/apps"
      expect(response.headers["Access-Control-Allow-Origin"]?).to eq("*")
    end

    it "includes Access-Control-Allow-Methods header" do
      options "/api/v1/apps"
      expect(response.headers["Access-Control-Allow-Methods"]?).to eq("POST, OPTIONS")
    end
  end

  describe "POST /api/v1/apps" do
    context "with JSON body" do
      let(body) do
        {
          "client_name"   => "Test App",
          "redirect_uris" => "https://example.com/callback",
          "scopes"        => "read write",
        }.to_json
      end

      it "succeeds" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(200)
      end

      it "includes client_id" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["client_id"]?).not_to be_nil
      end

      it "includes client_secret" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["client_secret"]?).not_to be_nil
      end

      it "includes name" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Test App")
      end

      it "includes scopes" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["scopes"].as_a.map(&.as_s)).to eq(["read", "write"])
      end

      it "includes redirect_uris as array" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["redirect_uris"].as_a.map(&.as_s)).to eq(["https://example.com/callback"])
      end

      it "includes redirect_uri as string" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["redirect_uri"]).to eq("https://example.com/callback")
      end

      it "includes client_secret_expires_at" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["client_secret_expires_at"]).to eq(0)
      end

      it "includes vapid_key" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["vapid_key"]).to eq("")
      end
    end

    context "with form-encoded body" do
      let(body) { "client_name=Test+App&redirect_uris=https%3A%2F%2Fexample.com%2Fcallback&scopes=read+write" }

      it "succeeds" do
        post "/api/v1/apps", headers: FORM_HEADERS, body: body
        expect(response.status_code).to eq(200)
      end

      it "parses client_name" do
        post "/api/v1/apps", headers: FORM_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Test App")
      end

      it "parses scopes" do
        post "/api/v1/apps", headers: FORM_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["scopes"].as_a.map(&.as_s)).to eq(["read", "write"])
      end
    end

    context "with multiple redirect_uris" do
      let(body) do
        {
          "client_name"   => "Test App",
          "redirect_uris" => ["https://example.com/callback", "https://example.com/oauth"],
          "scopes"        => "read",
        }.to_json
      end

      it "succeeds" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(200)
      end

      it "includes redirect_uris as array" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["redirect_uris"].as_a.map(&.as_s)).to eq(["https://example.com/callback", "https://example.com/oauth"])
      end

      it "includes redirect_uri as string" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["redirect_uri"]).to eq("https://example.com/callback\nhttps://example.com/oauth")
      end
    end

    context "with urn:ietf:wg:oauth:2.0:oob" do
      let(body) do
        {
          "client_name"   => "Test App",
          "redirect_uris" => "urn:ietf:wg:oauth:2.0:oob",
          "scopes"        => "read",
        }.to_json
      end

      it "succeeds" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(200)
      end
    end

    context "with missing client_name" do
      let(body) do
        {
          "redirect_uris" => "https://example.com/callback",
        }.to_json
      end

      it "returns 422" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(422)
      end

      it "returns error message" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["error"].as_s?).to contain("client_name")
      end
    end

    context "with blank client_name" do
      let(body) do
        {
          "client_name"   => "   ",
          "redirect_uris" => "https://example.com/callback",
        }.to_json
      end

      it "returns 422" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(422)
      end

      it "returns error message" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["error"].as_s?).to contain("client_name")
      end
    end

    context "with missing redirect_uris" do
      let(body) do
        {
          "client_name" => "Test App",
        }.to_json
      end

      it "returns 422" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(422)
      end

      it "returns error message" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["error"].as_s?).to contain("redirect_uris")
      end
    end

    context "with invalid redirect_uris" do
      let(body) do
        {
          "client_name"   => "Test App",
          "redirect_uris" => "invalid uri",
        }.to_json
      end

      it "returns 422" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(422)
      end

      it "returns error message" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["error"].as_s?).to contain("redirect_uris")
      end
    end

    context "with website" do
      let(body) do
        {
          "client_name"   => "Test App",
          "redirect_uris" => "https://example.com/callback",
          "website"       => "https://myapp.example.com",
        }.to_json
      end

      it "succeeds" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(200)
      end

      it "includes website" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        json = JSON.parse(response.body)
        expect(json["website"]).to eq("https://myapp.example.com")
      end
    end

    context "with malformed JSON" do
      let(body) { "{\"client_name\": \"Test\"" }

      it "returns 400" do
        post "/api/v1/apps", headers: JSON_HEADERS, body: body
        expect(response.status_code).to eq(400)
      end
    end
  end
end
