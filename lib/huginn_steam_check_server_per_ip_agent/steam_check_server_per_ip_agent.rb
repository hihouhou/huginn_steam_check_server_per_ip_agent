module Agents
  class SteamCheckServerPerIpAgent < Agent
    include FormConfigurable

    can_dry_run!
    no_bulk_receive!
    default_schedule "never"

    description do
      <<-MD
      The huginn catalog agent checks available server per ip.

      `debug` is used to verbose mode.

      `changes_only` is only used to emit event about a currency's change.

      `ip` is the ip wanted for checking.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "addr": "XXX.XXX.XXX.XXX:2457",
            "gmsindex": -1,
            "appid": 892970,
            "gamedir": "valheim",
            "region": -1,
            "secure": false,
            "lan": false,
            "gameport": 2456,
            "specport": 0
          }
    MD

    def default_options
      {
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'ip' => '',
        'changes_only' => 'true'
      }
    end

    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :ip, type: :string
    form_configurable :changes_only, type: :boolean
    form_configurable :debug, type: :boolean

    def validate_options
      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end

      unless options['ip'].present? && options['ip'].to_i > 0
        errors.add(:base, "Please provide 'ip' to indicate the server adress before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      fetch
    end

    private

    def fetch
      uri = URI.parse("https://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=#{interpolated['ip']}")
      response = Net::HTTP.get_response(uri)

      log "request  status : #{response.code}"

      payload = JSON.parse(response.body)

      if interpolated['debug'] == 'true'
        log payload
      end

      if interpolated['changes_only'] == 'true'
        if payload.to_s != memory['last_status']
          if "#{memory['last_status']}" == ''
            payload['response']['servers'].each do |servers|
              create_event payload: servers
            end
          else
            last_status = memory['last_status'].gsub("=>", ": ").gsub(": nil,", ": null,")
            last_status = JSON.parse(last_status)
            payload['response']['servers'].each do |servers|
              found = false
              if interpolated['debug'] == 'true'
                log "servers"
                log servers
              end
              last_status['response']['servers'].each do |serversbis|
                if servers == serversbis
                  found = true
                end
                if interpolated['debug'] == 'true'
                  log "serversbis"
                  log serversbis
                  log "found is #{found}!"
                end
              end
              if found == false
                if interpolated['debug'] == 'true'
                  log "found is #{found}! so event created"
                  log servers
                end
                create_event payload: servers
              end
            end
          end
          memory['last_status'] = payload.to_s
        end
      else
        create_event payload: payload['response']['servers']
        if payload.to_s != memory['last_status']
          memory['last_status'] = payload.to_s
        end
      end
    end
  end
end
