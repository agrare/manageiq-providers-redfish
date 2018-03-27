module ManageIQ::Providers::Redfish
  class Inventory::Collector::PhysicalInfraManager < Inventory::Collector
    def physical_servers
      rf_client.Systems.Members.collect(&:raw)
    end

    def physical_server_details
      rf_client.Systems.Members.collect { |s| get_server_location(s) }
    end

    private

    def get_server_location(server)
      chassis = [server.Links.Chassis[0]]
      while chassis.last.Links.respond_to?("ContainedBy")
        chassis.push(chassis.last.Links.ContainedBy)
      end
      # TODO(tadeboro): Location can also be string in old version of schema
      loc = { :server_id => server["@odata.id"] }
      chassis.reduce(loc) do |acc, c|
        acc.merge!(c.respond_to?(:Location) ? c.Location.raw : {})
      end
    end
  end
end
