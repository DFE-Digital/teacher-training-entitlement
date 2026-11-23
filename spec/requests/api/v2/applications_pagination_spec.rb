require "rails_helper"

RSpec.describe "API V2 applications sorting and cursor pagination", type: :request do
  include_context "with API V2 enabled"

  let(:lead_provider) { create(:lead_provider) }
  let(:profile) { "https://jsonapi.org/profiles/ethanresnick/cursor-pagination" }
  let(:base_time) { Time.zone.parse("2025-01-01T09:00:00Z") }

  def json
    JSON.parse(response.body)
  end

  def ids
    json["data"].map { |a| a["id"] }
  end

  def list(params = {})
    api_get("/api/v2/applications", lead_provider:, params:)
  end

  def follow(link)
    uri = URI(link)
    api_get(uri.path, lead_provider:, params: Rack::Utils.parse_nested_query(uri.query))
  end

  def link_query(name)
    Rack::Utils.parse_nested_query(URI(json["links"][name]).query)
  end

  # Sets every timestamp the effective updated_at is built from.
  def set_times(application, created_at:, updated_at:)
    application.update_columns(created_at:, updated_at:)
    application.user.update_columns(significantly_updated_at: updated_at)
    application.application_lead_providers.update_all(updated_at:)
    application.institution&.update_columns(updated_at:)
  end

  def create_application(created_at:, updated_at:)
    create(:application, lead_provider:).tap { |application| set_times(application, created_at:, updated_at:) }
  end

  def error
    json["errors"].first
  end

  describe "sorting" do
    let!(:first_created) { create_application(created_at: base_time, updated_at: base_time + 3.hours) }
    let!(:second_created) { create_application(created_at: base_time + 1.hour, updated_at: base_time + 1.hour) }
    let!(:third_created) { create_application(created_at: base_time + 2.hours, updated_at: base_time + 2.hours) }

    it "sorts by effective updated_at ascending by default" do
      list

      expect(ids).to eq([second_created, third_created, first_created].map(&:ecf_id))
    end

    it "uses the teacher's change in the updated_at sort" do
      second_created.user.update_columns(significantly_updated_at: base_time + 4.hours)
      list

      expect(ids).to eq([third_created, first_created, second_created].map(&:ecf_id))
    end

    {
      "created_at" => %i[first_created second_created third_created],
      "+created_at" => %i[first_created second_created third_created],
      "-created_at" => %i[third_created second_created first_created],
      "-updated_at" => %i[first_created third_created second_created],
    }.each do |sort, expected|
      it "sorts by #{sort}" do
        list(sort:)

        expect(ids).to eq(expected.map { |name| public_send(name).ecf_id })
      end
    end

    it "treats an unencoded + (decoded as a space) as ascending" do
      list(sort: " created_at")

      expect(ids).to eq([first_created, second_created, third_created].map(&:ecf_id))
    end

    it "sorts by several fields" do
      set_times(third_created, created_at: base_time + 2.hours, updated_at: base_time + 3.hours)
      list(sort: "-updated_at,created_at")

      expect(ids).to eq([first_created, third_created, second_created].map(&:ecf_id))
    end

    it "breaks ties by application id" do
      [first_created, second_created, third_created].each { |app| set_times(app, created_at: base_time, updated_at: base_time) }
      list

      expect(ids).to eq([first_created, second_created, third_created].map(&:ecf_id).sort)
    end

    ["name", "status", "updated_at,updated_at", "", ",created_at", "-", "created_at,"].each do |sort|
      it "rejects the sort #{sort.inspect} with a JSON:API 400" do
        list(sort:)

        expect([response.status, response.media_type, error["source"], error["links"]]).to eq(
          [400, "application/vnd.api+json", { "parameter" => "sort" }, { "type" => ["#{profile}/unsupported-sort"] }],
        )
      end
    end

    it "rejects a non-string sort" do
      list(sort: %w[created_at])

      expect([response.status, error["source"]]).to eq([400, { "parameter" => "sort" }])
    end
  end

  describe "pagination" do
    let!(:applications) do
      Array.new(5) { |i| create_application(created_at: base_time + i.hours, updated_at: base_time + i.hours) }
    end
    let(:all_ids) { applications.map(&:ecf_id) }

    it "returns the first page of the requested size" do
      list(page: { size: "2" })

      expect(ids).to eq(all_ids.first(2))
    end

    it "uses a default page size of 100" do
      stub_const("API::V2::Pagination::DEFAULT_PAGE_SIZE", 2)
      list

      expect(ids.size).to eq(2)
    end

    it "accepts the maximum page size of 3000" do
      list(page: { size: "3000" })

      expect([response.status, ids]).to eq([200, all_ids])
    end

    it "has no previous link on the first page" do
      list(page: { size: "2" })

      expect(json["links"]["prev"]).to be_nil
    end

    it "has no next link when there are no more results" do
      list(page: { size: "5" })

      expect(json["links"]["next"]).to be_nil
    end

    it "has no totals" do
      list(page: { size: "2" })

      expect(json).not_to have_key("meta")
    end

    it "walks forward through every application once" do
      list(page: { size: "2" })
      seen = ids
      while json["links"]["next"]
        follow(json["links"]["next"])
        seen += ids
      end

      expect(seen).to eq(all_ids)
    end

    it "walks back from the last page with prev links" do
      list(page: { size: "2" })
      follow(json["links"]["next"]) while json["links"]["next"]
      seen = ids
      while json["links"]["prev"]
        follow(json["links"]["prev"])
        seen = ids + seen
      end

      expect(seen).to eq(all_ids)
    end

    it "returns the page before a cursor" do
      list(page: { size: "4" })
      follow(json["links"]["next"])
      follow(json["links"]["prev"])

      expect(ids).to eq(all_ids.first(4))
    end

    it "keeps filters, include and sort in the next link" do
      list(page: { size: "2" }, include: "teacher", sort: "-created_at", filter: { updated_since: "2000-01-01T00:00:00Z" })

      expect(link_query("next").except("page")).to eq(
        "include" => "teacher", "sort" => "-created_at", "filter" => { "updated_since" => "2000-01-01T00:00:00Z" },
      )
    end

    it "keeps the page size and a cursor in the next link" do
      list(page: { size: "2" })

      expect(link_query("next")["page"].keys).to contain_exactly("size", "after")
    end

    it "uses a before cursor in the prev link" do
      list(page: { size: "2" })
      follow(json["links"]["next"])

      expect(link_query("prev")["page"].keys).to contain_exactly("size", "before")
    end

    it "links to the current request as self" do
      list(page: { size: "2" }, sort: "created_at")

      expect(link_query("self")).to eq("page" => { "size" => "2" }, "sort" => "created_at")
    end

    it "is not shifted by changes before the cursor" do
      list(page: { size: "2" })
      next_link = json["links"]["next"]
      applications.first.destroy!
      follow(next_link)

      expect(ids).to eq(all_ids[2, 2])
    end

    it "moves an application updated during a sync to the end" do
      list(page: { size: "2" })
      next_link = json["links"]["next"]
      set_times(applications.second, created_at: base_time, updated_at: base_time + 1.day)
      follow(next_link)
      follow(json["links"]["next"])

      expect(ids).to eq([all_ids.last, applications.second.ecf_id])
    end

    it "pages through a mixed-direction sort in the same order as one page" do
      set_times(applications.third, created_at: base_time + 2.hours, updated_at: base_time + 4.hours)
      list(sort: "-updated_at,created_at")
      unpaginated = ids
      list(sort: "-updated_at,created_at", page: { size: "1" })
      seen = ids
      while json["links"]["next"]
        follow(json["links"]["next"])
        seen += ids
      end

      expect(seen).to eq(unpaginated)
    end

    it "keeps the cursor stable for ties" do
      applications.each { |app| set_times(app, created_at: base_time, updated_at: base_time) }
      list(page: { size: "2" })
      seen = ids
      while json["links"]["next"]
        follow(json["links"]["next"])
        seen += ids
      end

      expect(seen).to eq(all_ids.sort)
    end

    {
      "zero" => "0",
      "negative" => "-1",
      "non-numeric" => "abc",
      "decimal" => "1.5",
    }.each do |description, size|
      it "rejects a #{description} page[size]" do
        list(page: { size: })

        expect([response.status, response.media_type, error["source"]]).to eq(
          [400, "application/vnd.api+json", { "parameter" => "page[size]" }],
        )
      end
    end

    it "rejects a page[size] above the maximum" do
      list(page: { size: "3001" })

      expect([response.status, error.slice("source", "meta", "links")]).to eq(
        [
          400,
          {
            "source" => { "parameter" => "page[size]" },
            "meta" => { "page" => { "maxSize" => 3000 } },
            "links" => { "type" => ["#{profile}/max-size-exceeded"] },
          },
        ],
      )
    end

    it "rejects using page[after] and page[before] together" do
      list(page: { size: "2" })
      cursor = link_query("next")["page"]["after"]
      list(page: { after: cursor, before: cursor })

      expect([response.status, error["links"]]).to eq([400, { "type" => ["#{profile}/range-pagination-not-supported"] }])
    end

    %w[after before].each do |param|
      it "rejects an invalid page[#{param}] cursor" do
        list(page: { param => "not-a-cursor" })

        expect([response.status, error["source"]]).to eq([400, { "parameter" => "page[#{param}]" }])
      end
    end

    it "rejects a cursor for another sort order" do
      list(page: { size: "2" })
      list(page: { after: link_query("next")["page"]["after"] }, sort: "created_at")

      expect([response.status, error["source"]]).to eq([400, { "parameter" => "page[after]" }])
    end

    it "rejects a tampered cursor" do
      cursor = Base64.urlsafe_encode64(JSON.generate("sort" => "updated_at:asc,id:asc", "values" => %w[yesterday nope]), padding: false)
      list(page: { after: cursor })

      expect([response.status, error["source"]]).to eq([400, { "parameter" => "page[after]" }])
    end

    {
      "an unknown page parameter" => { number: "1" },
      "the former page-number parameters" => { page: "1", per_page: "2" },
      "a nested page value" => { size: { a: "1" } },
    }.each do |description, page|
      it "rejects #{description}" do
        list(page:)

        expect([response.status, error["source"]]).to eq([400, { "parameter" => "page" }])
      end
    end

    it "rejects a non-hash page parameter" do
      list(page: "2")

      expect([response.status, error["source"]]).to eq([400, { "parameter" => "page" }])
    end

    it "validates pagination before querying applications" do
      allow(API::V2::Applications::Query).to receive(:new)
      list(page: { size: "0" })

      expect(API::V2::Applications::Query).not_to have_received(:new)
    end
  end
end
