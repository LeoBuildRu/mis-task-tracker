require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "MIS Task Tracker API",
        version: "v1",
        description: "API трекера задач для МИС: CRUD задач, теги, периодические задачи и состояние конкретных повторений."
      },
      paths: {},
      servers: [
        { url: "http://localhost:3000" }
      ]
    }
  }

  config.openapi_format = :yaml
end
