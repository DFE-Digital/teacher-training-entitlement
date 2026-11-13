require "rails_helper"
require "open3"
require "tmpdir"
require "yaml"

# A deploy run for an older main commit can finish its tests after a newer run.
# These specs cover the freshness check each deploy stage runs inside its
# environment lock, and the workflow wiring that stops an obsolete run.
RSpec.describe "main deploy ordering" do
  let(:script) { Rails.root.join(".github/scripts/check-main-freshness.sh").to_s }
  let(:tmp) { Dir.mktmpdir }
  let(:remote) { File.join(tmp, "remote.git") }
  let(:work) { File.join(tmp, "work") }
  let(:output_file) { File.join(tmp, "output") }

  def git(*args, dir: work)
    out, status = Open3.capture2e("git", *args, chdir: dir)
    raise "git #{args.join(' ')} failed: #{out}" unless status.success?

    out.strip
  end

  def commit(message)
    File.write(File.join(work, "file"), message)
    git("add", "file")
    git("-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-m", message)
    git("rev-parse", "HEAD")
  end

  def push_main
    git("push", "-f", "origin", "HEAD:refs/heads/main")
  end

  # Runs the check for +sha+ as one deploy stage and returns [fresh output, status]
  def check(sha, env = {})
    File.write(output_file, "")
    _out, status = Open3.capture2e({ "SHA" => sha, "REMOTE" => remote, "GITHUB_OUTPUT" => output_file }.merge(env), "bash", script)
    [File.read(output_file).strip, status]
  end

  before do
    git("init", "--bare", remote, dir: tmp)
    FileUtils.mkdir_p(work)
    git("init", "-b", "main")
    git("remote", "add", "origin", remote)
  end

  after { FileUtils.remove_entry(tmp) }

  context "when run A (older) reaches a stage after run B (newer) was pushed" do
    let!(:sha_a) { commit("A") }
    let!(:sha_b) { commit("B") }

    before { push_main }

    it "marks the older commit obsolete" do
      expect(check(sha_a).first).to eq("fresh=false")
    end

    it "does not fail the stage when skipping" do
      expect(check(sha_a).last).to be_success
    end

    it "lets the newer commit deploy" do
      expect(check(sha_b).first).to eq("fresh=true")
    end
  end

  context "when A deploys before B is pushed" do
    let!(:sha_a) { commit("A") }

    before { push_main }

    it "lets A deploy while it is the tip" do
      expect(check(sha_a).first).to eq("fresh=true")
    end

    it "makes A obsolete at a later stage once B is pushed" do
      commit("B")
      push_main
      expect(check(sha_a).first).to eq("fresh=false")
    end
  end

  context "when the branch was force-pushed away from the commit" do
    let!(:sha_a) { commit("A") }

    before do
      push_main
      git("checkout", "--orphan", "other")
      commit("rewritten")
      push_main
    end

    it "treats the replaced commit as obsolete" do
      expect(check(sha_a).first).to eq("fresh=false")
    end
  end

  context "when the tip of main cannot be determined" do
    let!(:sha_a) { commit("A") }

    it "fails closed when main does not exist on the remote" do
      expect(check(sha_a).last).not_to be_success
    end

    it "fails closed when the remote is unreachable" do
      expect(check(sha_a, "REMOTE" => File.join(tmp, "missing.git")).last).not_to be_success
    end

    it "writes no freshness output on failure" do
      expect(check(sha_a).first).to eq("")
    end
  end

  describe "workflow wiring" do
    let(:jobs) { YAML.load_file(Rails.root.join(".github/workflows/rspec.yml"))["jobs"] }

    %w[deploy-staging deploy-sandbox deploy-production].each do |name|
      context name do
        let(:job) { jobs.fetch(name) }
        let(:deploy_step) { job["steps"].find { |step| step["uses"] == "./.github/actions/deploy-environment-to-aks" } }

        it "keeps its per-environment lock" do
          expect(job["concurrency"]).to eq("deploy_app_#{name.delete_prefix('deploy-')}")
        end

        it "checks freshness before deploying" do
          ids = job["steps"].pluck("id")
          expect(ids.index("freshness")).to be < ids.index("deploy")
        end

        it "only deploys when fresh" do
          expect(deploy_step["if"]).to eq("steps.freshness.outputs.fresh == 'true'")
        end

        it "exposes freshness to later stages" do
          expect(job["outputs"]["fresh"]).to eq("${{ steps.freshness.outputs.fresh }}")
        end
      end
    end

    it "stops sandbox when staging was obsolete" do
      expect(jobs["deploy-sandbox"]["if"]).to include("needs.deploy-staging.outputs.fresh == 'true'")
    end

    it "stops production when sandbox was obsolete" do
      expect(jobs["deploy-production"]["if"]).to include("needs.deploy-sandbox.outputs.fresh == 'true'")
    end

    it "stops domains deployment when production was obsolete" do
      expect(jobs["deploy_domains_infra"]["if"]).to include("needs.deploy-production.outputs.fresh == 'true'")
    end

    describe "domains jobs" do
      let(:infra) { jobs.fetch("deploy_domains_infra") }
      let(:env) { jobs.fetch("deploy_domains_env") }

      def step_ids(job)
        job["steps"].pluck("id")
      end

      def apply_step(job, id)
        job["steps"].find { |step| step["id"] == id }
      end

      it "uses distinct lock groups for infrastructure and environments" do
        expect(infra["concurrency"]).not_to eq(env["concurrency"])
      end

      it "locks infrastructure on its own group" do
        expect(infra["concurrency"]).to eq("domains_infra")
      end

      it "locks each environment member on its own group" do
        expect(env["concurrency"]).to eq("domains_env_${{ matrix.domain_environment }}")
      end

      it "no longer reuses the production deploy group" do
        expect([infra["concurrency"], env["concurrency"]]).not_to include("deploy_production")
      end

      it "keeps environments serial" do
        expect(env["strategy"]["max-parallel"]).to eq(1)
      end

      it "keeps the production environment approval on both jobs" do
        expect([infra, env].map { |job| job["environment"]["name"] }).to eq(%w[production production])
      end

      it "keeps the staging, sandbox, production matrix" do
        expect(env["strategy"]["matrix"]["domain_environment"]).to eq(%w[staging sandbox production])
      end

      it "checks freshness before the infrastructure apply" do
        expect(step_ids(infra).index("freshness")).to be < step_ids(infra).index("deploy_domains_infra")
      end

      it "checks freshness before each environment apply" do
        expect(step_ids(env).index("freshness")).to be < step_ids(env).index("deploy_domains_env")
      end

      it "only applies infrastructure when fresh" do
        expect(apply_step(infra, "deploy_domains_infra")["if"]).to eq("steps.freshness.outputs.fresh == 'true'")
      end

      it "only applies each environment when fresh" do
        expect(apply_step(env, "deploy_domains_env")["if"]).to eq("steps.freshness.outputs.fresh == 'true'")
      end

      it "exposes infrastructure freshness" do
        expect(infra["outputs"]["fresh"]).to eq("${{ steps.freshness.outputs.fresh }}")
      end

      it "blocks the environment matrix when infrastructure was obsolete" do
        expect(env["if"]).to include("needs.deploy_domains_infra.outputs.fresh == 'true'")
      end

      it "pins the freshness checkout to the event SHA the composite actions use" do
        checkout = infra["steps"].first
        expect(checkout["with"]["ref"]).to eq("${{ github.sha }}")
      end

      it "pins each environment checkout to the event SHA" do
        expect(env["steps"].first["with"]["ref"]).to eq("${{ github.sha }}")
      end

      it "passes the event SHA to the freshness check" do
        expect(apply_step(env, "freshness")["env"]["SHA"]).to eq("${{ github.sha }}")
      end
    end

    it "has no workflow-level concurrency that could cancel queued CI" do
      expect(YAML.load_file(Rails.root.join(".github/workflows/rspec.yml"))).not_to have_key("concurrency")
    end
  end
end
