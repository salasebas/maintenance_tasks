# frozen_string_literal: true

module MaintenanceTasks
  # Class handles rendering the maintenance_tasks page in the host application.
  # It makes data about available, enqueued, performing, and completed
  # tasks accessible to the views so it can be displayed in the UI.
  #
  # @api private
  class TasksController < ApplicationController
    before_action :set_refresh, only: [:index, :show]

    # Renders the maintenance_tasks/tasks page, displaying
    # available tasks to users, grouped by category.
    def index
      @available_tasks = TaskDataIndex.available_tasks.group_by(&:category)
      @selected_category = params[:tab].presence_in(["new", "active", "completed"]) || "new"
      @tasks_page = TasksPage.new(
        @available_tasks.fetch(@selected_category.to_sym, []),
        cursor: params[:cursor],
        per_page: params[:per_page],
      )
    end

    # Renders the page responsible for providing Task actions to users.
    # Shows running and completed instances of the Task.
    def show
      @task = TaskDataShow.prepare(
        params.fetch(:id),
        runs_cursor: params[:cursor],
        runs_per_page: params[:per_page],
        arguments: params.except(:id, :controller, :action, :refresh, :cursor, :per_page).permit!,
      )
    end

    private

    def set_refresh
      @auto_refresh_enabled = params[:refresh] != "false"
    end
  end
end
