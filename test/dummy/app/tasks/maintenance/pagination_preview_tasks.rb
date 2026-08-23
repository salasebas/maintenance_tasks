# frozen_string_literal: true

module Maintenance
  module PaginationPreviewTasks
    if Rails.env.development?
      100.times do |index|
        task_class = Class.new(MaintenanceTasks::Task) do
          no_collection

          def process
            # This task exists only to preview pagination in the dummy app.
          end
        end

        const_set(format("PreviewTask%03d", index + 1), task_class)
      end
    end
  end
end
