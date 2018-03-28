module ManageIQ::Providers::Redfish
  class Inventory::Collector::PhysicalInfraManager < Inventory::Collector
    def physical_servers
      rf_client.Systems.Members.collect(&:raw)
    end

    def physical_server_details
      rf_client.Systems.Members.collect { |s| get_server_location(s) }
    end

    def hardwares
      rf_client.Systems.Members.collect { |s| get_server_hardware(s) }
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

    def get_server_hardware(server)
      {
        :memory_gb => server.MemorySummary.TotalSystemMemoryGiB,
        :cpu_cores => get_cpu_cores(server),
        :capacity  => get_disk_capacity(server),
        :server_id => server["@odata.id"]
      }
    end

    def get_cpu_cores(server)
      return 1 unless server.respond_to?(:Processors)

      server.Processors.Members.reduce(0) { |a, p| a + p.TotalCores }
    end

    def get_disk_capacity(server)
      get_simple_storage_sum(server) + get_storage_sum(server)
    end

    def get_simple_storage_sum(server)
      return 0 unless server.respond_to?(:SimpleStorage)

      server.SimpleStorage.Members.reduce(0) do |acc, s|
        acc + get_simple_storage_capacity(s)
      end
    end

    def get_simple_storage_capacity(storage)
      storage.Devices.reduce(0) { |acc, d| acc + (d&.CapacityBytes || 0) }
    end

    def get_storage_sum(server)
      return 0 unless server.respond_to?(:Storage)

      server.Storage.Members.reduce(0) do |acc, s|
        acc + get_storage_capacity(s)
      end
    end

    def get_storage_capacity(storage)
      return 0 unless storage.respond_to?(:Drives)

      storage.Drives.reduce(0) { |acc, d| acc + (d&.CapacityBytes || 0) }
    end
  end
end
