# frozen_string_literal: true

require "base64"
require "json"

module MaintenanceTasks
  # Handles cursor-based pagination for the task index.
  #
  # @api private
  class TasksPage
    PER_PAGE_OPTIONS = [25, 50, 100, 200].freeze
    DEFAULT_PER_PAGE = 50

    def initialize(tasks, cursor: nil, per_page: nil)
      @tasks = tasks
      @cursor = cursor
      @per_page = normalize_per_page(per_page)
    end

    attr_reader :per_page

    # Returns the Tasks visible on the current page.
    #
    # @return [Array<TaskDataIndex>] the current page of Tasks
    def records
      @records ||= @tasks.slice(start_index, per_page) || []
    end

    # Returns whether a Task is visible on the current page.
    #
    # @param task [TaskDataIndex] the Task to find
    # @return [Boolean] whether the current page contains the Task
    def include?(task)
      records.include?(task)
    end

    # Returns the number of Tasks across all pages.
    #
    # @return [Integer] the total number of Tasks
    def total_count
      @tasks.length
    end

    # Returns the one-based position of the first visible Task.
    #
    # @return [Integer] the first visible position, or zero when empty
    def range_start
      records.empty? ? 0 : start_index + 1
    end

    # Returns the one-based position of the last visible Task.
    #
    # @return [Integer] the last visible position
    def range_end
      start_index + records.length
    end

    # Returns whether the Task collection needs pagination controls.
    #
    # @return [Boolean] whether more than one page is available
    def paginated?
      total_count > per_page
    end

    # Returns whether this is the first page.
    #
    # @return [Boolean] whether this is the first page
    def first?
      start_index.zero?
    end

    # Returns whether this is the last page.
    #
    # @return [Boolean] whether this is the last page
    def last?
      range_end >= total_count
    end

    # Returns the cursor for the next page.
    #
    # @return [String, nil] the next cursor, or nil on the last page
    def next_cursor
      encode_cursor(records.last) unless last?
    end

    # Returns the cursor for the previous page.
    #
    # @return [String, nil] the previous cursor, or nil when it is the first page
    def previous_cursor
      return if first?

      previous_start_index = [start_index - per_page, 0].max
      encode_cursor(@tasks[previous_start_index - 1]) if previous_start_index.positive?
    end

    private

    def normalize_per_page(value)
      requested_per_page = Integer(value, exception: false)
      return requested_per_page if requested_per_page&.positive?

      DEFAULT_PER_PAGE
    end

    def start_index
      @start_index ||= begin
        cursor_key = decode_cursor(@cursor)
        cursor_index = @tasks.index { |task| task_key(task) == cursor_key } if cursor_key
        cursor_index ? cursor_index + 1 : 0
      end
    end

    def task_key(task)
      [task.name, task.related_run&.id&.to_s]
    end

    def encode_cursor(task)
      Base64.urlsafe_encode64(task_key(task).to_json, padding: false)
    end

    def decode_cursor(cursor)
      JSON.parse(Base64.urlsafe_decode64(cursor.to_s)) if cursor.present?
    rescue ArgumentError, JSON::ParserError
      nil
    end
  end
end
