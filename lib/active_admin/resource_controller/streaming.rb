require 'csv'

module ActiveAdmin
  class ResourceController < BaseController

    # This module overrides CSV responses to allow large data downloads.
    # Could be expanded to JSON and XML in the future.
    #
    module Streaming

      def index(options={}, &block)
        super(options) { |format| format.csv { stream_csv collection } }
      end

      protected

      def csv_line(resource, columns)
        columns.map do |column|
          call_method_or_proc_on resource, column.data
        end
      end

      def stream_csv(collection)
        columns = active_admin_config.csv_builder.columns

        headers['X-Accel-Buffering'] = 'no'
        headers['Cache-Control'] ||= 'no-cache'
        headers['Content-Type'] = 'text/csv; charset=utf-8'
        headers['Content-Disposition'] = "attachment; filename=\"#{csv_filename}\""
        headers.delete("Content-Length")
        response.status = 200
        self.response_body = Enumerator.new do |csv|
          csv << CSV.generate_line(columns.map(&:name))
          collection.find_each do |resource|
            csv << CSV.generate_line(csv_line(resource, columns))
          end
        end
      end
    end
  end
end

