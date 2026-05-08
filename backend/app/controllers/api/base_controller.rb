module Api
  class BaseController < ApplicationController
    # 注: ApplicationController は ActionController::API を継承（API モード）。
    # CSRF 保護は組み込まれていないため明示的な無効化は不要。
    # 認証は今後の Phase で別途追加。

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    def render_not_found(exception)
      render json: { error: "Not Found", message: exception.message }, status: :not_found
    end
  end
end
