require "json"

require "../../framework/framework"
require "../../models/account"
require "../../controllers/well_known"

module API
  module V2::Serializers
    # Serializes instance metadata to Mastodon Instance v2 JSON format.
    #
    # See: https://docs.joinmastodon.org/entities/Instance/
    #
    struct Instance
      include JSON::Serializable

      property domain : String
      property title : String
      property version : String
      property source_url : String
      property description : String
      property usage : Usage
      property thumbnail : Thumbnail
      property icon : Array(Icon)
      property languages : Array(String)
      property configuration : Configuration
      property registrations : Registrations
      property api_versions : ApiVersions
      property contact : Contact
      property rules : Array(Rule)

      def initialize(
        @domain : String,
        @title : String,
        @version : String,
        @source_url : String,
        @description : String,
        @usage : Usage,
        @thumbnail : Thumbnail,
        @icon : Array(Icon),
        @languages : Array(String),
        @configuration : Configuration,
        @registrations : Registrations,
        @api_versions : ApiVersions,
        @contact : Contact,
        @rules : Array(Rule),
      )
      end

      struct Usage
        include JSON::Serializable

        property users : Users

        def initialize(@users : Users)
        end

        struct Users
          include JSON::Serializable

          property active_month : Int64

          def initialize(@active_month : Int64)
          end
        end
      end

      struct Thumbnail
        include JSON::Serializable

        property url : String

        def initialize(@url : String)
        end
      end

      struct Icon
        include JSON::Serializable

        property src : String
        property size : String

        def initialize(@src : String, @size : String)
        end
      end

      struct Configuration
        include JSON::Serializable

        property urls : Urls
        property vapid : Vapid
        property accounts : Accounts
        property statuses : Statuses
        property media_attachments : MediaAttachments
        property polls : Polls
        property translation : Translation

        def initialize(
          @urls : Urls,
          @vapid : Vapid,
          @accounts : Accounts,
          @statuses : Statuses,
          @media_attachments : MediaAttachments,
          @polls : Polls,
          @translation : Translation,
        )
        end

        struct Urls
          include JSON::Serializable

          property streaming : String

          def initialize(@streaming : String)
          end
        end

        struct Vapid
          include JSON::Serializable

          property public_key : String

          def initialize(@public_key : String)
          end
        end

        struct Accounts
          include JSON::Serializable

          property max_featured_tags : Int32
          property max_pinned_statuses : Int32

          def initialize(@max_featured_tags : Int32, @max_pinned_statuses : Int32)
          end
        end

        struct Statuses
          include JSON::Serializable

          property max_characters : Int32
          property max_media_attachments : Int32
          property characters_reserved_per_url : Int32

          def initialize(
            @max_characters : Int32,
            @max_media_attachments : Int32,
            @characters_reserved_per_url : Int32,
          )
          end
        end

        struct MediaAttachments
          include JSON::Serializable

          property supported_mime_types : Array(String)
          property description_limit : Int32
          property image_size_limit : Int32
          property image_matrix_limit : Int32
          property video_size_limit : Int32
          property video_frame_rate_limit : Int32
          property video_matrix_limit : Int32

          def initialize(
            @supported_mime_types : Array(String),
            @description_limit : Int32,
            @image_size_limit : Int32,
            @image_matrix_limit : Int32,
            @video_size_limit : Int32,
            @video_frame_rate_limit : Int32,
            @video_matrix_limit : Int32,
          )
          end
        end

        struct Polls
          include JSON::Serializable

          property max_options : Int32
          property max_characters_per_option : Int32
          property min_expiration : Int32
          property max_expiration : Int32

          def initialize(
            @max_options : Int32,
            @max_characters_per_option : Int32,
            @min_expiration : Int32,
            @max_expiration : Int32,
          )
          end
        end

        struct Translation
          include JSON::Serializable

          property enabled : Bool

          def initialize(@enabled : Bool)
          end
        end
      end

      struct Registrations
        include JSON::Serializable

        property enabled : Bool
        property approval_required : Bool

        def initialize(
          @enabled : Bool,
          @approval_required : Bool,
        )
        end
      end

      struct ApiVersions
        include JSON::Serializable

        property mastodon : Int32

        def initialize(@mastodon : Int32)
        end
      end

      struct Contact
        include JSON::Serializable

        property email : String

        def initialize(@email : String)
        end
      end

      struct Rule
        include JSON::Serializable

        property id : String
        property text : String
        property hint : String

        def initialize(@id : String, @text : String, @hint : String)
        end
      end

      @@cached_instance : Instance?
      @@cached_settings_nonce : Int64 = 0
      @@cached_mau_timestamp : Int64 = 0

      # Clears the cached instance.
      #
      # For testing.
      #
      def self.clear_cache!
        @@cached_instance = nil
        @@cached_settings_nonce = 0
        @@cached_mau_timestamp = 0
      end

      # Returns the cached Instance, rebuilding only when settings or
      # monthly active users change.
      #
      def self.current : Instance
        settings_nonce = Ktistec::Settings.nonce
        mau_timestamp = WellKnownController.cached_mau_count.timestamp

        if @@cached_settings_nonce != settings_nonce || @@cached_mau_timestamp != mau_timestamp
          @@cached_settings_nonce = settings_nonce
          @@cached_mau_timestamp = mau_timestamp
          @@cached_instance = build_instance
        end

        @@cached_instance.not_nil!
      end

      SUPPORTED_MEDIA_TYPES =
        Ktistec::Constants::SUPPORTED_IMAGE_TYPES +
          Ktistec::Constants::SUPPORTED_VIDEO_TYPES +
          Ktistec::Constants::SUPPORTED_AUDIO_TYPES

      private def self.build_instance : Instance
        domain = URI.parse(Ktistec.host).host.not_nil!

        Instance.new(
          domain: domain,
          title: Ktistec.site,
          version: "4.2.0 (compatible; Ktistec #{Ktistec::VERSION})",
          source_url: "https://github.com/toddsundsted/ktistec",
          description: Ktistec.settings.description || "",
          usage: Usage.new(
            users: Usage::Users.new(
              active_month: WellKnownController.monthly_active_users
            )
          ),
          thumbnail: Thumbnail.new(
            url: Ktistec.settings.image || ""
          ),
          icon: [] of Icon,
          languages: Account.all.compact_map(&.language),
          configuration: Configuration.new(
            urls: Configuration::Urls.new(
              streaming: ""
            ),
            vapid: Configuration::Vapid.new(
              public_key: ""
            ),
            accounts: Configuration::Accounts.new(
              max_featured_tags: 0,
              max_pinned_statuses: Ktistec::Constants::MAX_PINNED_POSTS
            ),
            statuses: Configuration::Statuses.new(
              max_characters: Ktistec::Constants::MAX_POST_CHARACTERS,
              max_media_attachments: Ktistec::Constants::MAX_MEDIA_ATTACHMENTS,
              characters_reserved_per_url: 0
            ),
            media_attachments: Configuration::MediaAttachments.new(
              supported_mime_types: SUPPORTED_MEDIA_TYPES,
              description_limit: Ktistec::Constants::MAX_ATTACHMENT_CHARACTERS,
              image_size_limit: Ktistec::Constants::IMAGE_SIZE_LIMIT,
              image_matrix_limit: 0,
              video_size_limit: 0,
              video_frame_rate_limit: 0,
              video_matrix_limit: 0
            ),
            polls: Configuration::Polls.new(
              max_options: Ktistec::Constants::MAX_POLL_OPTIONS,
              max_characters_per_option: Ktistec::Constants::MAX_POLL_OPTION_CHARACTERS,
              min_expiration: Ktistec::Constants::MIN_POLL_EXPIRATION,
              max_expiration: Ktistec::Constants::MAX_POLL_EXPIRATION
            ),
            translation: Configuration::Translation.new(
              enabled: !Ktistec.translator.nil?
            )
          ),
          registrations: Registrations.new(
            enabled: false,
            approval_required: false
          ),
          api_versions: ApiVersions.new(
            mastodon: 0
          ),
          contact: Contact.new(
            email: ""
          ),
          rules: [] of Rule
        )
      end
    end
  end
end
