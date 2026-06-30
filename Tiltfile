docker_compose("./docker-compose.yml")

config.define_bool("local-web")

cfg = config.parse()

local_web = cfg.get("local-web", False)

resources = ["web", "db", "worker"]
load('ext://dotenv', 'dotenv')

if local_web:
    dotenv()
    resources.remove("web")
    resources.remove("worker")

    # setup local web
    local_resource(
        "local_web",
        serve_cmd="./bin/rails server -p 3000",
        resource_deps=["db", "local_js", "local_css"],
        readiness_probe=probe(
            period_secs=90, http_get=http_get_action(port=3000, path="/healthcheck.json")
        )
    )
    resources.append("local_web")

    local_resource(
        "local_js",
        serve_cmd="yarn build --watch"
    )
    resources.append("local_js")

    local_resource(
        "local_css",
        serve_cmd="yarn build:css --watch"
    )
    resources.append("local_css")

    local_resource(
        "local_worker",
        serve_cmd="bundle exec rake jobs:work"
    )
    resources.append("local_worker")

config.clear_enabled_resources()
config.set_enabled_resources(resources)
