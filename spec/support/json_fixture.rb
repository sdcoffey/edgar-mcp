# frozen_string_literal: true

def json_fixture(name)
  JSON.parse(file_fixture(name).read)
end
