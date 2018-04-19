module ManageIQ::Providers::Redfish
  module PhysicalInfraManager::Operations::Led
    # Keep this in sync with app/models/physical_server/operations/led.rb in
    # core and IndicatorLED enum in Redfish ComputerSystem type. Name of the
    # method comes from the core and the action name used in the reset call
    # from the IndicatorLED enum.

    def blink_loc_led(args, options = {})
      set_led_state("Blinking", args, options)
    end

    def turn_on_loc_led(args, options = {})
      set_led_state("Lit", args, options)
    end

    def turn_off_loc_led(args, options = {})
      set_led_state("Off", args, options)
    end

    private

    def set_led_state(state, args, options = {})
      with_provider_connection(options) do |client|
        sys = client.find(args.ems_ref)
        resp = sys.patch(:payload => { "IndicatorLED" => state })
        raise "Cannot change led status" unless resp.status == 200
      end
    end
  end
end
