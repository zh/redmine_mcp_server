# frozen_string_literal: true

Dir[File.join(__dir__, 'custom_fields', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer
  module Tools
    module CustomFields
      def self.register_all(mcp_server)
        [ListCustomFieldsTool.new, CreateCustomFieldTool.new, UpdateCustomFieldTool.new,
         DeleteCustomFieldTool.new].each do |tool|
          mcp_server.register_tool(tool)
        end
      end
    end
  end
end
