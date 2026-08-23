# frozen_string_literal: true

require "application_system_test_case"

module MaintenanceTasks
  class TasksTest < ApplicationSystemTestCase
    test "list all tasks" do
      visit maintenance_tasks_path

      assert_title "Maintenance Tasks"

      assert_link "Maintenance::UpdatePostsTask"
      assert_link "Maintenance::ErrorTask"
    end

    test "lists tasks by category" do
      visit maintenance_tasks_path

      expected = [
        "Active Tasks",
        "Maintenance::NoCollectionTask Enqueued",
        "Maintenance::NoCollectionTask Paused",
        "Maintenance::UpdatePostsTask Paused",
        "New Tasks",
        "Maintenance::BatchImportPostsTask New",
        "Maintenance::CallbackTestTask New",
        "Maintenance::CancelledEnqueueTask New",
        "Maintenance::CompositePrimaryKeyModelTask New",
        "Maintenance::CustomEnumeratingTask New",
        "Maintenance::EnqueueErrorTask New",
        "Maintenance::ErrorTask New",
        "Maintenance::ImportPostsWithEncodingTask New",
        "Maintenance::ImportPostsWithOptionsTask New",
        "Maintenance::Nested::NestedMore::NestedMoreTask New",
        "Maintenance::Nested::NestedTask New",
        "Maintenance::ParamsTask New",
        "Maintenance::TestTask New",
        "Maintenance::UpdatePostsInBatchesTask New",
        "Maintenance::UpdatePostsModulePrependedTask New",
        "Maintenance::UpdatePostsThrottledTask New",
        "Completed Tasks",
        "Maintenance::StaleTask Succeeded",
        "Maintenance::ImportPostsTask Succeeded",
      ]

      assert_equal expected, page.all("h3").map(&:text)
    end

    test "auto-refresh is not enabled when there are no tasks" do
      TaskDataIndex.stubs(available_tasks: [])

      visit maintenance_tasks_path

      assert_text "The MaintenanceTasks gem has been successfully installed!"
      assert_selector "[data-refresh='']"
      assert_no_selector "[data-refresh=true]"
    end

    test "toggle auto-refresh on the index page" do
      tasks_path = maintenance_tasks.tasks_path

      visit tasks_path

      assert_selector "[data-refresh=true]"
      assert_link "Disable auto-refresh", href: "#{tasks_path}?refresh=false"

      click_on "Disable auto-refresh"

      assert_no_selector "[data-refresh=true]"
      assert_link "Enable auto-refresh", href: tasks_path

      click_on "Enable auto-refresh"

      assert_selector "[data-refresh=true]"
      assert_link "Disable auto-refresh", href: "#{tasks_path}?refresh=false"
    end

    test "hide the auto-refresh toggle when there are no tasks" do
      TaskDataIndex.stubs(available_tasks: [])

      visit maintenance_tasks_path

      assert_no_link "Disable auto-refresh"
      assert_no_link "Enable auto-refresh"
    end

    test "navigates task categories with modern tabs" do
      visit maintenance_tasks_path
      page.execute_script("window.localStorage.setItem('maintenance_tasks.appearance', 'modern')")
      visit maintenance_tasks_path

      assert_selector ".task-tabs__trigger.is-active[aria-current=page]", text: "New Tasks"
      assert_selector ".task-group--new.is-active", visible: true
      assert_no_selector ".task-group--active", visible: true
      assert_no_selector ".task-group--completed", visible: true
      assert_no_selector ".task-group--new .task-card .tag", visible: true

      within ".task-tabs" do
        click_link "Completed Tasks"
      end

      assert_selector ".task-tabs__trigger.is-active[aria-current=page]", text: "Completed Tasks"
      assert_selector ".task-group--completed.is-active", visible: true
      assert_no_selector ".task-group--new", visible: true
      assert_selector ".task-group--completed .task-card .tag", text: "Succeeded", visible: true
    end

    test "shows an empty state for a selected task category" do
      Run.active.delete_all
      visit maintenance_tasks_path
      page.execute_script("window.localStorage.setItem('maintenance_tasks.appearance', 'modern')")
      visit maintenance_tasks_path(tab: "active")

      assert_selector ".task-tabs__trigger.is-active[aria-current=page]", text: "Active Tasks"
      assert_text "There are no active tasks right now."
      assert_no_selector ".task-group--active .task-card", visible: true
    end

    test "paginates modern task categories and keeps the page size in the URL" do
      tasks = 51.times.map do |index|
        TaskDataIndex.new(format("Maintenance::GeneratedTask%02d", index))
      end
      TaskDataIndex.stubs(:available_tasks).returns(tasks)

      visit maintenance_tasks_path(refresh: false)
      page.execute_script("window.localStorage.setItem('maintenance_tasks.appearance', 'modern')")
      visit maintenance_tasks_path(tab: "new", refresh: false)

      assert_selector ".task-pagination", visible: true
      assert_text "1–50 of 51"
      assert_equal 50, page.all(".task-card", visible: true).length

      within ".task-pagination" do
        click_link "Next"
      end

      query = Rack::Utils.parse_query(URI(page.current_url).query)
      assert_equal "new", query["tab"]
      assert_equal "50", query["per_page"]
      assert query["cursor"].present?
      assert_text "51–51 of 51"
      assert_equal 1, page.all(".task-card", visible: true).length

      within ".task-pagination" do
        click_link "Previous"
        find("select[data-per-page-select]").select("25")
      end

      query = Rack::Utils.parse_query(URI(page.current_url).query)
      assert_equal({ "tab" => "new", "per_page" => "25", "refresh" => "false" }, query)
      assert_text "1–25 of 51"
      assert_equal 25, page.all(".task-card", visible: true).length

      find("select[data-per-page-select]").select("100")

      query = Rack::Utils.parse_query(URI(page.current_url).query)
      assert_equal({ "tab" => "new", "per_page" => "100", "refresh" => "false" }, query)
      assert_selector ".task-pagination", visible: true
      assert_no_selector ".task-pagination__navigation", visible: true
      assert_equal "100", find("select[data-per-page-select]").value
      assert_equal 51, page.all(".task-card", visible: true).length

      find("select[data-per-page-select]").select("25")

      assert_text "1–25 of 51"
      assert_equal 25, page.all(".task-card", visible: true).length
    end

    test "uses a custom positive page size from the URL" do
      tasks = 51.times.map do |index|
        TaskDataIndex.new(format("Maintenance::GeneratedTask%02d", index))
      end
      TaskDataIndex.stubs(:available_tasks).returns(tasks)

      visit maintenance_tasks_path(refresh: false)
      page.execute_script("window.localStorage.setItem('maintenance_tasks.appearance', 'modern')")
      visit maintenance_tasks_path(tab: "new", per_page: 4, refresh: false)

      assert_text "1–4 of 51"
      assert_equal "4", find("select[data-per-page-select]").value
      assert_equal 4, page.all(".task-card", visible: true).length

      find("select[data-per-page-select]").select("25")

      query = Rack::Utils.parse_query(URI(page.current_url).query)
      assert_equal({ "tab" => "new", "per_page" => "25", "refresh" => "false" }, query)
      assert_equal 25, page.all(".task-card", visible: true).length
    end

    test "keeps the complete task list visible in classic mode" do
      tasks = 51.times.map do |index|
        TaskDataIndex.new(format("Maintenance::GeneratedTask%02d", index))
      end
      TaskDataIndex.stubs(:available_tasks).returns(tasks)

      visit maintenance_tasks_path(tab: "new", per_page: 25, refresh: false)

      assert_selector "html[data-appearance=classic]"
      assert_no_selector ".task-pagination", visible: true
      assert_equal 51, page.all(".task-card", visible: true).length
    end

    test "opens a Task by clicking anywhere on its modern row" do
      visit maintenance_tasks_path
      page.execute_script("window.localStorage.setItem('maintenance_tasks.appearance', 'modern')")
      visit maintenance_tasks_path

      find(".task-card", text: "Maintenance::BatchImportPostsTask").click

      assert_title "Maintenance::BatchImportPostsTask"
    end

    test "changes and persists display preferences" do
      visit maintenance_tasks_path
      page.execute_script("window.localStorage.clear()")
      visit maintenance_tasks_path

      assert_selector "html[data-appearance=classic][data-theme-preference=system]"
      assert_equal "Classic · System", find("[data-display-preference-summary]").text

      find("summary", text: "Display").click
      within "[data-preference-control=appearance]" do
        click_button "Modern"
        assert_selector "button[data-preference-value=modern][aria-pressed=true]"
      end
      within "[data-preference-control=theme]" do
        click_button "Dark"
        assert_selector "button[data-preference-value=dark][aria-pressed=true]"
      end

      assert_selector "html[data-appearance=modern][data-theme=dark]"
      assert_equal "modern", page.evaluate_script("window.localStorage.getItem('maintenance_tasks.appearance')")
      assert_equal "dark", page.evaluate_script("window.localStorage.getItem('maintenance_tasks.theme')")

      visit maintenance_tasks_path

      assert_selector "html[data-appearance=modern][data-theme=dark]"
      assert_equal "Modern · Dark", find("[data-display-preference-summary]").text

      find("summary", text: "Display").click
      within "[data-preference-control=theme]" do
        click_button "System"
        assert_selector "button[data-preference-value=system][aria-pressed=true]"
      end

      assert_selector "html[data-theme-preference=system]"
      assert_nil find("html", visible: :all)["data-theme"]
    end

    test "show a Task" do
      visit maintenance_tasks_path

      click_on("Maintenance::UpdatePostsTask")

      assert_title "Maintenance::UpdatePostsTask"
      assert_selector "time", text: "January 01, 2020" do |tag|
        assert_equal "2020-01-01 01:00:00 UTC", tag[:title]
      end
      assert_text "Succeeded"
      assert_text "Ran for less than 5 seconds, finished 8 days ago."
    end

    test "show a Task with active and completed runs" do
      visit maintenance_tasks_path

      click_on("Maintenance::UpdatePostsTask")

      assert_title "Maintenance::UpdatePostsTask"
      assert_text "Paused"

      assert_equal ["Active Runs", "Previous Runs"], page.all("h4").map(&:text)
      assert_text(/July 18, 2022 11:05 Paused #\d/)
      assert_text(/January 01, 2020 01:00 Succeeded #\d/)
    end

    test "toggle auto-refresh on a Task with active runs" do
      task_path = maintenance_tasks.task_path("Maintenance::UpdatePostsTask")

      visit task_path

      assert_selector "[data-refresh=true]"
      assert_link "Disable auto-refresh", href: "#{task_path}?refresh=false"

      click_on "Disable auto-refresh"

      assert_no_selector "[data-refresh=true]"
      assert_link "Enable auto-refresh", href: task_path

      click_on "Enable auto-refresh"

      assert_selector "[data-refresh=true]"
      assert_link "Disable auto-refresh", href: "#{task_path}?refresh=false"
    end

    test "hide the auto-refresh toggle when a Task has no active runs" do
      visit maintenance_tasks.task_path("Maintenance::ImportPostsTask")

      assert_no_link "Disable auto-refresh"
      assert_no_link "Enable auto-refresh"
    end

    test "show a Task with stale run" do
      travel_to(maintenance_tasks_runs(:stale_task).ended_at + 2.days) do
        MaintenanceTasks.with(task_staleness_threshold: 1.day) do
          visit maintenance_tasks_path

          within page
            .find("a", text: "Maintenance::StaleTask")
            .find(:xpath, "..")
            .sibling(".has-text-warning") do
            assert_text "This task last ran 1 day ago. Consider removing it as it may be stale."
          end
        end
      end
    end

    test "task with attributes renders default values on the form" do
      visit maintenance_tasks_path

      click_on("Maintenance::ParamsTask")

      content_text = page.find_field("task[content]").text
      assert_equal("default content", content_text)
      integer_attr_val = page.find_field("task[integer_attr]").value
      assert_equal("111222333", integer_attr_val)
    end

    test "task with attributes renders correct field tags on the form" do
      visit maintenance_tasks_path

      click_on "Maintenance::ParamsTask"
      assert_title "Maintenance::ParamsTask"

      content_field = page.find_field("task[content]")
      assert_equal("textarea", content_field.tag_name)
      assert_equal("default content", content_field.value)
      integer_field = page.find_field("task[integer_attr]")
      assert_equal("input", integer_field.tag_name)
      assert_equal("number", integer_field[:type])
      assert_empty(integer_field[:step])
      assert_equal("111222333", integer_field.value)
      big_integer_field = page.find_field("task[big_integer_attr]")
      assert_equal("input", big_integer_field.tag_name)
      assert_equal("number", big_integer_field[:type])
      assert_empty(big_integer_field[:step])
      assert_equal("111222333", big_integer_field.value)
      float_field = page.find_field("task[float_attr]")
      assert_equal("input", float_field.tag_name)
      assert_equal("number", float_field[:type])
      assert_equal("any", float_field[:step])
      assert_equal("12.34", float_field.value)
      decimal_field = page.find_field("task[decimal_attr]")
      assert_equal("input", decimal_field.tag_name)
      assert_equal("number", decimal_field[:type])
      assert_equal("any", decimal_field[:step])
      assert_equal("12.34", decimal_field.value)
      datetime_field = page.find_field("task[datetime_attr]")
      assert_equal("input", datetime_field.tag_name)
      assert_equal("datetime-local", datetime_field[:type])
      assert_equal("", datetime_field.value)
      date_field = page.find_field("task[date_attr]")
      assert_equal("input", date_field.tag_name)
      assert_equal("date", date_field[:type])
      assert_equal("", date_field.value)
      time_field = page.find_field("task[time_attr]")
      assert_equal("input", time_field.tag_name)
      assert_equal("time", time_field[:type])
      assert_equal("", time_field.value)
      boolean_field = page.find_field("task[boolean_attr]")
      assert_equal("input", boolean_field.tag_name)
      assert_equal("checkbox", boolean_field[:type])
      assert_nil(boolean_field[:checked])

      [
        "integer_dropdown_attr",
        "integer_dropdown_attr_proc_no_arg",
        "integer_dropdown_attr_proc_arg",
        "integer_dropdown_attr_from_method",
        "integer_dropdown_attr_callable",
      ].each do |dropdown_integer_attr|
        integer_dropdown_field = page.find_field("task[#{dropdown_integer_attr}]")
        assert_equal("select", integer_dropdown_field.tag_name)
        assert_equal("select-one", integer_dropdown_field[:type])
        integer_dropdown_field_options = integer_dropdown_field.find_all("option").map { |option| option[:value] }
        assert_equal(["", "100", "200", "300"], integer_dropdown_field_options)
      end

      text_integer_field = page.find_field("task[text_integer_attr_unbounded_range]")
      assert_equal("input", text_integer_field.tag_name)
      assert_equal("number", text_integer_field[:type])
      assert_empty(text_integer_field[:step])
      assert_equal("", text_integer_field.value)
    end

    test "task with attributes renders correct field tags on the form with values from query params" do
      visit maintenance_tasks.task_path("Maintenance::ParamsTask", params: {
        content: "string content",
        integer_attr: 12,
        big_integer_attr: 123456789,
        float_attr: 12.34,
        decimal_attr: 43.21,
        datetime_attr: "1984-01-01T12:34:56",
        date_attr: "1984-01-01",
        time_attr: "12:34:56",
        boolean_attr: "true",
        integer_dropdown_attr: "200",
        boolean_dropdown_attr: "false",
      })

      content_field = page.find_field("task[content]")
      assert_equal("textarea", content_field.tag_name)
      assert_equal("string content", content_field.value)
      integer_field = page.find_field("task[integer_attr]")
      assert_equal("input", integer_field.tag_name)
      assert_equal("number", integer_field[:type])
      assert_empty(integer_field[:step])
      assert_equal("12", integer_field.value)
      big_integer_field = page.find_field("task[big_integer_attr]")
      assert_equal("input", big_integer_field.tag_name)
      assert_equal("number", big_integer_field[:type])
      assert_empty(big_integer_field[:step])
      assert_equal("123456789", big_integer_field.value)
      float_field = page.find_field("task[float_attr]")
      assert_equal("input", float_field.tag_name)
      assert_equal("number", float_field[:type])
      assert_equal("any", float_field[:step])
      assert_equal("12.34", float_field.value)
      decimal_field = page.find_field("task[decimal_attr]")
      assert_equal("input", decimal_field.tag_name)
      assert_equal("number", decimal_field[:type])
      assert_equal("any", decimal_field[:step])
      assert_equal("43.21", decimal_field.value)
      datetime_field = page.find_field("task[datetime_attr]")
      assert_equal("input", datetime_field.tag_name)
      assert_equal("datetime-local", datetime_field[:type])
      assert_equal("1984-01-01T12:34:56", datetime_field.value)
      date_field = page.find_field("task[date_attr]")
      assert_equal("input", date_field.tag_name)
      assert_equal("date", date_field[:type])
      assert_equal("1984-01-01", date_field.value)
      time_field = page.find_field("task[time_attr]")
      assert_equal("input", time_field.tag_name)
      assert_equal("time", time_field[:type])
      assert_equal("12:34:56.000", time_field.value)
      boolean_field = page.find_field("task[boolean_attr]")
      assert_equal("input", boolean_field.tag_name)
      assert_equal("checkbox", boolean_field[:type])
      assert_equal("true", boolean_field[:checked])

      integer_dropdown_field = page.find_field("task[integer_dropdown_attr]")
      assert_equal("select", integer_dropdown_field.tag_name)
      assert_equal("select-one", integer_dropdown_field[:type])
      assert_equal("200", integer_dropdown_field.value)
      integer_dropdown_field_options = integer_dropdown_field.find_all("option").map { |option| option[:value] }
      assert_equal(["100", "200", "300"], integer_dropdown_field_options)

      boolean_dropdown_field = page.find_field("task[boolean_dropdown_attr]")
      assert_equal("select", boolean_dropdown_field.tag_name)
      assert_equal("select-one", boolean_dropdown_field[:type])
      assert_equal("false", boolean_dropdown_field.value)
      boolean_dropdown_field_options = boolean_dropdown_field.find_all("option").map { |option| option[:value] }
      assert_equal(["", "true", "false"], boolean_dropdown_field_options)
    end

    test "refresh=false does not interfere with Task parameters" do
      visit maintenance_tasks.task_path("Maintenance::ParamsTask", params: {
        refresh: false,
        content: "string content",
      })

      assert_field "task[content]", with: "string content"
    end

    test "view a Task with multiple pages of Runs" do
      Run.create!(
        task_name: "Maintenance::TestTask",
        created_at: 1.hour.ago,
        started_at: 1.hour.ago,
        tick_count: 2,
        tick_total: 10,
        status: :errored,
        ended_at: 1.hour.ago,
      )
      21.times do |i|
        Run.create!(
          task_name: "Maintenance::TestTask",
          created_at: i.minutes.ago,
          started_at: i.minutes.ago,
          tick_count: 10,
          tick_total: 10,
          status: :succeeded,
          ended_at: i.minutes.ago,
        )
      end

      visit maintenance_tasks_path

      click_on("Maintenance::TestTask")
      assert_no_text "Errored"
      assert_no_link "Previous page"

      click_on("Next page")
      assert_text "Errored"
      assert_no_link "Next page"
      assert_link "Previous page"

      click_on("Previous page")
      assert_no_text "Errored"
      assert_no_link "Previous page"
      assert_link "Next page"
    end

    test "change the number of Previous Runs shown per page" do
      12.times do |i|
        Run.create!(
          task_name: "Maintenance::TestTask",
          created_at: i.minutes.ago,
          started_at: i.minutes.ago,
          tick_count: 10,
          tick_total: 10,
          status: :succeeded,
          ended_at: i.minutes.ago,
        )
      end

      visit(maintenance_tasks.task_path("Maintenance::TestTask", per_page: 4, refresh: false))
      find("summary", text: "Display").click
      within("[data-preference-control=appearance]") do
        click_button("Modern")
      end

      assert_equal("4", find("select[aria-label='Runs per page']").value)
      assert_selector(".run-card", count: 4)

      click_on("Next")
      query = Rack::Utils.parse_query(URI.parse(page.current_url).query)
      assert_equal("4", query["per_page"])
      assert_equal("false", query["refresh"])
      assert(query["cursor"].present?)

      find("select[aria-label='Runs per page']").select("10")
      query = Rack::Utils.parse_query(URI.parse(page.current_url).query)
      assert_equal({ "per_page" => "10", "refresh" => "false" }, query)
      assert_selector(".run-card", count: 10)
    ensure
      page.execute_script("window.localStorage.clear()")
    end

    test "show a deleted Task" do
      visit maintenance_tasks_path + "/tasks/Maintenance::DeletedTask"

      assert_title "Maintenance::DeletedTask"
      assert_text "Succeeded"
      assert_button "Run", disabled: true
    end

    test "visit main page through iframe" do
      visit root_path

      within_frame("maintenance-tasks-iframe") do
        assert_content "Maintenance Tasks"
      end
    end
  end
end
