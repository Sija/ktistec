require "../../../src/api/serializers/instance"

require "../../spec_helper/base"
require "../../spec_helper/factory"

Spectator.describe API::V2::Serializers::Instance do
  setup_spec

  before_each { described_class.clear_cache! }

  macro with_setting(setting, value)
    around_each do |example|
      original = Ktistec.settings.{{setting.id}}
      Ktistec.settings.{{setting.id}} = {{value}}
      Ktistec.settings.save
      example.run
      Ktistec.settings.{{setting.id}} = original
      Ktistec.settings.save
    end
  end

  describe ".current" do
    subject { described_class.current }

    it "returns an Instance" do
      expect(subject).to be_a(API::V2::Serializers::Instance)
    end

    context "domain" do
      context "when host is set" do
        with_setting(host, "https://example.com")

        it "returns host domain" do
          expect(subject.domain).to eq("example.com")
        end
      end
    end

    context "title" do
      context "when site is set" do
        with_setting(site, "My Instance")

        it "returns site title" do
          expect(subject.title).to eq("My Instance")
        end
      end
    end

    context "version" do
      it "returns the software version" do
        expect(subject.version).to eq("4.2.0 (compatible; Ktistec #{Ktistec::VERSION})")
      end
    end

    context "source_url" do
      it "returns the source URL" do
        expect(subject.source_url).to eq("https://github.com/toddsundsted/ktistec")
      end
    end

    context "description" do
      it "returns empty string" do
        expect(subject.description).to eq("")
      end

      context "when description is set" do
        with_setting(description, "A test instance")

        it "returns the configured description" do
          expect(subject.description).to eq("A test instance")
        end
      end
    end

    context "usage" do
      let(actor) { register.actor }
      let_create!(:create, actor: actor, published: 15.days.ago)

      before_each do
        WellKnownController.cached_mau_count = WellKnownController::CachedMAUCount.new(0, 0)
      end

      it "returns monthly active users count" do
        expect(subject.usage.users.active_month).to eq(1)
      end
    end

    context "thumbnail" do
      it "returns empty string" do
        expect(subject.thumbnail.url).to eq("")
      end

      context "when image is set" do
        with_setting(image, "https://test.test/image.png")

        it "returns the configured image URL" do
          expect(subject.thumbnail.url).to eq("https://test.test/image.png")
        end
      end
    end

    context "icon" do
      it "returns empty array" do
        expect(subject.icon).to be_empty
      end
    end

    context "languages" do
      let!(account) { register.assign(language: "fr").save }

      it "returns the languages" do
        expect(subject.languages).to eq(["fr"])
      end
    end

    context "configuration" do
      context "urls" do
        it "returns empty string" do
          expect(subject.configuration.urls.streaming).to eq("")
        end
      end

      context "vapid" do
        it "returns empty string" do
          expect(subject.configuration.vapid.public_key).to eq("")
        end
      end

      context "accounts" do
        it "returns zero" do
          expect(subject.configuration.accounts.max_featured_tags).to eq(0)
        end

        it "returns maximum pinned statuses" do
          expect(subject.configuration.accounts.max_pinned_statuses).to eq(Ktistec::Constants::MAX_PINNED_POSTS)
        end
      end

      context "statuses" do
        it "returns maximum characters" do
          expect(subject.configuration.statuses.max_characters).to eq(Ktistec::Constants::MAX_POST_CHARACTERS)
        end

        it "returns maximum media attachments" do
          expect(subject.configuration.statuses.max_media_attachments).to eq(Ktistec::Constants::MAX_MEDIA_ATTACHMENTS)
        end

        it "returns zero" do
          expect(subject.configuration.statuses.characters_reserved_per_url).to eq(0)
        end
      end

      SUPPORTED_MEDIA_TYPES =
        Ktistec::Constants::SUPPORTED_IMAGE_TYPES +
          Ktistec::Constants::SUPPORTED_VIDEO_TYPES +
          Ktistec::Constants::SUPPORTED_AUDIO_TYPES

      context "media_attachments" do
        it "returns supported mime types" do
          expect(subject.configuration.media_attachments.supported_mime_types).to eq(SUPPORTED_MEDIA_TYPES)
        end

        it "returns description limit" do
          expect(subject.configuration.media_attachments.description_limit).to eq(Ktistec::Constants::MAX_ATTACHMENT_CHARACTERS)
        end

        it "returns image size limit" do
          expect(subject.configuration.media_attachments.image_size_limit).to eq(Ktistec::Constants::IMAGE_SIZE_LIMIT)
        end

        it "returns zero" do
          expect(subject.configuration.media_attachments.image_matrix_limit).to eq(0)
        end

        it "returns zero" do
          expect(subject.configuration.media_attachments.video_size_limit).to eq(0)
        end

        it "returns zero" do
          expect(subject.configuration.media_attachments.video_frame_rate_limit).to eq(0)
        end

        it "returns zero" do
          expect(subject.configuration.media_attachments.video_matrix_limit).to eq(0)
        end
      end

      context "polls" do
        it "returns max options" do
          expect(subject.configuration.polls.max_options).to eq(Ktistec::Constants::MAX_POLL_OPTIONS)
        end

        it "returns max characters per option" do
          expect(subject.configuration.polls.max_characters_per_option).to eq(Ktistec::Constants::MAX_POLL_OPTION_CHARACTERS)
        end

        it "returns min expiration" do
          expect(subject.configuration.polls.min_expiration).to eq(Ktistec::Constants::MIN_POLL_EXPIRATION)
        end

        it "returns max expiration" do
          expect(subject.configuration.polls.max_expiration).to eq(Ktistec::Constants::MAX_POLL_EXPIRATION)
        end
      end

      context "translation" do
        it "returns false" do
          expect(subject.configuration.translation.enabled).to be_false
        end

        def_mock Ktistec::Translator

        context "when translator is configured" do
          let(translator) { mock(Ktistec::Translator) }

          around_each do |example|
            Ktistec.set_translator(translator)
            example.run
            Ktistec.clear_translator
          end

          it "returns true" do
            expect(subject.configuration.translation.enabled).to be_true
          end
        end
      end
    end

    context "registrations" do
      it "returns false" do
        expect(subject.registrations.enabled).to be_false
      end

      it "returns false" do
        expect(subject.registrations.approval_required).to be_false
      end
    end

    context "api_versions" do
      it "returns zero" do
        expect(subject.api_versions.mastodon).to eq(0)
      end
    end

    context "contact" do
      it "returns empty string" do
        expect(subject.contact.email).to eq("")
      end
    end

    context "rules" do
      it "returns empty array" do
        expect(subject.rules).to be_empty
      end
    end
  end

  describe "#to_json" do
    subject { described_class.current }

    it "generates valid JSON" do
      expect { JSON.parse(subject.to_json) }.not_to raise_error
    end

    it "includes all required top-level fields" do
      json = JSON.parse(subject.to_json)
      expect(json["domain"]).to be_a(JSON::Any)
      expect(json["title"]).to be_a(JSON::Any)
      expect(json["version"]).to be_a(JSON::Any)
      expect(json["source_url"]).to be_a(JSON::Any)
      expect(json["description"]).to be_a(JSON::Any)
      expect(json["usage"]).to be_a(JSON::Any)
      expect(json["thumbnail"]).to be_a(JSON::Any)
      expect(json["icon"]).to be_a(JSON::Any)
      expect(json["languages"]).to be_a(JSON::Any)
      expect(json["configuration"]).to be_a(JSON::Any)
      expect(json["registrations"]).to be_a(JSON::Any)
      expect(json["api_versions"]).to be_a(JSON::Any)
      expect(json["contact"]).to be_a(JSON::Any)
      expect(json["rules"]).to be_a(JSON::Any)
    end
  end
end
