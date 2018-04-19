module ManageIQ::Providers::Redfish
  module PhysicalInfraManager::Operations::Power
    # Keep this in sync with app/models/physical_server/operations/power.rb in
    # core and ResetType enum in Redfish Resource type. Name of the method
    # comes from the core and the action name used in the reset call from the
    # ResetType enum.
    #
    # NOTE: Not all reset operations are implemented on all servers, so any of
    # the methods listed here can fail. We need to find a way to let those
    # failures bubble up to the user interface somehow or risk having a
    # completely useless tool.

    def power_on(args, options = {})
      reset_server("On", args, options)
    end

    def power_off(args, options = {})
      reset_server("GracefulShutdown", args, options)
    end

    def power_off_now(args, options = {})
      reset_server("ForceOff", args, options)
    end

    def restart(args, options = {})
      reset_server("GracefulRestart", args, options)
    end

    def restart_now(args, options = {})
      reset_server("ForceRestart", args, options)
    end

    def restart_to_sys_setup(_args, _options = {})
      raise "Restarting to system setup is not supported"
    end

    def restart_mgmt_controller(args, options = {})
      reset_manager("GracefulRestart", args, options)
    end

    private

    def reset_server(reset_type, args, options = {})
      with_provider_connection(options) do |client|
        sys = client.find(args.ems_ref)

        # TODO(tadej): target field can be empty, in which case we need to
        # construct it manually by following the instructions on
        # http://redfish.dmtf.org/schemas/DSP0266_1.4.0.html#create-post-a-id-create-post-a-
        sys.Actions["#ComputerSystem.Reset"].post(
          :field => "target", :payload => { "ResetType" => reset_type }
        )
      end
    end

    def reset_manager(_reset_type, _args, _options = {})
      # TODO(tadej): This operation is not well defined, since server can (and
      # usually is) managed by more that one manager.
      raise "Restarting manager is not supported"
    end
  end
end
