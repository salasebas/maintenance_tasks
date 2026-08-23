# frozen_string_literal: true

require "test_helper"

module MaintenanceTasks
  class TasksPageTest < ActiveSupport::TestCase
    TaskStub = Data.define(:name, :related_run)
    RunStub = Data.define(:id)

    setup do
      @tasks = 205.times.map do |index|
        TaskStub.new(format("Maintenance::Task%03d", index), RunStub.new(index))
      end
    end

    test "defaults to 50 records per page" do
      page = TasksPage.new(@tasks)

      assert_equal 50, page.per_page
      assert_equal @tasks.first(50), page.records
      assert_equal 1, page.range_start
      assert_equal 50, page.range_end
      assert_equal 205, page.total_count
      assert_predicate page, :paginated?
      assert_predicate page, :first?
      refute_predicate page, :last?
    end

    test "accepts the suggested page sizes" do
      TasksPage::PER_PAGE_OPTIONS.each do |per_page|
        assert_equal per_page, TasksPage.new(@tasks, per_page: per_page).records.length
      end
    end

    test "accepts any positive page size from the URL" do
      assert_equal 4, TasksPage.new(@tasks, per_page: 4).per_page
      assert_equal @tasks.first(4), TasksPage.new(@tasks, per_page: 4).records
    end

    test "uses the default page size for invalid values" do
      assert_equal 50, TasksPage.new(@tasks, per_page: 0).per_page
      assert_equal 50, TasksPage.new(@tasks, per_page: -1).per_page
      assert_equal 50, TasksPage.new(@tasks, per_page: "invalid").per_page
    end

    test "uses opaque cursors to navigate forward and backward" do
      first_page = TasksPage.new(@tasks)
      second_page = TasksPage.new(@tasks, cursor: first_page.next_cursor)
      third_page = TasksPage.new(@tasks, cursor: second_page.next_cursor)

      assert_equal @tasks[50, 50], second_page.records
      assert_nil second_page.previous_cursor
      assert_equal first_page.next_cursor, third_page.previous_cursor
    end

    test "returns the remaining records on the last page" do
      page = TasksPage.new(@tasks)
      4.times { page = TasksPage.new(@tasks, cursor: page.next_cursor) }

      assert_equal @tasks.last(5), page.records
      assert_equal 201, page.range_start
      assert_equal 205, page.range_end
      assert_predicate page, :last?
      assert_nil page.next_cursor
    end

    test "falls back to the first page when the cursor is invalid or no longer present" do
      invalid_page = TasksPage.new(@tasks, cursor: "not-a-cursor")
      missing_task_page = TasksPage.new(@tasks.drop(50), cursor: TasksPage.new(@tasks).next_cursor)

      assert_equal @tasks.first(50), invalid_page.records
      assert_equal @tasks.drop(50).first(50), missing_task_page.records
      assert_predicate invalid_page, :first?
      assert_predicate missing_task_page, :first?
    end
  end
end
