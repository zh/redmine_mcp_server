# frozen_string_literal: true

Dir[File.join(__dir__, 'time_entries', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer
  module Tools
    module TimeEntries
      def self.register_all(mcp_server)
        [ListTimeEntriesTool.new, GetTimeEntryTool.new, CreateTimeEntryTool.new, UpdateTimeEntryTool.new,
         DeleteTimeEntryTool.new, BulkCreateTimeEntriesTool.new].each { |tool|
          mcp_server.register_tool(tool)
        }
      end
    end
  end
end
