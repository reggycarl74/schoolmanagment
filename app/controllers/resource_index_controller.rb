class ResourceIndexController < ApplicationController
  private

  def render_index(scope, title:)
    @records = scope.limit(50)
    @title = title
    render "shared/resource_index"
  end
end
